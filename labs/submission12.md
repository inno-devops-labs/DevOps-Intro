# Lab 12 - WebAssembly Containers vs Traditional Docker

## Task 1 - Moscow Time Application

**One `main.go`, three modes:**
- CLI mode: `MODE=once`, prints JSON and exits
- Server mode: `net/http` on port `8080`
- WAGI mode (Spin): if `REQUEST_METHOD` is set, prints HTTP response to stdout

**CLI mode (`MODE=once`):**

```bash
docker run --rm -e MODE=once moscow-time-traditional
```

```json
{
  "city": "Moscow",
  "timezone": "UTC+3",
  "timestamp": "2026-04-24T12:54:56+03:00",
  "unix": 1777024496
}
```

**Server mode:** run `docker run --rm -p 8080:8080 moscow-time-traditional`, then open `http://localhost:8080`.

---

## Task 2 - Traditional Docker

| Item | Value |
|------|--------|
| Build | `docker build -t moscow-time-traditional -f Dockerfile .` |
| Binary (extracted from image) | `4698112` B (~4.48 MiB) |
| Image size (`docker image inspect` Size) | `2071518` B (~1.98 MiB); `docker images` also shows ~2.07 MB content size |
| CLI startup, 5 runs with `MODE=once` | **669.46 ms** average (Windows, PowerShell `Measure-Command`) |
| Memory, server mode | `docker stats`: **1.332 MiB** (MEM USAGE) |

---

## Task 3 - WASM + `ctr` (Ubuntu WSL)

`ctr` is not available in Windows PowerShell, so this task was executed in Ubuntu WSL.
Environment: `containerd 2.2.1`, runtime `io.containerd.wasmtime.v1`, wasmtime shim from `runwasi`.
Logs: `wsl-task3-setup-and-run.sh`, `task3-wsl-results.txt`.

| Item | Value |
|------|--------|
| TinyGo | **0.39.0** (`tinygo/tinygo:0.39.0`) |
| `main.wasm` | `2449770` B (~2.34 MiB) |
| Image in store (`ctr images ls`) | `docker.io/library/moscow-time-wasm:latest`, **819.4 KiB**, `wasi/wasm` |
| CLI startup, 5 runs with `MODE=once` | **0.6886 s** average (bash `time`; runs: 0.753, 0.760, 0.647, 0.653, 0.630 s) |
| Memory via `ctr` | **N/A** (different accounting than cgroup-based `docker stats`) |

**Why server mode is not run with plain `ctr`:** WASI Preview1 does not provide TCP sockets. HTTP for the same binary is handled by a host such as Spin (WAGI), not by plain `ctr`.

Reference commands:

```bash
docker buildx build --platform=wasi/wasm -t moscow-time-wasm:latest -f Dockerfile.wasm \
  --output=type=oci,dest=moscow-time-wasm.oci,annotation=index:org.opencontainers.image.ref.name=moscow-time-wasm:latest .
sudo ctr images import --platform=wasi/wasm --index-name docker.io/library/moscow-time-wasm:latest moscow-time-wasm.oci
sudo ctr run --rm --runtime io.containerd.wasmtime.v1 --platform wasi/wasm --env MODE=once \
  docker.io/library/moscow-time-wasm:latest <unique-name>
```

---

## Task 4 - Comparison and Analysis

### Table

| Metric | Traditional | WASM (`ctr`) | Improvement / Factor | Notes |
|--------|-------------|--------------|----------------------|-------|
| Binary size | ~4.48 MiB | ~2.34 MiB | **~48% smaller** (WASM) | Same `main.go` |
| Image size | ~1.98 MiB (inspect) | 819.4 KiB | **~59% smaller** (WASM) | `docker image inspect` vs `ctr images ls` |
| CLI startup | ~0.669 s | ~0.689 s | **~0.97x** (traditional slightly faster in this run) | Measured on Windows+Docker vs WSL+`ctr` |
| Memory | 1.332 MiB | N/A | N/A | Not comparable via `ctr` |
| Base image | `scratch` | `scratch` | Same | - |
| Server mode | `net/http` | not via plain `ctr` | N/A | Spin/WAGI in this lab |

**Lab formulas:**  
Size reduction = `(traditional - wasm) / traditional * 100`  
Startup factor = `traditional_time / wasm_time` (here ~`0.97`)

### Analysis questions

1. **Why the WASM binary is smaller:** TinyGo uses a smaller runtime and removes unused code more aggressively than full `go build`.

2. **Startup:** A smaller module can help startup, but in this run Docker was slightly faster than `ctr` + wasmtime. Actual results depend on the environment.

3. **When to use each:** Use WASM for compact artifacts and strong isolation. Use traditional containers for full Linux networking, long-running services, and mature tooling.
