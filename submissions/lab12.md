# Lab 12 — WebAssembly Containers

## Environment

* Host OS: Windows 10
* Test environment: WSL2 Ubuntu
* Go: 1.26.1
* Spin: 3.4.0
* TinyGo: 0.41.0
* Wasmtime: 46.0.1
* Docker: Docker Desktop 4.70.0
* Docker Engine: 29.4.0
* hyperfine: 1.18.0
* Spin Go SDK: `github.com/spinframework/spin-go-sdk/v2` v2.2.1

## Task 1 — Spin WASM endpoint

The application is located in:

```text
wasm/moscow-time
```

The project was scaffolded using the Spin Go HTTP template:

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

		utcNow := time.Now().UTC()
		moscowNow := utcNow.Add(3 * time.Hour)
		iso := moscowNow.Format("2006-01-02T15:04:05") + "+03:00"

		w.Header().Set("Content-Type", "application/json")

		fmt.Fprintf(
			w,
			`{"unix":%d,"iso":"%s","hour_minute":"%s"}`,
			utcNow.Unix(),
			iso,
			moscowNow.Format("15:04"),
		)
	})
}

func main() {}
```

The Unix timestamp is calculated from the original UTC instant. The UTC+3 offset is applied only when formatting the Moscow wall-clock time.

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
wasm/moscow-time/main.wasm: 370835 bytes
```

This is approximately 362 KiB. The human-readable output from `ls -lh` rounded it to approximately 363K.

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
    "unix": 1784042893,
    "iso": "2026-07-14T18:28:13+03:00",
    "hour_minute": "18:28"
}
```

The `unix` and `iso` fields represent the same instant. The Unix timestamp corresponds to `15:28:13 UTC`, which is `18:28:13` in Moscow at UTC+3.

The endpoint returned HTTP 200 with `Content-Type: application/json`.

## Task 1 design questions

### a) Browser WASM vs server WASM

A module built for browser WebAssembly depends on a browser and JavaScript integration. The usual Go browser target is `GOOS=js GOARCH=wasm`, and the resulting module uses JavaScript glue code to access browser functionality.

A module built with TinyGo for `wasip1` runs outside the browser through the WebAssembly System Interface. The server target does not have browser APIs, the DOM, or unrestricted operating-system access. Instead, interaction with the host is provided through explicitly supported WASI interfaces.

The server target gains portability across operating systems and CPU architectures, a relatively small artifact, fast startup, and capability-based isolation. The same WASI-compatible module can run under compatible runtimes without depending on a browser.

### b) Why is `-buildmode=c-shared` required?

Spin does not expect a normal standalone WASI command with only a `_start` entry point. It expects the module to expose the handler functions required by the Spin Go SDK and the HTTP host.

The `-buildmode=c-shared` option makes TinyGo export the functions needed by Spin to invoke the registered HTTP handler.

Without this option, the generated module has the wrong execution model for the Spin HTTP trigger, and Spin cannot invoke the handler correctly.

### c) Capability-based security and `allowed_outbound_hosts = []`

Spin follows a deny-by-default capability model. A component receives access only to resources explicitly granted in its manifest.

The following setting gives the component no permission to connect to external network hosts:

```toml
allowed_outbound_hosts = []
```

This is conceptually similar to Docker's `--network none` because both restrict network communication. The implementation is different.

Docker restricts networking at the container and operating-system level through Linux namespaces and virtual networking. Spin applies the restriction at the WebAssembly component capability level.

Spin can also grant access only to selected hosts while keeping all other destinations unavailable. This provides more fine-grained control than enabling or disabling the entire container network.

### d) TinyGo standard-library gaps

The main limitation encountered during the lab was time-zone handling. TinyGo does not provide the complete time-zone database normally available to upstream Go programs, so relying on:

```go
time.LoadLocation("Europe/Moscow")
```

may fail or make the build less portable.

Moscow time was therefore calculated using its fixed UTC+3 offset:

```go
utcNow := time.Now().UTC()
moscowNow := utcNow.Add(3 * time.Hour)
```

The Unix timestamp is taken from `utcNow`, while the formatted Moscow time is taken from `moscowNow`.

Another TinyGo limitation is reduced support for reflection-heavy code. Encoding a dynamic value such as `map[string]any` with `encoding/json` may require reflection functionality that is limited or increases the module size.

To avoid that issue, the small JSON response was constructed directly with `fmt.Fprintf`.

## Task 2 — Performance comparison

### Test methodology

Both applications were tested from the same WSL2 environment on the same physical machine.

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

The p50 and p95 values were calculated from the individual durations stored in the exported `hyperfine` JSON files.

Cold start was measured from runtime startup until the first successful HTTP response. Five independent samples were collected for each platform.

Because every warm benchmark sample starts a new `curl` process, the warm results include client process and shell overhead in addition to server response time. The same measurement method was used for both applications, so the comparison remains consistent, but the numbers should not be interpreted as pure server-side execution time.

### Artifact size

Docker image inspection reported:

```text
quicknotes:lab6
content size: 3545993 bytes
Docker Desktop disk usage: 15.5 MB
```

The exact WebAssembly artifact size was:

```text
wasm/moscow-time/main.wasm: 370835 bytes
```

The Docker content size is approximately 9.6 times larger than the Spin WebAssembly artifact. Docker Desktop disk usage is higher than the image content size because it also reflects local storage and image-layer overhead.

### Warm latency results

Docker:

```text
Runs: 50
Mean: 5.04 ms
p50: 4.99 ms
p95: 5.59 ms
Minimum: 4.56 ms
Maximum: 6.27 ms
```

Spin:

```text
Runs: 50
Mean: 7.70 ms
p50: 7.46 ms
p95: 8.97 ms
Minimum: 6.84 ms
Maximum: 9.41 ms
```

The endpoints perform different amounts of application work. Docker `/health` returns a small health response, while Spin `/time` reads the current time, formats multiple values, and constructs a JSON document.

The benchmark therefore compares the complete endpoints as implemented, rather than two identical business operations.

### Cold-start samples

Docker samples:

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

Docker cold-start average:

```text
269.6 ms
```

Spin samples:

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

Spin cold-start average:

```text
75.4 ms
```

The first Spin launch was slower than the following launches. A likely explanation is operating-system filesystem caching and runtime or module initialization data becoming cached after the first invocation.

### Results table

| Dimension        |    Lab 6 Docker | Lab 12 WASM/Spin |
| ---------------- | --------------: | ---------------: |
| Artifact size    | 3,545,993 bytes |    370,835 bytes |
| Cold start p50   |          263 ms |            58 ms |
| Warm latency p50 |         4.99 ms |          7.46 ms |
| Warm latency p95 |         5.59 ms |          8.97 ms |

Additional measured values:

| Dimension            | Lab 6 Docker | Lab 12 WASM/Spin |
| -------------------- | -----------: | ---------------: |
| Cold start average   |     269.6 ms |          75.4 ms |
| Warm latency mean    |      5.04 ms |          7.70 ms |
| Warm latency minimum |      4.56 ms |          6.84 ms |
| Warm latency maximum |      6.27 ms |          9.41 ms |

The Docker endpoint had lower warm latency in this experiment, while Spin had a much smaller artifact and substantially lower cold-start latency.

## Task 2 design questions

### e) What dominates each platform's cold start?

Docker cold start includes creating the container, preparing its filesystem and writable layer, configuring namespaces and networking, applying cgroup settings, and starting the application process.

If an image is not already available locally, downloading and extracting image layers adds a much larger cost. In this experiment, the image was already present, so the measured time mostly represents container creation and application process startup.

Spin cold start mainly includes loading the WebAssembly module, initializing the Wasmtime-based runtime, creating the component instance, linking the required WASI and HTTP interfaces, and starting the HTTP trigger.

Spin performs fewer operating-system-level initialization steps, which helps explain its lower measured cold-start time.

### f) Where is WASM better, and where is Docker still the right choice?

WASM is a good fit for:

* edge functions;
* serverless request handlers;
* short-lived workloads;
* plugin systems;
* multi-tenant platforms;
* applications where startup time and artifact size are important.

Docker remains a better choice for:

* long-running stateful services;
* databases;
* applications requiring arbitrary Linux system calls;
* applications using native system libraries;
* software that depends on operating-system packages;
* workloads requiring complex networking or operating-system configuration;
* applications that cannot be compiled for a WASI-compatible target.

WASM does not replace Docker for every workload. It is strongest for small, isolated, portable components, while Docker remains more flexible for general-purpose applications.

### g) Multi-tenant safety

A WebAssembly component cannot access the filesystem, network, environment, or other host resources unless the runtime explicitly grants the required capability.

For example, a malicious component cannot simply open `/etc/passwd`, scan the host filesystem, or connect to an arbitrary external server when those capabilities were not provided.

A container is isolated with Linux namespaces, cgroups, and other kernel security mechanisms, but it still shares the host kernel and exposes a much larger system-call surface.

The smaller WASM host interface and deny-by-default capability model reduce the available attack surface and make arbitrary filesystem access, arbitrary network access, and kernel-level container escape attacks more difficult.

# Bonus Task — Standalone WASI CLI

## Implementation

The standalone module is located in:

```text
wasm-cli
```

Unlike the Spin component, this module does not use the Spin Go SDK. It reads CGI-style request information from environment variables:

```text
REQUEST_METHOD
PATH_INFO
```

The module handles:

```text
GET /time
```

and prints Moscow time as JSON to standard output.

### main.go

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

	if method != "GET" {
		fmt.Fprintln(os.Stderr, "method not allowed")
		os.Exit(1)
	}

	if path != "/time" {
		fmt.Fprintln(os.Stderr, "not found")
		os.Exit(1)
	}

	utcNow := time.Now().UTC()
	moscowNow := utcNow.Add(3 * time.Hour)
	iso := moscowNow.Format("2006-01-02T15:04:05") + "+03:00"

	fmt.Printf(
		`{"unix":%d,"iso":"%s","hour_minute":"%s"}`+"\n",
		utcNow.Unix(),
		iso,
		moscowNow.Format("15:04"),
	)
}
```

The source file was converted to Unix LF line endings before the final build:

```bash
dos2unix main.go
```

This prevented the generated WebAssembly file from being corrupted by an incorrect source-file line-ending format in the WSL environment.

## Build

The standalone module was built with:

```bash
tinygo build \
  -o main.wasm \
  -target=wasi \
  -no-debug \
  ./main.go
```

Generated artifact:

```text
wasm-cli/main.wasm: 196623 bytes
```

For comparison, the Spin HTTP component size was:

```text
wasm/moscow-time/main.wasm: 370835 bytes
```

The standalone CLI module is approximately 47% smaller because it does not include the Spin Go SDK, `net/http`, or the Spin HTTP handler integration.

## Run

The module was executed with:

```bash
wasmtime run \
  --env REQUEST_METHOD=GET \
  --env PATH_INFO=/time \
  ./main.wasm
```

Example output:

```json
{
    "unix": 1784043312,
    "iso": "2026-07-14T18:35:12+03:00",
    "hour_minute": "18:35"
}
```

The Unix timestamp corresponds to `15:35:12 UTC`, which is the same instant as `18:35:12+03:00`.

Invalid paths were also rejected:

```bash
wasmtime run \
  --env REQUEST_METHOD=GET \
  --env PATH_INFO=/wrong \
  ./main.wasm
```

Output:

```text
not found
```

## Performance

The per-invocation Wasmtime execution model was measured with:

```bash
hyperfine \
  --warmup 2 \
  --runs 20 \
  --export-json /tmp/wasmtime-cli-final.json \
  'wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time ./main.wasm > /dev/null'
```

Final results:

| Metric             | Wasmtime CLI |
| ------------------ | -----------: |
| Runs               |           20 |
| Mean               |       8.2 ms |
| Standard deviation |       0.5 ms |
| Minimum            |       7.2 ms |
| Maximum            |       9.2 ms |

Each benchmark iteration started a new Wasmtime process, loaded the WASI module, created an instance, executed `main`, printed the result, and terminated.

### Execution model comparison

| Dimension                  |  Spin HTTP component |                   Standalone Wasmtime CLI |
| -------------------------- | -------------------: | ----------------------------------------: |
| Module size                |        370,835 bytes |                             196,623 bytes |
| Measured startup/execution | 58 ms cold-start p50 |                8.2 ms mean per invocation |
| Execution model            | Persistent HTTP host | New process and instance for each command |
| Interface                  |    Spin HTTP handler |                  WASI command entry point |

These timings represent different execution models and should not be treated as a direct request-latency comparison.

The Spin measurement includes starting the persistent HTTP host and waiting until the endpoint becomes reachable. The Wasmtime measurement executes a single CLI command without starting an HTTP server.

## Bonus design questions

### h) Why cannot the Spin component run under bare `wasmtime run`?

The Spin application is built for the Spin HTTP execution model. It exposes an HTTP handler that must be invoked by a compatible host.

Bare `wasmtime run` expects a standalone WASI command with a command entry point. It does not automatically provide Spin routing, read `spin.toml`, or invoke a Spin HTTP handler.

A host that understands the component's expected HTTP interface is therefore required. Spin provides that host and the surrounding application lifecycle.

### i) What does Spin add on top of Wasmtime?

Wasmtime is the low-level runtime responsible for loading and executing WebAssembly modules and components.

Spin adds an application framework around the runtime, including:

* an HTTP server loop;
* routing configured in `spin.toml`;
* HTTP handler invocation;
* component lifecycle management;
* instance creation and reuse;
* capability configuration;
* outbound-host policies;
* build, watch, run, and deployment workflows.

Wasmtime executes WebAssembly, while Spin turns WebAssembly components into managed HTTP applications.

### j) When does each execution model fit?

The per-invocation `wasmtime run` model is suitable for short standalone jobs such as:

* CLI utilities;
* cron jobs;
* processing one input file;
* data conversion;
* batch jobs;
* CGI-style request execution.

For example, a scheduled command that reads one file, transforms it, prints the result, and exits fits the standalone WASI CLI model.

The persistent Spin HTTP model is suitable for workloads that must continuously accept HTTP requests, such as:

* REST API endpoints;
* webhooks;
* edge functions;
* serverless HTTP handlers;
* lightweight microservices.

For example, an always-available `/time` endpoint fits Spin because the HTTP host remains running and routes incoming requests to the component.
