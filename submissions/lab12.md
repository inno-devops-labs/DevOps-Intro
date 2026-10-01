# Lab 12 — Bonus: WebAssembly Containers — A QuickNotes Endpoint on Spin

- Student: Arina Nikolaeva (Nik-ari-ai)
- Fork: https://github.com/Nik-ari-ai/DevOps-Intro
- Branch: feature/lab12
- Rig: MacBook Pro (Apple M3 Pro, arm64), macOS; Docker Desktop; Spin 4.1.0, TinyGo 0.42.0 (Go 1.27.1, LLVM 22), wasmtime, hyperfine, binaryen.

## Toolchain note (honest)

The lab was validated (May 2026) with Spin 3.4 + the `spin-go-sdk/v2` + a TinyGo
`-buildmode=c-shared` build. Scaffolding on **Spin 4.1** with `spin new -t http-go`
produced a **v3** SDK project whose build command is `go tool componentize-go build`.
That path failed here: `componentize-go` looks only for a `./wit` directory (there is no
`--wit`/`--world` flag), the template ships none, and the SDK carries no `.wit` files —
`Error: failed to read path for WIT [wit]`. This is exactly the "WASM tooling moves fast /
breaks" churn the lab warns about. So I used the lab's documented path instead:
`spin-go-sdk/v2` (v2.2.1) built with TinyGo `-target=wasip1 -gc=leaking -buildmode=c-shared`.
That builds and runs cleanly on the Spin 4.1 host. `wasm-opt` (binaryen) had to be installed
for TinyGo's optimizer.

## Task 1 — WASM endpoint with the Spin SDK

### `wasm/moscow-time/main.go`

```go
package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		// Moscow is UTC+3. TinyGo ships no tzdata, so a fixed zone is used
		// instead of time.LoadLocation("Europe/Moscow") (which fails in TinyGo).
		msk := time.Now().In(time.FixedZone("MSK", 3*60*60))

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w,
			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"zone\":\"Europe/Moscow\",\"offset\":\"+03:00\"}\n",
			msk.Unix(), msk.Format(time.RFC3339), msk.Format("15:04"),
		)
	})
}

func main() {}
```

### `wasm/moscow-time/spin.toml` (key parts)

```toml
[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []          # least privilege — no outbound network
[component.moscow-time.build]
command = "tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -o main.wasm ."
```

### Build + run

```
$ spin build
Building component moscow-time with `tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -o main.wasm .`
Finished building all Spin components
$ ls -lh main.wasm
-rw-r--r-- 1.8M main.wasm

$ spin up &
$ curl -s http://127.0.0.1:3000/time | python3 -m json.tool
{
    "unix": 1789984597,
    "iso": "2026-09-21T12:56:37+03:00",
    "hour_minute": "12:56",
    "zone": "Europe/Moscow",
    "offset": "+03:00"
}
```

HTTP 200, valid JSON, correct Moscow time (UTC+3), `Content-Type: application/json`.

### 1.4 Design questions

**a) Browser WASM (`-target=js/wasm`) vs server WASM (`-target=wasip1`).**
`js/wasm` targets a browser/JS host: it depends on the `wasm_exec.js` glue and reaches the outside world only through JS (DOM, `fetch`, `syscall/js`) — no direct stdio/files/sockets. `wasip1` targets a server runtime (wasmtime, Spin): it drops the JS bridge and instead speaks the WASI ABI, with capability-scoped stdio, env, clock, files and sockets. What's *missing* in the server target is the browser/DOM/JS interop. What you *gain* is a standalone module that runs outside any browser, with real POSIX-like capabilities, smaller/faster startup, and no JS runtime dependency — portable to any WASI host.

**b) Why does the build need `-buildmode=c-shared`?**
The Spin host does not run your module as a CLI (`_start`) and does not call `main()`. It calls an **exported handler** symbol per request (the wasi-http/Spin handler). `-buildmode=c-shared` builds the module as a shared library that exports those symbols; a normal executable build only exports `_start`. Without it, `spin up` starts but the host can't find the handler, so requests return **HTTP 500 with empty component logs** — the handler is never invoked.

**c) `allowed_outbound_hosts = []` and the capability model.**
Spin is capability-based: a component has **no ambient authority** — it cannot open a socket, read a file, or reach any host unless the manifest grants it. `[]` grants zero outbound hosts, so even a compromised dependency trying to phone home is denied — the capability simply doesn't exist. Docker's `--network none` reaches a similar end state but differently: it's coarse (all-or-nothing) and enforced by Linux **network namespaces** in the shared kernel; turning some access back on means attaching a whole interface. Spin's model is fine-grained default-deny at the **runtime** layer — you allowlist specific hosts, and there is no network stack in the sandbox to attack in the first place.

**d) TinyGo stdlib gaps hit.**
(1) **tzdata** — `time.LoadLocation("Europe/Moscow")` fails (no embedded zone data), so I used `time.FixedZone("MSK", 3*60*60)`. (2) **reflection-heavy `encoding/json`** — `json.Encode` of a `map[string]any` is unreliable under TinyGo's limited reflection, so the JSON is built with `fmt.Fprintf` + `%q`. (TinyGo's `reflect` and parts of `net/http` server internals are also incomplete.)

## Task 2 — Perf comparison vs the Lab 6 container

Both booted: `spin up` (`/time`) and the Lab 6 image `qn-lab6` (`/health`). Warm = `hyperfine --warmup 5 --runs 50` (p50/p95 from the exported per-run times). Cold = time from runtime start to first HTTP 200 (Docker: measured across the *blocking* `docker run` so container create is included; Spin: `spin up` is non-blocking, so the timer captures the whole startup), ≥5 samples.

| Dimension        | Lab 6 Docker | Lab 12 WASM/Spin |
|------------------|-------------:|-----------------:|
| Artifact size    |     21.9 MB  |         1.8 MB   |
| Cold start (p50) |      132 ms  |            9 ms  |
| Warm latency p50 |      6.1 ms  |          5.4 ms  |
| Warm latency p95 |      6.7 ms  |          5.7 ms  |

Cold samples — Docker: 120/129/132/132/135/156 ms → p50 132; Spin: 8/8/9/9/10 ms → p50 9.

> Note: warm numbers include the `curl` process spawn + loopback on both sides (both ≈5–6 ms), so they're close in absolute terms; the comparison is apples-to-apples. The decisive gap is **cold start** (≈15×) and **size** (≈12×).

### 2.3 Design questions

**e) What dominates each platform's cold start?**
Docker (132 ms): the OS work of *creating* the container — overlay-fs mount, Linux namespaces + cgroups, and (on Docker Desktop) the hop into the Linux VM — all before the Go process starts. The image is local, so it's create+init, not pull. Spin (9 ms): no OS container; the cost is wasmtime *instantiating* the ~1.8 MB module (load/validate + stand up linear memory) and binding the listener. No namespaces, no fs mount, no VM.

**f) Where is WASM clearly better, where is Docker still right?**
WASM/Spin wins for high-density, spiky, short-lived handlers — edge/FaaS where cold start and per-instance footprint dominate (9 ms vs 132 ms, 1.8 MB vs 22 MB), untrusted multi-tenant code, and portability across CPUs/hosts. Docker is still right when you need a full OS userland: existing binaries/languages without good WASM support, processes that fork/exec, threads, raw sockets, GPUs, the full syscall surface, long-lived stateful services, and the mature orchestration/logging ecosystem. "Normal Linux program" → Docker; "small sandboxed fast handler" → WASM.

**g) Multi-tenant safety — what attack does WASM make harder?**
Container escape via a **shared-kernel exploit**. Containers share the host kernel, so one kernel/syscall/namespace vulnerability can let a tenant break out and pivot to co-tenants or the host. A WASM module has no syscalls beyond the WASI capabilities it was granted, cannot address memory outside its own linear memory, and cannot reach another instance — so the classic "exploit the shared kernel to escape and hit a neighbor" attack is largely removed; there is no shared syscall surface to attack from inside the sandbox.

## Bonus — Two WASM execution models

The Task 1 component is a wasi-http component (needs a wasi-http host). The Bonus rebuilds
the same Moscow-time logic as a **standalone WASI CLI module** and runs it under bare `wasmtime run`.

### `wasm/wasm-cli/main.go` (no Spin SDK)

```go
func main() {
	method := os.Getenv("REQUEST_METHOD")
	if method == "" { method = "GET" }
	path := os.Getenv("PATH_INFO")
	msk := time.Now().In(time.FixedZone("MSK", 3*60*60))
	fmt.Print("Content-Type: application/json\n\n")            // CGI-style headers
	fmt.Printf("{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,...,\"method\":%q,\"path\":%q}\n",
		msk.Unix(), msk.Format(time.RFC3339), msk.Format("15:04"), method, path)
}
```

### Build + run

```
$ tinygo build -o main.wasm -target=wasi -no-debug ./main.go
$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
Content-Type: application/json

{"unix":1789985259,"iso":"2026-09-21T13:07:39+03:00","hour_minute":"13:07","zone":"Europe/Moscow","offset":"+03:00","method":"GET","path":"/time"}
```

### Comparison

| | Standalone WASI (`wasmtime run`) | Spin component (`spin up`) |
|---|---:|---:|
| Module size | **184 KB** | 1.8 MB |
| Per-invocation start | **~3.8 ms** (hyperfine, 30 runs) | server is persistent (warm p50 5.4 ms) |
| Model | new instance every call (CGI-shaped) | pooled instances, long-lived listener |

The CLI module is ~10× smaller (no wasi-http/component machinery) and each `wasmtime run` pays its own ~4 ms startup; Spin pays instantiation once and reuses instances.

### B.3 Design questions

**h) Why can't the Task 1 Spin component run under bare `wasmtime run`?**
It's a wasi-http **component**, not a CLI module: it exports a wasi-http request handler, not a `_start` entrypoint. `wasmtime run` expects a command module with `_start` to execute and exit; the component has none — it waits to be *called* by a wasi-http host. You'd host it with `wasmtime serve` (which provides the wasi-http world), not `wasmtime run`. The Bonus CLI module exports `_start`, so `wasmtime run` works.

**i) Spin uses wasmtime internally — what does Spin add?**
The application/server layer around wasmtime's engine: (1) the **wasi-http server loop** — listens, accepts HTTP, turns each request into a component invocation; (2) **instance pooling / lifecycle** — pre-instantiates and reuses instances so per-request cost is instantiation-free (why warm ≈ cold here); (3) the **manifest/routing** layer (`spin.toml` maps routes→components, triggers); (4) the **capability/policy** layer (`allowed_outbound_hosts`, KV/SQLite, variables) enforced per component; plus non-HTTP triggers (Redis, cron). Bare wasmtime just instantiates and calls modules.

**j) Two execution models — when each fits.**
Per-invocation `wasmtime run` (CGI-shaped): fresh process + instance per request. Fits low-frequency, isolated, one-shot work — a cron job, a CLI tool, a build step, a rarely-hit webhook — where "spawn, run, exit" simplicity and maximal isolation (zero residual state) beat per-request startup cost. Spin's persistent server: long-lived, pooled. Fits high-frequency online serving — a public API or edge function under real traffic — where you amortize instantiation and keep latency consistently low. One each: a nightly report generator → `wasmtime run`; a public JSON API under load → Spin.
