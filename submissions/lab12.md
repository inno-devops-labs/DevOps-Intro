# Lab 12 Submission - Bonus: WebAssembly Containers - A QuickNotes Endpoint on Spin

> **Test rig:** Fedora 43 (kernel 7.0.12), x86_64 · Go 1.25.11 · TinyGo 0.39.0 (LLVM 19.1.7) ·
> Spin 4.0.2 · spin-go-sdk **v2.2.1** · wasmtime 46.0.1 · Docker 29.6.0 · hyperfine 1.20.0

---

## Toolchain note (the lab's "tooling churn" warning, lived)

The lab was validated on **Spin 3.4** and documents a **TinyGo + `spin-go-sdk/v2` + `-target=wasip1 -buildmode=c-shared`** build. Scaffolding with the *current* template (`spin new -t http-go`, Spin **4.0.2**) generated something different again:

| Lab documents (Spin 3.4) | Spin 4.0.2 scaffold actually generated |
|---|---|
| SDK `spin-go-sdk/**v2**` | SDK **`spin-go-sdk/v3`** |
| `tinygo build -target=wasip1 -buildmode=c-shared` | **`go tool componentize-go build`** (standard Go, no TinyGo) |

I first followed the scaffold. It failed twice:

1. `Error: failed to read path for WIT [wit]` - fixed by `go mod download` (componentize-go discovers the WIT world by scanning module deps for `componentize-go.toml`; the SDK hadn't been fetched).
2. Then: `componentize-go` determined the SDK v3 `wasi-http` world uses **async features**, so it tried to download a **patched Go toolchain** (`go1.25.5-wasi-on-idle-v2`) - which timed out from this network, twice.

So I fell back to the **documented, supported path**: `spin-go-sdk/v2` + TinyGo (`wasip1` + `-buildmode=c-shared`). Spin 4 still runs wasip1 Spin modules, and this needs no patched toolchain.

---

## Task 1 - WASM Endpoint with the Spin SDK

### 1.1 `wasm/moscow-time/main.go`

```go
package main

import (
	"encoding/json"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

// Moscow has been UTC+3 year-round since Russia abolished DST in 2014, so a
// fixed offset is correct AND avoids depending on the IANA tz database, which
// does not exist inside the WASM sandbox (time.LoadLocation is a classic WASM
// footgun - see design question d).
var moscow = time.FixedZone("MSK", 3*60*60)

// A struct, not map[string]any: struct marshalling avoids the reflection-heavy
// paths TinyGo's encoding/json struggles with.
type timeResponse struct {
	Unix       int64  `json:"unix"`
	ISO        string `json:"iso"`
	HourMinute string `json:"hour_minute"`
	Zone       string `json:"zone"`
}

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		now := time.Now().In(moscow)
		resp := timeResponse{
			Unix:       now.Unix(),
			ISO:        now.Format(time.RFC3339),
			HourMinute: now.Format("15:04"),
			Zone:       "Europe/Moscow (UTC+3)",
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(resp)
	})
}

// main must exist for the compiler but is never executed: the Spin host invokes
// the handler registered in init() through the wasi-http component interface.
func main() {}
```

### 1.2 `wasm/moscow-time/spin.toml`

```toml
spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"

[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
# Least privilege: the component is granted NO outbound network capability.
allowed_outbound_hosts = []

[component.moscow-time.build]
# -buildmode=c-shared is REQUIRED: it makes TinyGo export the handler symbols
# the Spin host calls (see design question b).
command = "tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm ."
watch = ["**/*.go", "go.mod"]
```

### 1.3 Build + run

```text
$ spin build
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components

$ ls -lh main.wasm
-rwxr-xr-x. 1 mackay mackay 493K Jul 13 12:30 main.wasm

$ spin up
Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000/time
```

**493 KB** - against the Lab 6 Docker image's **23.6 MB**.

*(Build gotcha: TinyGo needs `wasm-opt` from Binaryen, which Fedora's `tinygo` package does not pull in - `sudo dnf install binaryen`.)*

### 1.4 It serves valid Moscow-time JSON

```text
$ curl -s http://127.0.0.1:3000/time | python3 -m json.tool
{
    "unix": 1783910563,
    "iso": "2026-07-13T05:42:43+03:00",
    "hour_minute": "05:42",
    "zone": "Europe/Moscow (UTC+3)"
}

$ curl -si http://127.0.0.1:3000/time | head -4
HTTP/1.1 200 OK
content-type: application/json
content-length: 107
date: Mon, 13 Jul 2026 02:42:43 GMT
```

`02:42 GMT` = `05:42 MSK` - the +03:00 offset is correct.

### 1.5 Design Questions

**a) Browser WASM (`go build -target=js/wasm`) vs server WASM (`tinygo build -target=wasip1`).**
`go build` for `js/wasm` produces a module that **only runs in a JavaScript host**: it needs the `wasm_exec.js` glue, reaches the outside world through `syscall/js`, and embeds the **full Go runtime** (GC, scheduler), typically several MB. It has no WASI imports, so no server runtime can execute it.

`tinygo -target=wasip1` produces a **WASI-compliant** module that imports the standard WASI ABI (`fd_write`, `clock_time_get`, `environ_get`, …). Any WASI host runs it, wasmtime, Spin, containerd shims, edge runtimes.

**What you lose on the server target:** the JS interop (`syscall/js`), the DOM, and a big slice of Go's runtime/stdlib that TinyGo doesn't implement (full `reflect`, cgo, `os/exec`, real sockets, the complete goroutine scheduler).
**What you gain:** a tiny artifact (our **493 KB** / **362 KB** vs multi-MB), a standard OS-agnostic ABI, a capability-based sandbox, and one binary that runs on any CPU architecture.

**b) Why does the build need `-buildmode=c-shared`?**
Because Spin doesn't want to *run a program* - it wants to **call a handler**. Without `-buildmode=c-shared`, TinyGo emits a WASI **command**: a module whose only entrypoint is `_start`, which runs `main()` to completion and exits. With it, TinyGo emits a **reactor**: `_initialize` (run once - this is where our `init()` registers the handler) plus the exported handler symbols the host invokes per request.

The `wasm-dis` dump of our two modules shows this precisely:

```text
Spin component exports:  _initialize
                         spin_http_handle_http_request
                         handle-http-request           <- what the host calls
                         (NO _start)

CLI module exports:      _start                        <- what wasmtime run calls
                         (no handler)
```

Omit `-buildmode=c-shared` and Spin loads a module with **no handler export** - it has nothing to call, hence the lab's documented symptom: HTTP 500 with empty component logs.

**c) `allowed_outbound_hosts = []` - the capability model vs Docker's `--network none`.**
WASM is **deny-by-default with no ambient authority**. A module can do *only* what the host explicitly **imports** into it. There is no `open()`, no socket API, no filesystem root - the module literally cannot *express* "connect to 1.2.3.4" unless the host hands it that capability. `allowed_outbound_hosts = []` grants zero outbound HTTP, so even if the code called an HTTP client, **there is no import to reach the network**. Enforcement happens at the **ABI boundary**, per component.

Docker's `--network none` is a **namespace subtraction**: the container is still a full Linux process with the entire syscall surface available; you've merely given it an empty network namespace. The kernel is still right there, and a kernel bug or a stray capability can undo it.

The difference is architectural: Docker is **subtractive** (start from a whole OS, take things away); WASM is **additive** (start from nothing, grant only what's needed). WASM's attack surface is smaller because there are no syscalls to abuse in the first place.

**d) TinyGo stdlib gaps hit in this lab.**
Two, both designed around deliberately:

1. **Timezone data.** `time.LoadLocation("Europe/Moscow")` needs the IANA tz database on disk (`/usr/share/zoneinfo`) - which does not exist in the WASM sandbox, where the filesystem is capability-gated and empty by default. Used `time.FixedZone("MSK", 3*60*60)` instead (correct: Moscow is UTC+3 year-round since 2014).
2. **Reflection-heavy JSON.** TinyGo implements only a subset of `reflect`, so `json.Marshal(map[string]any{...})` is fragile. Used a **tagged struct**, which marshals through a much simpler path - it compiled and ran cleanly.

More broadly TinyGo omits cgo, `os/exec`, real sockets under wasip1, parts of `reflect`, and the full goroutine scheduler. That's the price of a 493 KB artifact instead of a multi-MB one.

*(Third gap, at the toolchain level: Spin 4's default `componentize-go` path uses **standard Go** and would have side-stepped TinyGo's limits entirely - but it required a patched Go toolchain we could not download. See the toolchain note above.)*

---

## Task 2 - Perf Comparison vs the Lab 6 Container

### 2.1 The table

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin | Winner |
|-----------|-------------:|-----------------:|--------|
| Artifact size | 23.6 MB (5.8 MB content) | **493 KB** | **WASM ~48x smaller** |
| Cold start (median of 5) | 314 ms | **64 ms** | **WASM ~4.9x faster** |
| Warm latency p50 | **8.09 ms** | 8.49 ms | tie |
| Warm latency p95 | **9.32 ms** | 11.62 ms | tie |

### 2.2 Raw measurements

**Warm** - `hyperfine -N --warmup 5 --runs 50` (p50/p95 computed from the exported samples):

```text
Benchmark 1: WASM-Spin /time
  Time (mean ± σ):       8.7 ms ±   1.6 ms    Range: 5.9 ms … 14.9 ms   50 runs
Benchmark 2: Docker /health
  Time (mean ± σ):       7.8 ms ±   1.2 ms    Range: 5.1 ms …  9.9 ms   50 runs

WASM-Spin /time    p50=  8.49 ms   p95= 11.62 ms
Docker /health     p50=  8.09 ms   p95=  9.32 ms
```

> **Honest caveat:** hyperfine times the whole **`curl` process**, and it warned that the
> commands complete in under 5 ms. Both figures are therefore dominated by **client process
> spawn (~8 ms)**, not by the servers, both of which answer in well under a millisecond over
> loopback. The warm comparison is a **tie**, and the correct conclusion is that
> **WASM's advantage is not warm latency.**

**Cold start** - kill the runtime, restart, time to first successful response (5 samples):

```text
=== Spin (WASM) cold starts ===        === Docker (Lab 6) cold starts ===
spin cold #1: 57 ms                    docker cold #1: 320 ms
spin cold #2: 64 ms                    docker cold #2: 314 ms
spin cold #3: 66 ms                    docker cold #3: 298 ms
spin cold #4: 73 ms                    docker cold #4: 311 ms
spin cold #5: 64 ms                    docker cold #5: 318 ms
median: 64 ms                          median: 314 ms
```

### 2.3 Design Questions

**e) What dominates each platform's cold start?**
- **Docker (314 ms):** the **container lifecycle**, not the program. `docker run` must create the container, set up namespaces (pid/net/mnt/uts/ipc), configure cgroups, mount the image layers (overlayfs), create the veth pair and the iptables/NAT rules for the published port, and only then exec the process - which still has to start the Go runtime and bind a socket. The OS and network plumbing dominates; the actual Go binary starts in single-digit ms.
- **Spin (64 ms):** launching the **host**: process start, wasmtime engine init, reading the manifest, loading and JIT-compiling the 493 KB module, binding the listener. No namespaces, no overlayfs, no veth.

**The crucial nuance:** 64 ms is the cost of booting the *host*, **not** of instantiating the module. Once Spin is up, it instantiates a **fresh WASM instance per request in microseconds** - *that* is the "~1 ms cold start" the reading cites, and it's what makes edge platforms viable. Our per-invocation `wasmtime run` (**15.6 ms**, Bonus) is the closest thing we measured to a true per-request cold start, and even that is dominated by **process** spawn rather than WASM instantiation.

**f) Where is WASM clearly better, and where is Docker still right?**

**WASM wins:**
- **Edge / high fan-out** - per-request instantiation in microseconds means cold start never reaches the user (Cloudflare Workers, Fastly Compute).
- **Multi-tenant plugin systems** - run untrusted third-party code under a capability sandbox.
- **Spiky, scale-to-zero traffic** - no cold-start penalty to amortise.
- **CPU portability** - one artifact for amd64 / arm64 / RISC-V.
- **Size-sensitive distribution** - 493 KB vs 23.6 MB matters at the edge and on IoT.

**Docker still right:**
- **Long-running stateful services** - like QuickNotes itself: a persistent process with a file-backed store.
- **Anything needing a real OS** - arbitrary syscalls, `apt install`, shelling out, running existing binaries.
- **Rich library ecosystems**, above all **database drivers** - most don't work under WASI yet.
- **Mature operations** - debuggers, profilers, registries, Kubernetes: everything already speaks container. *Our own two-detour toolchain fight in this lab is the honest price of WASM's immaturity.*

Our numbers make the boundary concrete: warm throughput was a **tie**, so for a warm, long-lived service WASM buys **nothing** on latency - only size and boot time. Choose it when *those* are what hurt.

**g) Multi-tenant safety: what concrete attack does WASM make harder?**
**Container escape through the shared kernel.** Containers are just processes sharing one kernel, and their attack surface is the **entire syscall interface** (~350 syscalls). A kernel bug reachable from a syscall, Dirty COW (CVE-2016-5195), Dirty Pipe (CVE-2022-0847), or any unpatched io_uring flaw, lets a tenant escalate out of its namespace and reach the host or a neighbouring tenant.

A WASM module has **no syscall interface at all**. It can invoke only the functions the host explicitly imported; there is no `open()`, `ioctl()`, or `mmap()` to attack. Escaping requires a bug in the wasmtime runtime itself (a much smaller, memory-safe-Rust, heavily-audited surface) *and* in the specific capabilities granted. Linear memory is bounds-checked and never shared with the host, so classic memory-corruption escapes stay contained.

That's precisely why edge platforms happily run **thousands of mutually untrusted tenants in a single process** with WASM, and would never do so with containers.

---

## Bonus Task - Two WASM Execution Models

### B.1 The standalone WASI CLI module (`wasm/wasm-cli/`)

No Spin SDK, no HTTP server. CGI-shaped: the request arrives as **environment variables**, the response goes to **stdout**, and the process exits.

```go
func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")
	if method != "" && method != "GET" { fmt.Println("Status: 405 Method Not Allowed"); fmt.Println(); return }
	if path != "" && path != "/time"   { fmt.Println("Status: 404 Not Found");         fmt.Println(); return }

	now := time.Now().In(moscow)   // same time.FixedZone("MSK", 3*60*60)
	resp := timeResponse{ /* unix, iso, hour_minute, zone */ }

	fmt.Println("Content-Type: application/json")   // CGI: headers, blank line, body
	fmt.Println()
	_ = json.NewEncoder(os.Stdout).Encode(resp)
}
```

```text
$ tinygo build -o main.wasm -target=wasip1 -no-debug ./main.go
$ ls -lh main.wasm
-rwxr-xr-x. 1 mackay mackay 362K Jul 13 12:59 main.wasm

$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
Content-Type: application/json

{"unix":1783911591,"iso":"2026-07-13T05:59:51+03:00","hour_minute":"05:59","zone":"Europe/Moscow (UTC+3)"}
```

### B.2 The Spin component will NOT run under bare `wasmtime run`

```text
$ wasmtime run wasm/moscow-time/main.wasm ; echo "exit=$?"
exit=0
```

No output, no error - it simply **did nothing**. The exports explain why:

```text
Spin component:  _initialize, spin_http_handle_http_request, handle-http-request   (NO _start)
CLI module:      _start                                                            (no handler)
```

### B.3 Comparison

| | Spin component (`wasi-http`) | CLI module (`wasmtime run`) |
|--|------------------------------|------------------------------|
| Module size | 493 KB | **362 KB** |
| Module kind | **reactor** (`_initialize` + handler) | **command** (`_start`) |
| Startup cost | **64 ms once**, then ~0 per request | **15.6 ms per invocation** |
| Driven by | a long-lived wasi-http host | one `wasmtime run` process, then exit |
| Build flag | `-buildmode=c-shared` (required) | none (plain `_start`) |

Per-invocation cost, `hyperfine -N --runs 20`:
```text
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
  Time (mean ± σ):      15.6 ms ±   3.2 ms    Range: 10.4 ms … 23.1 ms   20 runs
```

### B.4 Design Questions

**h) Why can't the Task 1 Spin component run under bare `wasmtime run`?**
Because it is not a **command**, it is a **reactor**. `wasmtime run` looks for the WASI command entrypoint **`_start`** and executes it. Our `wasm-dis` dump shows the Spin component exports **`_initialize`, `spin_http_handle_http_request`, `handle-http-request`** and **no `_start`** - while the CLI module exports **`_start`** and no handler.

So wasmtime happily **loaded and initialised** the component and then had nothing to run - exactly what we observed: **exit code 0, zero output, not even an error**. To drive it you need a host that speaks wasi-http and calls `handle-http-request` per request: Spin, or `wasmtime serve`.

**i) Spin uses wasmtime internally - so what does Spin add?**
Spin embeds wasmtime and wraps an entire application platform around it:
- **A wasi-http server loop** - binds the socket, parses HTTP, and translates each request into a call to the component's exported handler.
- **A manifest + routing layer** (`spin.toml`) - named components, routes (`/time`), triggers (http/redis/cron).
- **Instance lifecycle management** - the module is compiled **once** at startup, then a **fresh instance per request** (isolation without paying process-spawn cost).
- **A capability/policy layer** - `allowed_outbound_hosts`, key-value and SQLite stores, secrets, granted declaratively per component.
- **Developer ergonomics** - `spin new` templates, `spin build`, `spin up`, structured logs, plugins, `spin deploy`.

Bare wasmtime is a runtime and a CLI; Spin is an application platform built on it.

**j) Two execution models - when does each fit?**
- **Per-invocation (`wasmtime run`, CGI-shaped):** the process starts, does exactly one job, exits. Fits **batch, CLI, scheduled, and one-shot untrusted work** - a cron job that transcodes an image, a CI step, a user-supplied data transform. You pay full startup **every** time (**15.6 ms** here), which is irrelevant at low rates and fatal at high ones. In exchange you get dead-simple semantics and perfect isolation between invocations (nothing survives).
- **Persistent wasi-http server (Spin):** pay startup **once** (**64 ms**), then serve requests with per-request instances created in microseconds. Fits **HTTP APIs, edge handlers, and high-request-rate services** - exactly our `/time` endpoint, and how Cloudflare/Fastly operate. The cost is a long-lived host process to run and operate.

**The request rate decides.** Below roughly one request per second, per-invocation is simpler and its startup cost doesn't matter. Above that, the persistent host wins by orders of magnitude: **15.6 ms of startup on every request, versus ~0**.
