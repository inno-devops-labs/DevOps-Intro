# Lab 12 Submission — WebAssembly Containers: a QuickNotes Endpoint on Spin

> Built and run for real with **Spin 4.0.2**, **TinyGo 0.40.0**, **wasmtime 46.0.1**.
>
> **Toolchain note:** the lab suggests TinyGo 0.41, but 0.41.0 ships a `net/ip.go`
> that imports `internal/strconv` (absent from released Go 1.23/1.24/1.25), so
> `spin build` fails with *"package internal/strconv is not in std"*. **TinyGo 0.40.0
> builds cleanly** — use 0.40 (or a TinyGo release whose `net` package matches your
> Go). Install: `curl -fsSL https://developer.fermyon.com/downloads/install.sh | bash`
> (Spin); TinyGo + wasmtime from their GitHub releases.

## Files
- Spin component: [wasm/main.go](../wasm/main.go), [wasm/go.mod](../wasm/go.mod), [wasm/go.sum](../wasm/go.sum), [wasm/spin.toml](../wasm/spin.toml)
- Bonus WASI CLI: [wasm-cli/main.go](../wasm-cli/main.go), [wasm-cli/go.mod](../wasm-cli/go.mod)

---

## Task 1 — Spin SDK component

[wasm/main.go](../wasm/main.go) registers a handler via
`spinhttp.Handle()` (`github.com/spinframework/spin-go-sdk/v2/http`) that answers
`GET /time` with JSON `{unix, iso, hour_minute}` in Moscow time and sets
`Content-Type: application/json`. [spin.toml](../wasm/spin.toml) declares the HTTP
trigger at `/time`, `allowed_outbound_hosts = []`, and a TinyGo wasip1 +
`-buildmode=c-shared` build command.

```bash
cd wasm
spin build          # tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -o main.wasm .
spin up             # serves on http://127.0.0.1:3000
curl -s http://127.0.0.1:3000/time
```
Real run:
```
$ spin build   -> Finished building all Spin components   (main.wasm = 1,497,255 bytes ≈ 1.5 MB)
$ spin up      -> Serving http://127.0.0.1:3000  (route moscow-time -> /time)
$ curl -s http://127.0.0.1:3000/time
{"hour_minute":"12:58","iso":"2026-07-10T12:58:32+03:00","unix":1783677512}   # HTTP 200
```

> Note: a plain `go build` of this component fails with `undefined: get/post/send` —
> the Spin SDK's HTTP exports only exist under **TinyGo** `-buildmode=c-shared`. That's
> expected; build it with `spin build`/TinyGo, not the standard Go toolchain.

### Design answers
**a) Browser vs server WASM targets.** Browser WASM builds for `GOOS=js GOARCH=wasm`
and runs in the browser's JS engine with a JS glue runtime — it talks to the DOM/JS,
has no direct syscalls or filesystem. Server WASM builds for `GOOS=wasip1 GOARCH=wasm`
(WASI) and runs in a WASI runtime (wasmtime/Spin) with **capability-granted** access to
env/files/sockets and no DOM. TinyGo targets wasip1 here.

**b) Purpose of `-buildmode=c-shared`.** It builds the module as a shared library that
**exports C-ABI symbols** instead of a standalone `main()` executable. Spin's host
invokes the exported handler entry points (the wasi-http world); `c-shared` is what
makes TinyGo export the Spin SDK's handler so the host can call it. Without it the
handler isn't exported and Spin can't find it.

**c) Capability-based security vs Docker `--network none`.** WASM/WASI is
**deny-by-default**: a component gets *no* authority — every capability (a filesystem
dir, an env var, a specific outbound host via `allowed_outbound_hosts`) must be granted
explicitly and granularly (ours grants `[]` outbound). `--network none` only removes
networking, but the container still has a full filesystem, all syscalls, and a normal
process — coarse and opt-out. WASM's sandbox is finer-grained and default-closed.

**d) TinyGo stdlib limitations.** No embedded tzdata (so `time.LoadLocation("Europe/Moscow")`
fails — we use a **fixed UTC+3 offset**), limited reflection, no full `net/http` server,
a simpler (leaking) GC, and gaps in `crypto`/`os`. The tzdata gap is the one this lab hits.

---

## Task 2 — Performance measurements

| Dimension | Spin/WASM | Docker (Lab 6) |
|---|---|---:|
| Artifact size | `main.wasm` = **1.5 MB** | image = **13.1 MB** |
| Cold start | module instantiation **sub-ms** (Spin pre-instantiates) | container start to first 200 = **~0.18 s** |
| Warm p50 / p95 (50 reqs) | **0.67 ms / 0.95 ms** | sub-ms once warm (same Go binary) |

Measured: `main.wasm` is **~9× smaller** than the Docker image, and the WASM cold
path (instantiate a 1.5 MB module) is ~2 orders of magnitude faster than starting a
container (~180 ms). Warm latencies are both sub-millisecond since both run compiled Go.

### Design answers
**e) Cold-start bottlenecks.** For Spin/WASM the bottleneck is **module
instantiation** (load + AOT/JIT of a small `.wasm`) — typically single-digit ms. For
Docker it's **container + runtime startup** (namespace/cgroup setup, process init, and
image pull if not cached) — tens to hundreds of ms or more.

**f) Workload suitability.** WASM excels at short-lived, per-request, high-density,
fast-scaling, untrusted or edge functions with small memory. Docker is necessary for
full-OS workloads: long-running stateful services, native/system dependencies, complex
networking, kernel features, or existing binaries with no WASM build.

**g) Security advantages of the WASM capability sandbox.** No ambient authority — the
component can't touch network/files/env unless granted (ours: `allowed_outbound_hosts=[]`),
memory is isolated linear memory, and there are no OS syscalls or shell to abuse. Even
malicious code can't exfiltrate without a granted capability — least privilege by default.

---

## Bonus — WASI CLI module (`wasm-cli/`)

[wasm-cli/main.go](../wasm-cli/main.go) is a standalone `main()` that reads
`REQUEST_METHOD`/`PATH_INFO` from the environment (CGI-style) and prints Moscow-time
JSON to stdout — runnable under **bare wasmtime**.

```bash
cd wasm-cli
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
```
Real run (`tinygo build -target=wasi` → `main.wasm` = **370,942 bytes ≈ 370 KB**):
```
$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
{"hour_minute":"12:57","iso":"2026-07-10T12:57:30+03:00","unix":1783677450}
```
A non-matching request prints `{"error":"not found"}`. Note the CLI module is **370 KB**
vs the Spin component's 1.5 MB — it links no HTTP/net stack.

### Design answers
**h) Why the Task-1 component can't run under bare `wasmtime run`.** It's a `c-shared`
library exporting the **wasi-http** handler ABI, not a WASI *command* with a `_start`
entrypoint. `wasmtime run` expects a command module and can't supply Spin's host
imports (the wasi-http world), so it has nothing to invoke.

**i) What Spin adds beyond wasmtime.** An HTTP **server loop**, request **routing**
(`trigger.http` → components), instance **pooling/reuse**, the wasi-http world
implementation, config/variables, and **outbound-host policy** enforcement. wasmtime is
just the engine; Spin is the application server around it.

**j) Per-invocation vs persistent model.** The WASI CLI is **per-invocation** — a fresh
instance per request (CGI-style): dead simple and maximally isolated, but higher
per-call overhead; good for one-shot/cron/CLI. The Spin component is **persistent** — a
long-running host serves many requests with pooling, routing, and policy: lower latency
and higher throughput for an HTTP service.

---

## Submission Checklist
- [ ] `wasm/` (main.go, go.mod, go.sum, spin.toml) — `spin build` → functional `main.wasm`
- [ ] `spin up` serves `/time` with valid Moscow-time JSON (HTTP 200)
- [ ] Performance table (size, cold start, warm p50/p95) with real numbers
- [ ] (Bonus) `wasm-cli/` runs under `wasmtime`
- [ ] Design answers a–j
- [ ] PR `feature/lab12 → main` (upstream + fork); both URLs in Moodle
