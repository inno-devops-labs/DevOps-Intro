# Lab 12 - Bonus: WebAssembly Containers with Spin

## Objective

This lab builds one QuickNotes-style endpoint as a WebAssembly component with
the Spin Go SDK and TinyGo. The endpoint serves Moscow time at `/time`, then I
compare its size and startup behavior with the Lab 6 Docker image. For the
bonus task, the same Moscow-time logic is also built as a standalone WASI CLI
module and executed with bare `wasmtime run`.

## Environment

| Component | Version / value |
|-----------|-----------------|
| Host OS | macOS, Apple Silicon |
| Branch | `feature/lab12` |
| Go on host | `go1.26.4 darwin/arm64` |
| Spin | `spin 3.4.0 (4f671be 2025-08-26)` |
| TinyGo | `tinygo version 0.41.1 darwin/arm64 (using go version go1.26.4 and LLVM version 20.1.1)` |
| wasmtime | `wasmtime 46.0.1 (823d1b8f2 2026-06-24)` |
| wasm-opt | `wasm-opt version 130` |
| hyperfine | `hyperfine 1.20.0` |
| Docker | `Docker version 29.1.5, build 0e6fee6` |
| Lab 6 image | `quicknotes:lab6`, `sha256:7563fb5d9ff374fd90f39f55462796959edbf828a6efabfb7b36b086120a247c` |

TinyGo was installed from the official `v0.41.1` darwin-arm64 release archive.
Because it was unpacked manually, builds used:

```bash
PATH="$HOME/.local/bin:$PATH"
TINYGOROOT="$HOME/.local/tools/tinygo"
```

## Repository layout

```text
wasm/
|- .gitignore
|- go.mod
|- go.sum
|- main.go
`- spin.toml
wasm-cli/
|- .gitignore
|- go.mod
`- main.go
submissions/lab12.md
```

The generated `main.wasm` files are not committed. Their sizes and build
outputs are recorded below.

---

## Task 1 - Spin SDK WebAssembly Endpoint

### Scaffold

The Spin application was scaffolded from the official Spin 3.4 template:

```bash
mkdir -p wasm
cd wasm
spin new -t http-go moscow-time --accept-defaults
```

The generated template was then moved to the `wasm/` root so the final
submission contains `wasm/main.go`, `wasm/go.mod`, `wasm/go.sum`, and
`wasm/spin.toml`.

The template generated the current Spin SDK import path:

```text
github.com/spinframework/spin-go-sdk/v2 v2.2.1
```

### `wasm/main.go`

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
			http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
			return
		}

		moscow := time.Now().In(time.FixedZone("MSK", 3*60*60))

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(
			w,
			`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow","utc_offset":"+03:00"}`,
			moscow.Unix(),
			moscow.Format(time.RFC3339),
			moscow.Format("15:04"),
		)
	})
}
```

### `wasm/spin.toml`

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["Arseny Pinigin <hidancloud@yandex.ru>"]
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

### Build evidence

Command:

```bash
PATH="$HOME/.local/bin:$PATH" TINYGOROOT="$HOME/.local/tools/tinygo" spin build
```

Output:

```text
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components
```

Artifact size:

```bash
ls -lh wasm/main.wasm
wc -c wasm/main.wasm
```

```text
-rw-r--r--@ 1 arsenypinigin  staff   360K Jul 14 19:45 wasm/main.wasm
369057 wasm/main.wasm
```

### Runtime evidence

Command:

```bash
PATH="$HOME/.local/bin:$PATH" TINYGOROOT="$HOME/.local/tools/tinygo" spin up --listen 127.0.0.1:3000
curl -s http://127.0.0.1:3000/time | python3 -m json.tool
```

Spin output:

```text
Logging component stdio to ".spin/logs/"

Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000/time
```

HTTP response:

```json
{
    "unix": 1784047565,
    "iso": "2026-07-14T19:46:05+03:00",
    "hour_minute": "19:46",
    "timezone": "Europe/Moscow",
    "utc_offset": "+03:00"
}
```

### Design questions

**a) Browser WASM vs server WASM: `go build` for `js/wasm` vs TinyGo `wasip1`. What is missing in the server target, and what do you gain?**

Browser WASM expects a JavaScript host and Go's `wasm_exec.js` glue. It is
designed to run inside the browser event loop and call browser APIs through
JavaScript. Server WASM with `wasip1` does not have the browser DOM,
JavaScript APIs, or arbitrary OS syscalls. In exchange, it gets a small
portable server-side artifact with explicit WASI capabilities, no browser
runtime dependency, and a much tighter sandbox.

**b) Why does the build command need `-buildmode=c-shared`?**

Spin hosts a wasi-http component and expects exported symbols that its host
runtime can call for HTTP handling. TinyGo's `-buildmode=c-shared` creates the
right component-style exports for the Spin Go SDK. Without it, the module may
compile as a normal WASI program, but Spin cannot call it as an HTTP handler
and requests fail at runtime.

**c) Why use `allowed_outbound_hosts = []`? Compare it to Docker's `--network none`.**

Spin uses capability-based security: a component has no network access unless
the manifest grants specific outbound hosts. `allowed_outbound_hosts = []`
means this endpoint cannot call any external service, which is the correct
least-privilege policy for a local time endpoint. Docker's `--network none`
also blocks network access, but it is a coarse container-level switch. Spin's
model is more granular because the policy can be per component and per allowed
host.

**d) Which TinyGo stdlib gap appeared in this lab?**

The relevant gap was time-zone data. I avoided
`time.LoadLocation("Europe/Moscow")` because TinyGo WASI builds do not carry
the normal host timezone database. I used `time.FixedZone("MSK", 3*60*60)`
instead. I also avoided `encoding/json` with `map[string]any` and built the
small JSON response with `fmt.Fprintf`, which avoids reflection-heavy paths
that can be fragile in TinyGo.

---

## Task 2 - Performance Comparison vs Lab 6 Docker

### Test rig

All measurements were taken on the same macOS Apple Silicon laptop. The Spin
app listened on `127.0.0.1:3000/time`. The Docker baseline used the already
built Lab 6 image `quicknotes:lab6`, mapped to `127.0.0.1:18082/health`.

The Docker image metadata:

```text
[quicknotes:lab6] Id=sha256:7563fb5d9ff374fd90f39f55462796959edbf828a6efabfb7b36b086120a247c Size=5462588 Created=2026-07-07T11:17:32.307382424Z
```

### Warm latency

Command:

```bash
hyperfine --warmup 5 --runs 50 --export-json /tmp/lab12-warm.json \
  'curl -s -o /dev/null http://127.0.0.1:3000/time' \
  'curl -s -o /dev/null http://127.0.0.1:18082/health'
```

Output excerpt:

```text
Benchmark 1: curl -s -o /dev/null http://127.0.0.1:3000/time
  Time (mean +/- sigma):       4.7 ms +/-   0.4 ms
  Range (min ... max):         4.2 ms ...   6.2 ms    50 runs

Benchmark 2: curl -s -o /dev/null http://127.0.0.1:18082/health
  Time (mean +/- sigma):       6.2 ms +/-   0.4 ms
  Range (min ... max):         5.0 ms ...   7.1 ms    50 runs
```

Parsed percentiles from Hyperfine JSON:

```text
Spin /time:
mean_ms=4.745
p50_ms=4.635
p95_ms=5.563
min_ms=4.216 max_ms=6.196

Docker /health:
mean_ms=6.238
p50_ms=6.303
p95_ms=6.713
min_ms=5.040 max_ms=7.138
```

### Cold start

Cold start was measured by killing the runtime, starting it fresh, and polling
until the first successful HTTP response. I used seven samples for each
runtime.

Spin samples:

```text
26.5 ms, 25.7 ms, 26.3 ms, 26.8 ms, 26.7 ms, 26.9 ms, 24.3 ms
p50_ms=26.5
p95_ms=26.9
mean_ms=26.2
```

Docker samples, including `docker run -d` time:

```text
124.3 ms, 90.4 ms, 94.1 ms, 88.9 ms, 91.5 ms, 92.1 ms, 95.1 ms
p50_ms=92.1
p95_ms=124.3
mean_ms=96.6
```

### Comparison table

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|-----------|-------------:|-----------------:|
| Artifact size | 5,462,588 B image, shown by Docker as 22.1 MB virtual size | 369,057 B `main.wasm` |
| Cold start p50 | 92.1 ms | 26.5 ms |
| Warm latency p50 | 6.303 ms | 4.635 ms |
| Warm latency p95 | 6.713 ms | 5.563 ms |

On this machine, Spin was smaller and faster to cold-start. The warm latency
numbers are close because the local `curl` process and loopback networking are
a large part of each measured request.

### Design questions

**e) What dominates each platform's cold start?**

For Docker, the measured cold start is mostly Docker daemon work: creating the
container, setting up networking and namespaces, starting the process, and
waiting for the Go HTTP server to listen. The image was already local, so this
does not include registry pull time. For Spin, cold start is mostly starting
the Spin host, loading the WASM module, and instantiating it through wasmtime.

**f) For what workloads is WASM clearly better, and where is Docker still right?**

WASM is clearly better for small request handlers, edge functions, plugin
systems, and multi-tenant extension points where startup time, small artifact
size, and sandboxing matter. Docker is still the better default for larger
services, stateful workloads, database clients, programs needing full OS
behavior, and teams that rely on mature container tooling.

**g) What concrete attack does a WASM platform make harder?**

WASM makes host filesystem and network escape harder. A malicious or
compromised module cannot simply open `/etc/passwd`, scan the network, or make
arbitrary syscalls unless the host explicitly grants those capabilities. That
is stronger isolation for plugin-style multi-tenant workloads than relying
only on Linux namespaces around a normal process.

---

## Bonus Task - Two WASM Execution Models

### Standalone WASI CLI module

The bonus module lives in `wasm-cli/`. It does not use the Spin SDK. It reads
`REQUEST_METHOD` and `PATH_INFO`, then prints the same Moscow-time JSON to
stdout.

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

	moscow := time.Now().In(time.FixedZone("MSK", 3*60*60))
	fmt.Printf(
		"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":\"Europe/Moscow\",\"utc_offset\":\"+03:00\"}\n",
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		moscow.Format("15:04"),
	)
}
```

### Build and run evidence

Build command:

```bash
PATH="$HOME/.local/bin:$PATH" TINYGOROOT="$HOME/.local/tools/tinygo" \
  tinygo build -o main.wasm -target=wasi -no-debug ./main.go
```

Run command:

```bash
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm | python3 -m json.tool
```

Output:

```json
{
    "unix": 1784047565,
    "iso": "2026-07-14T19:46:05+03:00",
    "hour_minute": "19:46",
    "timezone": "Europe/Moscow",
    "utc_offset": "+03:00"
}
```

Module size:

```text
-rw-r--r--@ 1 arsenypinigin  staff   191K Jul 14 19:45 wasm-cli/main.wasm
195096 wasm-cli/main.wasm
```

Per-invocation `wasmtime run` benchmark:

```bash
hyperfine --warmup 5 --runs 50 --export-json /tmp/lab12-wasmtime.json \
  'wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time wasm-cli/main.wasm >/dev/null'
```

```text
Time (mean +/- sigma):       5.3 ms +/-   0.3 ms
Range (min ... max):         5.0 ms ...   6.6 ms    50 runs

mean_ms=5.258
p50_ms=5.155
p95_ms=5.924
min_ms=4.976 max_ms=6.632
```

### Spin vs wasmtime CLI comparison

| Dimension | Spin wasi-http component | Standalone wasmtime CLI |
|-----------|-------------------------:|------------------------:|
| Module size | 369,057 B | 195,096 B |
| Execution model | HTTP server host with routing and wasi-http handler | Per-invocation CLI module |
| Cold/per-invocation p50 | 26.5 ms to start Spin and first HTTP response | 5.155 ms per `wasmtime run` invocation |
| Best fit | HTTP endpoints and edge services | Small command-style jobs and CGI-like adapters |

The CLI module is smaller because it does not include the Spin SDK HTTP
adapter. Spin adds the server loop, manifest-driven routing, and policy layer,
which are exactly what make it useful as an HTTP application runtime.

### Design questions

**h) Why cannot the Task 1 Spin component run under bare `wasmtime run`?**

The Spin component is a wasi-http component. It exports the handler shape that
Spin expects, not a normal `_start` entrypoint for a CLI program. Bare
`wasmtime run` executes command modules, so it does not know how to route an
HTTP request into the Spin SDK handler.

**i) Spin uses wasmtime internally. What does Spin add on top of bare wasmtime?**

Spin adds the HTTP server, wasi-http request/response wiring, manifest parsing,
routing, component configuration, outbound-host capability policy, logging,
and operational commands like `spin build` and `spin up`. In other words,
wasmtime is the execution engine, while Spin is the application runtime around
it.

**j) When does each execution model fit?**

Per-invocation `wasmtime run` fits small command jobs, filters, validators, or
CGI-like adapters where each call is independent and stdout is the interface.
Spin's persistent wasi-http server fits request/response services such as edge
functions, webhook handlers, and small API endpoints like `/time`.
