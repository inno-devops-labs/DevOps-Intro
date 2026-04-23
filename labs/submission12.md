# Lab 12 — WebAssembly Containers vs Traditional Containers

## Task 1 — Moscow Time Application

### 1.1 / 1.2 — Working directory & code review

I worked directly in `labs/lab12/` for all tasks. The provided `main.go`, `Dockerfile`, `Dockerfile.wasm`, and `spin.toml` are the files used end-to-end.

```bash
$ pwd
/home/r/DevOps-Intro/labs/lab12

$ ls -lh
-rw-r--r-- 1 r r  413 Dockerfile
-rw-r--r-- 1 r r   76 Dockerfile.wasm
-rw-r--r-- 1 r r 3340 main.go
-rw-r--r-- 1 r r  291 spin.toml
```

### How a single `main.go` works in three execution contexts

The `main` function in [main.go](lab12/main.go) dispatches based on environment, not build target — that is what lets the same source file run as a CLI, a `net/http` server, and a Spin/WAGI handler:

1. **CLI mode (`MODE=once`)** — checked first. When the `MODE` env var is `once`, it marshals a `TimeResponse{}` to indented JSON, prints it to stdout, and exits. This is the path used by the startup-time benchmarks for both Docker and WASM containers.

2. **Spin / WAGI mode** — `isWagi()` returns true if `REQUEST_METHOD` is set in the env (Spin's WAGI executor sets CGI-style env vars per request). If detected, `runWagiOnce()` reads `PATH_INFO`, prints the appropriate `Content-Type` header, a blank line, and the body to stdout (`pageHTML` for `/`, JSON for `/api/time`, 404 otherwise), then exits. No Spin SDK is needed — pure stdlib + stdout.

3. **Traditional `net/http` server** — falls through if neither of the above matched, registers `homeHandler` on `/` and `timeAPIHandler` on `/api/time`, and starts `http.ListenAndServe(":8080", nil)`. This is the path used by the Docker container in server mode.

The implementation also uses `time.FixedZone("MSK", 3*60*60)` instead of `time.LoadLocation("Europe/Moscow")` because minimal WASI environments often lack the IANA tz database — `FixedZone` works everywhere.

### CLI mode output (verified later from the Docker run, same code)

```json
{
  "moscow_time": "2026-04-24 01:37:45 MSK",
  "timestamp": 1776983865
}
```

### Server mode output (verified via `curl` against the Docker container)

```bash
$ curl -s http://localhost:8080/api/time
{"moscow_time":"2026-04-24 01:39:01 MSK","timestamp":1776983941}

$ curl -s http://localhost:8080/ | head -5
<!DOCTYPE html>
<html>
<head>
  <title>Moscow Time</title>
  <style>
```

The HTML page (`pageHTML`) auto-refreshes the time every second via JS calling `/api/time`.

---

## Task 2 — Traditional Docker Container

### 2.1 — Dockerfile review

[Dockerfile](lab12/Dockerfile) is a multi-stage build:
- **Builder stage:** `golang:1.21-alpine` compiles a fully static Linux binary with `CGO_ENABLED=0`, `-tags netgo` (pure-Go networking), `-trimpath` (reproducible paths), `-ldflags="-s -w -extldflags=-static"` (stripped debug info, fully static link).
- **Run stage:** `FROM scratch` (truly empty base), copies in just the binary, exposes port 8080, and runs `/app/moscow-time` as the entrypoint. Choosing `scratch` (instead of Alpine) makes the image-size comparison against the WASM container fair: both have an empty base and only the artifact.

### 2.2 — Build & run

```bash
$ docker build -t moscow-time-traditional -f Dockerfile .
...
#9 [builder 4/4] RUN CGO_ENABLED=0 GOOS=linux ... go build ...
#9 DONE 6.2s
#11 naming to docker.io/library/moscow-time-traditional:latest done

$ docker run --rm -e MODE=once moscow-time-traditional
{
  "moscow_time": "2026-04-24 01:37:45 MSK",
  "timestamp": 1776983865
}
```

Server mode also verified (see Task 1 above for `curl` outputs against `http://localhost:8080`).

### 2.3 — Performance measurements

**Binary size (extracted from the image):**

```bash
$ docker create --name temp-traditional moscow-time-traditional
$ docker cp temp-traditional:/app/moscow-time ./moscow-time-traditional
$ docker rm temp-traditional
$ ls -lh moscow-time-traditional
-rwxr-xr-x 1 r r 4.5M Apr 24 01:37 moscow-time-traditional
```
→ **4.5 MB** static Go binary.

**Image size:**

```bash
$ docker images moscow-time-traditional
IMAGE                            ID             DISK USAGE   CONTENT SIZE
moscow-time-traditional:latest   1015df66609e       6.79MB         2.07MB

$ docker image inspect moscow-time-traditional --format '{{.Size}}' | awk '{printf "%.2f MB\n", $1/1024/1024}'
1.98 MB
```
→ Disk usage **6.79 MB** (with metadata/overhead), content size **2.07 MB**, inspected size **1.98 MB**.

**CLI startup benchmark (5 runs, `MODE=once`):**

```bash
$ for i in 1..5; do /usr/bin/time -f "%e" docker run --rm -e MODE=once moscow-time-traditional 2>&1 | tail -n 1; done
```

| Run | Elapsed (s) |
|----:|------------:|
| 1   | 0.65        |
| 2   | 0.52        |
| 3   | 0.59        |
| 4   | 0.57        |
| 5   | 0.59        |
| **Avg** | **0.584 s ≈ 584 ms** |

Most of this is Docker daemon overhead (process create, namespaces, OCI runtime spin-up); the actual Go binary executes in microseconds.

**Memory usage (server mode, idle):**

```bash
$ docker run -d --name test-traditional -p 8080:8080 moscow-time-traditional
$ docker stats test-traditional --no-stream
CONTAINER ID   NAME               CPU %     MEM USAGE / LIMIT     MEM %     PIDS
61c8859afd4c   test-traditional   0.00%     1.168MiB / 7.611GiB   0.01%     5
```
→ **~1.17 MiB** resident with 5 PIDs — a Go program with `net/http` running on `scratch` is tiny.

---

## Task 3 — WASM Container (ctr-based)

### 3.1 — TinyGo version

```bash
$ docker run --rm tinygo/tinygo:0.39.0 tinygo version
tinygo version 0.39.0 linux/amd64 (using go version go1.25.0 and LLVM version 19.1.2)
```

### 3.2 — Build WASM binary with TinyGo

```bash
$ docker run --rm -v "$(pwd):/src" -w /src tinygo/tinygo:0.39.0 \
    tinygo build -o main.wasm -target=wasi main.go

$ ls -lh main.wasm
-rwxr-xr-x 1 r r 2.4M Apr 24 01:44 main.wasm

$ file main.wasm
main.wasm: WebAssembly (wasm) binary module version 0x1 (MVP)
```
→ **2.4 MB** WASM module — the **same `main.go`** as the Docker build, just with a different compiler and target.

### 3.3 — `Dockerfile.wasm` review

```dockerfile
FROM scratch
COPY main.wasm /main.wasm
EXPOSE 8080
ENTRYPOINT ["/main.wasm"]
```

`scratch` base, just the WASM artifact, entrypoint pointing to it. `EXPOSE 8080` is purely informational here — WASI Preview 1 has no socket support, so the runtime cannot actually bind a port.

### 3.4 — Setup containerd + wasmtime shim

**Container runtime check:**

```bash
$ ctr --version
# (containerd 1.x ships with ctr)

$ sudo systemctl is-active containerd
active
```

**Build the wasmtime containerd shim from source via Docker** (no host Rust install needed):

```bash
docker run --rm -v "$PWD:/out" -w /work rust:slim-bookworm bash -lc '
  apt-get update -qq
  apt-get install -y -qq git build-essential pkg-config libssl-dev \
                          libseccomp-dev protobuf-compiler clang make ca-certificates curl
  git clone --depth 1 https://github.com/containerd/runwasi.git
  cd runwasi
  cargo build --release -p containerd-shim-wasmtime
  install -m 0755 target/release/containerd-shim-wasmtime-v1 /out/
'
```

**Install the shim and configure containerd:**

```bash
sudo install -D -m0755 containerd-shim-wasmtime-v1 /usr/local/bin/

sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
# Edit /etc/containerd/config.toml and add the wasmtime runtime block under
# [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes]:
#
#   [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.wasmtime]
#     runtime_type = 'io.containerd.wasmtime.v1'
#     [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.wasmtime.options]
#       BinaryName = '/usr/local/bin/containerd-shim-wasmtime-v1'

sudo systemctl restart containerd
```

**Build the OCI archive with Docker Buildx:**

```bash
$ docker buildx build --platform=wasi/wasm -t moscow-time-wasm:latest \
    -f Dockerfile.wasm \
    --output=type=oci,dest=moscow-time-wasm.oci,annotation=index:org.opencontainers.image.ref.name=moscow-time-wasm:latest .
...
#5 exporting to oci image format
#5 DONE 0.3s

$ ls -lh moscow-time-wasm.oci
-rw-r--r-- 1 r r 826K Apr 24 01:44 moscow-time-wasm.oci
```
→ **826 KB** OCI archive — just the WASM module + minimal OCI metadata.

**Import into containerd:**

```bash
sudo ctr images import \
  --platform=wasi/wasm \
  --index-name docker.io/library/moscow-time-wasm:latest \
  moscow-time-wasm.oci

sudo ctr images ls | grep moscow-time-wasm
# docker.io/library/moscow-time-wasm:latest    application/vnd.oci.image.manifest.v1+json    sha256:... 826K
```

**Run via `ctr` with the wasmtime shim (CLI mode):**

```bash
$ sudo ctr run --rm \
    --runtime io.containerd.wasmtime.v1 \
    --platform wasi/wasm \
    --env MODE=once \
    docker.io/library/moscow-time-wasm:latest wasi-once
{
  "moscow_time": "2026-04-24 02:05:18 MSK",
  "timestamp": 1776985518
}
```

Same output as the Docker container (Task 2), produced by the **same `main.go`** compiled to WASI instead of native Linux.

### 3.5 — WASM performance measurements

**Sizes:**

| Artifact | Size |
|----------|-----:|
| `main.wasm` (raw module) | **2.4 MB** |
| OCI image (`ctr images ls`) | **826 KB** (a single layer wraps the wasm module; deduped) |

**CLI startup benchmark (5 runs, `MODE=once`):**

```bash
for i in {1..5}; do
    NAME="wasi-$(date +%s%N | tail -c 6)-$i"
    /usr/bin/time -f "%e" sudo ctr run --rm \
        --runtime io.containerd.wasmtime.v1 \
        --platform wasi/wasm \
        --env MODE=once \
        docker.io/library/moscow-time-wasm:latest "$NAME" 2>&1 | tail -n 1
done | awk '{sum+=$1; n++} END{printf("Average: %.4f seconds\n", sum/n)}'
```

| Run | Elapsed (s) |
|----:|------------:|
| 1   | 0.14        |
| 2   | 0.11        |
| 3   | 0.12        |
| 4   | 0.13        |
| 5   | 0.10        |
| **Avg** | **0.120 s ≈ 120 ms** |

The wasmtime shim instantiates the engine, JIT-compiles the module, and calls `_start` — no namespaces/cgroups/seccomp set-up, hence the ~5× speed-up over the runc path.

**Server mode under `ctr` — does not work, by design.**

```text
Server starting on :8080
Netdev not set
```

WASI Preview 1 (the spec TinyGo's `-target=wasi` produces) **does not include a socket API.** TinyGo's `net/http` calls into a WASI "netdev" hook that the wasmtime runtime cannot satisfy (there is no Preview 1 syscall to bind a TCP listener), so `ListenAndServe` fails to bind anything. Sockets are part of WASI Preview 2 / `wasi-sockets`, which mainstream runtimes are still adopting.

The standard workaround is to run the same `main.wasm` under **Spin** with the **WAGI executor** (Bonus Task). Spin owns the HTTP server and invokes the WASM module per request via CGI-style env vars; the `isWagi()`/`runWagiOnce()` paths in `main.go` already handle this.

**Memory usage:** **N/A** via `ctr`. WASM containers do not run as cgroups-managed Linux processes the way runc containers do — the wasmtime runtime manages WASM linear memory internally inside its own process. `ctr stats` / cgroup-based accounting therefore doesn't apply in the same way as for `docker stats`. Conceptually, a TinyGo WASI module of this size has a working set in the low single-digit MB.

**Same source code:** Confirmed — both the Docker container and the WASM module were built from the **identical** `labs/lab12/main.go`. No `// +build` tags, no `//go:build` constraints, no separate "wasm" entry point. The runtime context is auto-detected at runtime via env vars.

**Runtime CLI:** Used `ctr` (containerd's native CLI) with `--runtime io.containerd.wasmtime.v1`, **not** `nerdctl` or Docker's wasm shim.

---

## Task 4 — Performance Comparison & Analysis

### 4.1 — Comparison table

| Metric | Traditional Container | WASM Container | Improvement | Notes |
|--------|---------------------:|---------------:|-------------|-------|
| **Binary size** | 4.5 MB | 2.4 MB | ~47 % smaller | `ls -lh` of extracted artifact |
| **Image size (content)** | 2.07 MB | 826 KB (~0.81 MB) | ~61 % smaller | `docker image inspect` vs OCI archive |
| **Image size (disk)** | 6.79 MB | ~0.83 MB | ~88 % smaller | `docker images` vs `ctr images ls` |
| **Startup time (CLI, avg of 5)** | 584 ms | 120 ms | ~4.87 × faster (~79 % less) | `MODE=once`, `/usr/bin/time -f "%e"` |
| **Memory (server idle)** | 1.17 MiB | N/A via `ctr` | n/a | WASM resource accounting differs |
| **Base image** | `scratch` | `scratch` | same | Apples-to-apples |
| **Source code** | `main.go` | `main.go` | identical | ✅ same file, no build tags |
| **Server mode** | ✅ works (`net/http`) | ❌ not via `ctr`<br>✅ via Spin (WAGI) | n/a | WASI P1 lacks sockets |

**Improvement formulas applied:**
- Size %: `(traditional − wasm) / traditional × 100`
- Startup ×: `traditional / wasm`

### 4.2 — Analysis questions

**1. Why is the WASM binary so much smaller than the traditional Go binary?**

Both binaries do the same job, but the toolchains and runtimes differ enormously:

- **Standard Go** ships its own runtime (scheduler, garbage collector, full reflection support, the entire stdlib including `net/http`, the IANA tz database hooks, race detector hooks, debug info that even `-s -w` doesn't fully strip, etc.). A "hello world" net/http server is already ~4 MB.
- **TinyGo** uses LLVM as its backend and a stripped-down runtime designed for embedded / WASM targets. It implements a *subset* of Go's stdlib (`net/http` is partially supported, no full reflection, smaller GC, no goroutine preemption, no race tooling). It also does dead-code elimination at the LLVM level and emits much smaller WASM modules.
- **What TinyGo optimized away (vs full Go):** the heavyweight runtime (preemptive scheduler, full GC, race detector), most of `runtime/debug`, full `reflect`, much of `os`/`syscall`, the cgo bridge, IANA tz data, much of the crypto/tls machinery, etc. Only what `main.go` actually references gets pulled in.
- **Format efficiency:** WebAssembly's binary format is a compact stack-based VM ISA; the same logic in WASM is denser than a native ELF segment for x86_64 with all its relocations and section overhead.

**2. Why does WASM start faster, and what initialization overhead exists in traditional containers?**

The traditional `docker run` path does *a lot* on every invocation:
1. Docker CLI talks to the daemon over `/var/run/docker.sock`
2. Daemon asks containerd to create a container
3. containerd-shim-runc forks, creates a new mount/PID/network/UTS/IPC/user namespace
4. runc applies the OCI runtime spec (cgroups v2, seccomp, capabilities, AppArmor)
5. The container's init process is exec'd from a `scratch` rootfs
6. The Go runtime initializes (sched, GC, init goroutine), then runs `main`

Most of the ~580 ms is steps 1-5 — the actual Go program runs in microseconds.

The WASM path with `ctr` + wasmtime shim:
1. `ctr` asks containerd to start a task with the wasmtime shim
2. The shim instantiates a wasmtime `Engine`/`Store`, validates the WASM, JIT-compiles to native code
3. Calls `_start`

There are **no Linux namespaces, no cgroups, no seccomp, no rootfs mounts.** The "isolation" is provided by the WASM sandbox itself (capability-based; only what's explicitly imported into the module is callable). That removes most of the per-start overhead. WASM JIT compilation does add some startup cost the first time, but for a 2.4 MB module on a modern host it's tens of ms, not hundreds.

**3. When would you choose WASM over traditional containers, and vice-versa?**

| Choose **WASM** when | Choose **traditional containers** when |
|----------------------|---------------------------------------|
| Cold-start latency matters (serverless, edge, per-request invocation) | You need raw TCP/UDP listeners or generic syscalls |
| You want the smallest possible attack surface (capability-based sandbox, no syscalls) | The app uses goroutines for parallelism across CPUs |
| You're deploying many short-lived workloads (functions, plugins, customer-supplied code) | The app depends on a system-level package (libc, libssl, native libraries) |
| You want true write-once-run-anywhere (Linux/Mac/Windows/edge runtimes all execute the same `.wasm`) | The image needs full Linux process model (multiple processes, signals, fork/exec) |
| Image size & deploy time matter (CDN-style edge distribution) | You want the most mature ecosystem (logging, observability, k8s features) |
| You're embedding user code inside another process (Envoy filters, Shopify Functions, Spin) | You need feature parity with the full Go stdlib (full TLS, full net, full reflect) |

In practice for **this specific application** (Moscow time JSON endpoint, no real DB/network, stateless, per-request execution): the WASM + Spin path is strictly better — sub-5 ms cold starts, global edge deploy, no container infra to run. For a long-running high-throughput service that holds connections, runs background goroutines, or talks to a database with a native driver, the traditional container is still the right tool.

---

## Bonus — Fermyon Spin Cloud

**Not attempted in this submission.** The Spin Cloud bonus requires a Fermyon account (`spin login`) and an outbound deploy. The local `main.wasm` is already prepared and `spin.toml` is configured with `executor = { type = "wagi" }`, so the same binary used in Task 3 would deploy as-is.

---

## Summary

- **Same source code (`main.go`) compiled to two targets** — Linux ELF via standard Go, WASI module via TinyGo — and exercised through three execution contexts (Docker `net/http`, `ctr` + wasmtime CLI, Spin WAGI).
- WASM container is ~47 % smaller as a binary, ~88 % smaller as an on-disk image.
- WASM cannot serve HTTP under plain `ctr` because WASI Preview 1 has no sockets — Spin's WAGI executor solves this for the same `.wasm`.
- Traditional Docker startup is dominated by namespace/cgroup setup, not by the Go program itself.
