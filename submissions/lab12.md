# Lab 12 Submission — WebAssembly / Spin

## Tooling (pinned)

| Tool | Version |
|------|---------|
| Spin | 3.4.0 |
| TinyGo | 0.34.0 (Go 1.22.12, LLVM 18.1.2) |
| Go host | 1.22.12 |
| wasmtime | 46.0.1 |
| hyperfine | 1.18.0 |

**Test rig:** Linux `x86_64` VPS (`6.8.0-134-generic`), ~3.8 GiB RAM.

> Note: TinyGo **0.41** failed here (`internal/strconv` GOROOT overlay + Spin OOM/`random_get` trap on init). TinyGo **0.34** + Spin **3.4** matches the lab’s TinyGo+`wasip1`+`-buildmode=c-shared` path and runs cleanly. Scaffolded with `spin new -t http-go`.

---

## Task 1 — Spin SDK `/time` endpoint (4 pts)

### Layout

- [`wasm/main.go`](../wasm/main.go)
- [`wasm/spin.toml`](../wasm/spin.toml)
- [`wasm/go.mod`](../wasm/go.mod) / [`wasm/go.sum`](../wasm/go.sum)
- [`wasm/main.wasm`](../wasm/main.wasm) (built artifact, ~123 KiB)

`spin.toml` route `/time`, `allowed_outbound_hosts = []`, build:

```text
tinygo build -target=wasip1 -gc=leaking -scheduler=none -buildmode=c-shared -no-debug -o main.wasm .
```

(`-gc=leaking -scheduler=none` required for stable TinyGo→Spin wasi-http init on this host.)

### `spin build` size

```text
Finished building all Spin components
-rw-r--r-- 1 root root 123K main.wasm
```

### `curl` JSON (Moscow)

```text
$ curl -s http://127.0.0.1:3000/time
{"unix":1784037658,"iso":"2026-07-14T17:00:58+03:00","hour_minute":"17:00","timezone":"Europe/Moscow","offset":"+03:00"}
```

### Design questions (a–d)

**a) Browser WASM (`js/wasm`) vs server (`wasip1`)**  
Browser target expects a JS host (syscall stubs via `wasm_exec.js`); you lose direct WASI filesystem/clock/random imports and gain DOM/JS glue. Server `wasip1` targets WASI Preview1 — no browser APIs, but a capability host (Spin/wasmtime) can grant clocks/stdio/etc. Missing in server target: JS interop / DOM. Gained: portable server sandbox without a JS runtime.

**b) Why `-buildmode=c-shared`?**  
Spin’s wasi-http adapter expects the module to export the Spin/WASI-HTTP handler symbols (a shared library–style component), not a CLI `_start`. Without `c-shared`, TinyGo emits a command module; `spin up` returns 500 with an empty handler (or fails to bind the component exports).

**c) `allowed_outbound_hosts = []` vs Docker `--network none`**  
Spin’s capability model: the guest can only open outbound HTTP to hostnames explicitly listed. Empty list = no egress. Docker `--network none` removes the container’s network namespace interfaces entirely. Similar intent (deny-by-default network), different mechanism — Spin policy is per-component inside a shared host process; Docker isolation is kernel-namespace based.

**d) TinyGo stdlib gaps hit in this lab**  
`time.LoadLocation("Europe/Moscow")` needs tzdata TinyGo doesn’t embed — used `time.FixedZone("MSK", 3*3600)` instead. Also avoided `encoding/json` + `map[string]any` (reflection-heavy) in favor of `fmt.Sprintf` JSON.

---

## Task 2 — Perf vs Lab 6 Docker (4 pts)

Endpoints compared: Spin `GET /time` vs Docker QuickNotes `GET /health` (cheap JSON handlers; cold/warm quantify runtime overhead).

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|-----------|-------------:|-----------------:|
| Artifact size | **22.5 MB** (`quicknotes:lab6`) | **123 KiB** (`main.wasm`) |
| Cold start (p50) | **328.7 ms** | **84.5 ms** |
| Warm latency p50 | **9.68 ms** | **10.36 ms** |
| Warm latency p95 | **11.68 ms** | **12.03 ms** |

Cold samples (ms): Spin `66.8–96.3`; Docker `315.0–356.9`. Warm: `hyperfine --warmup 5 --runs 50` (curl client overhead dominates warm numbers — nearly tied).

### Design questions (e–g)

**e) What dominates cold start?**  
Docker: image graph setup, containerd/shim, namespace + cgroup init, process start, then app listen. Spin: load/instantiate the tiny `.wasm` in wasmtime + HTTP trigger bind — no OCI extract or Linux namespaces.

**f) When is WASM better / Docker still right?**  
WASM wins for high-fan-out edge functions, multi-tenant plugins, ms-scale scaling, tiny artifacts. Docker still right for full Linux ABI apps (cgo, local disk services, systemd-like daemons), rich tooling/ecosystem, and when you need arbitrary syscalls the WASI surface doesn’t grant.

**g) Multi-tenant attack WASM makes harder**  
A guest escape to open raw host sockets, read `/etc/passwd`, or ptrace neighbors is far harder — no ambient Linux syscall table. Capability sandbox denies FS/net unless granted. Classic container breakout via kernel syscall bugs is a weaker path than against shared-kernel Docker tenants (still possible against the WASM runtime, but the attack surface is smaller).

---

## Bonus — Standalone WASI CLI under wasmtime (2 pts)

### Build / run

```bash
cd wasm-cli
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
```

Output:

```text
Content-Type: application/json

{"unix":1784037713,"iso":"2026-07-14T17:01:53+03:00","hour_minute":"17:01","timezone":"Europe/Moscow","offset":"+03:00"}
```

### Size + cold-start

| Runtime model | Module size | Cold start p50 |
|---------------|------------:|---------------:|
| Spin wasi-http (persistent server) | 123 KiB | 84.5 ms (server process) |
| wasmtime CLI (per invocation) | **183 KiB** | **15.3 ms** / invoke |

Per-invocation wasmtime is faster to first byte for a one-shot, but Spin wins when amortizing one server across many HTTP requests (no process/module startup each hit beyond warm path ~10 ms curl RTT).

### Design questions (h–j)

**h) Why can’t the Spin component run under bare `wasmtime run`?**  
It exports a **wasi-http** handler component, not a WASI CLI `_start`/command entrypoint. `wasmtime run` looks for a CLI start; use `wasmtime serve` (or Spin) for wasi-http components.

**i) What does Spin add atop wasmtime?**  
HTTP trigger/server loop, `spin.toml` routing & config, instance pooling/lifecycle, outbound-host allowlists, logging/trigger adapters — wasmtime is the engine; Spin is the app platform.

**j) When each model fits**  
- **Per-invocation `wasmtime run`:** CLI filters, one-shot jobs, CGI-like plugins invoked rarely.  
- **Spin persistent wasi-http:** HTTP APIs / edge routes with many warm requests sharing one loaded module.

---

## Reproduce

```bash
# Spin 3.4 + TinyGo 0.34 recommended for this tree
cd wasm && spin build && spin up --listen 127.0.0.1:3000
curl -s http://127.0.0.1:3000/time

cd ../wasm-cli
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
```
