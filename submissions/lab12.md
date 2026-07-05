# Lab 12 — WebAssembly Containers: Moscow Time Endpoint on Spin

## Task 1 — Build a WASM Endpoint with the Spin SDK

### Source: `wasm/main.go`

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
		// time.LoadLocation("Europe/Moscow") is unavailable in TinyGo (no embedded tzdata).
		// Moscow is permanently UTC+3 (no DST since 2014), so a fixed zone is exact.
		moscowLoc := time.FixedZone("Moscow/UTC+3", 3*60*60)
		moscow := time.Now().In(moscowLoc)

		w.Header().Set("Content-Type", "application/json")
		// Build JSON with fmt.Fprintf — TinyGo's reflect support limits encoding/json
		// on map[string]any; string formatting is always safe.
		fmt.Fprintf(w,
			`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow (UTC+3)"}`,
			moscow.Unix(),
			moscow.Format(time.RFC3339),
			moscow.Format("15:04"),
		)
	})
}

func main() {}
```

### Source: `wasm/spin.toml`

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["Irina <irina.bychkova06@mail.ru>"]
description = ""

[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []
[component.moscow-time.build]
# TinyGo 0.41 overlays files from Go 1.26; set GOROOT to the 1.26 SDK.
# Install: go install golang.org/dl/go1.26.4@latest && go1.26.4 download
command = "sh -c 'GOROOT=$(go1.26.4 env GOROOT 2>/dev/null || go env GOROOT) tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .'"
watch = ["**/*.go", "go.mod"]
```

### `spin build` output

```
Building component moscow-time with `sh -c 'GOROOT=$(go1.26.4 env GOROOT 2>/dev/null || go env GOROOT) tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .'`
Finished building all Spin components
```

Artifact: `main.wasm` — **359 KB**

### `curl` response (Moscow time JSON)

```
$ spin up --listen 127.0.0.1:3000
$ curl -s http://127.0.0.1:3000/time | python3 -m json.tool
{
    "unix": 1783253804,
    "iso": "2026-07-05T15:16:44+03:00",
    "hour_minute": "15:16",
    "timezone": "Europe/Moscow (UTC+3)"
}
```

HTTP 200, valid JSON, `+03:00` offset confirms Moscow time.

### Design Questions (Task 1)

**a) Browser WASM vs server WASM (`js/wasm` vs `wasip1`)**

`go build -target=js/wasm` targets the browser sandbox: it integrates with the JS event loop, exposes Go functions via `syscall/js`, and relies on the browser's fetch/DOM APIs. The module runs inside a V8 context and can't do raw I/O. `tinygo build -target=wasip1` targets the WASI system interface: the host provides a subset of POSIX — file descriptors, clocks, env vars, args — instead of a browser. What's missing in the server target is the JS runtime and DOM; what you gain is portability across any WASI host (Spin, wasmtime, WasmEdge) and a lighter binary since you don't pull in the JS bridge glue.

**b) Why does the build command need `-buildmode=c-shared`?**

Spin's wasi-http host expects the component to export a `wasi:http/incoming-handler@0.2.x` interface — specifically the `handle` export. Without `-buildmode=c-shared`, TinyGo emits a CLI-style module whose only export is `_start`. Spin can't find the handler export and returns HTTP 500 with an empty component. The flag switches the code-generation strategy so TinyGo emits the proper Wasm Component Model exports that the host can call.

**c) `allowed_outbound_hosts = []` and capability-based security**

Spin implements capability-based security at the manifest level: a component can only reach the network hosts explicitly listed in `allowed_outbound_hosts`. If the list is empty, outbound sockets are blocked entirely — the WASI runtime never grants the network capability. This is structurally similar to Docker's `--network none`, but at a different layer: `--network none` removes the container's network namespace so the process can't create sockets at all. Spin's approach is finer-grained — the WASM module could in principle list `https://api.example.com` and be blocked from everything else, combining sandboxing with allow-listing at the module level rather than the host level.

**d) TinyGo stdlib gaps encountered**

Two gaps hit during this lab:
1. **No embedded timezone data**: `time.LoadLocation("Europe/Moscow")` panics — TinyGo doesn't bundle tzdata. Worked around with `time.FixedZone("Moscow/UTC+3", 3*60*60)` (pure arithmetic, no data file needed).
2. **Reflection-limited `encoding/json`**: `json.Marshal(map[string]any{...})` silently fails or produces garbage under TinyGo's reduced reflect implementation. Replaced with `fmt.Fprintf` and manual JSON formatting using `%d` and `%q` verbs.
3. **Go 1.24 + TinyGo 0.41 incompatibility**: TinyGo 0.41's overlay `net/ip.go` is copied from Go 1.26 and references `internal/strconv` (absent in Go 1.24 stdlib). Fixed by installing Go 1.26.4 and pointing TinyGo at its GOROOT via `GOROOT=$(go1.26.4 env GOROOT)`.

---

## Task 2 — Perf Comparison vs Lab 6 Container

**Test rig:** Apple M-series Mac, macOS Sequoia, Docker Desktop 4.x, Spin 3.4.0, TinyGo 0.41.0.

**Methodology:**
- Warm latency: `hyperfine --warmup 10 --runs 100` against Spin `/time` and Lab 6 Docker `/health`
- Cold start: 5 samples each — process/container killed, timed from launch command to first successful `curl`
- Artifact size: `ls -lh main.wasm`; `docker image inspect --format='{{.Size}}'`

### Performance Table

| Dimension              | Lab 6 Docker | Lab 12 WASM/Spin |
|------------------------|-------------:|-----------------:|
| Artifact size          |      21.6 MB |          359 KB  |
| Cold start (p50)       |       190 ms |           80 ms  |
| Warm latency p50       |         7.6 ms |           5.5 ms|
| Warm latency p95       |        ~9.4 ms |          ~7.6 ms|

Raw warm latency measurements:
- Spin `/time`: mean=5.5 ms ± 1.3 ms, range 4.3–12.6 ms (100 runs, 10 warmup)
- Docker `/health`: mean=7.6 ms ± 1.1 ms, range 6.3–11.6 ms (100 runs, 10 warmup)

Raw cold-start measurements (ms):
- Spin: 149, 87, 80, 73, 74 → p50 ≈ 80 ms (sample 1 was higher due to cold TinyGo JIT cache)
- Docker: 191, 190, 187, 182, 195 → p50 ≈ 190 ms

### Design Questions (Task 2)

**e) What dominates each platform's cold start?**

Docker's ~190 ms cold start is dominated by namespace and cgroup initialization in the Linux kernel (even on macOS via the VM), plus extracting the image layers into an overlay filesystem. The actual Go binary startup is fast; the host overhead is the bottleneck.

Spin's ~80 ms cold start is dominated by wasmtime's instantiation of the WASM module — AOT compilation of the module to native code (or loading a cached compiled artifact), setting up the linear memory, and wiring the WASI imports. The WASM binary itself is small (359 KB), so load time is low; most of the time is the JIT/AOT work.

**f) For what workloads is WASM clearly better, and where is Docker still right?**

WASM/Spin wins for: short-lived stateless compute (edge functions, webhooks, request transformers), multi-tenant serverless with strong isolation requirements, extremely fast scale-to-zero environments, and scenarios where artifact size matters (CDN distribution, IoT, embedded runtimes).

Docker is still right for: workloads that need a full POSIX environment (legacy daemons, database servers, GPU libraries), applications with heavy C/C++ FFI that TinyGo can't compile, teams that need mature observability tooling (the Docker/k8s ecosystem is far more battle-tested), and long-running stateful services where cold-start advantage doesn't matter.

**g) Multi-tenant safety: what concrete attack does WASM make harder?**

WASM's capability model makes host-filesystem escape significantly harder. In a container breakout (e.g., CVE-2019-5736, runc vulnerabilities), a malicious process exploits kernel namespace bugs to reach the host filesystem or other containers. A WASM component has no filesystem access whatsoever unless the host explicitly grants it a `wasi:filesystem/preopened-dir` capability — even then, it's scoped to a specific directory. Syscall-based exploits like Dirty COW also can't work because WASM never executes native syscalls directly; all I/O is mediated through the WASI host's import table. A compromised WASM component is strictly confined to what its manifest declares.

---

## Bonus Task — Two WASM Execution Models

### `wasm-cli/main.go`

```go
package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method == "" {
		method = "GET"
	}
	if path == "" {
		path = "/time"
	}

	if method != "GET" || path != "/time" {
		fmt.Println(`{"error":"not found"}`)
		os.Exit(1)
	}

	// Moscow is permanently UTC+3 (no DST since 2014).
	moscowLoc := time.FixedZone("Moscow/UTC+3", 3*60*60)
	moscow := time.Now().In(moscowLoc)

	fmt.Printf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow (UTC+3)"}`,
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		moscow.Format("15:04"),
	)
	fmt.Println()
}
```

### Build command

```bash
GOROOT=$(go1.26.4 env GOROOT) tinygo build -o main.wasm -target=wasi -no-debug ./main.go
# produces: 191 KB main.wasm
```

### Run command + output

```bash
$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
{"unix":1783254144,"iso":"2026-07-05T15:22:24+03:00","hour_minute":"15:22","timezone":"Europe/Moscow (UTC+3)"}
```

### Size + cold-start comparison

| Dimension       | Task 1 (Spin component) | Bonus (wasm-cli / wasmtime) |
|-----------------|------------------------:|----------------------------:|
| Module size     |                  359 KB |                      191 KB |
| Cold start (p50)|                   80 ms |                       35 ms |
| Execution model | Persistent wasi-http server | Per-invocation CLI module |

Cold-start samples for `wasmtime run` (ms): 30, 38, 35, 31, 36 → p50 ≈ 35 ms

The wasm-cli module is almost half the size (no Spin SDK, no httprouter dependency, no WASI socket plumbing) and cold-starts twice as fast because wasmtime spins up a single-function CLI module rather than initializing a full wasi-http listener loop.

### Design Questions (Bonus)

**h) Why can't the Task 1 Spin component run under bare `wasmtime run`?**

The Spin component is compiled with `-buildmode=c-shared`, which makes TinyGo emit a Wasm Component that exports the `wasi:http/incoming-handler` interface — specifically a `handle` function. Bare `wasmtime run` expects a CLI module: a module with a `_start` export (the WASI "main"). There is no `_start` in the component. Conversely, the wasm-cli module has `_start` but no `handle` export, so a wasi-http host like Spin can't use it as an HTTP handler.

**i) What does Spin add on top of bare wasmtime?**

Spin wraps wasmtime with:
- **Instance pooling**: wasmtime instances are pre-compiled and pooled, so each request reuses a JIT-compiled module instead of re-instantiating from scratch. This is why Spin's warm latency (~5.5 ms) is much lower than the cold start (~80 ms).
- **The wasi-http server loop**: Spin implements the WASI 0.2 HTTP server (listening socket, connection acceptance, request framing) and calls the component's `handle` export per request. Bare wasmtime has no HTTP server.
- **Manifest and routing layer**: `spin.toml` maps URL routes to components, allowing one Spin app to serve multiple endpoints from different WASM modules.
- **Outbound-host policy enforcement**: `allowed_outbound_hosts` is checked at the Spin layer before granting outbound socket capabilities to the component.

**j) Two execution models — when does each fit?**

- **Per-invocation `wasmtime run` (CGI-over-WASM)**: fits infrequent, bursty workloads where keeping a persistent server alive wastes resources — e.g., a serverless function that triggers once per webhook event, a build-time code generator invoked by a Makefile, or an edge function on a CDN where instances are spawned and discarded per request. The per-invocation model is also simpler to reason about: no shared state between calls, no memory leaks accumulating across requests.

- **Spin's persistent wasi-http server**: fits steady-traffic APIs where warm latency matters — e.g., a low-latency JSON API serving 1 000 req/s, a WebSocket upgrade handler, or any service where the 30–80 ms cold-start penalty on every request would be unacceptable. The instance pool amortizes JIT cost across many requests and keeps warm latency in the single-digit milliseconds.
