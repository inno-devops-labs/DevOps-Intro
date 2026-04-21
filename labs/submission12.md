# Lab 12 Submission

## Build Environment

- Working directory: `labs/lab12/`
- Host environment used for this submission: Windows + Docker Desktop Linux backend
- Traditional container runtime: Docker 28.0.4
- containerd server: 1.7.26
- `ctr` client used for WASM tests: 1.6.20~ds1
- TinyGo version:

```text
tinygo version 0.39.0 linux/amd64 (using go version go1.25.0 and LLVM version 19.1.2)
```

The same source file, `labs/lab12/main.go`, was used for all targets:
- Traditional Docker native Linux binary
- WASM binary compiled with TinyGo for `wasi`
- Spin/WAGI-compatible mode implemented in the same file

## Task 1 - Create the Moscow Time Application

### CLI Mode Output

Command:

```bash
docker run --rm -e MODE=once moscow-time-traditional
```

Output:

```json
{
  "moscow_time": "2026-04-21 03:14:20 MSK",
  "timestamp": 1776730460
}
```

### Server Mode Verification

I verified server mode locally by running the container and querying `http://localhost:8080/api/time`.

Response:

```json
{"moscow_time":"2026-04-21 03:14:39 MSK","timestamp":1776730479}
```

### How `main.go` Works in Three Contexts

- `MODE=once` switches the application into one-shot CLI mode, prints JSON once, and exits.
- `isWagi()` checks `REQUEST_METHOD`; if it is present, the program assumes Spin WAGI execution.
- `runWagiOnce()` prints CGI/WAGI-style headers and body to stdout, which lets the same binary answer HTTP requests in Spin without a Spin SDK.
- If neither CLI nor WAGI mode is detected, the program starts a normal `net/http` server on port `8080`.
- `time.FixedZone("MSK", 3*60*60)` avoids dependence on an external timezone database, which is useful for minimal WASM/WASI environments.

## Task 2 - Traditional Docker Container

### Binary Size

Extracted binary:

```text
moscow-time-traditional: 4698112 bytes (4.48 MiB)
```

### Image Size

`docker images`:

```text
REPOSITORY                TAG       IMAGE ID       SIZE
moscow-time-traditional   latest    0c135595fe2a   4.7MB
```

`docker image inspect`:

```text
4698112 bytes
```

### Startup Time Benchmark

5 runs of CLI mode:

```text
0.5300
0.4272
0.4517
0.4292
0.4915
Average: 0.4659 seconds
```

### Memory Usage

`docker stats test-traditional --no-stream`:

```text
MEM USAGE / LIMIT
1.234MiB / 7.683GiB
```

## Task 3 - WASM Container

### WASM Binary Size

`main.wasm`:

```text
2450459 bytes (2.34 MiB)
```

### WASM OCI Image Size

`ctr images ls`:

```text
docker.io/library/moscow-time-wasm:latest ... 819.9 KiB wasi/wasm
```

### WASM CLI Run Verification

Command:

```bash
ctr run --rm \
  --runtime io.containerd.wasmtime.v1 \
  --platform wasi/wasm \
  --env MODE=once \
  docker.io/library/moscow-time-wasm:latest wasi-once-test
```

Output:

```json
{
  "moscow_time": "2026-04-21 03:28:27 MSK",
  "timestamp": 1776731307
}
```

### WASM Startup Time Benchmark

5 runs:

```text
0.9010
0.9038
0.8932
0.8622
0.9207
Average: 0.8962 seconds
```

### Server Mode Limitation Under `ctr`

Running the WASM container without `MODE=once` failed as expected:

```text
2026/04/21 00:28:38 Server starting on :8080
2026/04/21 00:28:38 Netdev not set
```

Explanation:

- Plain WASI Preview1 does not provide TCP sockets.
- The Go `net/http` server attempts to bind to `:8080`.
- Under plain `ctr` + WASI runtime there is no network device for that socket operation.
- The same source code can still serve HTTP in Spin because Spin provides the HTTP layer through WAGI/CGI-style environment variables.

### Memory Usage

```text
N/A - not available via ctr
```

Reason:

- The WASM workload runs inside the Wasmtime runtime rather than as a traditional Linux container process with normal `docker stats` style accounting.
- In this setup, `ctr` did not expose a comparable per-container memory metric.

### Notes

- The same `main.go` source file was used for both traditional and WASM builds.
- WASM execution was performed with `ctr` against `containerd` using runtime `io.containerd.wasmtime.v1`.

## Task 4 - Performance Comparison and Analysis

### Comparison Table

| Metric | Traditional Container | WASM Container | Improvement | Notes |
|--------|----------------------|----------------|-------------|-------|
| Binary Size | 4.48 MiB | 2.34 MiB | 47.84% smaller | From extracted binary / `main.wasm` |
| Image Size | 4.48 MiB (`4698112` bytes, `docker image inspect`) | 819.9 KiB | 82.14% smaller | Both use `scratch` |
| Startup Time (CLI) | 465.9 ms | 896.2 ms | 0.52x, WASM slower in this setup | Average of 5 runs |
| Memory Usage | 1.234 MiB | N/A | N/A | `ctr` metric unavailable |
| Base Image | `scratch` | `scratch` | Same | Fair comparison |
| Source Code | `main.go` | `main.go` | Identical | Same file |
| Server Mode | Works with `net/http` | Not via plain `ctr`; possible via Spin/WAGI | N/A | WASI Preview1 lacks sockets |

### Analysis

#### 1. Why is the WASM binary smaller?

- TinyGo produces a much smaller runtime than the standard Go toolchain.
- It removes a large amount of standard runtime functionality that is not needed for this program.
- Debug and symbol data were also absent from the final WASM artifact.
- Even though my `main.wasm` was larger than the "typical" numbers mentioned in the lab text, it was still materially smaller than the native Go binary.

#### 2. Why can WASM start faster in theory, and why was it slower here?

- In a native Linux environment, WASM often starts quickly because the module is small and the runtime can initialize it with less process and filesystem overhead than a full containerized native binary.
- Traditional containers still need normal process startup, binary loading, and runtime initialization.
- In my measurements, WASM was slower. The most likely reason is the test environment: Docker Desktop on Windows, host `containerd` accessed through its Linux backend, and Wasmtime shim overhead. This is different from the lab's ideal prerequisite of a plain Linux host.
- So the artifact size advantage was clear, but the startup-time advantage did not appear in this specific environment.

#### 3. When would I choose WASM vs traditional containers?

Choose WASM when:

- Fast distribution and very small image sizes matter.
- You need stronger sandboxing and portability.
- The workload is short-lived, stateless, and does not need raw OS features.
- You plan to use a platform such as Spin that provides HTTP/event abstractions for WASM.

Choose traditional containers when:

- You need normal Linux networking, background services, or broader system access.
- You rely on the full Go runtime and standard container tooling.
- Operational simplicity matters more than image-size reduction.
- The workload is a long-running HTTP service that should bind sockets directly.

## Conclusion

- The lab objective of using the same `main.go` for both traditional and WASM targets was achieved.
- Traditional Docker mode worked in both CLI and server modes.
- WASM mode worked in CLI mode via `ctr` and `io.containerd.wasmtime.v1`.
- The expected server limitation under plain WASI Preview1 was reproduced and documented.
- In this environment, WASM produced clearly smaller artifacts, but startup time was slower than the traditional container benchmark.
