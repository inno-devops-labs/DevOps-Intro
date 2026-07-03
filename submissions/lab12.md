# Lab 12 Submission — WebAssembly Containers

## Summary

This submission completes Task 1, Task 2, and the Bonus Task.

Implemented files:

- `wasm/moscow-time/main.go`
- `wasm/moscow-time/go.mod`
- `wasm/moscow-time/go.sum`
- `wasm/moscow-time/spin.toml`
- `wasm/moscow-time/main.wasm`
- `wasm-cli/main.go`
- `wasm-cli/main.wasm`
- `submissions/lab12.md`
- `artifacts/lab12/*` evidence files

## Tool versions

    spin: spin 3.4.0 (4f671be 2025-08-26)
    tinygo: tinygo version 0.41.1 linux/amd64 (using go version go1.24.13 and LLVM version 20.1.1)
    wasmtime: wasmtime 44.0.1 (f302ebd6b 2026-04-30)
    hyperfine: hyperfine 1.18.0
    docker: Docker version 29.2.1, build a5c7197
    go: go version go1.24.13 linux/amd64

## Task 1 — Spin SDK WebAssembly endpoint

The Spin app was scaffolded from the current Spin 3.4 template:

    spin new -t http-go moscow-time --accept-defaults

The endpoint serves:

    GET /time

It returns Moscow time as JSON with `unix`, `iso`, `hour_minute`, and `timezone`.

### main.go

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
    
    		if r.URL.Path != "/time" {
    			http.NotFound(w, r)
    			return
    		}
    
    		now := time.Now().UTC()
    		moscow := now.Add(3 * time.Hour)
    
    		iso := moscow.Format("2006-01-02T15:04:05") + "+03:00"
    		hourMinute := moscow.Format("15:04")
    
    		w.Header().Set("Content-Type", "application/json")
    		fmt.Fprintf(
    			w,
    			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":%q}\n",
    			now.Unix(),
    			iso,
    			hourMinute,
    			"UTC+03:00",
    		)
    	})
    }
    
    func main() {}

### spin.toml

    #:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json
    
    spin_manifest_version = 2
    
    [application]
    name = "moscow-time"
    version = "0.1.0"
    authors = ["Tivdzualubem <tivdzualubem@gmail.com>"]
    description = ""
    
    [[trigger.http]]
    route = "/time"
    component = "moscow-time"
    
    [component.moscow-time]
    source = "main.wasm"
    allowed_outbound_hosts = []
    [component.moscow-time.build]
    command = "tinygo build -target=wasip1 -buildmode=c-shared -no-debug -interp-timeout=10m -o main.wasm ."
    watch = ["**/*.go", "go.mod"]

### Build and run evidence

    scaffold_command: spin new -t http-go moscow-time --accept-defaults
    build_command: spin build
    run_command: spin up --listen 127.0.0.1:3000
    route: /time
    wasm_size: -rw-r--r-- 1 teeroyce teeroyce 355K Jul  3 17:57 main.wasm;main.wasm bytes=363281;
    response: {"unix":1783090869,"iso":"2026-07-03T18:01:09+03:00","hour_minute":"18:01","timezone":"UTC+03:00"}
    headers:
    HTTP/1.1 200 OK
    content-type: application/json
    content-length: 99
    date: Fri, 03 Jul 2026 15:01:09 GMT

### Spin build output

    Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
    go: downloading github.com/spinframework/spin-go-sdk/v2 v2.2.1
    go: downloading github.com/julienschmidt/httprouter v1.3.0
    Finished building all Spin components

### WASM size

    -rw-r--r-- 1 teeroyce teeroyce 355K Jul  3 17:57 main.wasm
    main.wasm bytes=363281

### Design answers a-d

a. Browser WASM with `go build -o m.wasm -target=js/wasm` expects a JavaScript host and Go's browser glue code, so it is not a standalone server-side module. Server WASM with TinyGo `-target=wasip1` targets WASI instead. It loses browser APIs and the full Go runtime surface, but gains a small, portable, server-side module with explicit WASI capabilities.

b. `-buildmode=c-shared` is needed because Spin hosts a `wasi-http` component and expects exported handler symbols that the Spin host can call. Without that build mode, TinyGo builds a different module shape, so Spin cannot invoke the handler correctly.

c. `allowed_outbound_hosts = []` grants no outbound network capability. This follows WASM's capability-based security model: the module starts with no ambient access and receives only explicitly listed capabilities. Docker's `--network none` also blocks network access, but Docker containers still run as Linux processes under the shared host kernel and can have broader ambient OS surface unless separately restricted.

d. The TinyGo stdlib gap handled here is time-zone data. Instead of `time.LoadLocation("Europe/Moscow")`, the handler computes Moscow time with `time.Now().UTC().Add(3 * time.Hour)`. The JSON is also formatted explicitly with `fmt.Fprintf` rather than relying on reflection-heavy dynamic maps.

## Task 2 — Perf comparison vs Lab 6 Docker container

### Test rig

    date: 2026-07-03T18:18:33+03:00
    hostname: DESKTOP-U1R4GKD
    kernel: Linux DESKTOP-U1R4GKD 6.18.33.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun 18 21:54:43 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
    os:
    Distributor ID:	Ubuntu
    Description:	Ubuntu 24.04.1 LTS
    Release:	24.04
    Codename:	noble
    cpu:
    Architecture:                            x86_64
    CPU(s):                                  4
    On-line CPU(s) list:                     0-3
    Model name:                              Intel(R) Core(TM) i5-4300M CPU @ 2.60GHz
    Thread(s) per core:                      2
    Core(s) per socket:                      2
    Socket(s):                               1
    NUMA node0 CPU(s):                       0-3
    memory:
                   total        used        free      shared  buff/cache   available
    Mem:           5.8Gi       1.7Gi       1.8Gi       3.7Mi       2.4Gi       4.1Gi
    Swap:          2.0Gi       695Mi       1.3Gi
    tools:
    spin: spin 3.4.0 (4f671be 2025-08-26)
    tinygo: tinygo version 0.41.1 linux/amd64 (using go version go1.24.13 and LLVM version 20.1.1)
    wasmtime: wasmtime 44.0.1 (f302ebd6b 2026-04-30)
    hyperfine: hyperfine 1.18.0
    docker: Docker version 29.2.1, build a5c7197
    go: go version go1.24.13 linux/amd64

### Lab 6 Docker baseline

    id=sha256:cdb60389fc889120915e7fc5c6caa27b8dcbd1c93b35ee1f65e708b74e8193e5 size=13538083 created=2026-07-03T12:12:38.54570022Z

Lab 6 health response:

    {"notes":4,"status":"ok"}

### Warm latency summary

    spin-time
      runs: 50
      p50_ms: 10.233
      p95_ms: 16.530
      mean_ms: 11.258
    lab6-docker-health
      runs: 50
      p50_ms: 9.108
      p95_ms: 12.851
      mean_ms: 9.777

### Cold-start summary

    spin
      samples_ms: 226.485, 333.234, 345.051, 717.656, 1829.145
      p50_ms: 345.051
      p95_ms: 1829.145
      mean_ms: 690.314
    docker
      samples_ms: 1325.120, 1553.595, 2700.065, 2749.837, 9077.770
      p50_ms: 2700.065
      p95_ms: 9077.770
      mean_ms: 3481.277

### Perf table

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|---|---:|---:|
| Artifact size | 13,538,083 bytes | 363,281 bytes |
| Cold start p50 | 2700.065 ms | 345.051 ms |
| Warm latency p50 | 9.108 ms | 10.233 ms |
| Warm latency p95 | 12.851 ms | 16.530 ms |

Bonus standalone WASI CLI:

| Dimension | Standalone wasmtime CLI |
|---|---:|
| Artifact size | 196,686 bytes |
| Per-invocation p50 | 12.855 ms |
| Per-invocation p95 | 22.028 ms |

### Design answers e-g

e. Docker cold start is dominated by container startup work: Docker daemon coordination, creating namespaces/cgroups, starting the container process, and waiting for the service to accept requests. Spin cold start is dominated by starting the Spin host and loading/instantiating the WASM component. In these measurements, Spin's p50 cold start was lower than Docker's.

f. WASM is clearly better for small, stateless, high-fan-out request handlers, edge functions, plugins, and multi-tenant workloads where size, portability, and sandboxing matter. Docker is still right for long-running services, stateful systems, applications that need mature OS tooling, arbitrary native dependencies, full database client ecosystems, or broader Linux syscall behavior.

g. WASM's deny-by-default capability sandbox makes cross-tenant escape and host filesystem/network access harder. For example, a compromised WASM handler cannot simply open `/etc/passwd`, scan the local network, or reach arbitrary outbound hosts unless the host explicitly granted those capabilities.

## Bonus Task — Standalone WASI CLI with wasmtime

The same Moscow-time logic was rebuilt without the Spin SDK as a standalone WASI CLI module.

### wasm-cli/main.go

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
    		fmt.Fprintf(os.Stderr, "method not allowed: %s\n", method)
    		os.Exit(1)
    	}
    
    	if path != "/time" {
    		fmt.Fprintf(os.Stderr, "not found: %s\n", path)
    		os.Exit(1)
    	}
    
    	now := time.Now().UTC()
    	moscow := now.Add(3 * time.Hour)
    
    	iso := moscow.Format("2006-01-02T15:04:05") + "+03:00"
    	hourMinute := moscow.Format("15:04")
    
    	fmt.Printf(
    		"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":%q}\n",
    		now.Unix(),
    		iso,
    		hourMinute,
    		"UTC+03:00",
    	)
    }

### Build, run, and size evidence

    build_command: tinygo build -o main.wasm -target=wasi -no-debug ./main.go
    run_command: wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
    size: -rw-r--r-- 1 teeroyce teeroyce 193K Jul  3 18:11 main.wasm;main.wasm bytes=196686;
    response: {"unix":1783091492,"iso":"2026-07-03T18:11:32+03:00","hour_minute":"18:11","timezone":"UTC+03:00"}

### wasmtime per-invocation benchmark

    wasmtime-cli-time
      runs: 50
      p50_ms: 12.855
      p95_ms: 22.028
      mean_ms: 14.339

### Design answers h-j

h. The Task 1 Spin component cannot run under bare `wasmtime run` because it is a `wasi-http` component, not a CLI module with a normal `_start` entrypoint. It exports handler functionality for a wasi-http host such as Spin.

i. Spin uses wasmtime internally, but adds the HTTP server loop, manifest and route handling, component lifecycle management, capability policy such as `allowed_outbound_hosts`, and the host-side glue that maps HTTP requests into the WASI HTTP component model.

j. Per-invocation `wasmtime run` fits CLI-style jobs, batch transforms, or CGI-like request execution where each invocation starts, handles one unit of work, and exits. Spin's persistent wasi-http server model fits HTTP services and edge handlers where routing, repeated requests, and lower server-loop overhead matter.
