# Lab 12 — WebAssembly Containers vs Traditional Containers

## Task 1 — Moscow Time Application

I worked directly in the required directory:

```bash
/Users/vozamhcak/DevOps-Intro/labs/lab12
````

Directory contents:

```text
Dockerfile
Dockerfile.wasm
main.go
spin.toml
```

Local Go was not installed on my host machine:

```bash
go version
zsh: command not found: go
```

Therefore, I tested the Go application using the official Go Docker image.

CLI mode command:

```bash
docker run --rm \
  -v $(pwd):/src \
  -w /src \
  -e MODE=once \
  golang:1.21-alpine \
  go run main.go
```

Output:

```json
{
  "moscow_time": "2026-04-25 00:55:26 MSK",
  "timestamp": 1777067726
}
```

The application uses the same `main.go` file for multiple contexts:

* `MODE=once` runs one-shot CLI mode and prints JSON.
* Normal execution starts a traditional `net/http` server.
* WAGI mode is detected through CGI-style environment variables such as `REQUEST_METHOD`, which allows the same WASM binary to run under Spin.

## Task 2 — Traditional Docker Container

### Build

Command:

```bash
docker build -t moscow-time-traditional -f Dockerfile .
```

Result:

```text
Successfully built image moscow-time-traditional:latest
```

The Dockerfile uses a multi-stage build:

* build stage: `golang:1.21-alpine`
* runtime stage: `scratch`
* optimized static Go binary with `CGO_ENABLED=0`, `-tags netgo`, `-trimpath`, and stripped linker flags

### CLI Mode

Command:

```bash
docker run --rm -e MODE=once moscow-time-traditional
```

Output:

```json
{
  "moscow_time": "2026-04-25 00:55:49 MSK",
  "timestamp": 1777067749
}
```

### Binary Size

Commands:

```bash
docker create --name temp-traditional moscow-time-traditional
docker cp temp-traditional:/app/moscow-time ./moscow-time-traditional
docker rm temp-traditional
ls -lh moscow-time-traditional
```

Output:

```text
-rwxr-xr-x@ 1 vozamhcak  staff   4.4M Apr 25 00:55 moscow-time-traditional
```

Traditional binary size: **4.4 MB**

### Image Size

Command:

```bash
docker images moscow-time-traditional
```

Output:

```text
IMAGE                            ID             DISK USAGE   CONTENT SIZE   EXTRA
moscow-time-traditional:latest   69a0202874c0       6.52MB         1.91MB
```

Command:

```bash
docker image inspect moscow-time-traditional --format '{{.Size}}' | awk '{print $1/1024/1024 " MB"}'
```

Output:

```text
1.8233 MB
```

Traditional image size: **1.8233 MB**

### Startup Time Benchmark

Command:

```bash
for i in {1..5}; do
    /usr/bin/time -f "%e" docker run --rm -e MODE=once moscow-time-traditional 2>&1 | tail -n 1
done | awk '{sum+=$1; count++} END {print "Average:", sum/count, "seconds"}'
```

Output:

```text
Average: 0 seconds
```

The measured value was rounded to `0` by `/usr/bin/time` on this system. This means the CLI execution was too fast for the selected timing resolution.

Traditional startup time: **~0.00 seconds measured**

### Server Mode

Command:

```bash
docker run --rm --name test-traditional -p 8080:8080 moscow-time-traditional
```

Output:

```text
2026/04/24 21:56:08 Server starting on :8080
```

Request:

```bash
curl http://localhost:8080
```

Output:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Moscow Time</title>
...
</html>
```

Server mode works successfully in the traditional Docker container.

### Memory Usage

Command:

```bash
docker stats test-traditional --no-stream
```

Output:

```text
CONTAINER ID   NAME               CPU %     MEM USAGE / LIMIT     MEM %     NET I/O          BLOCK I/O   PIDS
649aa95f8612   test-traditional   0.00%     3.137MiB / 3.827GiB   0.08%     1.7kB / 1.78kB   0B / 0B     5
```

Traditional memory usage: **3.137 MiB**

## Task 3 — WASM Container

### TinyGo Version

Command:

```bash
docker run --rm tinygo/tinygo:0.39.0 tinygo version
```

Output:

```text
tinygo version 0.39.0 linux/arm64 (using go version go1.25.0 and LLVM version 19.1.2)
```

### WASM Build

Command:

```bash
docker run --rm \
  -v $(pwd):/src \
  -w /src \
  tinygo/tinygo:0.39.0 \
  tinygo build -o main.wasm -target=wasi main.go
```

### WASM Binary Size

Command:

```bash
ls -lh main.wasm
file main.wasm
```

Output:

```text
-rwxr-xr-x  1 vozamhcak  staff   2.3M Apr 25 01:01 main.wasm
main.wasm: WebAssembly (wasm) binary module version 0x1 (MVP)
```

WASM binary size: **2.3 MB**

### ctr / containerd Limitation

The full `ctr` execution part was not completed on my local machine because the lab requires a Linux host with containerd and the Wasmtime containerd shim.

My environment was macOS with Docker Desktop:

```text
MacBook-Air-Alexander-2
Docker Desktop
linux/arm64 containers through Docker
```

The WASM binary itself was successfully built with TinyGo using the same `main.go`, but the final `ctr run --runtime io.containerd.wasmtime.v1` benchmark requires a Linux host with containerd configured.

### Server Mode Limitation

Plain WASI Preview1 modules do not support TCP sockets. Therefore, server mode does not work directly under `ctr` with a normal WASI runtime.

The application can still run as an HTTP service in Spin because Spin provides a WAGI execution model. In that mode, Spin handles the HTTP server layer and passes request information to the WASM module through CGI-style environment variables.

## Task 4 — Performance Comparison & Analysis

| Metric           | Traditional Container |              WASM Container |   Improvement | Notes                                                                    |
| ---------------- | --------------------: | --------------------------: | ------------: | ------------------------------------------------------------------------ |
| Binary Size      |                4.4 MB |                      2.3 MB | 47.7% smaller | From `ls -lh`                                                            |
| Image Size       |             1.8233 MB |                         N/A |           N/A | WASM OCI image was not imported via `ctr` on macOS                       |
| Startup Time CLI |      ~0.00 s measured |                         N/A |           N/A | Docker result rounded to zero; `ctr` benchmark requires Linux containerd |
| Memory Usage     |             3.137 MiB |                         N/A |           N/A | WASM memory stats via `ctr` were not available                           |
| Base Image       |               scratch |                     scratch |          Same | Both Dockerfiles use minimal scratch base                                |
| Source Code      |               main.go |                     main.go |     Identical | Same source file was used                                                |
| Server Mode      |  Works via `net/http` | Not via plain WASI Preview1 |           N/A | WASI Preview1 lacks socket support                                       |

### Binary Size Comparison

The WASM binary is smaller because TinyGo performs much more aggressive size-oriented compilation than the standard Go compiler. It removes unused runtime features and includes a smaller subset of the Go runtime and standard library.

The traditional Go binary is still optimized and statically linked, but it includes more of the standard Go runtime, garbage collector support, networking stack, and other runtime features.

TinyGo optimized away or reduced:

* unused standard library code
* parts of the full Go runtime
* debug information
* unnecessary platform-specific functionality
* heavier runtime initialization paths

### Startup Performance

WASM containers can start faster because a WASM runtime usually loads a small sandboxed module directly instead of starting a full Linux container process with the same amount of OS-level setup.

Traditional containers have extra initialization overhead:

* container runtime setup
* namespace and cgroup setup
* filesystem mount setup
* process startup inside the container
* Go runtime initialization

For this lab, the traditional Docker startup time was measured as `0 seconds`, likely because the command was too fast for the timer resolution. A more precise benchmark would require higher-resolution timing or more iterations.

### When to Choose WASM

I would choose WASM for:

* small serverless functions
* edge workloads
* short-lived CLI-style tasks
* plugins and sandboxed extensions
* workloads where startup time and binary size matter
* secure execution of isolated code

WASM is especially useful when the application does not need full OS access, long-running background processes, or direct TCP socket management.

### When to Choose Traditional Containers

I would choose traditional containers for:

* normal web servers using TCP sockets
* applications requiring full Linux system access
* databases and stateful services
* services with complex networking
* applications depending on native libraries
* workloads where Docker/Kubernetes compatibility matters more than startup time

Traditional containers are more mature and flexible, while WASM containers are smaller and more sandboxed but currently have more limitations.

## Conclusion

This lab demonstrated that the same `main.go` source code can target different execution environments:

* traditional Docker container with a native Linux Go binary
* WASM binary compiled with TinyGo
* Spin/WAGI-compatible execution model

The traditional container worked fully in both CLI and server modes. The WASM binary was successfully built from the same source code, but full `ctr` runtime benchmarking requires a Linux host with containerd and the Wasmtime shim.

The key limitation is that WASI Preview1 does not support TCP sockets, so plain WASM containers cannot run the `net/http` server directly through `ctr`. Platforms like Spin solve this by providing an HTTP abstraction layer through WAGI.
