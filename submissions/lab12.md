# Lab 12 Submission

## Task 1 - Build a WASM Endpoint with the Spin SDK

### Tool versions

Commands:

```bash
go version
tinygo version
spin --version
```

Output:

```text
go version go1.24.13 linux/amd64
tinygo version 0.41.1 linux/amd64 (using go version go1.24.13 and LLVM version 20.1.1)
spin 3.4.1 (3ab5404 2025-08-28)
```

### Implementation

#### `main.go`

Path: [`wasm/moscow-time/main.go`](../wasm/moscow-time/main.go)

```go
package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		if r.Method != http.MethodGet {
			w.Header().Set("Allow", http.MethodGet)
			w.WriteHeader(http.StatusMethodNotAllowed)
			fmt.Fprintln(w, `{"error":"method not allowed"}`)
			return
		}

		now := time.Now()
		moscow := now.UTC().Add(3 * time.Hour)
		iso := moscow.Format("2006-01-02T15:04:05") + "+03:00"

		fmt.Fprintf(
			w,
			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q}\n",
			now.Unix(),
			iso,
			moscow.Format("15:04"),
		)
	})
}
```

The handler registers through `spinhttp.Handle`, accepts `GET` requests, and
returns the current Moscow time as JSON. Other HTTP methods receive a `405
Method Not Allowed` response.

#### `spin.toml`

Path: [`wasm/moscow-time/spin.toml`](../wasm/moscow-time/spin.toml)

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["MostafaKhaled2017 <m.kira@innopolis.university>"]
description = ""

[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []
[component.moscow-time.build]
command = "tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm ."
watch = ["**/*.go", "go.mod"]
```

The manifest exposes only `/time`, grants no outbound network hosts, and keeps
the scaffolded TinyGo `wasip1` and `c-shared` build configuration.

### Build and artifact size

Command:

```bash
spin build
```

Output:

```text
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components
```

Commands:

```bash
ls -lh main.wasm
stat -c '%n: %s bytes' main.wasm
```

Output:

```text
-rw-rw-r-- 1 mostafa nix-users 354K Jul 15 13:28 main.wasm
main.wasm: 361854 bytes
```

The generated WebAssembly component is 361,854 bytes (approximately 354 KiB).

### Runtime verification

The application was started with:

```bash
spin up
```

Relevant output:

```text
Logging component stdio to ".spin/logs/"

Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000/time
```

Command:

```bash
curl -i http://127.0.0.1:3000/time
```

Output:

```text
HTTP/1.1 200 OK
content-type: application/json
content-length: 76
date: Wed, 15 Jul 2026 10:30:09 GMT

{"unix":1784111409,"iso":"2026-07-15T13:30:09+03:00","hour_minute":"13:30"}
```

The response is valid JSON. The HTTP date is `10:30:09 GMT`, while the returned
Moscow timestamp is `13:30:09+03:00`, confirming the UTC+3 offset.

Pretty-printed response:

```bash
curl -sS http://127.0.0.1:3000/time | python3 -m json.tool
```

```json
{
    "unix": 1784111420,
    "iso": "2026-07-15T13:30:20+03:00",
    "hour_minute": "13:30"
}
```

Non-GET requests are rejected:

```bash
curl -i -X POST http://127.0.0.1:3000/time
```

```text
HTTP/1.1 405 Method Not Allowed
allow: GET
content-type: application/json
content-length: 31
date: Wed, 15 Jul 2026 10:30:28 GMT

{"error":"method not allowed"}
```

### Design question a: Browser WASM versus server WASM

A `js/wasm` build targets a JavaScript host and relies on JavaScript glue and
browser-provided APIs. A server-side `wasip1` module does not have browser
objects such as the DOM, `window`, or other Web APIs.

In return, the WASI target gains a portable system interface designed for WASM
runtimes outside the browser. The host controls which system capabilities are
available, so the same component can run in a server-side WASI host without a
browser or JavaScript runtime.

### Design question b: Why is `-buildmode=c-shared` required?

The default WASI command model provides a `_start` entry point, runs once, and
then exits. Spin needs a reusable component whose HTTP handler can be invoked
for multiple requests.

With `-buildmode=c-shared`, TinyGo builds a reactor/library-style module with an
initialization export rather than a one-shot command. This allows the Spin host
to initialize the Go runtime and invoke the handler export registered by the
Spin SDK. Without this build mode, the module does not provide the execution
model and exports expected by the Spin HTTP host.

### Design question c: Capability-based security

WASM components can only use host capabilities explicitly granted to them. The
setting `allowed_outbound_hosts = []` grants this component no permission to
make outbound network requests. Code inside the component cannot obtain that
capability if the host does not expose it.

Docker's `--network none` places a container in a network namespace without an
external network interface, which also blocks normal outbound traffic. The
difference is the isolation boundary: Docker still exposes a Linux process and
a filtered set of kernel system calls, filesystems, namespaces, and
capabilities. A WASM component instead interacts with the host through a much
narrower set of imported interfaces. Both configurations deny outbound
networking, but WASM expresses the permission directly as an absent host
capability.

### Design question d: TinyGo standard-library gaps

The relevant TinyGo limitation is incomplete support for parts of the upstream
Go standard library that depend on runtime data or reflection. In particular,
WASI builds do not normally include the IANA time-zone database needed by
`time.LoadLocation("Europe/Moscow")`. Reflection-heavy JSON encoding, such as
encoding a `map[string]any`, can also encounter TinyGo limitations.

The final handler avoids both problem areas. It calculates Moscow time from UTC
using the fixed UTC+3 offset and constructs the small JSON object with formatted
output rather than reflection over `map[string]any`. The earlier
`internal/stringslite` build failure was a separate Go/TinyGo version mismatch,
not one of these standard-library limitations; using Go 1.24.13 with TinyGo
0.41.1 resolved it.

## Task 2 - Performance Comparison with the Lab 6 Container

### Test rig

The measurements were collected on the following system:

```text
Date: 2026-07-15T13:54:32+03:00
OS: Ubuntu 24.04.2 LTS
Kernel: Linux 6.17.0-1011-oem x86_64
Architecture: x86_64
CPU: 13th Gen Intel(R) Core(TM) i7-13700H
Logical CPUs: 20
Memory: 15 GiB
Docker: 29.3.0, build 5927d80
Spin: 3.4.1 (3ab5404 2025-08-28)
TinyGo: 0.41.1, using Go 1.24.13 and LLVM 20.1.1
Hyperfine: 1.18.0
```

### Measurement method

Both artifacts were built before measurements began, so compilation, image
building, and image pulling were excluded. Both services were tested over the
IPv4 loopback interface on the same machine. The endpoints were the ones
required by the lab: `/time` for Spin and `/health` for Docker.

Warm latency was measured with five warmup runs followed by 50 measured runs.
Each Hyperfine sample launched `curl`, so the reported duration includes curl
process startup as well as HTTP request processing. This overhead is present in
both measurements.

Cold start was measured ten times per platform. Each timer started immediately
before starting the runtime and stopped after the first successful HTTP
response. The Docker daemon and local image remained available, but every
sample created a fresh container. Every Spin sample started a fresh `spin up`
process after confirming that port 3000 was free. Percentiles were calculated
from the individual samples using linear interpolation.

### Artifact size

Commands:

```bash
stat -c '%n: %s bytes' wasm/moscow-time/main.wasm
docker image inspect quicknotes:lab6 --format '{{.Size}}'
docker image ls quicknotes:lab6
```

Relevant output:

```text
wasm/moscow-time/main.wasm: 361854 bytes
13661397

IMAGE             ID             DISK USAGE
quicknotes:lab6   91a4553e2041       13.7MB
```

The raw WASM artifact is 361,854 bytes, or approximately 354 KiB. Docker reports
an exact image size of 13,661,397 bytes, or approximately 13.03 MiB. By these
reported sizes, the Docker image is approximately 37.75 times larger than the
WASM artifact.

### Warm latency

Spin command:

```bash
hyperfine \
    --warmup 5 \
    --runs 50 \
    --export-json /tmp/lab12-bench/spin-warm.json \
    'curl --fail --silent --show-error --output /dev/null http://127.0.0.1:3000/time'
```

Output:

```text
Benchmark 1: curl --fail --silent --show-error --output /dev/null http://127.0.0.1:3000/time
  Time (mean ± σ):      14.1 ms ±   3.0 ms    [User: 4.9 ms, System: 6.4 ms]
  Range (min … max):    10.4 ms …  23.7 ms    50 runs
```

Docker command:

```bash
hyperfine \
    --warmup 5 \
    --runs 50 \
    --export-json /tmp/lab12-bench/docker-warm.json \
    'curl --fail --silent --show-error --output /dev/null http://127.0.0.1:8080/health'
```

Output:

```text
Benchmark 1: curl --fail --silent --show-error --output /dev/null http://127.0.0.1:8080/health
  Time (mean ± σ):      11.8 ms ±   1.9 ms    [User: 4.4 ms, System: 6.4 ms]
  Range (min … max):     8.7 ms …  16.0 ms    50 runs
```

Calculated warm percentiles:

```text
spin-warm: p50=13.445 ms, p95=19.965 ms
docker-warm: p50=11.545 ms, p95=15.472 ms
```

Docker was slightly faster in this warm test. This result includes the cost of
launching curl for every sample and compares two different endpoint
implementations, as specified by the lab, rather than isolating only runtime
overhead.

### Cold start

The ten valid cold-start samples were:

| Sample | Spin | Docker |
| ---: | ---: | ---: |
| 1 | 90.965 ms | 328.881 ms |
| 2 | 183.817 ms | 328.589 ms |
| 3 | 83.279 ms | 333.406 ms |
| 4 | 90.316 ms | 352.305 ms |
| 5 | 100.501 ms | 335.688 ms |
| 6 | 100.380 ms | 320.642 ms |
| 7 | 102.018 ms | 366.090 ms |
| 8 | 107.735 ms | 367.177 ms |
| 9 | 115.000 ms | 399.880 ms |
| 10 | 96.188 ms | 374.382 ms |

Calculated cold-start percentiles:

```text
spin-cold-ms: samples=10, p50=100.441 ms, p95=152.849 ms
docker-cold-ms: samples=10, p50=343.996 ms, p95=388.406 ms
```

Spin's measured median cold start was approximately 3.42 times faster than the
Docker container's median cold start. All samples were retained, including the
183.817 ms Spin sample, because no measurement failure was observed.

### Performance results

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
| --- | ---: | ---: |
| Artifact size | 13,661,397 bytes / 13.03 MiB | 361,854 bytes / 354 KiB |
| Cold start (p50) | 343.996 ms | 100.441 ms |
| Warm latency p50 | 11.545 ms | 13.445 ms |
| Warm latency p95 | 15.472 ms | 19.965 ms |

### Design question e: What dominates each platform's cold start?

For Docker, the local image was already built and available, so pulling and
building did not contribute to the measured time. The measured startup includes
creating the container, preparing its overlay filesystem, configuring
namespaces and cgroups, launching the process, initializing the Go runtime,
seeding the QuickNotes data file, and reaching the first successful health
response. Image download and layer decompression would add further delay on a
host where the image was not already present.

For Spin, the measurement includes launching the Spin process, reading the
manifest and route configuration, binding the HTTP listener, initializing the
Wasmtime engine, loading or finding compiled code for the WASM module,
instantiating the component, and handling the first wasi-http request. It does
not include compiling the Go source into `main.wasm`, because `spin build` was
completed before benchmarking.

In these measurements, Spin's smaller module and lighter instance model produced
a 100.441 ms median cold start, compared with 343.996 ms for Docker. The result
measures the complete local `spin up` path, not only raw Wasmtime instantiation.

### Design question f: Where is WASM better, and where is Docker still right?

WASM is a strong fit for short, stateless request handlers, edge functions,
untrusted plugins, multi-tenant request execution, IoT workloads, and bursty
services where cold-start latency and artifact size matter. Its portable bytecode
and capability-oriented host interface also make it useful when the same small
component must run safely across different CPU architectures.

Docker remains the better fit for long-running or stateful applications,
services that require arbitrary Linux system calls, Cgo or native libraries,
heavy database clients, multiple cooperating processes, OS packages, or mature
container debugging and operational tooling. Containers can package almost any
Linux application, while WASI and TinyGo still have library, syscall, reflection,
and debugging limitations.

### Design question g: Multi-tenant safety

Consider a malicious tenant attempting to inspect another process with
`ptrace`, mount a filesystem, issue a dangerous `ioctl`, or open a host resource
such as `/etc/shadow` or the Docker socket. A WASM component cannot directly
make arbitrary Linux system calls. It can only invoke interfaces explicitly
provided by its host. If filesystem, process, or network access was not granted,
the corresponding operation is unavailable to the component.

A container can restrict the same behavior through namespaces, capability
drops, mount rules, and seccomp, but the containerized process still interacts
with the shared host kernel. A kernel or container-runtime vulnerability can
therefore expose a broader attack surface. WASM makes this class of attack
harder by placing the tenant behind a smaller capability-based host interface,
although vulnerabilities in the WASM runtime or explicitly granted host
functions remain possible.
