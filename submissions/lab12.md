# Lab 12 — WebAssembly Containers (Spin + TinyGo)

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + WSL2  
**Tool versions:** Spin 3.4.0, TinyGo 0.40.0, wasmtime 34.0.0, `github.com/spinframework/spin-go-sdk/v2` v2.2.1

---

## Task 1 — Spin SDK `/time` endpoint

### Source

- [`wasm/main.go`](../wasm/main.go)
- [`wasm/spin.toml`](../wasm/spin.toml)
- [`wasm/go.mod`](../wasm/go.mod)

Scaffolded to match `spin new -t http-go` layout (Spin 3.x / CNCF SDK).

### `spin build` output

```text
$ spin build
Building component moscow-time with `tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components
$ ls -lh main.wasm
-rw-r--r-- 1 user user 221K main.wasm
```

### `curl` proof

```text
$ spin up --listen 127.0.0.1:13001
$ curl -s http://127.0.0.1:13001/time | python3 -m json.tool
{
    "unix": 1782912324,
    "iso": "2026-07-01T16:25:24+03:00",
    "hour_minute": "16:25",
    "moscow_utc_offset": "+03:00"
}
```

### Design questions (Task 1)

**a) Browser WASM vs server WASM (`js/wasm` vs `wasip1`)?**

`js/wasm` targets the browser: it links against `syscall/js`, expects a JS host to provide DOM/network APIs, and cannot use WASI syscalls. **`wasip1`** targets a server WASM runtime (Spin/wasmtime): no DOM, but you get **WASI** (files, clocks, sockets via host capabilities). You gain a **portable, sandboxed server module** with near-native startup; you lose the full Go stdlib (TinyGo subset) and direct OS access.

**b) Why `-buildmode=c-shared`?**

Spin's host loads the module as a **shared library-style WASM component** and calls exported handler symbols. Without `-buildmode=c-shared`, TinyGo emits a plain executable-style module missing those exports — Spin starts but returns **HTTP 500** because it cannot find the HTTP entrypoint.

**c) `allowed_outbound_hosts = []` vs Docker `--network none`?**

Both block outbound network. Spin uses a **capability list in the manifest**: the component cannot open sockets unless the host grants a host pattern — enforced at the WASM runtime, per-component. Docker `--network none` removes the container's network namespace — coarse, **per-container**, and still leaves a full Linux process/kernel attack surface if the boundary is breached.

**d) TinyGo stdlib gap you hit?**

**`time.LoadLocation("Europe/Moscow")`** fails without embedded tzdata; used `time.FixedZone("MSK", 3*3600)` instead. Also avoided `json.NewEncoder(w).Encode(map[string]any{...})` (reflection-heavy) and built JSON with **`fmt.Sprintf`** for reliability under TinyGo.

---

## Task 2 — Perf comparison vs Lab 6 Docker

**Test rig:** Windows 11 host, WSL2 Ubuntu, Docker Desktop, Spin 3.4.0 + TinyGo 0.40.0. Benchmark script: [`wasm/bench-lab12.sh`](../wasm/bench-lab12.sh) (5 cold samples; warm: 5 warmup + 50 runs via `curl`).

| Dimension | Lab 6 Docker (`quicknotes:lab6`) | Lab 12 WASM/Spin |
|-----------|--------------------------------:|-----------------:|
| Artifact size | 22.7 MB | 220 KB (`main.wasm`, 225,551 bytes) |
| Cold start (p50) | 523 ms | 97 ms |
| Warm latency p50 | 6.0 ms | 6.0 ms |
| Warm latency p95 | 8.6 ms | 8.0 ms |

**Cold samples (ms):** Docker `[656, 523, 395, 678, 414]` · Spin `[266, 97, 53, 98, 89]`  
**Endpoints:** Docker `GET /health` on `:18080` · Spin `GET /time` on `:13002`

### Design questions (Task 2)

**e) What dominates each platform's cold start?**

**Docker:** image layer extract/cache, container namespace setup (cgroups, network, mounts), process start, then app listen. **Spin:** wasmtime **module load + instantiation** (much smaller artifact → faster I/O), HTTP trigger bind — no full OS container bootstrap.

**f) When is WASM better vs Docker?**

**WASM/Spin** wins on **artifact size, cold start, and per-tenant isolation** for small stateless HTTP handlers (edge functions, webhooks). **Docker** remains right for **full stdlib**, long-lived services, complex dependencies (DB drivers, CGO), and workloads needing a complete Linux userspace.

**g) Multi-tenant safety — concrete attack WASM makes harder?**

A compromised guest **cannot open arbitrary outbound TCP** without manifest capability — e.g. exfiltrating data to `attacker.example.com` is blocked by `allowed_outbound_hosts = []`. In Docker, a missed firewall rule or `--network host` misconfig can expose the whole host network stack; WASM capability checks are enforced **inside the runtime per module**.

---

## Bonus — Standalone WASI CLI (`wasm-cli/`)

Same Moscow-time logic without the Spin SDK — **CGI-style**: read `REQUEST_METHOD` / `PATH_INFO` from the environment, write HTTP response to stdout.

### Source

- [`wasm-cli/main.go`](../wasm-cli/main.go)

### Build + run

```text
$ cd wasm-cli
$ tinygo build -o main.wasm -target=wasi -no-debug ./main.go
$ ls -lh main.wasm
-rw-r--r-- 1 user user 191K main.wasm

$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
Status: 200 OK
Content-Type: application/json

{"unix":1782904206,"iso":"2026-07-01T14:10:06+03:00","hour_minute":"14:10","moscow_utc_offset":"+03:00"}
```

**Tool:** wasmtime **34.0.0** (user-local install in WSL)

### Two execution models — size + cold start

| Model | Artifact | Cold start (p50) | Notes |
|-------|----------|------------------|-------|
| Spin `wasi-http` server (`wasm/main.wasm`) | 221 KB (225,551 B) | **97 ms** (server boot) | One `spin up`; warm requests ~6 ms |
| `wasmtime run` CLI (`wasm-cli/main.wasm`) | 191 KB (194,917 B) | **9 ms** (per invocation) | Fresh process + instantiate **every** request |

**wasmtime cold samples (ms):** `[12, 8, 9, 9, 11]` — benchmark: [`wasm-cli/bench-bonus.sh`](../wasm-cli/bench-bonus.sh)

The CLI module is **~14% smaller** (no Spin SDK / wasi-http component glue). Per-request `wasmtime run` is fast for a tiny module, but unlike Spin there is **no persistent server** — every request pays process spawn unless you use `wasmtime serve` or a host with instance pooling.

### Design questions (Bonus)

**h) Why can't the Spin component run under bare `wasmtime run`?**

The Spin build exports a **`wasi-http` component handler** (`-buildmode=c-shared`, SDK-registered callback), not a classic `_start` CLI entry that reads env vars and writes stdout. Bare `wasmtime run` expects a **command module** with `main()` — it does not start an HTTP listener or route `GET /time` to the Spin handler.

**i) What does Spin add on top of wasmtime?**

Spin embeds wasmtime but adds: **manifest routing** (`spin.toml` triggers), the **persistent wasi-http server loop**, **per-component outbound-host policy**, build orchestration (`spin build`), and **instance lifecycle** management — so components stay loaded between requests instead of one OS process per `wasmtime run`.

**j) When does each execution model fit?**

| Model | Fits |
|-------|------|
| **Per-invocation `wasmtime run`** (CGI-style) | Rare cron jobs, one-off CLI tools, batch transforms, serverless with an external router spawning workers |
| **Spin persistent wasi-http server** | Edge HTTP APIs, webhooks, multi-route microservices where amortizing server boot beats per-request process spawn |

---

## Lab 12 completion checklist

### Task 1 (4 pts)

- [x] Scaffolded from `spin new -t http-go` pattern
- [x] `spin build` → `main.wasm` (221 KB)
- [x] `spin up` serves valid Moscow-time JSON on `/time`
- [x] Design questions a–d answered

### Task 2 (4 pts)

- [x] Perf table with real measurements
- [x] Cold + warm + size captured
- [x] Design questions e–g answered

### Bonus (2 pts)

- [x] `wasm-cli/` module runs under `wasmtime run`
- [x] Size + cold-start comparison
- [x] Design questions h–j answered

### Submission

- [ ] Course PR: <!-- URL -->
- [ ] Fork PR: <!-- URL -->
- [ ] Moodle URLs submitted
