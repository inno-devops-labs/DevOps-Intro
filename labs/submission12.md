## Task 1

For CLI mode:
```bash
(hw) lexi@lexandrinnnt:~/inno/DevOps-Intro/labs/lab12$ MODE=once go run main.go
{
  "moscow_time": "2026-04-15 19:04:18 MSK",
  "timestamp": 1776269058
}
```

For server mode:
![task_1.png](task_1.png)

## Task 2

```bash
# ls -lh moscow-time-traditional
-rwxr-xr-x 1 lexi lexi 4.5M Apr 15 19:07 moscow-time-traditional
```

```bash
# docker images moscow-time-traditional
REPOSITORY                TAG       IMAGE ID       CREATED              SIZE
moscow-time-traditional   latest    61ed8daabb46   About a minute ago   4.7MB
# docker image inspect moscow-time-traditional --format '{{.Size}}' | \
#    awk '{print $1/1024/1024 " MB"}'
4.48047 MB
```

```bash
# for i in {1..5}; do
#     /usr/bin/time -f "%e" docker run --rm -e MODE=once moscow-time-traditional 2>&1 | tail -n 1
# done | awk '{sum+=$1; count++} END {print "Average:", sum/count, "seconds"}'
# Average: 0.158 seconds
Average: 0.158 seconds
```

```bash
# docker stats test-traditional --no-stream
CONTAINER ID   NAME               CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
5811a23df472   test-traditional   0.00%     1.574MiB / 15.18GiB   0.01%     19.3kB / 6.28kB   0B / 0B     5
```

![task_2.png](task_2.png)

## Task 3

```bash
# ls -lh main.wasm
# file main.wasm
-rwxr-xr-x 1 lexi lexi 2.4M Apr 16 06:35 main.wasm
main.wasm: WebAssembly (wasm) binary module version 0x1 (MVP)
```

```bash
● containerd.service - containerd container runtime
     Loaded: loaded (/usr/lib/systemd/system/containerd.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-04-16 06:46:16 MSK; 798ms ago
       Docs: https://containerd.io
   Main PID: 26954 (containerd)
      Tasks: 13
     Memory: 16.5M (peak: 20.7M)
        CPU: 58ms
     CGroup: /system.slice/containerd.service
             └─26954 /usr/bin/containerd

Apr 16 06:46:16 lexandrinnnt containerd[26954]: time="2026-04-16T06:46:16.733733416+03:00" level=info msg="Start event monitor"
```

```bash
# ctr --version
ctr github.com/containerd/containerd/v2 2.2.1
```

```bash
# sudo systemctl restart containerd
# sudo systemctl status containerd --no-pager

● containerd.service - containerd container runtime
     Loaded: loaded (/usr/lib/systemd/system/containerd.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-04-16 07:11:00 MSK; 12ms ago
       Docs: https://containerd.io
    Process: 40031 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
   Main PID: 40033 (containerd)
      Tasks: 13
     Memory: 33.1M (peak: 36.0M)
        CPU: 76ms
     CGroup: /system.slice/containerd.service
             └─40033 /usr/bin/containerd
```

```bash
# sudo containerd config dump | sed -n "/io.containerd.cri.v1.runtime'.containerd/,/^\[/p" | sed -n '/runtimes/,+20p'
...
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc]
    runtime_type = 'io.containerd.runc.v2'
    runtime_path = ''
    ...
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.wasmtime]
    runtime_type = 'io.containerd.wasmtime.v1'
    runtime_path = ''
    ...
```

Final verification:

```bash
-rwxr-xr-x 1 root root 32325480 Apr 16 07:05 /usr/local/bin/containerd-shim-wasmtime-v1
Client:
  Version:  2.2.1
  Revision: 
  Go version: go1.24.4

Server:
  Version:  2.2.1
  Revision: 
  UUID: 2cfcc2dd-966e-420b-a072-a058991108b8
```

```bash
# sudo ctr images ls | grep -E 'moscow-time-wasm|wasi|wasm'
docker.io/library/moscow-time-wasm:latest application/vnd.oci.image.manifest.v1+json sha256:e8ed8c1b72df551faab0b9af8bc6c399cdf431df050017990268ec1266e2e7a0 819.9 KiB wasi/wasm -  
```

```bash
# Binary size
# ls -lh main.wasm

# Image size (ctr images ls)
# sudo ctr images ls | awk 'NR>1 && $1 ~ /moscow-time-wasm/ {print "IMAGE:", $1, "SIZE:", $4}'
-rwxr-xr-x 1 lexi lexi 2.4M Apr 16 06:35 main.wasm
IMAGE: docker.io/library/moscow-time-wasm:latest SIZE: 819.9
```

```bash
# for i in {1..5}; do
#     NAME="wasi-$(date +%s%N | tail -c 6)-$i"
#     /usr/bin/time -f "%e" sudo ctr run --rm \
#         --runtime io.containerd.wasmtime.v1 \
#         --platform wasi/wasm \
#         --env MODE=once \
#         docker.io/library/moscow-time-wasm:latest "$NAME" 2>&1 | tail -n 1
# done | awk '{sum+=$1; n++} END{printf("Average: %.4f seconds\n", sum/n)}'
Average: 0.3780 seconds
```

## Task 4

### 4.1 Comprehensive Comparison Table

| Metric | Traditional Container | WASM Container | Improvement | Notes |
|--------|------------------------|----------------|-------------|-------|
| **Binary Size** | 4.5 MB | 2.4 MB | **46.7% smaller** | From `ls -lh` |
| **Image Size** | 4.48047 MB | 0.80068 MB (819.9 KiB) | **82.1% smaller** | Traditional from `docker image inspect`, WASM from `ctr images ls` |
| **Startup Time (CLI)** | 158 ms | 378 ms | **0.42x faster (WASM is slower)** | Average of 5 runs |
| **Memory Usage** | 1.574 MiB | N/A via `ctr` | N/A | `docker stats` works for traditional container; WASM runtime accounting differs |
| **Base Image** | `scratch` | `scratch` | Same | Both minimal |
| **Source Code** | `main.go` | `main.go` (TinyGo -> `main.wasm`) | Identical logic | Same application behavior in CLI mode |
| **Server Mode** | ✅ Works (`net/http`) | ❌ Not via `ctr` / WASI Preview1<br>✅ Via Spin (WAGI) | N/A | WASI Preview1 has no socket API; Spin provides HTTP abstraction |

**Calculations used:**
- Size reduction % = `((Traditional - WASM) / Traditional) × 100`
- Binary: `((4.5 - 2.4) / 4.5) × 100 = 46.7%`
- Image: `((4.48047 - 0.80068) / 4.48047) × 100 = 82.1%`
- Speed factor = `Traditional / WASM = 158 / 378 = 0.42x`

### 4.2 Analysis Questions

1. **Binary Size Comparison**
   - The WASM binary is much smaller because TinyGo targets a compact WASI runtime model and aggressively minimizes generated code.
   - TinyGo optimized away most of the heavyweight Go runtime pieces (large GC/runtime scaffolding, scheduler complexity, reflection-related metadata, and unused standard library code through dead-code elimination/link-time trimming).

2. **Startup Performance**
   - In this benchmark, WASM under `ctr + wasmtime` did **not** start faster; it was slower (378 ms vs 158 ms). This is expected in some setups because runtime invocation overhead (shim + wasmtime startup + sandbox setup per run) can dominate for tiny programs.
   - Traditional container startup still has overhead too (container create/start, namespace/cgroup setup, process spawn), but on this machine that path was cheaper than the current WASM runtime path for single-shot CLI runs.

3. **Use Case Decision Matrix**
   - Choose **WASM** when you need very small artifacts, strong sandboxing, fast distribution, and portability across runtimes/edge platforms (especially for short tasks/plugins where size and isolation matter more than raw startup in this environment).
   - Stick with **traditional containers** when you need full Linux compatibility, mature networking/process model, straightforward observability (`docker stats`, common tooling), and predictable performance for long-running HTTP services.

