# Lab 12 — Comparative Analysis of WebAssembly and Traditional Docker Containers


## Task 1 — Moscow Time Application Development (2 pts)

### CLI Mode Output (MODE=once)

https://imgur.com/a/hyQFfCT

### Browser Output (Server Mode)

https://imgur.com/a/mV5nWd1


### Environment Confirmation

*Current path:*
```/mnt/c/Users/mngtr/DevOps-Intro/labs/lab12*```


### How the unified main.go operates across different contexts

The application uses internal conditional logic to adapt to three distinct execution scenarios from a single codebase:

CLI Mode: If the environment variable MODE=once is detected, the app prints the current time in JSON format and terminates immediately.

WAGI/Spin Mode: The isWagi() function looks for the REQUEST_METHOD variable. If present, it triggers runWagiOnce(), which pipes HTTP headers and data directly to STDOUT (standard output).

Native Server Mode: If neither of the above is detected, the application initializes a standard web server using the net/http package.



## Task 2 — Traditional Docker Container Deployment (3 pts)


### Binary File Size (ls -lh moscow-time-traditional)

https://imgur.com/a/PrGDNfi


### Docker Image Size (docker images & inspect)

https://imgur.com/a/tlS3kIz


### Execution Benchmarking (Average of 5 CLI runs)

https://imgur.com/a/vBSO6l4



### Resource Consumption (docker stats)

https://imgur.com/a/7CXuGkh

## Task 3 — WASM Container Deployment via ctr (3 pts)


### TinyGo Compiler Version

tinygo version 0.39.0 linux/amd64 (using go version go1.25.0 and LLVM version 19.1.2)



### WASM Binary Size (ls -lh main.wasm)

-rwxrwxrwx 1 mngtr mngtr 2.4M Apr 20 23:03 main.wasm



### WASI Image Footprint (ctr images ls)

https://imgur.com/a/FZCHCUM


### Startup Latency via ctr (CLI mode)

https://imgur.com/a/Ur1chuo


### Limitations of Server Mode in ctr (WASI Preview1)

Running a server directly through ctr fails due to the lack of network socket support in the WASI Preview1 specification. When TinyGo's net/http library attempts to open a TCP listener, it encounters a "Netdev not set" error. WASI Preview1 was originally designed for secure system-level tasks and file I/O, excluding network primitives. To host a server, an external orchestrator like Spin is required to manage network traffic and interact with the WASM module via environment variables (CGI-style).



### Server Functionality via Spin

The same main.wasm file functions perfectly as a server when managed by Spin. Spin implements the WAGI (WebAssembly Gateway Interface) mechanism: it acts as the primary HTTP host and translates requests into environment variables. The module then writes its response to STDOUT. This abstraction allows the WASM runtime to operate without direct socket access, maintaining high portability.



### Memory Reporting (N/A Explanation)

Memory metrics for WASM containers are listed as N/A because the ctr utility does not currently support resource tracking for non-Linux runtimes. WASM modules run within a specialized sandbox (like Wasmtime) that manages its own heap memory independently of the Linux cgroups used by traditional Docker containers. Since the Wasmtime shim does not export this data to containerd in a standard format, a direct comparison using docker stats is not feasible.



### Code Consistency

Both the traditional Docker container and the WASM module were compiled from the exact same main.go file without any modifications. The only difference lies in the compilation toolchain: the standard Go compiler for the Docker image and TinyGo with the -target=wasi flag for the WASM module. This demonstrates a seamless "write once, run anywhere" workflow.



### Runtime Verification

The WASM image was built as an OCI archive (wasi/wasm platform) using Docker Buildx and then imported into the containerd store via ctr images import. It was executed using the sudo ctr run --rm --runtime io.containerd.wasmtime.v1 command, which bypasses the standard Docker Engine to use the Wasmtime runtime directly.



## Task 4 — Comparative Analysis & Conclusions (2 pts)


| Metric | Traditional Container | WASM Container | Improvement | Notes |
|--------|----------------------|----------------|-------------|-------|
| Binary Size | 4.5 MB | 2.4 MB | ~47% reduction | via `ls -lh` |
| Image Size | 1.98 MB | 0.80 MB | ~60% reduction | `inspect` vs `ctr` |
| Startup Time (CLI) | 436 ms | 302 ms | 1.44x faster | 5-run average |
| Memory | 1.19 MB | N/A | - | via `docker stats` |
| Base Image | `scratch` | `scratch` | Identical | Minimalist approach |
| Source Code | `main.go` | `main.go` | Identical | No code changes |
| Server Mode | Supported (Native) | Supported (via Spin) | - | WASI requires a host |



### Analysis Summary


*1. Binary Size Comparison*

Why is the WASM binary significantly smaller than the standard Go binary?
The standard Go compiler bundles a robust runtime, a full garbage collector, and extensive standard libraries into the executable. TinyGo, however, is specifically optimized for WebAssembly and resource-constrained environments. It uses LLVM to perform aggressive dead code elimination, utilizes a lightweight GC, and excludes heavy reflection and networking modules.



*2. Startup Performance*

What makes WASM start faster?
WASM operates within a lightweight sandbox (Wasmtime) that simply maps bytecode into memory and begins execution.

What are the overheads of traditional containers?
Traditional Docker containers require the Linux kernel to initialize namespaces (network, PID, mount), set up cgroup limits, and mount multiple filesystem layers. WASM bypasses these kernel-level initialization steps.



*3. Strategic Use Cases*

When to choose WebAssembly?
WASM is the superior choice for Serverless, FaaS, and Edge computing, where instant cold starts and high density (running thousands of instances on one host) are critical.

When to stick with Traditional Containers?
Traditional containers remain necessary for complex microservices that require full networking capabilities (TCP/UDP listeners), heavy multithreading, or deep integration with established Kubernetes ecosystems and kernel-level features.