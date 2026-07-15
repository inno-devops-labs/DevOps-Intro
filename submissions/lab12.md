# Lab 12 — WebAssembly Containers — QuickNotes Endpoint on Spin

## Task 1 — Build a WASM Endpoint with the Spin SDK

### Scaffolding note

`spin new -t http-go` on Spin 4.0.2 defaulted to an experimental `componentize-go` build path (`go tool componentize-go build`), which failed with `failed to read path for WIT [wit]` — the scaffold didn't generate the required `wit/` directory. This is a known class of bug in the current template registry (same failure pattern reported for the Python template). Worked around it by using the documented, stable path instead: TinyGo direct build with the `v2` SDK, matching Spin's official Go component docs.

### `main.go`

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
		w.Header().Set("Content-Type", "application/json")

		mskLoc := time.FixedZone("MSK", 3*60*60)
		moscow := time.Now().In(mskLoc)

		fmt.Fprintf(w, `{"unix":%d,"iso":%q,"hour_minute":%q}`,
			moscow.Unix(),
			moscow.Format(time.RFC3339),
			moscow.Format("15:04"),
		)
	})
}

func main() {}
```

### `spin.toml`

```toml
spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["darknesod"]
description = "Moscow time endpoint"

[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []

[component.moscow-time.build]
command = "tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -no-debug -o main.wasm ."
watch = ["**/*.go", "go.mod"]
```

### Build output

```
$ spin build
Building component moscow-time with `tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components

$ ls -la main.wasm
-rwxrwxrwx 1 darknesod darknesod 313349 Jul 15 21:18 main.wasm
```

### Runtime proof

```
$ spin up &
Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000/time

$ curl -s http://127.0.0.1:3000/time
{"unix":1784139630,"iso":"2026-07-15T21:20:30+03:00","hour_minute":"21:20"}
```

### Design questions

**a) Browser WASM vs server WASM:** `js/wasm` targets a browser JS runtime — expects a JS glue layer and DOM/browser APIs, no direct filesystem/network access (everything routed through JS callbacks). `wasip1` targets WASI, a standardized system interface for non-browser hosts — gets real (sandboxed) filesystem/clock/random access without a JS host, but loses anything DOM-specific. Gain: a standalone, embeddable binary any WASI-compatible runtime (Spin, wasmtime, wasmer) can run directly.

**b) Why `-buildmode=c-shared`:** the Spin host expects the compiled module to export specific handler functions with a C ABI-compatible calling convention so the host can call into the module directly. Without it, TinyGo produces a WASI CLI-style binary with a `_start` entrypoint instead of the exported handler Spin's HTTP trigger looks for — `spin up` fails to route requests (no handler found).

**c) `allowed_outbound_hosts = []` vs `--network none`:** Spin's model is capability-based — zero ambient authority by default; every capability (which hosts, which stores) must be explicitly declared. `--network none` is coarser: Docker's network namespace isolation is all-or-nothing per container. Spin lets you allowlist exactly `["https://api.example.com:443"]` and nothing else, enforced by the runtime itself rather than the OS network stack.

**d) TinyGo stdlib gap hit in this lab:** `time.LoadLocation("Europe/Moscow")` fails — TinyGo doesn't embed IANA tzdata by default. Used `time.FixedZone` with a manual UTC+3 offset instead.

---

## Task 2 — Perf Comparison vs Lab 6 Container

### Table

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|---|---:|---:|
| Artifact size | 3.32MB (compressed) / 14.8MB (disk) | ~305KB (313,349 bytes) |
| Cold start (p50) | ~1710ms | ~90ms (steady state), 289ms (very first) |
| Warm latency p50 | 9.32ms | 12.01ms |
| Warm latency p95 | 11.22ms | 13.12ms |

Note: warm latency is slightly *lower* for Docker here — at this scale, `curl` process spawn + localhost TCP overhead likely dominates over either runtime's own request handling, so the gap isn't meaningful. Cold start and artifact size are where the real difference shows.

### Test rig

WSL2 (Ubuntu) on Windows, Docker Desktop (WSL2 backend), `hyperfine 1.19.0`, 50 warm runs with 5 warmup runs per target, 5 cold-start samples per target.

### Raw measurements

```
Spin warm (hyperfine):
  Time (mean ± σ):      11.4 ms ±   0.8 ms
  Range (min … max):     9.9 ms …  13.1 ms    50 runs
  p50=12.01ms p95=13.12ms

Docker warm (hyperfine):
  Time (mean ± σ):       8.7 ms ±   0.8 ms
  Range (min … max):     7.5 ms …  11.9 ms    50 runs
  p50=9.32ms p95=11.22ms

Spin cold start (5 samples, kill+restart):
  289ms, 88ms, 89ms, 96ms, 90ms

Docker cold start (5 samples, docker compose down/up):
  1839ms, 1725ms, 1710ms, 1689ms, 1700ms
```

### Design questions

**e) What dominates cold start:** Docker's cold start is dominated by container/namespace initialization — cgroups, network namespace setup, mounting the writable layer, process startup in the isolated environment. Spin's cold start is dominated by wasmtime instantiating the WASM module and linking imports — much lighter, no OS-level namespace/cgroup machinery, just loading (and JIT/pre-compiling) WASM bytecode into a sandboxed runtime.

**f) Where WASM wins, where Docker is still right:** WASM is clearly better for latency-sensitive, high-frequency, short-lived workloads — edge functions, per-request serverless handlers, plugin sandboxes — where minimizing cold-start and footprint matters most. Docker remains right for long-running services, workloads needing full OS/filesystem/networking access, existing container-ecosystem tooling, or apps with dependencies that don't compile to WASM cleanly (TinyGo's stdlib gaps around timezones, hit in Task 1, are a small example of that friction).

**g) Concrete attack WASM's capability sandbox makes harder:** WASM components have zero ambient authority — no filesystem, network, or syscall access unless explicitly granted via imports (like `allowed_outbound_hosts`). This makes container/kernel-escape-style attacks (exploiting a shared-kernel vulnerability to break out of a Linux namespace and reach the host or other tenants) fundamentally harder, since a compromised WASM component isn't relying on OS-level isolation at all — it's sandboxed at the language-runtime/instruction level, with no direct syscall surface to attack.

---

## Bonus Task — Two WASM Execution Models

### WASI CLI implementation

A second implementation of the same Moscow-time endpoint was created as a standalone WASI CLI module without using the Spin SDK. Instead of exposing a `wasi-http` handler, the program reads the request information from the `REQUEST_METHOD` and `PATH_INFO` environment variables and writes an HTTP-style response to standard output.

### Build and run

#### Build command

```bash
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
```

Result:

```bash
$ ls -la main.wasm
-rwxrwxrwx 1 darknesod darknesod 196955 Jul 15 21:51 main.wasm
```

#### Run command

```bash
wasmtime run \
  --env REQUEST_METHOD=GET \
  --env PATH_INFO=/time \
  main.wasm
```

Output:

```text
Status: 200 OK
Content-Type: application/json

{"unix":1784141564,"iso":"2026-07-15T21:52:44+03:00","hour_minute":"21:52"}
```

### Size and cold-start comparison

| Execution model | WASM size | Cold start |
|---|---:|---:|
| Spin (`wasi-http` component) | 312,636 B | ~89–96 ms after startup (289 ms first launch) |
| Standalone WASI CLI (`wasmtime run`) | 196,955 B | ~19–20 ms per invocation (36 ms first run) |

The standalone CLI module is approximately 115 KB smaller because it links only the standard WASI runtime and does not include the Spin SDK or the `wasi-http` component interface. Unlike Spin, which keeps a persistent server process running, `wasmtime run` creates a new WebAssembly instance for every invocation.

### Design questions

**h) Why can't the Task 1 Spin component run under bare `wasmtime run`?**

The Spin application is compiled as a `wasi-http` component instead of a standalone WASI program. It exports a `wasi-http` request handler that the Spin runtime calls whenever an HTTP request arrives. In contrast, `wasmtime run` expects a conventional WASI module exposing a `_start` entrypoint. Since the Spin component does not export `_start`, there is no program entrypoint for `wasmtime run` to execute.

**i) Spin uses Wasmtime internally. What does Spin add on top of bare Wasmtime?**

Wasmtime is responsible only for executing WebAssembly modules inside a sandbox. Spin builds a complete application platform on top of it by providing:

- an HTTP server implementing the `wasi-http` interface;
- routing based on `spin.toml`;
- component lifecycle and instance management;
- capability-based security such as `allowed_outbound_hosts`;
- application packaging, configuration, and build integration.

In other words, Wasmtime is the execution engine, while Spin provides the web application runtime.

**j) Two execution models — when does each fit?**

The standalone `wasmtime run` model is best suited for short-lived command-line programs or CGI-style workloads where each request executes a fresh WebAssembly instance. Typical examples include CLI utilities, batch-processing jobs, and scripts executed on demand.

Spin's persistent `wasi-http` server is better suited for long-running HTTP services such as REST APIs or edge functions. Since the runtime remains active between requests, it avoids the overhead of starting a new Wasmtime process for every invocation while also providing routing, configuration, and capability management.