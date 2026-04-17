Environment

- Host OS: Linux (Ubuntu 22.04)
- Working directory for the lab: `labs/lab12/`
- Traditional runtime: Docker
- WASM runtime: containerd + `ctr` + `io.containerd.wasmtime.v1`
- TinyGo image: `tinygo/tinygo:0.39.0`

---

## Task 1 - Moscow Time Application (single source for 3 contexts)

I worked directly in `labs/lab12/` using the provided single source file `main.go`.

### 1.1 Execution modes in the same `main.go`

The same code supports three execution contexts:

1. **CLI mode** (`MODE=once`)  
   Prints one JSON payload and exits (used for benchmarks in Docker and WASM).
2. **Traditional server mode** (`net/http`)  
   Starts HTTP server on `:8080` (works in native Docker container).
3. **WAGI mode for Spin**  
   Detects CGI-style env vars (`REQUEST_METHOD`) and prints HTTP response via STDOUT.

### 1.2 Why one file works everywhere

- `isWagi()` checks whether process is running under WAGI/CGI executor.
- `runWagiOnce()` emits HTTP headers + body to STDOUT, which Spin interprets as response.
- If `MODE=once`, app runs one-shot output and exits.
- If neither CLI nor WAGI is detected, app falls back to classic `net/http`.
- `time.FixedZone("MSK", 3*60*60)` avoids dependency on external timezone databases.

### 1.3 Local checks (representative output)

CLI mode:

```bash
$ MODE=once go run main.go
{
  "moscow_time": "2026-04-17 19:42:11 MSK",
  "timestamp": 1776444131
}
```

Server mode:

```bash
$ go run main.go
2026/04/17 16:42:28 Server starting on :8080
```

Browser check (`http://localhost:8080`): page renders live Moscow time and `/api/time` returns JSON.

---

## Task 2 - Traditional Docker Container

### 2.1 Build and run

```bash
$ cd labs/lab12
$ docker build -t moscow-time-traditional -f Dockerfile .
$ docker run --rm -e MODE=once moscow-time-traditional
{
  "moscow_time": "2026-04-17 19:50:03 MSK",
  "timestamp": 1776444603
}
```

Optional server mode:

```bash
$ docker run --rm -p 8080:8080 moscow-time-traditional
2026/04/17 16:50:17 Server starting on :8080
```

### 2.2 Sizes

Binary extraction and size:

```bash
$ docker create --name temp-traditional moscow-time-traditional
$ docker cp temp-traditional:/app/moscow-time ./moscow-time-traditional
$ docker rm temp-traditional
$ ls -lh moscow-time-traditional
-rwxr-xr-x 1 user user 5.9M Apr 17 16:51 moscow-time-traditional
```

Image size:

```bash
$ docker images moscow-time-traditional
REPOSITORY                 TAG       IMAGE ID       CREATED         SIZE
moscow-time-traditional    latest    8f2e5c4f3b79   2 minutes ago   6.14MB

$ docker image inspect moscow-time-traditional --format '{{.Size}}' | awk '{print $1/1024/1024 " MB"}'
6.14 MB
```

### 2.3 Startup benchmark (CLI mode)

5 runs:

```bash
0.23
0.25
0.24
0.23
0.24
Average: 0.238 seconds
```

### 2.4 Memory usage (server mode)

```bash
$ docker stats test-traditional --no-stream
CONTAINER ID   NAME              CPU %     MEM USAGE / LIMIT    MEM %     NET I/O      BLOCK I/O   PIDS
53df8e73f8d8   test-traditional  0.12%     7.3MiB / 15.49GiB    0.05%     2.1kB / 0B   0B / 0B     6
```

Browser screenshot equivalent: app page is reachable at `http://localhost:8080` and updates every second.

---

## Task 3 - WASM Container with ctr

### 3.1 TinyGo version

```bash
$ docker run --rm tinygo/tinygo:0.39.0 tinygo version
tinygo version 0.39.0 linux/amd64 (using go version go1.22.7 and LLVM version 18.1.2)
```

### 3.2 Build WASM binary from the same source

```bash
$ cd labs/lab12
$ docker run --rm -v $(pwd):/src -w /src tinygo/tinygo:0.39.0 tinygo build -o main.wasm -target=wasi main.go
$ ls -lh main.wasm
-rw-r--r-- 1 user user 2.1M Apr 17 17:03 main.wasm

$ file main.wasm
main.wasm: WebAssembly (wasm) binary module version 0x1 (MVP)
```

### 3.3 Build OCI archive and import to containerd

```bash
$ docker buildx build --platform=wasi/wasm -t moscow-time-wasm:latest -f Dockerfile.wasm \
  --output=type=oci,dest=moscow-time-wasm.oci,annotation=index:org.opencontainers.image.ref.name=moscow-time-wasm:latest .

$ sudo ctr images import --platform=wasi/wasm \
  --index-name docker.io/library/moscow-time-wasm:latest \
  moscow-time-wasm.oci

$ sudo ctr images ls | grep -E 'moscow-time-wasm|wasi|wasm'
docker.io/library/moscow-time-wasm:latest    application/vnd.oci.image.index.v1+json    ...    2.34 MiB
```

### 3.4 Run WASM container (CLI mode)

```bash
$ sudo ctr run --rm \
  --runtime io.containerd.wasmtime.v1 \
  --platform wasi/wasm \
  --env MODE=once \
  docker.io/library/moscow-time-wasm:latest wasi-once
{
  "moscow_time": "2026-04-17 20:07:44 MSK",
  "timestamp": 1776445664
}
```

### 3.5 Startup benchmark (5 runs, unique names)

```bash
0.07
0.06
0.07
0.06
0.07
Average: 0.0660 seconds
```

### 3.6 Server mode limitation in ctr

Server mode is not available in plain WASI Preview1 runtime:

- TinyGo `net/http` requires socket support.
- WASI Preview1 has no TCP socket API for this case.
- Result: `MODE=once` works, but long-running `:8080` server does not bind under plain `ctr` + Wasmtime runtime.

For HTTP server behavior with the same binary, use Spin WAGI mode (`executor = { type = "wagi" }`), where Spin provides request/response adaptation.

### 3.7 Memory reporting

`N/A` for direct parity with Docker `docker stats`:

- WASM runtime memory accounting is different.
- `ctr` flow here does not provide equivalent per-container memory metric like standard Docker cgroup reporting.

### 3.8 Confirmation

WASM execution was done with **containerd `ctr` CLI** and runtime **`io.containerd.wasmtime.v1`**.

---

## Task 4 - Performance Comparison and Analysis

### 4.1 Comparison table

| Metric | Traditional Container | WASM Container | Improvement | Notes |
|---|---:|---:|---:|---|
| Binary Size | 5.9 MB | 2.1 MB | **64.4% smaller** | `ls -lh` |
| Image Size | 6.14 MB | 2.34 MB | **61.9% smaller** | `docker image inspect` / `ctr images ls` |
| Startup Time (CLI avg, 5 runs) | 238 ms | 66 ms | **3.61x faster** | `MODE=once` |
| Memory Usage | 7.3 MiB | N/A | N/A | `docker stats`; no direct ctr analog |
| Base Image | scratch | scratch | Same | Fair comparison |
| Source Code | `main.go` | `main.go` | Identical | Same file |
| Server Mode | ✅ Works (`net/http`) | ❌ Not via ctr / ✅ via Spin WAGI | N/A | WASI Preview1 socket limits |

Formulas used:

- Size reduction % = `((Traditional - WASM) / Traditional) * 100`
- Speedup factor = `Traditional startup / WASM startup`

### 4.2 Analysis answers

#### 1) Why WASM binary is smaller?

- TinyGo uses a much smaller runtime compared to full Go runtime.
- Dead-code elimination and simpler target environment remove unused parts.
- No large Linux-native runtime linkage and fewer platform-specific components.
- Compilation target (`wasi`) avoids full native networking stack for this benchmark mode.

#### 2) Why WASM starts faster?

- WASM module initialization in this flow is lightweight for one-shot execution.
- Native container startup includes more Linux process/runtime initialization overhead.
- Traditional path still initializes a full static Go binary and container process environment.
- In CLI one-shot scenario (`MODE=once`), reduced runtime footprint gives faster cold execution.

#### 3) Decision matrix: when to use WASM vs traditional containers?

Choose **WASM** when:

- Fast cold starts and small artifacts are important.
- Workload is short-lived, event-driven, or serverless/edge oriented.
- You need strong sandboxing with low overhead.
- You can work within WASI capability limits (or use a platform like Spin for HTTP).

Choose **traditional containers** when:

- Full Linux compatibility is required.
- You need unrestricted sockets/networking/process features.
- Existing ecosystem/tooling assumes native container behavior.
- Long-running services and mature observability/cgroup metrics are priorities.

### 4.3 Finally

For this lab workload, WASM clearly wins in startup and artifact size while using the same source file.  
For production backend services that require full socket/network/system features, traditional containers remain the default unless a WASM platform abstraction (e.g., Spin) fits the architecture.

---