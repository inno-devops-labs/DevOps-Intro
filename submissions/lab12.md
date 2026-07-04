# Lab 12 - A QuickNotes Endpoint as a WebAssembly Component on Spin

Test rig for every number below: MacBook Pro (Apple M4, 24 GB RAM),
macOS 26.5.2, Docker Desktop / Docker 29.2.1. Pinned tool versions:

| Tool | Version |
|---|---|
| Spin | 3.6.3 (88d51cf 2026-04-09) |
| TinyGo | 0.41.1 (using go 1.26.4, LLVM 20.1.1) |
| Spin Go SDK | github.com/spinframework/spin-go-sdk/v2 v2.2.1 |
| wasmtime | 46.0.1 |
| hyperfine | 1.20.0 |

The lab was validated upstream with Spin 3.4 + TinyGo 0.41; this run uses
the newest 3.x Spin (the prerequisites say Spin 3.x, so 4.0.2 was
deliberately skipped) and the exact TinyGo minor the lab names.

---

## Task 1 - WASM endpoint with the Spin SDK

### 1.1 Scaffold

Scaffolded exactly as instructed, no hand-written manifest:

```console
$ spin new -t http-go moscow-time --accept-defaults
```

The generated project already had the current SDK import
(`github.com/spinframework/spin-go-sdk/v2`), the `wasip1` +
`-buildmode=c-shared` build command, and `allowed_outbound_hosts = []` as
the default. The files were moved into `wasm/` to match the submission
layout, and only two things were edited: the handler body and the route.

### 1.2 `wasm/main.go`

```go
package main

import (
    "encoding/json"
    "net/http"
    "time"

    spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

// Fixed offset because time.LoadLocation needs tzdata, which TinyGo lacks.
var moscow = time.FixedZone("MSK", 3*60*60)

type timeResponse struct {
    Unix       int64  `json:"unix"`
    ISO        string `json:"iso"`
    HourMinute string `json:"hour_minute"`
    Timezone   string `json:"timezone"`
}

func init() {
    spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
        if r.Method != http.MethodGet {
            http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
            return
        }
        now := time.Now().In(moscow)
        body, err := json.Marshal(timeResponse{
            Unix:       now.Unix(),
            ISO:        now.Format(time.RFC3339),
            HourMinute: now.Format("15:04"),
            Timezone:   "MSK (UTC+3)",
        })
        if err != nil {
            http.Error(w, "encode failed", http.StatusInternalServerError)
            return
        }
        w.Header().Set("Content-Type", "application/json")
        w.Write(body)
    })
}
```

### 1.3 `wasm/spin.toml`

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["Aleksandr <55945487+Dekart-hub@users.noreply.github.com>"]
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

Route scoped to `/time` (not the scaffold's `/...`), no outbound network.

### 1.4 Build and verify

```console
$ spin build
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components
$ ls -l main.wasm
-rw-r--r-- 531468 main.wasm          # 0.53 MB

$ spin up
Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000/time

$ curl -si http://127.0.0.1:3000/time
HTTP/1.1 200 OK
content-type: application/json

{"unix":1783161043,"iso":"2026-07-04T13:30:43+03:00","hour_minute":"13:30","timezone":"MSK (UTC+3)"}
```

`python3 -m json.tool` parses it, the offset is +03:00, and the epoch
matches the ISO instant. A POST gets 405; a path outside the route
(`/health`) gets 404 from Spin's router without ever reaching the
component.

### 1.5 Design questions

**a) Browser WASM (`go build -target=js/wasm`) vs server WASM
(`tinygo build -target=wasip1`).**
The js/wasm target produces a module whose every interaction with the
world goes through JavaScript glue (`wasm_exec.js`): syscalls are faked
by the JS host, so the artifact only runs where a JS engine hosts it. It
ships the full Go runtime, so it is large (MBs) but supports the whole
stdlib. The wasip1 target instead imports the standardized WASI
interface (`wasi_snapshot_preview1`): stdio, clocks, environment,
pre-opened directories come from any WASI runtime - wasmtime, Spin,
containerd shims - with no JS anywhere. What is missing in the server
target: the browser/JS bridge and chunks of stdlib that TinyGo strips
(question d). What is gained: a small, portable, capability-sandboxed
binary that a server host can run - which is the entire point here.

**b) Why `-buildmode=c-shared`?**
The Spin host does not run the module like a program; it calls an
exported handler function per request. `-buildmode=c-shared` makes
TinyGo emit a reactor-style library: no `_start` entrypoint, an
`_initialize` export that runs the `init()` functions (registering the
handler with the SDK), and the SDK's exported entry that the host calls.
Measured both failure shapes on this toolchain. First, the scaffold has
no `func main()` at all, so dropping the flag does not even link:

```text
wasm-ld: error: lto.tmp: undefined symbol: main.main
```

Second, adding a stub `func main() {}` and building without the flag
produces a command module - on this exact Spin 3.6.3 + SDK v2.2.1 combo
it still served (the SDK exports the handler symbol either way and Spin
componentizes core modules at load), but that is incidental
compatibility, not the contract; the lab's documented symptom for other
combos is a 500 with empty logs. The scaffold's build command is the
supported shape, which is why the lab says not to change it.

**c) `allowed_outbound_hosts = []` vs Docker's `--network none`.**
The WASM capability model is deny-by-default at the API boundary: the
component can only perform an action if the host hands it that
capability, and outbound HTTP is granted per named host in the manifest.
An empty list means the component cannot open any outbound connection -
there is no socket API to abuse, so SSRF from a compromised handler dies
in the host function. `--network none` is coarser: it is an all-or-
nothing kernel namespace switch for the whole container. The moment the
app needs one API endpoint you must give it a network interface and then
bolt on egress firewalls to narrow it again. Spin expresses "this
component may talk to api.example.com and nothing else" in one manifest
line, per component, enforced above the kernel rather than by it.

**d) TinyGo stdlib gaps hit in this lab.**
One hit for real: time-zone data. `time.LoadLocation("Europe/Moscow")`
needs the tzdata database that TinyGo does not embed, hence
`time.FixedZone("MSK", 3*60*60)` (Moscow has no DST since 2014, so a
fixed offset is faithful). The other famous gap - reflection-heavy
`encoding/json` - did not bite: marshalling a flat struct with tags
works fine on TinyGo 0.41; the pitfall belongs to `map[string]any`
payloads, which this handler avoids by design.

---

## Task 2 - Perf comparison vs the Lab 6 container

Both runtimes served their endpoint on loopback; the container is the
kept `quicknotes:lab6` image (distroless, healthcheck probe) from the
Lab 6 build. Two latency instruments were used: curl's own
`%{time_total}` (in-process, no fork overhead - the fair number) and
hyperfine (which times a whole `curl` process spawn per run and warns
below 5 ms; reported for completeness).

- Warm: 50 requests per target after 5 warmups.
- Cold: 5 samples each, timing runtime launch to first HTTP 200
  (1 ms polling), image/module already local.

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|---|---:|---:|
| Artifact size | 21.6 MB unpacked (5.3 MB compressed) | 0.53 MB (`main.wasm`) |
| Cold start (p50 of 5) | 121.2 ms | 57.0 ms |
| Warm latency p50 (curl time_total) | 1.87 ms | 0.59 ms |
| Warm latency p95 (curl time_total) | 2.37 ms | 0.75 ms |
| Warm p50 / p95 (hyperfine, incl. curl spawn) | 7.2 / 9.0 ms | 5.1 / 6.4 ms |

Cold-start samples: Docker 174.5 / 115.9 / 121.2 / 114.3 / 130.1 ms;
Spin 34.2 / 57.0 / 48.4 / 57.9 / 57.1 ms.

The WASM artifact is roughly 41x smaller, cold start is about 2x faster
even with the whole `spin` CLI boot in the measurement, and warm
latency is about 3x lower - on macOS the container path also pays the
Docker Desktop VM port-forward hop, which is part of honest local
numbers.

### Design questions

**e) What dominates each cold start?**
Docker (121 ms median here, image already local): the `docker` CLI to
daemon round trip, containerd materializing the layer snapshot, network
namespace plus port-forward plumbing (via the Desktop VM on macOS), and
runc spawning the process; the Go binary itself then boots in
single-digit ms. Spin (57 ms): the `spin` CLI process boot, manifest
parse, wasmtime engine setup and loading the precompiled 0.53 MB module,
then binding the listener. Neither number contains image pulls or
compiles; a cold pull would add seconds to Docker specifically. And the
number that actually sells Spin is not in this table: once the server is
up, each request gets a fresh instance in well under a millisecond
(0.59 ms p50 includes the full HTTP round trip).

**f) Where is WASM clearly better; where does Docker stay right?**
WASM wins where cold starts and density decide the product: edge
functions at hundreds of POPs, scale-to-zero per-request platforms,
untrusted plugin systems, multi-tenant SaaS handlers - tiny artifact,
ms-level start, per-tenant sandbox. Docker stays right for the rest of
this course's stack: QuickNotes itself (a persistent process with a
data file, full stdlib, Prometheus client), databases, anything wanting
arbitrary Linux dependencies, mature debugging and ops tooling. The
honest split from Reading 12 holds in our numbers: the WASM endpoint is
one function; the container is the whole service.

**g) What concrete attack does a WASM platform make harder?**
Container isolation is the Linux kernel's syscall surface behind
namespaces: a compromised tenant can still issue syscalls, and every
kernel LPE or namespace-escape bug (dirty-pipe class, /proc tricks,
leaky mounts) is one exploit away from the neighbors. A WASM tenant has
no syscalls at all - only the host functions it was granted. Concretely:
an attacker who fully controls our component still cannot open an
outbound socket (empty `allowed_outbound_hosts`), read another tenant's
files (no filesystem capability), or attack the shared kernel directly
(no syscall reaches it unmediated). SSRF, lateral movement, and
kernel-exploit pivoting all lose their entry point by construction.

---

## Bonus - Two WASM execution models

### B.1 The standalone WASI CLI module

`wasm-cli/main.go` reimplements the same Moscow-time logic with no Spin
SDK, in the WAGI/CGI shape: request metadata from environment variables,
response (header block, blank line, body) to stdout:

```go
func main() {
    if os.Getenv("REQUEST_METHOD") != "GET" || os.Getenv("PATH_INFO") != "/time" {
        fmt.Println("Status: 404 Not Found")
        fmt.Println()
        os.Exit(1)
    }
    now := time.Now().In(moscow)
    body, err := json.Marshal(timeResponse{ ... })
    ...
    fmt.Println("Content-Type: application/json")
    fmt.Println()
    fmt.Println(string(body))
}
```

Build and run (TinyGo 0.41 spells the target `wasip1`; the older alias
`wasi` from the lab text was renamed):

```console
$ tinygo build -o main.wasm -target=wasip1 -no-debug .
$ ls -l main.wasm
-rw-r--r-- 381879 main.wasm          # 0.37 MB

$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
Content-Type: application/json

{"unix":1783161281,"iso":"2026-07-04T13:34:41+03:00","hour_minute":"13:34","timezone":"MSK (UTC+3)"}

$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/notes main.wasm
Status: 404 Not Found
$ echo $?
1
```

### B.2 The comparison

| | Spin component (`wasm/`) | CLI module (`wasm-cli/`) |
|---|---:|---:|
| Module size | 531,468 B | 381,879 B |
| Execution model | persistent wasi-http server, instance per request | one OS process + instance per invocation |
| Cost per request | 0.59 ms p50 (server warm) | 6.0 ms p50 / 7.0 ms p95 (hyperfine, 50 runs) |
| One-time server boot | 57 ms | none |

The CLI module is ~28% smaller (no SDK, no router, no wasi-http
adapter). Per invocation it pays the full wasmtime process + module
instantiation every time - 6 ms - where the persistent Spin server
amortizes that into a one-time 57 ms boot and then serves in 0.59 ms.
Break-even after about a dozen requests; beyond that the server model
wins by an order of magnitude.

### B.3 Design questions

**h) Why can't the Task 1 Spin component run under bare
`wasmtime run`?**
Because it exports no `_start` program entrypoint - it is a reactor
that exports `_initialize` plus the handler entry the wasi-http host
calls. Both probes are in this repo's logs: `wasmtime run wasm/main.wasm`
exits 0 in silence (wasmtime runs `_initialize`, the `init()` registers
the handler into module memory, and then nothing ever calls it - there
is no HTTP host), and `wasmtime serve wasm/main.wasm` refuses with
"Error: The serve command currently requires a component" - TinyGo
emits a core module, and it is Spin that wraps it with the wasi-http
adapter and componentizes it at load time.

**i) Spin uses wasmtime internally - what does it add?**
Everything between a raw execution engine and a platform: the wasi-http
server loop and trigger routing from `spin.toml` (the 404 for `/health`
came from Spin's router, not our code), the componentization/adapter
step that makes a TinyGo core module a wasi-http citizen, per-component
capability policy like `allowed_outbound_hosts`, instance pooling and
pre-instantiation that turn per-request isolation into a sub-ms cost,
and the developer loop (`spin new/build/watch/up`, templates pinned to
the current SDK). Bare wasmtime executes a module; Spin operates it.

**j) When does each execution model fit?**
Per-invocation `wasmtime run` is CGI reborn: right when invocations are
rare, isolation per run matters more than latency, and a process
boundary is the natural unit - a cron-style report generator, a CI
plugin step, running one untrusted data-transform per uploaded file.
The persistent wasi-http server fits request-serving APIs where the
6 ms per-hit tax is unacceptable and throughput is steady - exactly a
`/time`-style public endpoint, which at 0.59 ms p50 handled from a
warm server is 10x cheaper per request than its CLI twin.
