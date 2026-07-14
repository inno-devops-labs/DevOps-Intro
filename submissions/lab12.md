# Lab 12 — WebAssembly Containers

## Environment

- Host OS: Windows 10
- Test environment: WSL2 Ubuntu
- Go: 1.26.1
- Spin: 3.4.0
- TinyGo: 0.41.0
- Docker: Docker Desktop 4.70.0
- Docker Engine: 29.4.0
- hyperfine: 1.18.0
- Spin Go SDK: `github.com/spinframework/spin-go-sdk/v2` v2.2.1

## Task 1 — Spin WASM endpoint

The application is located in:

```text
wasm/moscow-time
```

The project was scaffolded using the current Spin Go template:

```bash
mkdir -p wasm
cd wasm
spin new -t http-go moscow-time --accept-defaults
```

### main.go

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
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		now := time.Now().UTC().Add(3 * time.Hour)
		iso := now.Format("2006-01-02T15:04:05") + "+03:00"

		w.Header().Set("Content-Type", "application/json")

		fmt.Fprintf(
			w,
			`{"unix":%d,"iso":"%s","hour_minute":"%s"}`,
			now.Unix(),
			iso,
			now.Format("15:04"),
		)
	})
}

func main() {}
```

### spin.toml

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["levak"]
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

### Build

The component was built with:

```bash
spin build
```

Build output:

```text
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components
```

Generated artifact:

```text
main.wasm: 363K
```

### Run and verification

The application was started with:

```bash
spin up
```

Spin exposed the following route:

```text
http://127.0.0.1:3000/time
```

Verification command:

```bash
curl -s http://127.0.0.1:3000/time | python3 -m json.tool
```

Example response:

```json
{
    "unix": 1784051355,
    "iso": "2026-07-14T17:49:15+03:00",
    "hour_minute": "17:49"
}
```

The endpoint returned HTTP 200 with `Content-Type: application/json`.

## Task 1 design questions

### a) Browser WASM vs server WASM

A module built for browser WebAssembly depends on a browser and JavaScript integration. The usual Go browser target is `GOOS=js GOARCH=wasm`, and the resulting module uses JavaScript glue code to access browser functionality.

A module built with TinyGo for `wasip1` runs outside the browser through the WebAssembly System Interface. The server target does not have browser APIs, the DOM, or unrestricted operating-system access. Instead, interaction with the host is provided through explicitly supported WASI interfaces.

The server target gains portability across operating systems and CPU architectures, a smaller artifact, fast startup, and capability-based isolation. The same WASI module can run under compatible server runtimes without depending on a browser.

### b) Why is `-buildmode=c-shared` required?

Spin does not expect a normal standalone WASI command with only a `_start` entry point. It expects the module to export the handler interfaces required by the Spin Go SDK and the wasi-http host.

The `-buildmode=c-shared` option makes TinyGo export the symbols and component interface that Spin needs to invoke the registered HTTP handler.

Without this option, Spin cannot call the handler correctly and requests may fail with an HTTP 500 error.

### c) Capability-based security and `allowed_outbound_hosts = []`

Spin follows a deny-by-default capability model. A component receives access only to the resources explicitly granted in its manifest.

The following setting gives the component no permission to connect to external network hosts:

```toml
allowed_outbound_hosts = []
```

This is similar to Docker's `--network none` because both prevent network communication. The difference is that Docker disables networking for the container through Linux networking and namespaces, while Spin applies permissions at the WebAssembly component level.

Spin can grant access only to selected hosts, while keeping every other destination unavailable. This provides more fine-grained control than enabling or disabling the whole container network.

### d) TinyGo standard-library gaps

The main limitation encountered during this lab was time-zone handling. TinyGo does not provide the complete time-zone database used by upstream Go, so relying on:

```go
time.LoadLocation("Europe/Moscow")
```

may fail.

Moscow time was therefore calculated using its fixed UTC+3 offset:

```go
time.Now().UTC().Add(3 * time.Hour)
```

Another TinyGo limitation is incomplete support for reflection-heavy code. Encoding a value such as `map[string]any` with `encoding/json` may require reflection functionality that is limited in TinyGo.

To avoid that issue, the JSON response was constructed directly with `fmt.Fprintf`.

## Task 2 — Performance comparison

### Test methodology

Both applications were tested from the same WSL2 environment on the same machine.

The Docker baseline was:

```text
quicknotes:lab6
```

The Docker endpoint was:

```text
http://127.0.0.1:8080/health
```

The Spin endpoint was:

```text
http://127.0.0.1:3000/time
```

Warm latency was measured with 10 warmup runs and 50 measured runs.

Docker command:

```bash
hyperfine \
  --warmup 10 \
  --runs 50 \
  --export-json docker-warm.json \
  'curl -s -o /dev/null http://127.0.0.1:8080/health'
```

Spin command:

```bash
hyperfine \
  --warmup 10 \
  --runs 50 \
  --export-json spin-warm.json \
  'curl -s -o /dev/null http://127.0.0.1:3000/time'
```

Cold start was measured from runtime startup until the first successful HTTP response. Five independent samples were collected for each platform.

### Artifact size

Docker image inspection reported:

```text
quicknotes:lab6
content size: 3,545,993 bytes
Docker disk usage: 15.5 MB
```

The WebAssembly artifact size was:

```text
main.wasm: 363K
```

### Warm latency results

Docker result:

```text
Time (mean ± σ): 5.0 ms ± 0.3 ms
Range: 4.6 ms ... 6.3 ms
Runs: 50
```

Spin result:

```text
Time (mean ± σ): 7.7 ms ± 0.7 ms
Range: 6.8 ms ... 9.4 ms
Runs: 50
```

The endpoints perform different amounts of work. Docker `/health` returns a small health response, while Spin `/time` reads the current time, formats multiple values, and constructs JSON.

### Cold-start samples

Docker:

```text
329 ms
232 ms
285 ms
263 ms
239 ms
```

Sorted Docker samples:

```text
232 ms
239 ms
263 ms
285 ms
329 ms
```

Docker cold-start p50:

```text
263 ms
```

Docker average:

```text
269.6 ms
```

Spin:

```text
147 ms
56 ms
58 ms
57 ms
59 ms
```

Sorted Spin samples:

```text
56 ms
57 ms
58 ms
59 ms
147 ms
```

Spin cold-start p50:

```text
58 ms
```

Spin average:

```text
75.4 ms
```

The first Spin launch was slower than the following launches, most likely because runtime or module data was not cached yet.

### Results table

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|---|---:|---:|
| Artifact size | 3.54 MB content / 15.5 MB disk usage | 363 KB |
| Cold start p50 | 263 ms | 58 ms |
| Cold start average | 269.6 ms | 75.4 ms |
| Warm latency mean | 5.0 ms | 7.7 ms |
| Warm latency observed range | 4.6–6.3 ms | 6.8–9.4 ms |

The exact warm p50 and p95 values were not printed in the default `hyperfine` terminal summary. The exported JSON files preserve the individual benchmark data for additional percentile processing.

## Task 2 design questions

### e) What dominates each platform's cold start?

Docker cold start includes creating the container, preparing its filesystem and writable layer, configuring namespaces and networking, applying cgroup settings, and starting the application process.

If an image is not already available locally, downloading and extracting image layers adds an even larger cost. In this experiment, the image was already present, so the measured time mostly represents container creation and process startup.

Spin cold start mainly includes loading the WebAssembly module, initializing Wasmtime, creating an instance, linking the required WASI and wasi-http interfaces, and starting the HTTP trigger.

Spin performs fewer operating-system-level initialization steps, which explains its lower measured cold-start time.

### f) Where is WASM better, and where is Docker still the right choice?

WASM is a good fit for:

- edge functions;
- serverless request handlers;
- short-lived workloads;
- plugin systems;
- multi-tenant platforms;
- applications where startup time and artifact size are important.

Docker remains a better choice for:

- long-running stateful services;
- databases;
- applications requiring arbitrary Linux system calls;
- applications using native system libraries;
- software that depends on package managers such as `apt`;
- complex networking and operating-system configuration;
- applications that cannot be compiled with TinyGo or another WASM-compatible toolchain.

WASM does not replace Docker for every workload. It is strongest for small, isolated, portable components, while Docker remains more flexible for general-purpose applications.

### g) Multi-tenant safety

A WebAssembly component cannot access the filesystem, network, environment, or other host resources unless the runtime explicitly grants the required capability.

For example, a malicious component cannot simply open `/etc/passwd`, scan the host filesystem, or connect to an arbitrary external server when these capabilities were not provided.

A container is isolated with Linux namespaces, cgroups, and other kernel security mechanisms, but it still shares the host kernel and exposes a much larger system-call surface.

The smaller WASM interface and deny-by-default capability model make host filesystem access, arbitrary network access, and kernel-level container escape attacks harder.