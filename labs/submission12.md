# Lab 12

## Task 1


### CLI Mode Test

```bash
docker run --rm -v ${PWD}:/app -w /app -e MODE=once golang:1.21-alpine go run main.go
```
![alt text](<lab12/img/Снимок экрана 2025-11-25 154747.png>)

### Server Mode Test

```bash
docker run --rm -v ${PWD}:/app -w /app -p 8080:8080 golang:1.21-alpine go run main.go
```
on http://localhost:8080

![alt text](<lab12/img/Снимок экрана 2025-11-25 155044.png>)

![alt text](<lab12/img/Снимок экрана 2025-11-25 155057.png>)

### Explanation of how works `main.go`
One `main.go` file works in three modes because it checks environment variables:
- If the `MODE=once` variable is set, it simply outputs the time and shuts down (CLI mode).
- If not, it starts the web server.
- It can also determine if it is running in a special Spin environment.


#### Environment Note
- Used Docker to run the Go application
- Command to run: `docker run --rm -v${PWD}:/app -w /app -e MODE=once golang:1.21-alpine go run main.go`
- The CLI mode works correctly, outputs JSON with Moscow time

## Task 2

### Test CLI Mode
```bash
docker run --rm -e MODE=once moscow-time-traditional
```

![alt text](<lab12/img/Снимок экрана 2025-11-25 160516.png>)


### Test Server Mode

![alt text](<lab12/img/Снимок экрана 2025-11-25 161104.png>)

### Check Binary Size

```bash
docker create --name temp-traditional moscow-time-traditional
docker cp temp-traditional:/app/moscow-time ./moscow-time-traditional
docker rm temp-traditional

ls moscow-time-traditional
```

![alt text](<lab12/img/Снимок экрана 2025-11-25 160705.png>)

Result: 4.48 MB

### Check Image Size

```bash
docker images moscow-time-traditional
```

![alt text](<lab12/img/Снимок экрана 2025-11-25 161156.png>)

Result: 6.79 MB

### Average startup time across 5 CLI mode runs

```bash
1..5 | ForEach-Object {
    (Measure-Command { docker run --rm -e MODE=once moscow-time-traditional 2>&1 | Out-Null }).TotalSeconds
} | Measure-Object -Average | Select-Object -ExpandProperty Average
```

![alt text](<lab12/img/Снимок экрана 2025-11-25 161520.png>)

Average: 0.69972248 seconds

### Memory Usage (Server Mode)

```bash
docker stats test-traditional --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

![alt text](<lab12/img/Снимок экрана 2025-11-25 161823.png>)

Result: 1.16MiB

## Task 3

### TinyGo version

0.39.0

### WASM binary size

```bash
ls main.wasm
```

![alt text](<lab12/img/Снимок экрана 2025-11-25 163038.png>)

Result: 2.34 MB

### WASM Image Size

```bash
docker images moscow-time-wasm
```
Result: 809.3 KiB

### Average Startup Time

```bash
1..5 | ForEach-Object {
    (Measure-Command { docker run --rm -e MODE=once --runtime=io.containerd.wasmtime.v1 moscow-time-wasm 2>&1 | Out-Null }).TotalSeconds
} | Measure-Object -Average | Select-Object -ExpandProperty Average
```

Result: 0.4532 seconds

### Explanation of why server mode doesn't work under `ctr`

WASM in its current version (WASI Preview1) does not support network sockets, so it cannot open a port for the web server. This requires a special platform like Spin.

### Memory usage reporting

N/A is unavailable by ctr, because the wasmtime runtime uses a different approach to memory organization.

## Task 4

Comprehensive Comparison Table

| Metric | Traditional Container | WASM Container | Improvement | Notes |
|--------|----------------------|----------------|-------------|-------|
| **Binary Size** | 4.48 MB | 2.34 MB MB | 47.77% smaller | From `ls` command |
| **Image Size** | 6.79 MB | 0.8 MB MB | 88.22% smaller | From `docker images` command |
| **Startup Time (CLI)** | 0.6997 seconds | 0.4532 seconds | 1.54x faster | Average of 5 runs |
| **Memory Usage** | 1.16MiB | N/A | N/A | Not measured for simplicity |
| **Base Image** | scratch | scratch | Same | Both use minimal base |
| **Source Code** | main.go | main.go | Identical | Same source file |
| **Server Mode** | Works (net/http) | WAGI | N/A | WASI Preview1 lacks socket support |

**Improvement Calculations:**
- **Binary Size Reduction:** ((4.48 - 2.34) / 4.48) × 100 = 47.77% smaller
- **Image Size Reduction:** ((6.79 - 0.8) / 6.79) × 100 = 88.22% smaller  
- **Speed Improvement Factor:** 0.6997 / 0.4532 = 1.54x faster

### Analysis Questions

#### 1. Binary Size Comparison:
The WASM binary is significantly smaller than the traditional Go binary because **TinyGo compiles only the essential parts** of the Go standard library that are actually used in the program. Unlike the standard Go compiler, which includes the entire runtime and extensive standard library, TinyGo performs **tree-shaking** and eliminates unused code paths, resulting in a much more compact binary. Additionally, TinyGo doesn't include Go's garbage collector and other runtime components that aren't needed for this simple application.

#### 2. Startup Performance:
WASM containers start faster because they have **minimal initialization overhead**. Traditional containers need to:
- Boot a minimal operating system environment
- Load the entire binary into memory
- Initialize the Go runtime
- Set up process isolation

Whereas WASM containers:
- Execute directly in the WebAssembly runtime
- Have no OS boot process
- Use lightweight sandboxing instead of full container isolation
- Benefit from the efficient WASM instruction format

#### 3. Use Case Decision Matrix:

**Choose WASM containers when:**
- You need fast cold starts (serverless functions, CLI tools)
- Security is critical (WASM provides strong sandboxing)
- Resource efficiency matters (edge devices with limited memory)
- You're deploying stateless applications
- Portability across different platforms is important

**Choose traditional containers when:**
- You need full system access (networking, file system)
- Running long-lived stateful applications (databases, web servers)
- Using languages or libraries not supported by WASM
- You need multi-threading or complex I/O operations
- Compatibility with existing container orchestration is required