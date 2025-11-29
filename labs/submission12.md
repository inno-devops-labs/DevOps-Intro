# Lab 12 

```powershell
cd labs/lab12
# CLI mode (prints JSON and exits)
$env:MODE='once'; go run main.go
# Server mode (starts net/http on :8080)
go run main.go
```

**![output](1.png)**
**![output](2.png)**

## Single `main.go` — three execution contexts

The Moscow Time app was intentionally written so that the exact same `labs/lab12/main.go` adapts to whatever runtime wraps it:

- **CLI benchmark (`MODE=once`)** — `main()` short‑circuits when the env var is set, marshals the current Moscow time to JSON, prints it, and exits. That makes both the traditional Docker container and the WASM container comparable because nothing else (HTTP listeners, goroutines, etc.) gets initialized.
- **Traditional server mode (`net/http`)** — when no special env vars are set, the program registers the HTML + JSON handlers and calls `http.ListenAndServe(":8080")`. This path works in native Go, the scratch-based Docker image, or any environment that provides real TCP sockets.
- **Spin / WAGI mode (`REQUEST_METHOD` present)** — `isWagi()` detects Spin’s CGI-style environment variables. Instead of starting a server, `runWagiOnce()` writes HTTP headers and either the HTML landing page or `/api/time` JSON directly to STDOUT, which satisfies Spin’s requirement of one response per invocation. Because this branch only depends on stdio/env vars, the exact same binary works for Spin Cloud without code changes.


## Task 2.1 — Dockerfile review

- **Build stage** uses `FROM golang:1.21-alpine AS builder`, copies only `main.go`, and runs `CGO_ENABLED=0 GOOS=linux go build -tags netgo -trimpath -ldflags="-s -w -extldflags=-static" -o moscow-time main.go` so the binary is fully static (no CGO, minimal metadata).
- **Run stage** switches to `FROM scratch`, copies `/app/moscow-time`, exposes `8080`, and sets `ENTRYPOINT ["/app/moscow-time"]`, meaning the final image is literally just the binary + OCI metadata.
- **Result:** Because both stages are minimal, the traditional container is a fair baseline when we later compare it to the WASM build—base image differences don’t skew the numbers.

## Task 2.3 — Traditional container metrics

- `ls -lh moscow-time-traditional` → **4.4M** binary size after copying it out of the container via `docker cp`.
- `docker images moscow-time-traditional` → **4.59MB** image size from Docker’s listing; `docker image inspect ...` reports **4.375 MB** for the exact byte count.
- CLI startup timings from the Bash loop `TIMEFORMAT=%R; time docker run ...` produced `0.352, 0.366, 0.332, 0.336, 0.294` seconds, averaging **≈0.336 s**.
- `docker stats test-traditional --no-stream` while the server was bound to `:8080` read **1.535 MiB / 7.654 GiB (0.02 %)** in the MEM USAGE column.
- The screenshot labelled `![output](2.png)` shows the gradient Moscow Time page being served through the `moscow-time-traditional` container in a browser.


**![output](3.png)**



## Task 3 — Build WASM Container

### TinyGo Version

```
tinygo version 0.39.0 linux/amd64 (using go version go1.25.0 and LLVM version 19.1.2)
```

### Build WASM Binary

```bash
docker run --rm -v ${PWD}:/src -w /src tinygo/tinygo:0.39.0 tinygo build -o main.wasm -target=wasi main.go
```

### Build OCI Image

```bash
docker buildx build --platform=wasi/wasm -t moscow-time-wasm:latest -f Dockerfile.wasm --output=type=oci,dest=moscow-time-wasm.oci .
```

### WASM Metrics

| Metric | Value |
|--------|-------|
| WASM Binary Size | 2.34 MB |
| OCI Image Size | 0.83 MB |

### Running WASM with Wasmtime

Instead of setting up containerd with ctr (which requires a Linux host), I used the wasmtime runtime directly on Windows:

```bash
wasmtime --env MODE=once main.wasm
```

Output:
```json
{
  "moscow_time": "2025-11-26 17:01:08 MSK",
  "timestamp": 1764165668
}
```

### Startup Time Benchmark (5 runs)

| Run | Time (sec) |
|-----|------------|
| 1 | 0.084 |
| 2 | 0.055 |
| 3 | 0.052 |
| 4 | 0.046 |
| 5 | 0.048 |
| **Average** | **0.057** |

### Server Mode Limitation

WASI Preview1 does not support TCP sockets, so the server mode cannot work with plain WASI runtimes. To run HTTP server with WASM, platforms like Fermyon Spin can be used (see Bonus Task).

---

## Task 4 — Performance Comparison & Analysis

### 4.1 Comparison Table

| Metric | Traditional Container | WASM Container | Improvement | Notes |
|--------|----------------------|----------------|-------------|-------|
| **Binary Size** | 4.4 MB | 2.34 MB | 47% smaller | From `ls -lh` on the `moscow-time` binary vs `main.wasm`. |
| **Image Size** | 4.38 MB | 0.83 MB | 81% smaller | Byte counts from `docker image inspect` (scratch base in both cases). |
| **Startup Time (CLI)** | 336 ms | 57 ms | 5.9x faster | Average of 5 `docker run` vs 5 `wasmtime` executions with `MODE=once`. |
| **Memory Usage** | 1.54 MiB | N/A | N/A | `docker stats` observed steady-state RAM; wasmtime CLI exits too quickly for a comparable sampling. |
| **Base Image** | scratch | scratch | Same | Both artifacts are single-binary roots on scratch/OCI. |
| **Source Code** | main.go | main.go | Identical | ✅ Same file! |
| **Server Mode** | ✅ Works (net/http) | ❌ Not via ctr <br> ✅ Via Spin (WAGI) | N/A | WASI Preview1 lacks sockets; Spin provides an HTTP abstraction layer. |

_Calculations_: Size reduction % = `((Traditional - WASM) / Traditional) × 100`. Speedup factor = `Traditional / WASM` (e.g., `0.336 / 0.057 ≈ 5.9x`).

### 4.2 Analysis

1. **Binary Size Comparison**
   - TinyGo emits a much smaller WASM binary because it swaps the full Go runtime for a minimized WASI-friendly runtime, strips unused stdlib symbols via aggressive dead-code elimination, and uses compact Wasm instruction encodings instead of ELF sections, symbol tables, and DWARF metadata that the linux/amd64 build keeps even with `-s -w`.
   - TinyGo optimizes away features the Moscow Time app does not rely on—reflection, `net/http` server scaffolding, goroutine scheduler bookkeeping, and glibc/ABI shims—which is why the Wasm output is roughly half the size of the traditional static binary.

2. **Startup Performance**
   - The WASM workload starts faster because the runtime just instantiates a precompiled module inside wasmtime, zeroes its linear memory, and jumps to `_start`. There is no OCI unpack, no container process fork, and the module’s init logic is tiny.
   - A traditional container has to ask dockerd to create a sandbox, set up overlayfs layers, configure namespaces/cgroups, launch `runc`, start PID 1, and then let the Go runtime initialize goroutine stacks, the GC, and `net/http` before `main()` runs—all extra milliseconds that vanish in the WASM path.

3. **Use Case Decision Matrix**
   - Choose WASM when you want sub-100 ms cold starts, high-density multi-tenant hosting (Spin, wasmCloud, Cloudflare Workers), or you need to run untrusted plugins with a strong sandbox while keeping the codebase identical.
   - Stick with traditional containers when you need full POSIX I/O (sockets, files, DNS), long-lived servers with streaming connections, mature observability tooling, or when you must integrate with orchestrators (Kubernetes, ECS) that already expect OCI/OCI-compliant networking.
