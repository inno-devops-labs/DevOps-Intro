# Lab 12 - Bonus: WebAssembly Containers

## Overview

This lab adds a Spin/TinyGo WebAssembly endpoint that returns the current Moscow time at `/time`, plus a standalone WASI CLI module for the bonus comparison.

Artifacts:

```text
wasm/moscow-time/
wasm-cli/
reports/lab12-cold-starts.txt
reports/lab12-docker-warm.json
reports/lab12-spin-warm.json
reports/lab12-tool-versions.txt
reports/lab12-wasmtime-cli.json
submissions/lab12.md
```

## Tool Versions

Measured under Windows 11 with WSL2 Ubuntu 24.04:

```text
spin 3.4.0 (4f671be 2025-08-26)
tinygo version 0.41.0 linux/amd64 (using go version go1.26.4 and LLVM version 20.1.1)
wasmtime 46.0.1 (823d1b8f2 2026-06-24)
hyperfine 1.20.0
Docker version 29.5.3, build d1c06ef
```

## Task 1 - Spin WebAssembly Endpoint

The app was scaffolded from the current Spin template:

```bash
mkdir -p wasm
cd wasm
spin new -t http-go moscow-time --accept-defaults
```

### Handler

File: `wasm/moscow-time/main.go`

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
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		moscow := time.Now().UTC().In(time.FixedZone("Europe/Moscow", 3*60*60))

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(
			w,
			`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow","utc_offset":"+03:00"}`+"\n",
			moscow.Unix(),
			moscow.Format(time.RFC3339),
			moscow.Format("15:04"),
		)
	})
}

func main() {}
```

### Manifest

File: `wasm/moscow-time/spin.toml`

```toml
spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["Nikita Schankin <nikita.sshankin@gmail.com>"]
description = ""

[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []

[component.moscow-time.build]
command = "tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm ."
watch = ["**/*.go", "go.mod"]
```

### Build And Run

Build:

```text
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components
```

WASM size:

```text
wasm/moscow-time/main.wasm 370177 bytes (362K)
```

Runtime proof:

```bash
spin up --listen 127.0.0.1:3000
curl -fsS http://127.0.0.1:3000/time
```

Output:

```json
{"unix":1783974918,"iso":"2026-07-13T23:35:18+03:00","hour_minute":"23:35","timezone":"Europe/Moscow","utc_offset":"+03:00"}
```

## Task 1 Design Questions

### a) Browser WASM vs server WASM

Browser WASM built for `js/wasm` expects JavaScript glue and browser APIs. Server WASM built with TinyGo for `wasip1` does not have the DOM, browser event loop, or JavaScript host objects. In return, it gets a server-side ABI with explicit WASI capabilities, a much smaller module, and a runtime that can run outside browsers in hosts such as Spin or Wasmtime.

### b) Why `-buildmode=c-shared`?

Spin's Go SDK adapts the Go handler into exports that the Spin host can call as a `wasi-http` component. `-buildmode=c-shared` makes TinyGo produce the expected exported symbols instead of a plain CLI-style `_start` module. Without it, Spin can load the file but cannot call the HTTP handler correctly.

### c) `allowed_outbound_hosts = []`

Spin follows a capability model: a component starts with no ambient network access and receives only the hosts listed in the manifest. `allowed_outbound_hosts = []` means this component cannot make outbound network calls at all. Docker's `--network none` also blocks networking, but Docker containers still have a broader Linux process model and kernel syscall surface. Spin's policy is per-component and explicit in the app manifest.

### d) TinyGo stdlib gaps

I avoided `time.LoadLocation("Europe/Moscow")` because TinyGo/WASI does not ship the normal host timezone database by default. I used `time.FixedZone("Europe/Moscow", 3*60*60)` instead. I also avoided `encoding/json` over `map[string]any`; reflection-heavy JSON paths are more fragile in TinyGo, so the handler builds the small fixed JSON response with `fmt.Fprintf`.

## Task 2 - Performance Comparison

Warm latency was measured with Hyperfine:

```bash
hyperfine --warmup 5 --runs 50 --export-json reports/lab12-spin-warm.json \
  'curl -fsS -o /dev/null http://127.0.0.1:3000/time'

hyperfine --warmup 5 --runs 50 --export-json reports/lab12-docker-warm.json \
  'curl -fsS -o /dev/null http://127.0.0.1:18080/health'
```

Cold start was measured as runtime start to first successful HTTP response, 5 samples each.

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|---|---:|---:|
| Artifact size | 22.8 MB image | 362 KB `main.wasm` |
| Cold start p50 | 694.66 ms | 388.02 ms |
| Warm latency p50 | 7.162 ms | 13.812 ms |
| Warm latency p95 | 12.053 ms | 32.899 ms |

Cold samples:

```text
Spin:   373.10, 367.56, 429.78, 388.02, 462.21 ms
Docker: 583.95, 694.66, 731.21, 733.12, 675.01 ms
```

Notes:

```text
Spin warm mean:   18.970 ms
Docker warm mean:  8.067 ms
```

On this WSL2/Docker Desktop test rig, Docker had lower warm request latency, while Spin had a smaller artifact and faster measured cold start.

## Task 2 Design Questions

### e) What dominates cold start?

For Docker, cold start includes Docker Desktop/engine scheduling, creating namespaces/cgroups, filesystem setup, and starting the Linux process inside the container. For Spin, cold start is mostly loading the WASM module, creating the Wasmtime instance, wiring the wasi-http handler, and starting the HTTP host loop. The Spin artifact is much smaller, so there is less image/layer work.

### f) Where WASM is better, and where Docker is still right

WASM is clearly better for small request handlers, plugins, edge functions, and multi-tenant extension points where startup time, artifact size, and sandboxing matter. Docker is still the better default for full services, stateful workloads, apps needing arbitrary OS packages, mature observability/debug tooling, database clients, and anything relying on normal Linux syscalls or cgo-heavy libraries.

### g) Multi-tenant safety

WASM makes kernel-escape and noisy-neighbor attacks harder because the guest code does not get normal Linux syscalls by default. A malicious plugin cannot simply scan the filesystem, open sockets, fork processes, or attack kernel interfaces unless the host grants those capabilities. Containers isolate with namespaces but still share the host kernel syscall surface.

## Bonus Task - Standalone WASI CLI

File: `wasm-cli/main.go`

The CLI module reads `REQUEST_METHOD` and `PATH_INFO`, then prints headers and the same JSON body to stdout.

Build:

```bash
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
```

Run:

```bash
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
```

Output:

```text
Content-Type: application/json

{"unix":1783974628,"iso":"2026-07-13T23:30:28+03:00","hour_minute":"23:30","timezone":"Europe/Moscow","utc_offset":"+03:00"}
```

Comparison:

| Dimension | Spin wasi-http component | Bare `wasmtime run` CLI |
|---|---:|---:|
| Module size | 370177 bytes | 196959 bytes |
| Execution model | Persistent HTTP host | Per-invocation CLI |
| Benchmark p50 | 13.812 ms warm HTTP | 131.471 ms per invocation |
| Benchmark p95 | 32.899 ms warm HTTP | 173.830 ms per invocation |

## Bonus Design Questions

### h) Why the Spin component cannot run under bare `wasmtime run`

The Spin component exports a wasi-http handler shape expected by a wasi-http host. Bare `wasmtime run` expects a command-style WASI module with a `_start` entrypoint. The Spin module is therefore not a standalone CLI program.

### i) What Spin adds on top of Wasmtime

Spin adds the application manifest, HTTP routing, wasi-http host implementation, component lifecycle, development server, build integration, and capability policy such as `allowed_outbound_hosts`. It uses Wasmtime underneath, but gives the module an HTTP platform instead of a raw CLI invocation.

### j) When each model fits

Per-invocation `wasmtime run` fits batch-style tools, filters, small CLI plugins, or job runners where stdin/stdout is the interface. Spin's persistent wasi-http model fits request/response services, edge endpoints, webhooks, and API handlers where an HTTP host should keep listening and route requests to components.
