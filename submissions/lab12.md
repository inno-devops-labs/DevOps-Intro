# Lab 12 submission

**Host:** Apple Silicon Mac (no WASM toolchain). **Build/bench env:** University VM (Linux x86_64, 1.8 GiB RAM + swap). **Toolchain:** Spin 3.4.0, TinyGo 0.41.1 (Nix), wasmtime 29.0.0, hyperfine 1.18.0.

---

## Task 1 — Spin SDK `/time` endpoint

### Source

- [`wasm/main.go`](../wasm/main.go)
- [`wasm/spin.toml`](../wasm/spin.toml)
- [`wasm/go.mod`](../wasm/go.mod) · SDK `github.com/spinframework/spin-go-sdk/v2 v2.2.1`

Scaffolded layout matches `spin new -t http-go` (Spin 3.4 templates installed on VM). Route `/time`, `allowed_outbound_hosts = []`, TinyGo `wasip1` + `-buildmode=c-shared`.

### Build

[`attachments/lab12/spin-build.log`](attachments/lab12/spin-build.log)

```text
Finished building all Spin components
main.wasm  362115 bytes
```

Built with `GOMAXPROCS=1` on the VM (TinyGo + Go 1.26 via Nix; system Go 1.22 alone fails TinyGo 0.41 `net` build).

### Runtime proof

[`attachments/lab12/spin-time.json`](attachments/lab12/spin-time.json)

```bash
spin up --listen 127.0.0.1:3000
curl -s http://127.0.0.1:3000/time | python3 -m json.tool
```

```json
{
    "unix": 1783548307,
    "iso": "2026-07-08T22:05:07Z",
    "hour_minute": "22:05",
    "moscow": "2026-07-08 22:05:07",
    "tz": "UTC+3"
}
```

### Design questions (a–d)

**a) Browser WASM vs server WASM**

`go build -target=js/wasm` targets the browser ABI (DOM callbacks via `syscall/js`). `tinygo build -target=wasip1` targets WASI — no DOM, no full stdlib, but a portable server module with explicit capabilities. You lose browser APIs and much of upstream Go stdlib; you gain a small, sandboxed artifact runnable in Spin/wasmtime.

**b) Why `-buildmode=c-shared`?**

Spin's host expects the module to export the wasi-http handler symbols as a shared library-style component, not a bare `_start` CLI entrypoint. Without `-buildmode=c-shared`, the handler isn't exported → `spin up` serves HTTP 500.

**c) `allowed_outbound_hosts = []` vs Docker `--network none`**

Spin's capability model denies outbound network at manifest level — the runtime won't grant socket capabilities the module didn't request. Docker `--network none` removes network namespaces at the container level, but the process still carries a larger Linux attack surface (full libc, more syscalls). WASM defaults to least-privilege per component.

**d) TinyGo stdlib gaps hit**

- `time.LoadLocation("Europe/Moscow")` — no embedded tzdata → used `UTC().Add(3 * time.Hour)`.
- Avoided `json.NewEncoder` + `map[string]any` (reflection-heavy) → built JSON with `fmt.Sprintf` and `%q`.

---

## Task 2 — Perf vs Lab 6 Docker

**Test rig:** University VM, Ubuntu 24.04, 1.8 GiB RAM, 7.8 GiB swap, x86_64. Lab 6 image `quicknotes:lab6` (distroless), Spin on `:3000`, Docker on `:18080`.

### Table

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|-----------|-------------:|-----------------:|
| Artifact size | 3.8 MB | 354 KB (`main.wasm`) |
| Cold start p50 | 1.4 s | 12.9 s |
| Warm latency p50 | 7.1 ms | 9.4 ms |
| Warm latency p95 | 7.8 ms | 10.5 ms |

Sources: [`attachments/lab12/sizes.txt`](attachments/lab12/sizes.txt), [`cold-docker.txt`](attachments/lab12/cold-docker.txt), [`cold-spin.txt`](attachments/lab12/cold-spin.txt), [`warm-docker.json`](attachments/lab12/warm-docker.json), [`warm-spin.json`](attachments/lab12/warm-spin.json).

> Spin cold start on this 1.8 GiB VM is dominated by process restart + wasmtime init under memory pressure (consistent ~13 s across 5 samples). Warm requests stay in single-digit milliseconds once `spin up` is running.

### Design questions (e–g)

**e) What dominates cold start?**

Docker: image layer setup + namespace/cgroup init + process start. Spin: `spin up` process + wasmtime engine init + WASM module load/instantiate (on this VM, memory pressure amplifies restart cost).

**f) When is WASM better, when Docker?**

WASM wins for tiny, short-lived, high-churn functions (small artifact, fast per-request instantiation in warm server). Docker wins for full apps needing rich stdlib, long-lived state, complex networking, and mature ops tooling.

**g) Multi-tenant safety**

WASM capability sandboxes make it harder for a tenant module to reach hosts/files/sockets it wasn't granted — e.g. exfiltrating via outbound TCP to arbitrary IPs (`allowed_outbound_hosts = []` blocks this at the manifest).

---

## Bonus — Two WASM execution models

### wasm-cli (standalone WASI)

[`wasm-cli/main.go`](../wasm-cli/main.go)

```bash
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
```

[`attachments/lab12/wasm-cli-time.json`](attachments/lab12/wasm-cli-time.json) — same Moscow JSON as Spin.

### Comparison

| | Spin wasi-http | wasmtime CLI |
|--|--:|--:|
| `main.wasm` size | 354 KB | 192 KB |
| Cold (per-invocation / restart) p50 | 12.9 s (`spin up` restart) | 12 ms (`wasmtime run`) |

[`attachments/lab12/cold-wasmtime.txt`](attachments/lab12/cold-wasmtime.txt)

### Design questions (h–j)

**h) Why can't the Spin component run under bare `wasmtime run`?**

Task 1 builds a **wasi-http component** exporting HTTP handler symbols for a persistent host. Bare `wasmtime run` expects a CLI module with `_start` reading env/stdin — different ABI.

**i) What does Spin add on top of wasmtime?**

Manifest routing (`spin.toml`), wasi-http server loop, per-component outbound policy, instance lifecycle — wasmtime is the engine; Spin is the application host.

**j) When does each model fit?**

Per-invocation `wasmtime run` (CGI-style): rare admin tasks, CLI tools, batch jobs. Spin persistent server: HTTP microservices, edge functions with steady request traffic.

---

## Artifacts

| Path | Description |
|------|-------------|
| `wasm/` | Spin component (`main.go`, `spin.toml`, `go.mod`, `go.sum`) |
| `wasm-cli/` | Standalone WASI module for `wasmtime run` |
| `cloud/scripts/lab12-vm-*.sh` | VM setup + benchmark scripts |
| `submissions/attachments/lab12/` | Build logs, curl output, hyperfine JSON, cold-start samples |
