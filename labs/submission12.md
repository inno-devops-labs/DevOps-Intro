# Lab 12 — WebAssembly Containers vs Traditional Containers


## Task 1 — Create the Moscow Time Application (2 pts)

### Screenshot of CLI mode output (MODE=once)

![CLI](<CLI.png>)

### Screenshot of server mode running in browser

![Browser](<Browser.png>)


### Confirmation that you're working directly in labs/lab12/ directory

*Working directory:*
```/mnt/c/Users/mngtr/DevOps-Intro/labs/lab12*```


### Explanation of how the single main.go works in three different contexts

```
One main.go file works in 3 contexts thanks to checks inside the code:

If the MODE=once environment variable is set, a one-time JSON output is performed and the program exits.

The isWagi() function checks for the presence of the REQUEST_METHOD variable (which is set by Spin). If it exists, runWagiOnce() is called (outputting HTTP headers and body to STDOUT).

If neither condition is met, the standard net/http web server is started.
```


## Task 2 — Build Traditional Docker Container (3 pts)


### Binary size from ls -lh moscow-time-traditional

![bin_size](<bin_size.png>)


### Image size from both docker images and docker image inspect


![image_size](<image_size.png>)


### Average startup time across 5 CLI mode runs


![start_time](<start_time.png>)



### Memory usage from docker stats


![mem_usage](<mem_usage.png>)


### Screenshot of application running in browser (server mode)

![Browser](<Browser.png>)



## Task 3 — Build WASM Container (ctr-based) (3 pts)


### TinyGo version used


```
tinygo version 0.39.0 linux/amd64 (using go version go1.25.0 and LLVM version 19.1.2)
```


### WASM binary size (from ls -lh main.wasm)


```
-rwxrwxrwx 1 mngtr mngtr 2.4M Apr 20 23:03 main.wasm
```


### WASI image size (from ctr images ls)


![wasi_size](<wasi_size.png>)


### Average startup time from the ctr run benchmark loop (CLI mode)


![av_time](<av_time.png>)


### Explanation of why server mode doesn't work under ctr (WASI Preview1 lacks socket support)


```
Server mode does not work under ctr because WASI Preview1 does not include any socket or networking APIs. The TinyGo net/http library expects to open a TCP socket to listen for incoming connections, but when it tries to do so inside the WASM runtime, it receives a "Netdev not set" error and cannot bind to a port. WASI Preview1 was designed for command-line tools and file system access, not for long-running network services. This is why server mode requires something like Spin, which provides the HTTP server externally and communicates with the WASM module via CGI-style environment variables instead.
```



### Note that server mode can be demonstrated via Spin using the same main.wasm

```
Server mode can still be demonstrated using the exact same main.wasm file by running it with Spin instead of ctr. Spin uses the WAGI executor, which acts as an external HTTP server and forwards each request to the WASM module by setting CGI-style environment variables like REQUEST_METHOD and PATH_INFO. The module then writes HTTP headers and the response body directly to standard output. This approach completely bypasses the need for socket support inside the WASM runtime, allowing the same binary to function as a fully capable web server without any code changes.
```


### Memory usage reporting (likely "N/A" with explanation)


```
Memory usage reporting for WASM containers is marked as N/A because traditional container metrics are not available through ctr. WASM modules run inside a sandboxed WebAssembly runtime like Wasmtime, which manages its own memory heap and execution environment separately from the host operating system. Standard Linux container monitoring tools rely on cgroups to track and limit resource usage, but WASM containers do not use cgroups in the same way. The Wasmtime shim handles memory allocation internally, and ctr does not expose detailed runtime memory statistics for WASM workloads. As a result, a direct comparison of memory consumption using the same tooling is not possible in this lab setup.
```


### Note: used same source code as traditional build


```
It is worth emphasizing that the exact same main.go source file was used for both the traditional Docker container and the WASM container builds. No code modifications or conditional compilation flags were introduced to accommodate the different targets. The application logic, including the CLI mode and the WAGI detection functions, remained completely unchanged. The only difference between the two builds was the compiler used: standard Go for the traditional binary and TinyGo with the -target=wasi flag for the WASM module. This demonstrates a true "write once, compile anywhere" approach where a single codebase can target fundamentally different execution environments without any platform-specific adjustments.
```


### Confirmation that you used ctr (containerd CLI) for WASM execution


```
The WASM image was built as an OCI archive using Docker Buildx with the --platform=wasi/wasm flag and then imported directly into containerd's image store using ctr images import. Each run of the WASM module was executed with sudo ctr run --rm --runtime io.containerd.wasmtime.v1 --platform wasi/wasm, which explicitly invokes the Wasmtime shim to handle WebAssembly execution. No other container runtime, such as Docker Engine or nerdctl, was used for the WASM benchmarks.
```


## Task 4 — Performance Comparison & Analysis (2 pts)


| Metric | Traditional Container | WASM Container | Improvement | Notes |
|--------|----------------------|----------------|-------------|-------|
| Binary Size | 4.5 MB | 2.4 MB | ~47% smaller | From `ls -lh` |
| Image Size | 1.98 MB | 0.80 MB | ~60% smaller | From `docker inspect` / `ctr` |
| Startup Time (CLI) | 436 ms | 302 ms | 1.44x faster | Average of 5 runs |
| Memory Usage | 1.19 MB | N/A | N/A | From `docker stats` |
| Base Image | `scratch` | `scratch` | Same | Both minimal |
| Source Code | `main.go` | `main.go` | Identical |  Same file! |
| Server Mode | Works (`net/http`) | Not via `ctr`<br> Via Spin | N/A | WASI Preview1 lacks sockets;<br>Spin provides HTTP abstraction |



### Analysis questions


*1. Binary Size Comparison*


```
Why is the WASM binary so much smaller than the traditional Go binary?

The traditional Go compiler includes a large runtime, garbage collector, and full standard library packages. The WASM binary is built with TinyGo, which is designed for microcontrollers and WebAssembly

where size is critical.

What did TinyGo optimize away?

TinyGo aggressively removes unused code via LLVM's dead code elimination. It uses a much lighter garbage collector, strips out heavy reflection support, and excludes bulky networking libraries, leaving

 only the minimum required for WASI.
```



*2. Startup Performance*


```
Why does WASM start faster?

WASM runs in a lightweight sandbox (Wasmtime) that simply loads bytecode into memory and begins execution.

What initialization overhead exists in traditional containers?

Traditional Docker containers require significant kernel work at startup: creating isolated namespaces for networking, processes, and mounts, configuring cgroup resource limits, and initializing layered

filesystems and virtual network interfaces. WASM has none of this overhead.
```



*3. Use Case Decision Matrix*

```
When would you choose WASM over traditional containers?

WASM is ideal for serverless and edge computing where near-instant cold starts and high instance density are critical. It also suits IoT devices with limited memory or building secure plugin systems.

When would you stick with traditional containers?

Traditional containers are necessary for microservices requiring a full networking stack (listening on TCP/UDP ports, still limited in WASI Preview 1), complex multithreading, access to host kernel

features, or when using enterprise solutions deeply integrated with standard Kubernetes tooling.
```


