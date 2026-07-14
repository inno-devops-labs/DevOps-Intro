# Lab 12 - Bonus: WebAssembly Containers - QuickNotes Endpoint on Spin

## Overview

This lab implements a QuickNotes-style `/time` endpoint as a WebAssembly component using Spin.

The endpoint returns Moscow time as JSON and is compared against the Lab 6 Docker container for artifact size, warm latency, and cold-start time.

This machine used the current Spin 4 Go template, which differs from the lab's May 2026 Spin 3.4/TinyGo reference. The lab explicitly says to scaffold from the current `spin new -t http-go` template for the installed Spin version, so this submission keeps the generated Spin 4 layout and documents the difference.

---

# Task 1 - Spin WebAssembly Endpoint

## Tool versions

```text
spin 4.0.2 (bfc7543 2026-06-23)
go version go1.26.4 linux/amd64
```

The generated template used:

```text
github.com/spinframework/spin-go-sdk/v3 v3.0.0
go tool componentize-go build
```

During the first Windows build attempt, `componentize-go` failed because the Windows asset URL returned 404. The successful build was done in WSL/Linux.

The generated scaffold initially used `componentize-go v0.3.3`, which failed with a missing WIT path. Updating to `componentize-go v0.3.4` fixed the build.

---

## Project layout

```text
wasm/moscow-time/
  .gitignore
  go.mod
  go.sum
  main.go
  spin.toml
  main.wasm
```

---

## spin.toml

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["Maximilian Mifsud Bonici <m.mifsudbonici@innopolis.university>"]
description = ""

[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []

[component.moscow-time.build]
command = "go tool componentize-go build"
watch = ["**/*.go", "go.mod"]
```

The route is `/time`, and outbound network access is disabled with:

```toml
allowed_outbound_hosts = []
```

---

## main.go

```go
package main

import (
"fmt"
"net/http"
"time"

spinhttp "github.com/spinframework/spin-go-sdk/v3/http"
)

func init() {
spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
if r.Method != http.MethodGet || r.URL.Path != "/time" {
w.Header().Set("Content-Type", "application/json")
w.WriteHeader(http.StatusNotFound)
fmt.Fprint(w, `{"error":"not found"}`)
return
}

moscowLocation := time.FixedZone("MSK", 3*60*60)
moscow := time.Now().In(moscowLocation)

body := fmt.Sprintf(
`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow","utc_offset":"+03:00"}`,
moscow.Unix(),
moscow.Format(time.RFC3339),
moscow.Format("15:04"),
)

w.Header().Set("Content-Type", "application/json")
w.WriteHeader(http.StatusOK)
fmt.Fprint(w, body)
})
}

// main function must be included for the compiler but is not executed.
func main() {}
```

The endpoint uses a fixed UTC+3 zone instead of `time.LoadLocation("Europe/Moscow")`. This avoids timezone database issues in WASM environments.

---

## Build output

Command:

```bash
spin build
```

Output:

```text
Building component moscow-time with `go tool componentize-go build`
Downloading `componentize-go` binary from https://github.com/bytecodealliance/componentize-go/releases/download/v0.3.4/componentize-go-linux-amd64.tar.gz and extracting to /root/.cache/componentize-go/bin
Note: /snap/go/11200/bin/go does not support async operation; will use downloaded version.
Downloading patched Go from https://github.com/dicej/go/releases/download/go1.25.5-wasi-on-idle-v2/go-linux-amd64-bootstrap.tbz.
Extracting patched Go to /root/.cache/componentize-go/v2.
Using /root/.cache/componentize-go/v2/go-linux-amd64-bootstrap/bin/go.
Finished building all Spin components
```

---

## Run and verify

Command:

```bash
spin up --listen 127.0.0.1:3000
```

Verification:

```powershell
curl.exe -s http://127.0.0.1:3000/time
```

Output:

```json
{"unix":1783997770,"iso":"2026-07-14T05:56:10+03:00","hour_minute":"05:56","timezone":"Europe/Moscow","utc_offset":"+03:00"}
```

The response contains:

```text
unix
iso
hour_minute
timezone
utc_offset
```

The `iso` field uses `+03:00`, so it represents Moscow time rather than UTC.

---

## WASM artifact size

Command:

```bash
ls -lh main.wasm
wc -c main.wasm
```

Output:

```text
-rwxrwxrwx 1 root root 4.6M Jul 14 05:55 main.wasm
4818469 main.wasm
```

Artifact size:

```text
4,818,469 bytes
4.6 MB
```

---

## Task 1 design questions

### a) Browser WASM vs server WASM: `go build -o m.wasm -target=js/wasm` vs `tinygo build -target=wasip1`. What's missing in the server target, and what do you gain?

Browser WASM targets JavaScript and the browser runtime. It expects browser APIs, JavaScript glue code, and a JS event loop. It is designed to run inside a web page.

Server WASM targets WASI or wasi-http. It does not have access to browser APIs such as DOM, fetch, localStorage, or browser timers. Instead, it gets a small capability-based system interface from the host.

The gain is portability and sandboxing. A server-side WASM module can run in a small, isolated runtime without a full container filesystem or a Linux userspace. It starts quickly, has fewer privileges by default, and exposes only the capabilities the host grants.

In this lab, the current Spin 4 scaffold used `componentize-go` instead of TinyGo, but the same browser-vs-server distinction still applies: this component targets a server-side wasi-http host, not a browser.

### b) Why does the build command need `-buildmode=c-shared`?

For the older Spin 3 + TinyGo workflow, `-buildmode=c-shared` is needed because Spin expects the module to export functions in the shape required by the Spin HTTP host ABI. Without the correct export shape, the host cannot call the component as an HTTP handler.

In this Spin 4 scaffold, the generated build command is:

```text
go tool componentize-go build
```

This uses `componentize-go` to produce a WebAssembly component with the correct wasi-http interface. So the exact flag differs, but the underlying reason is the same: the module must export the interface the Spin host expects. A plain WASI CLI module with only `_start` would not be enough for Spin's HTTP trigger.

### c) `allowed_outbound_hosts = []` is the strictest setting. Explain the capability-based security model and compare it to Docker's `--network none`.

Spin uses a capability-based security model. A component only receives the capabilities declared in the manifest. With:

```toml
allowed_outbound_hosts = []
```

the component has no permission to make outbound network calls. The runtime denies that capability rather than relying on the application to behave.

Docker's `--network none` disables container networking at the Linux namespace level. It is effective, but it is broader and tied to the container's OS-level networking setup.

Spin's model is more fine-grained. Instead of saying "this container has or does not have networking," Spin can restrict outbound access to specific hosts. In this lab, the strictest setting is used: no outbound hosts.

### d) TinyGo stdlib gaps: which part of upstream Go's stdlib did you hit?

This run used the Spin 4 Go template with `componentize-go`, not TinyGo. However, the same WASM constraints showed up around time handling.

The endpoint avoids:

```go
time.LoadLocation("Europe/Moscow")
```

and instead uses:

```go
time.FixedZone("MSK", 3*60*60)
```

That avoids relying on embedded timezone data. The handler also formats JSON manually with `fmt.Sprintf` instead of using reflection-heavy dynamic structures such as `map[string]any`.

---

# Task 2 - Performance Comparison vs Lab 6 Docker

## Test rig

```text
Machine: Windows desktop with WSL2 Ubuntu
Spin runtime: Spin 4.0.2 on WSL
Go: go1.26.4 linux/amd64
Docker: Docker Desktop on Windows
WASM endpoint: http://127.0.0.1:3000/time
Docker endpoint: http://127.0.0.1:18080/health
Benchmark tool: hyperfine 1.18.0
```

Spin was run from WSL. Docker was built and run from Windows PowerShell because Docker Desktop was not integrated into the WSL distro.

---

## Docker baseline

Build command:

```powershell
docker build -t quicknotes:lab6 .\app
```

Run command:

```powershell
docker run -d --name qn-lab12-docker -p 18080:8080 quicknotes:lab6
```

Health check:

```powershell
curl.exe -s http://127.0.0.1:18080/health
```

Output:

```json
{"notes":0,"status":"ok"}
```

Docker image size:

```text
REPOSITORY   TAG       IMAGE ID                                                                  CREATED         SIZE
quicknotes   lab6      sha256:e3fd75a21416f0e37996c3c3c218bc41df229d7fb25f6ee1da75a9820e887e87   2 minutes ago   23.5MB
```

---

## Warm latency

Commands:

```bash
hyperfine --warmup 5 --runs 50 \
  --export-json reports/lab12/spin-warm.json \
  'curl -s -o /dev/null http://127.0.0.1:3000/time'

hyperfine --warmup 5 --runs 50 \
  --export-json reports/lab12/docker-warm.json \
  'curl -s -o /dev/null http://127.0.0.1:18080/health'
```

Hyperfine summary:

```text
Benchmark 1: curl -s -o /dev/null http://127.0.0.1:3000/time
  Time (mean ± σ):       6.5 ms ±   0.4 ms
  Range (min … max):     5.7 ms …   7.6 ms    50 runs

Benchmark 1: curl -s -o /dev/null http://127.0.0.1:18080/health
  Time (mean ± σ):       6.0 ms ±   0.7 ms
  Range (min … max):     5.2 ms …   7.8 ms    50 runs
```

Computed values:

```text
spin-warm:   p50=0.006451s p95=0.007229s mean=0.006527s
docker-warm: p50=0.005832s p95=0.007322s mean=0.006046s
```

---

## Cold-start samples

### Spin cold-start samples

Script started `spin up`, repeatedly curled `/time`, and recorded the time until the first successful response.

Samples:

```text
0.277534408
0.125822042
0.096302104
0.125284767
0.096735832
```

Sorted:

```text
0.096302104
0.096735832
0.125284767
0.125822042
0.277534408
```

Spin cold-start p50:

```text
0.125284767s
```

### Docker cold-start samples

PowerShell script repeatedly removed the container, started it, curled `/health`, and recorded time until the first successful response.

Samples:

```text
0.355959
0.318798
0.321260
0.308819
0.336151
```

Sorted:

```text
0.308819
0.318798
0.321260
0.336151
0.355959
```

Docker cold-start p50:

```text
0.321260s
```

---

## Performance table

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|---|---:|---:|
| Artifact size | 23.5 MB | 4.6 MB / 4,818,469 bytes |
| Cold start p50 | 0.321260 s | 0.125285 s |
| Warm latency p50 | 0.005832 s | 0.006451 s |
| Warm latency p95 | 0.007322 s | 0.007229 s |
| Warm latency mean | 0.006046 s | 0.006527 s |

In this run, the WASM artifact was much smaller and had faster cold-start p50. Warm latency was very similar; Docker was slightly faster at p50, while Spin was slightly better at p95.

---

## Task 2 design questions

### e) What dominates each platform's cold start?

For Docker, cold start includes container creation, namespace setup, mounting the filesystem, setting up port forwarding, starting the process, and waiting for the HTTP server to accept requests. If the image is not already pulled, image pull/extract time can dominate even more.

For Spin/WASM, cold start is dominated by starting Spin, loading the WASM component, instantiating it through Wasmtime, and wiring it into the wasi-http trigger.

In this measured run, Spin cold-start p50 was lower than Docker cold-start p50:

```text
Spin:   0.125285 s
Docker: 0.321260 s
```

### f) For what workloads is WASM clearly better, and where is Docker still right?

WASM is better for small, stateless, event-driven services where fast startup, small artifacts, and strong sandboxing matter. Examples include edge functions, small API endpoints, plugins, webhooks, and multi-tenant serverless code.

Docker is still better for larger applications that need a full Linux userspace, native libraries, background processes, mature debugging workflows, or broad compatibility with existing software. Full QuickNotes with persistent storage and normal deployment assumptions fits Docker better than a single small endpoint.

### g) Multi-tenant safety: what concrete attack does a WASM platform make harder?

WASM makes host escape and lateral movement harder because the module cannot freely access syscalls, the filesystem, or the network. It only receives explicit capabilities from the host.

A concrete example is server-side request forgery or data exfiltration. With `allowed_outbound_hosts = []`, even if the handler had a bug or malicious logic, it would not be allowed to make outbound HTTP calls to cloud metadata endpoints, internal services, or attacker-controlled servers.

WASM also reduces the attack surface compared with a full Linux container because there is no shell, package manager, or broad syscall surface inside the module.

---

# Bonus Task - Two WASM Execution Models

The bonus task was not attempted.

No standalone `wasm-cli/` WASI module was created, and no `wasmtime run` comparison was measured.

## Bonus design questions

Not answered because the bonus task was not attempted.

---

# Final status

Task 1 complete:

```text
Spin scaffold created in wasm/moscow-time
Spin SDK v3 used from current Spin 4 template
/time route configured
allowed_outbound_hosts = []
main.wasm builds successfully
/time returns Moscow time JSON
WASM size captured
Design questions a-d answered
```

Task 2 complete:

```text
Lab 6 Docker baseline rebuilt
Docker /health verified
Warm latency measured with hyperfine for both Spin and Docker
Cold-start samples collected for both Spin and Docker
Artifact sizes captured
Performance table completed
Design questions e-g answered
```

Bonus not attempted.