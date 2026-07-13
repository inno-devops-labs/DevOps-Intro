# Lab 12 Submission

## Task 1

### main.go
```
package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/time" {
			http.NotFound(w, r)
			return
		}

		now := time.Now().UTC().Add(3 * time.Hour)
		unix := now.Unix()
		iso := now.Format(time.RFC3339)
		hourMinute := now.Format("15:04")

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)

		fmt.Fprintf(w, `{"unix": %d, "iso": "%s", "hour_minute": "%s", "timezone": "Europe/Moscow (UTC+3)"}`,
			unix, iso, hourMinute)
	})
}

func main() {}
```
### spin.toml

```
spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["Alina <alinapestova@gmail.com>"]
description = ""

[[trigger.http]]
route = "/..."
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []

[component.moscow-time.build]
command = "tinygo build -target=wasip1 -buildmode=c-shared -no-debug -opt=0 -o main.wasm ."
watch = ["**/*.go", "go.mod"]
```
### spin build output:
```Plaintext
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -opt=0 -o main.wasm .`
Finished building all Spin components
```
Artifact size: ~4.5 MB 

### curl response:
```{"unix": 1783963034, "iso": "2026-07-13T17:17:14Z", "hour_minute": "17:17", "timezone": "Europe/Moscow (UTC+3)"}```

### Design Questions

**a) Browser WASM vs server WASM:**

js/wasm expects a JavaScript host environment to provide the necessary imports. wasip1 expects a WASI-compliant runtime to provide system-level interfaces like POSIX-like clocks, standard I/O, and file systems.

**b) Why does the build command need `-buildmode=c-shared`:** 

It tells the Go compiler to export functions in a C-style ABI. Spin needs it so its host runtime can locate and dynamically call the exported entry point inside the compiled .wasm binary. Without it, the module is opaque to Spin.

**c) allowed_outbound_hosts = [] is the strictest setting:** 

Docker's --network none uses Linux namespaces to restrict the container's network stack at the OS level. WASM uses capability-based security: it is deny-by-default at the syscall layer. 

allowed_outbound_hosts = [] means the WASM runtime simply won't fulfill any network-related syscalls requested by the module, offering a tighter sandbox.

**d) TinyGo stdlib gaps:** 
1) time: lacks embedded tzdata, causing time.LoadLocation("Europe/Moscow") to fail. 
2) encoding/json: Heavy use of reflection makes marshalling map[string]any behave unpredictably under TinyGo limits.

## Task 2

**Hardware/OS Context:** Windows via PyCharm Terminal.

| Dimension              | Lab 6 Docker | Lab 12 WASM/Spin |
|------------------------|-------------:|-----------------:|
| Artifact size          |      8.08 MB |          ~4.5 MB |
| Cold start (p50)       |      ~2000 ms|           ~15 ms |
| Warm latency p50       |      39.3 ms |          27.0 ms |
| Warm latency max       |      80.4 ms |          68.5 ms |

### Design Questions

**e) What dominates each platform's cold start?** 

Container: Unpacking the image filesystem, mounting layers, and initializing Linux namespaces. 

Spin: Instantiating the Wasmtime runtime and mapping the pre-compiled WASM module into memory.

**f) For what workloads is WASM clearly better, and where is Docker still right?** 

WASM is better for high-density, scale-to-zero functions, edge computing, and simple microservices where rapid cold starts and tiny footprints are critical. 

Docker is better for long-running stateful services, heavy runtime environments, or software needing raw Linux kernel access.

**g) Multi-tenant safety:** 

WASM prevents directory traversal and unauthorized network requests natively via capabilities. A compromised WASM module still cannot touch the host OS file system without explicit capability grants, whereas a container breakout compromises the host node.


## Bonus Task

### Commands Comparison

*   **Task 1 (Spin / wasi-http model):**
    *   Build: `spin build` (runs `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -opt=0 -o main.wasm .`)
    *   Run: `spin up`
*   **Bonus Task (Standalone WASI CLI model):**
    *   Build: `tinygo build -target=wasi -no-debug -opt=0 -o main.wasm main.go`
    *   Run: `wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm`

### Size & Cold-Start Comparison

*   **Artifact Size:** Both compiled .wasm modules are virtually identical in size, as they compile the same core Go logic and import similar standard libraries.
*   **Cold-Start / Execution Model:**
    *   **Spin (Persistent):** The Wasmtime runtime is booted once when spin up is called. Subsequent HTTP requests hit a warm runtime, mapping the module into memory in just ~15-20ms.
    *   **Wasmtime (Per-invocation):** The CGI-style model requires instantiating the entire Wasmtime runtime, loading the module, executing main(), and tearing it down for every single execution. While fast for a CLI, it is much slower per-request than Spin's persistent listening server.

### Design Questions

**h) Why can't Task 1 run under bare wastime run?**

A bare wasmtime run command looks for a standard WASI CLI `_start` main entrypoint function. The Spin component from Task 1 is built specifically as a wasi-http component, exporting HTTP handler functions rather than a standard CLI execution flow.

**i) Spin uses wasmtime internally:** 

Spin provides an entire server framework on top of Wasmtime: instance pooling, HTTP request routing via a server loop, manifest parsing, and a policy layer for capabilities like outbound network access.

**j) Execution model fit:** 

Per-invocation fits batch processing scripts, data transformers, or traditional CLI tools executed via cron jobs. Spin's persistent server fits HTTP APIs, event-driven webhooks, and microservices expecting persistent network traffic.
