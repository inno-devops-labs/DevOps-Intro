# Lab 12 — WebAssembly Containers vs Traditional Containers

## Task 1 — Create the Moscow Time Application

### 1.1 Navigate to Lab Directory

**Command:**
```sh
cd labs/lab12
```
Confirmed that all work is performed in the labs/lab12/ directory.

### 1.2 Review the Go Application

The provided `main.go` was reviewed directly in `labs/lab12/`.

This single file supports three execution contexts:

- **CLI mode (`MODE=once`)** — prints JSON once and exits  
- **Traditional server mode (`net/http`)** — works in Docker  
- **WAGI mode (Spin)** — works through CGI-style environment variables  

Key implementation details:

- `time.FixedZone("MSK", 3*60*60)` is used instead of `time.LoadLocation`
- `isWagi()` detects execution inside Spin/WAGI
- `runWagiOnce()` outputs HTTP response via STDOUT
- `net/http` is used for traditional server mode

### CLI mode test

```sh
MODE=once go run main.go
```
Result:
The program outputs a JSON object with Moscow time and exits successfully.

![12_img_1.png](screenshots%2F12_img_1.png)

### Server mode test (optional)

```sh
go run main.go
```

Open in browser:  
http://localhost:8080

Result:

Server started on port 8080
Web interface successfully opened at http://localhost:8080
JSON API available at http://localhost:8080/api/time

![12_img_2.png](screenshots%2F12_img_2.png)

### Explanation

The same `main.go` works in three contexts because it detects the runtime environment and switches behavior:

- In CLI mode → prints one JSON response and exits  
- In normal mode → starts a Go HTTP server  
- In WAGI mode → handles CGI-style request variables and prints HTTP response to STDOUT

## Task 2 — Build Traditional Docker Container

### 2.1 Review Dockerfile

The provided `Dockerfile` in `labs/lab12/` was reviewed.

It uses:

- a Go build stage
- static build flags
- `FROM scratch` as the final minimal image

### 2.2 Build and Run Traditional Container

#### Build command

```sh
docker build -t moscow-time-traditional -f Dockerfile .
```

#### CLI mode test

```sh
docker run --rm -e MODE=once moscow-time-traditional
```

#### Server mode test

```sh
docker run --rm --name test-traditional -p 8080:8080 moscow-time-traditional
```

Open in browser:  
http://localhost:8080

![12_img_6.png](screenshots%2F12_img_6.png)

### 2.3 Measure Performance

#### Binary size

```sh
docker create --name temp-traditional moscow-time-traditional
docker cp temp-traditional:/app/moscow-time ./moscow-time-traditional
docker rm temp-traditional
Get-Item .\moscow-time-traditional | Select-Object Name,Length
```

![12_img_3.png](screenshots%2F12_img_3.png)

#### Image size

```sh
docker images moscow-time-traditional
docker image inspect moscow-time-traditional --format '{{.Size}}'
```

- docker images: 6.79MB  
- docker inspect: 2073223 bytes  

#### Startup time benchmark

Average over 5 runs:  
0.5569 seconds

![12_img_5.png](screenshots%2F12_img_5.png)

### Memory Usage

```sh
docker stats test-traditional --no-stream
```

Measured memory usage: 4.625 MiB

![12_img_4.png](screenshots%2F12_img_4.png)


### Results

- **Binary size:** 4698112 bytes
- **Image size (docker images):** 6.79 MB
- **Image size (inspect):** 2073223 bytes
- **Average startup time:** 0.5569 seconds
- **Memory usage:** 4.625 MiB

## Task 3 — Build WASM Container (ctr-based)

### 3.1 TinyGo Version

```sh
docker run --rm tinygo/tinygo:0.39.0 tinygo version
```
![12_img_7.png](screenshots%2F12_img_7.png)

Result: TinyGo was available and used to compile the same `main.go` source file into a WASM binary.

### 3.2 Build WASM Binary

```sh
docker run --rm \
  -v $(pwd):/src \
  -w /src \
  tinygo/tinygo:0.39.0 \
  tinygo build -o main.wasm -target=wasi main.go
```

### Check binary

```sh
ls -lh main.wasm
file main.wasm
```

Result:
The same `main.go` used for the traditional container was successfully compiled into `main.wasm`

### 3.3 Review Dockerfile.wasm
The provided `Dockerfile.wasm` in `labs/lab12/` was reviewed.

- Base image: FROM scratch
- Packages only the main.wasm binary
- Uses a minimal OCI image layout

### 3.4 Prepare containerd / ctr / wasmtime

```sh
ctr --version
sudo systemctl status containerd --no-pager
```
![12_img_8.png](screenshots%2F12_img_8.png)
```sh
ls -la /usr/local/bin/containerd-shim-wasmtime-v1
sudo ctr version
```

```sh
sudo containerd config dump | grep -A 8 wasmtime
```
![12_img_9.png](screenshots%2F12_img_9.png)

Result:
`containerd` was running, `ctr` was available, the `containerd-shim-wasmtime-v1` binary was installed, and the `wasmtime` runtime was successfully registered in containerd configuration.

### 3.5 Build OCI Archive and Run WASM Container
The OCI archive was created with Docker Buildx on Windows, then imported and executed on the Linux host with `ctr`.
```sh
docker buildx build \
  --platform=wasi/wasm \
  -t moscow-time-wasm:latest \
  -f Dockerfile.wasm \
  --output=type=oci,dest=moscow-time-wasm.oci,annotation=index:org.opencontainers.image.ref.name=moscow-time-wasm:latest \
```

```sh
cd /media/lab12
ls -lh moscow-time-wasm.oci
```
![12_img_10.png](screenshots%2F12_img_10.png)
```sh
sudo ctr images import \
  --platform=wasi/wasm \
  --index-name docker.io/library/moscow-time-wasm:latest \
  moscow-time-wasm.oci
```
![12_img_11.png](screenshots%2F12_img_11.png)
```sh
sudo ctr images ls | grep -E 'moscow-time-wasm|wasi|wasm'
```

```sh
sudo ctr run --rm \
  --runtime io.containerd.wasmtime.v1 \
  --platform wasi/wasm \
  --env MODE=once \
  docker.io/library/moscow-time-wasm:latest wasi-once
```
![12_img_12.png](screenshots%2F12_img_12.png)

Result:
The WASM image was imported successfully and executed with `ctr`.
The container returned Moscow time in JSON format, confirming correct execution.

### 3.6 Measure WASM Performance
Binary size:
```sh
ls -lh main.wasm
```
Image size:
```sh
sudo ctr images ls | awk 'NR>1 && $1 ~ /moscow-time-wasm/ {print "IMAGE:", $1, "SIZE:", $4}'
```
Startup time benchmark:
```sh
for i in {1..5}; do
    NAME="wasi-$(date +%s%N | tail -c 6)-$i"
    /usr/bin/time -f "%e" sudo ctr run --rm \
      --runtime io.containerd.wasmtime.v1 \
      --platform wasi/wasm \
      --env MODE=once \
      docker.io/library/moscow-time-wasm:latest "$NAME" 2>&1 | tail -n 1
done | awk '{sum+=$1; n++} END{printf("Average: %.4f seconds\n", sum/n)}'
```
![12_img_13.png](screenshots%2F12_img_13.png)

### Results

- **TinyGo version:** `tinygo version 0.39.0 linux/amd64 (using go version go1.25.0 and LLVM version 19.1.2)`  
- **WASM binary size:** `2.4M`  
- **WASM image size:** `819.9 KiB`  
- **Average startup time:** `1.1480 seconds`
- **Memory usage:** N/A - not available via ctr  

Note: The measured startup time includes the overhead of `sudo ctr run` in the lab environment.

### Server Mode Limitation

Server mode does not work under plain WASI Preview1 via `ctr` because TCP sockets are not supported.

The same `main.wasm` can still be used with Spin/WAGI, where HTTP is provided by the platform rather than by direct socket access.


## Task 4 — Performance Comparison & Analysis

### 4.1 Comparison Table

| Metric | Traditional | WASM | Improvement | Notes |
|------|------------|------|------------|------|
| Binary Size | 4698112 bytes | 2.4M | ~49% smaller | WASM built with TinyGo |
| Image Size | 6.79 MB | 819.9 KiB | ~88% smaller | WASM OCI image is much smaller |
| Startup Time (CLI) | 0.5569 s | 1.1480 s | Traditional is ~2.06× faster | In this lab environment, `sudo ctr run` and runtime overhead increased WASM startup time |
| Memory Usage | 4.625 MiB | N/A | N/A | Memory stats were not available for WASM via `ctr` |
| Base Image | `scratch` | `scratch` | Same | Both images are minimal |
| Source Code | `main.go` | `main.go` | Identical | Same source file used for both builds |
| Server Mode | Works | Not via `ctr` | N/A | WASI Preview1 does not support TCP sockets |

### 4.2 Analysis

**Binary Size:**  
The WASM binary is smaller because TinyGo uses a much more lightweight runtime and removes a large part of the standard Go runtime overhead. In contrast, the traditional Go binary includes more runtime support and static linking for native Linux execution.

**Image Size:**  
The WASM image is significantly smaller because it only packages the `main.wasm` module in a minimal OCI layout. The traditional image is also minimal, but it still contains a larger native binary.

**Startup Time:**  
In this lab environment, the WASM container was slower to start than the traditional container. The measured WASM startup time included the overhead of `sudo ctr run`, containerd execution, and the wasmtime shim. So although WASM is often expected to start faster, the actual benchmark in this setup showed the opposite result.

**Memory Usage:**  
Traditional container memory usage was measurable with `docker stats`, while WASM memory usage via `ctr` was not available in the same way. This is due to a different execution and accounting model for WASM runtimes.

**Use Cases:**  
- **WASM containers** are a good choice for lightweight CLI workloads, sandboxed execution, and serverless/edge-style platforms where minimal image size matters.
- **Traditional containers** are a better choice for full backend services, standard HTTP servers, and workloads that need full Linux networking and tooling support.

### Conclusion

The experiment confirmed that the same `main.go` source code can be compiled into both a traditional container and a WASM container.  
The WASM build produced a much smaller binary and image, but in this specific lab setup the traditional container started faster.  
This shows that WASM provides strong portability and compactness benefits, while traditional containers still offer better compatibility and, in this case, better startup performance.
