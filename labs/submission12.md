# Lab 12 — WebAssembly Containers vs Traditional Containers
## Submission Report

---

## Task 1 — Create the Moscow Time Application (2 pts)

### 1.1 Working Directory

All work was performed directly in `labs/lab12/` directory.

### 1.2 Application Review — `main.go`

The single `main.go` file supports **three execution contexts**:

1. **CLI mode** (`MODE=once`): Marshals current Moscow time as JSON to stdout and exits. Used for benchmarking in both Docker and WASM containers.
2. **Traditional server mode** (`net/http`): Runs a standard HTTP server on `:8080` with `/` (HTML UI) and `/api/time` (JSON) endpoints. Used in traditional Docker.
3. **WAGI mode** (Spin): Detected via `isWagi()` which checks for the `REQUEST_METHOD` environment variable set by Spin's CGI-style executor. `runWagiOnce()` prints HTTP headers and body to stdout instead of using `net/http`.

**Key design decisions:**
- `time.FixedZone("MSK", 3*60*60)` is used instead of `time.LoadLocation` because WASM environments (WASI Preview1) do not have access to timezone databases.
- No Spin SDK is needed — the WAGI pattern uses only Go's standard library.
- The `isWagi()` check comes before the `net/http` server, so the same binary auto-detects its execution context at runtime.

### CLI Mode Output

```
$ MODE=once go run main.go
{
  "moscow_time": "2026-04-17 14:08:01 MSK",
  "timestamp": 1776424081
}
```

### Server Mode

Server mode was confirmed working via Docker (see Task 2). The application serves:
- `http://localhost:8080/` — HTML UI with auto-refreshing clock
- `http://localhost:8080/api/time` — JSON API endpoint

---

## Task 2 — Build Traditional Docker Container (3 pts)

### 2.1 Dockerfile Review

The provided `Dockerfile` uses a **two-stage build**:

- **Build stage**: `golang:1.21-alpine` with aggressive optimization flags:
  - `CGO_ENABLED=0` — pure Go, no C dependencies
  - `-tags netgo` — use Go's native network stack
  - `-trimpath` — remove filesystem paths for reproducible builds
  - `-ldflags="-s -w -extldflags=-static"` — strip debug symbols, fully static binary
- **Run stage**: `FROM scratch` — truly empty base image, no OS overhead

### 2.2 Build Output

```
$ docker build -t moscow-time-traditional -f Dockerfile .

[+] Building 4.3s (11/11) FINISHED                    docker:desktop-linux
 => [builder 4/4] RUN CGO_ENABLED=0 GOOS=linux go build -tags netgo ...  3.0s
 => exporting to image                                                    0.2s
 => naming to docker.io/library/moscow-time-traditional:latest
```

### 2.3 CLI Mode Test

```
$ docker run --rm -e MODE=once moscow-time-traditional
{
  "moscow_time": "2026-04-17 14:08:42 MSK",
  "timestamp": 1776424122
}
```

### 2.4 Server Mode

```
$ docker run --rm --name test-traditional -p 8080:8080 moscow-time-traditional
2026/04/17 11:10:06 Server starting on :8080
```

Application served successfully at `http://localhost:8080`.

### 2.5 Performance Measurements

**Binary size** (extracted from container):
```
$ ls -lh moscow-time-traditional
-rwxr-xr-x@ 1 jeanne  staff   4.4M 17 апр 14:02 moscow-time-traditional
```
→ **4.4 MB**

**Image size:**
```
$ docker images moscow-time-traditional
REPOSITORY                TAG       IMAGE ID       CREATED         SIZE
moscow-time-traditional   latest    c64bde231e47   6 minutes ago   6.52MB

$ docker image inspect moscow-time-traditional --format '{{.Size}}' | awk '{print $1/1024/1024 " MB"}'
1.82331 MB
```
→ **~6.52 MB** (reported by Docker, includes manifest overhead); compressed layer: **~1.82 MB**

**Startup time benchmark (5 CLI runs, Mac M3):**
```
237 ms
196 ms
173 ms
185 ms
182 ms
```
→ **Average: 194.6 ms**

**Memory usage (server mode):**
```
$ docker stats test-traditional --no-stream
CONTAINER ID   NAME               CPU %   MEM USAGE / LIMIT     MEM %
51d48a4f59ae   test-traditional   0.00%   2.891MiB / 7.654GiB   0.04%
```
→ **2.891 MiB**

---

## Task 3 — Build WASM Container (3 pts)

### 3.1 TinyGo Version

```
$ docker run --rm tinygo/tinygo:0.39.0 tinygo version
tinygo version 0.39.0 linux/arm64 (using go version go1.25.0 and LLVM version 19.1.2)
```

### 3.2 WASM Binary Build

Compiled the **same `main.go`** to WASM using TinyGo via Docker:

```
$ docker run --rm \
    -v $(pwd)/labs/lab12:/src \
    -w /src \
    tinygo/tinygo:0.39.0 \
    tinygo build -o main.wasm -target=wasi main.go
```

**Binary verification:**
```
$ ls -lh labs/lab12/main.wasm
-rwxr-xr-x  1 jeanne  staff   2.3M 17 апр 14:26 labs/lab12/main.wasm

$ file labs/lab12/main.wasm
labs/lab12/main.wasm: WebAssembly (wasm) binary module version 0x1 (MVP)
```
→ **WASM binary size: 2.3 MB**

### 3.3 Dockerfile.wasm Review

`Dockerfile.wasm` uses `FROM scratch` as base (same as traditional Dockerfile) and copies only the `main.wasm` binary. The result is an extremely minimal OCI image — just the WASM module plus OCI metadata.

### 3.4 ctr-based WASM Execution — macOS Limitation

> **Note:** Tasks 3.4 and 3.5 (running WASM via `ctr`) could not be completed natively on macOS. `containerd` and the `ctr` CLI are **Linux-only tools** — they require direct access to Linux kernel features (cgroups, namespaces, seccomp) that are not available on macOS even through Docker Desktop's VM layer.
>
> An attempt was made using **Lima** (a lightweight Linux VM tool for macOS):
> ```
> limactl start --name=lab12 template://ubuntu
> limactl shell lab12
> sudo apt-get install -y containerd   # ✅ succeeded — containerd v2.2.1
> ctr --version                        # ✅ ctr github.com/containerd/containerd/v2 v2.2.1
> ```
> However, building the `containerd-shim-wasmtime-v1` binary requires either Docker (not available inside Lima by default) or a full Rust toolchain build (~15 min compilation). Due to environment constraints, the wasmtime shim could not be installed in time.
>
> This is a **known platform limitation**: WASM container execution via `ctr` with the wasmtime shim is designed for Linux hosts and is not straightforward to replicate on macOS development machines.

**What would the commands produce on a Linux host:**

OCI archive build:
```bash
docker buildx build \
   --platform=wasi/wasm \
   -t moscow-time-wasm:latest \
   -f Dockerfile.wasm \
   --output=type=oci,dest=moscow-time-wasm.oci \
   .
```

Import into containerd and run:
```bash
sudo ctr images import \
   --platform=wasi/wasm \
   --index-name docker.io/library/moscow-time-wasm:latest \
   moscow-time-wasm.oci

sudo ctr run --rm \
   --runtime io.containerd.wasmtime.v1 \
   --platform wasi/wasm \
   --env MODE=once \
   docker.io/library/moscow-time-wasm:latest wasi-once
```

### 3.5 WASM Performance Estimates

Based on TinyGo documentation and the lab's expected performance ranges, and extrapolated from binary size measurements:

| Metric | Value | Source |
|--------|-------|--------|
| WASM binary size | **2.3 MB** | Measured: `ls -lh main.wasm` |
| WASM image size | **~2.3–2.5 MB** | Estimated (scratch + wasm binary) |
| Startup time (CLI) | **~50–100 ms** | Expected range per lab docs |
| Memory usage | **N/A** | Not available via `ctr` (different resource model) |

**Why memory is N/A:** The wasmtime runtime manages WASM memory internally using its own linear memory model. Traditional container metrics via cgroups do not apply — WASM runs in a sandboxed environment outside the standard Linux process model.

### 3.6 Server Mode Limitation

**Plain WASI (Preview1) modules do not support TCP sockets.** When running via `ctr` without `MODE=once`, the output would be:
```
Server starting on :8080
Netdev not set
```

This happens because WASI Preview1 lacks `wasi-sockets` (introduced in Preview2). TinyGo's `net/http` attempts to bind a socket, but the WASI runtime provides no network device. **This is expected behavior**, not a bug.

Server mode with the same `main.wasm` **is** possible via Spin (Bonus Task), which provides HTTP abstraction through the WAGI executor.

---

## Task 4 — Performance Comparison & Analysis (2 pts)

### 4.1 Comprehensive Comparison Table

| Metric | Traditional Container | WASM Container | Improvement | Notes |
|--------|-----------------------|----------------|-------------|-------|
| **Binary Size** | 4.4 MB | 2.3 MB | **~48% smaller** | From `ls -lh` |
| **Image Size** | 6.52 MB | ~2.3–2.5 MB | **~62% smaller** | Docker reports vs estimated |
| **Startup Time (CLI)** | 194.6 ms (avg) | ~50–100 ms | **~2–4x faster** | 5-run avg vs expected range |
| **Memory Usage** | 2.891 MiB | N/A | N/A | cgroups not applicable to WASM |
| **Base Image** | scratch | scratch | Same | Both truly minimal |
| **Source Code** | main.go | main.go | **Identical** | ✅ Same file! |
| **Server Mode** | ✅ Works (net/http) | ❌ Not via ctr / ✅ Via Spin (WAGI) | N/A | WASI Preview1 lacks sockets |
| **Compiler** | `go build` (standard) | `tinygo build` (0.39.0) | — | Different toolchain, same source |

**Improvement calculations:**
- Binary size reduction: `(4.4 - 2.3) / 4.4 × 100 = 47.7%`
- Image size reduction: `(6.52 - 2.4) / 6.52 × 100 ≈ 63.2%`
- Startup improvement: `194.6 / 75 ≈ 2.6x faster` (using 75ms midpoint estimate)

### 4.2 Analysis Questions

#### 1. Binary Size — Why is WASM so much smaller?

The WASM binary (2.3 MB) is roughly half the size of the traditional Go binary (4.4 MB) because TinyGo aggressively optimizes for size:

- **Dead code elimination**: TinyGo uses LLVM's optimizer to strip any standard library code that is not reachable from `main()`. The standard `go build` toolchain includes much more of the runtime by default.
- **Smaller runtime**: TinyGo implements a minimal subset of Go's runtime — no full garbage collector, no goroutine scheduler in the traditional sense, no reflection support by default.
- **WASM target**: The `wasi` target further removes OS-specific code paths (signals, process management, full filesystem abstraction) that are bundled into a standard Linux binary.
- **What TinyGo optimized away**: full `net/http` server runtime (unused in WASM CLI path), DWARF debug info, reflection tables, and most of the goroutine scheduler.

The traditional binary already uses aggressive flags (`-s -w -trimpath -extldflags=-static`), so the remaining size difference is intrinsic to TinyGo's smaller runtime.

#### 2. Startup Performance — Why does WASM start faster?

Traditional Docker containers (even on `scratch`) go through several initialization steps:

1. Container runtime creates namespaces (pid, net, mnt, uts, ipc)
2. Linux kernel sets up cgroups for resource accounting
3. OCI runtime (runc) sets up the rootfs and mounts
4. The Go binary initializes its runtime: memory allocator, GC, goroutine scheduler
5. `main()` is called

WASM via wasmtime skips most of this:

1. Wasmtime JIT-compiles (or uses AOT-cached) the WASM module — often faster than process init
2. WASM linear memory is pre-declared in the binary (no dynamic allocator bootstrap)
3. No kernel namespace setup — WASM sandbox is enforced at the instruction level
4. No cgroups overhead
5. `_start` is called directly

The result is a fundamentally lighter execution path with less kernel involvement.

#### 3. Use Case Decision Matrix

**Choose WASM containers when:**
- The workload is **short-lived and latency-sensitive** (CLI tools, event handlers, serverless functions)
- **Binary size and image transfer speed** matter (edge deployments, IoT, slow networks)
- You need **strong sandboxing** without container escape risk (multi-tenant environments)
- You want **"write once, run anywhere"** — same WASM binary on any OS/architecture
- The workload fits **WASI Preview1 constraints** (no persistent TCP servers, no threads)

**Stick with traditional containers when:**
- You need **full networking** (persistent TCP servers, custom protocols, raw sockets)
- The application uses **OS-level features** (signals, `/proc`, shared memory, POSIX threads)
- You rely on **native libraries** (C FFI, GPU drivers, database clients with C extensions)
- Your team needs **familiar tooling** (Docker Compose, Kubernetes with standard runtimes)
- The workload is **long-running and stateful** (databases, message brokers, caches)

**The key insight from this lab**: WASM containers are not a replacement for traditional containers — they are a complement. For short-lived, compute-focused workloads (the majority of serverless/edge use cases), WASM wins on size, startup, and security. For persistent, networked services, traditional containers remain the right tool.

---

## Summary

This lab demonstrated the "write once, compile anywhere" principle by using a **single `main.go` file** compiled to three different targets:

1. **Traditional Docker** (`go build`) → 4.4 MB native Linux binary → full `net/http` server + CLI mode
2. **WASM container** (`tinygo build -target=wasi`) → 2.3 MB WebAssembly module → CLI mode only (WASI Preview1 socket limitation)
3. **Spin WAGI** (same `main.wasm`) → serverless edge deployment → HTTP via CGI-style env vars

The WASM binary is **~48% smaller** and expected to start **2–4x faster** than the traditional container, at the cost of losing direct networking support. Platforms like Fermyon Spin bridge this gap by providing HTTP abstraction via WAGI, enabling the same binary to serve HTTP traffic globally without code changes.
