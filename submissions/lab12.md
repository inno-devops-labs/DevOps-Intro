# Lab 12 — Bonus: WebAssembly Containers — A QuickNotes Endpoint on Spin

> Every command output, size, JSON body, and latency number below was produced
> on real tooling — nothing is invented. Because the host is Windows and the
> WASM toolchain (TinyGo/Spin/wasmtime) targets Linux, all builds and
> measurements were run inside Linux containers on the same physical machine.
> The test rig is documented in the Task 2 section.

## Toolchain (pinned)

| Tool | Version |
|------|---------|
| TinyGo | 0.41.0 (using Go 1.26.2, LLVM 20.1.1) |
| Spin | 3.4.0 (`4f671be`, 2025-08-26) |
| wasmtime | 46.0.1 (bonus runtime) |
| hyperfine | 1.20.0 (benchmarking) |
| Spin Go SDK | `github.com/spinframework/spin-go-sdk/v2 v2.2.1` |

---

## Task 1 — Build a WASM Endpoint with the Spin SDK

Scaffolded with `spin new -t http-go moscow-time --accept-defaults` (template
installed from the CNCF `spinframework/spin` repo). The scaffold generated the
current SDK import path and the `-buildmode=c-shared` build command — I only
edited `main.go` and set the route to `/time`.

### main.go

```go
package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

// Moscow is UTC+3 year-round (no DST since 2014). TinyGo ships no tzdata, so a
// fixed zone is used instead of time.LoadLocation("Europe/Moscow").
func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		msk := time.FixedZone("MSK", 3*60*60)
		now := time.Now().In(msk)

		// Built with fmt.Sprintf + %q rather than encoding/json: TinyGo's
		// reflection-based json marshalling of map[string]any is unreliable.
		body := fmt.Sprintf(
			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":%q,\"utc_offset\":%q}\n",
			now.Unix(),
			now.Format(time.RFC3339),
			now.Format("15:04"),
			"Europe/Moscow",
			"+03:00",
		)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, body)
	})
}
```

### spin.toml

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
allowed_outbound_hosts = []
[component.moscow-time.build]
command = "tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm ."
watch = ["**/*.go", "go.mod"]
```

### `spin build` output

```
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components
```

Artifact: `main.wasm` = **370,475 bytes (362 KB)**.

### `spin up` + curl /time

```
Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000/time
```

```
$ curl -s -D - http://127.0.0.1:3000/time
HTTP/1.1 200 OK
content-type: application/json
content-length: 125
date: Wed, 15 Jul 2026 11:39:27 GMT

{"unix":1784115567,"iso":"2026-07-15T14:39:27+03:00","hour_minute":"14:39","timezone":"Europe/Moscow","utc_offset":"+03:00"}
```

Valid JSON, HTTP 200, `Content-Type: application/json`, Moscow time UTC+3
(14:39 MSK = 11:39 UTC, matching the `date` header).

### Design Questions

**a) Browser WASM (`-target=js/wasm`) vs server WASM (`tinygo build -target=wasip1`)**

`js/wasm` targets a JavaScript host: the module can only reach the outside world
through JS glue (`wasm_exec.js`) and browser APIs (DOM, `fetch`), it ships the
full Go runtime (multi-MB), and needs a JS engine to run. `wasip1` targets WASI:
a standalone module that any WASI host (Spin, wasmtime) runs with no JavaScript.
What's *missing* in the server target: DOM/JS interop and browser APIs, plus
TinyGo drops parts of Go's stdlib (full reflection, tzdata, some of `net`). What
you *gain*: a tiny artifact (362 KB here), a capability sandbox, fast cold start,
and host-agnostic portability with no JS runtime.

**b) Why `-buildmode=c-shared`?**

Spin's host does not call a `_start` main — it expects the module to *export* a
handler (the "reactor" model) that Spin invokes per request. `-buildmode=c-shared`
produces a reactor module: it runs `init()` (via `_initialize`) to register the
handler with `spinhttp.Handle` and exports the entry symbol, rather than a
command module that runs `main` once and exits. Remove it and TinyGo builds a
`_start` command; Spin can't find the exported handler and returns HTTP 500 with
empty component logs. I observed the mirror image of this: the c-shared component
under bare `wasmtime run` produces *no* output (exit 0) precisely because it has
no command entrypoint — it only exports a handler for a host to call.

**c) `allowed_outbound_hosts = []` vs Docker `--network none`**

Spin is capability-based: the guest starts with *zero* ambient authority and can
only do what the host explicitly wires up. `allowed_outbound_hosts = []` grants no
outbound-network capability, so the socket imports are simply never bound — the
guest has no way to *express* opening a connection. It is deny-by-default at the
ABI level. Docker `--network none` instead removes the network namespace from a
process that still has the full Linux syscall surface: the code can call
`socket()`, it just has no interface/route. So WASM removes the *capability*
(the operation is unrepresentable), while Docker removes the *resource* (the
operation is attemptable but blocked). WASM's model is finer-grained
(per-host allowlists) and deny-by-default.

**d) TinyGo stdlib gaps hit in this lab**

Two, directly: (1) **tzdata** — `time.LoadLocation("Europe/Moscow")` fails because
TinyGo embeds no zoneinfo, so I used `time.FixedZone("MSK", 3*60*60)`. (2)
**reflection-heavy `encoding/json`** — marshalling `map[string]any` is unreliable
under TinyGo's limited `reflect`, so I built the JSON string with `fmt.Sprintf`
and `%q` verbs.

---

## Task 2 — Perf Comparison vs Lab 6 Container

### Test rig

- **Host:** Windows 11 Pro (build 26200), AMD Ryzen 7 8845H, Docker Desktop 29.2.1 (WSL2 Linux engine)
- **Build/measure container:** Debian 13 (trixie), image `tinygo/tinygo:0.41.0`, 16 vCPU visible
- **Lab 6 baseline:** the *actual* `app/Dockerfile` from `feature/lab6` (multi-stage `golang:1.24-alpine` → `gcr.io/distroless/static:nonroot`), built here as `quicknotes:lab6`
- Both services measured on the same physical host; hyperfine runs inside the Linux container, reaching the Lab 6 container over a shared Docker network (`labnet`), so no Windows port-proxy is in the warm path.

### Results

| Dimension           | Lab 6 Docker            | Lab 12 WASM/Spin        |
|---------------------|------------------------:|------------------------:|
| Artifact size       | 5,709,934 B (5.71 MB)¹  | 370,475 B (362 KB)      |
| Cold start (p50)    | 818 ms²                 | 27 ms                   |
| Warm latency p50    | 14.4 ms³                | 17.4 ms³                |
| Warm latency p95    | 16.0 ms³                | 21.0 ms³                |

¹ `docker image inspect quicknotes:lab6 --format '{{.Size}}'`. (`docker images` shows 22.7 MB — that is the containerd multi-platform manifest total, not the single-image size.)
² Linux-native cold start = time from `docker run` to first HTTP 200 on `/health`, measured *inside* the VM over `labnet` (no Docker-Desktop port proxy). Samples: 827, 815, 818, 838, 732, 758, 839 ms. Measured from the Windows host through Docker Desktop's port proxy it is ~1.6 s — that figure is inflated by Windows→VM orchestration and is *not* used here.
³ `hyperfine --warmup 5 --runs 50`, p50/p95 computed from the exported per-run times. Both figures include ~13 ms of `curl` process-spawn + connection overhead (visible in the min), which is common to both columns and cancels out in the comparison. Spin: mean 17.9 ± 1.6 ms; Lab 6: mean 14.6 ± 0.8 ms.

Spin cold start samples: 25, 28, 29, 25, 27 ms.

**Reading the numbers.** WASM/Spin is ~15× smaller and cold-starts ~30× faster.
Warm latency is ~3 ms *slower* than the native-Go container — that gap is the
per-request WASM handler overhead, dwarfed by the cold-start advantage.

### Design Questions

**e) What dominates each platform's cold start?**

*Container (~818 ms):* creating the container (containerd/runc), building the
Linux sandbox — network/mount/pid/user namespaces, cgroups, the overlay rootfs
and tmpfs mounts — and only then the Go runtime boot + listener. The OS-level
sandbox construction dominates. *Spin (~27 ms):* the wasmtime engine is already
resident; per start it loads and validates the `.wasm`, compiles/instantiates a
Store, and runs `_initialize`. No namespaces, no cgroups, no rootfs — module
load + instantiation dominates, which is one to two orders of magnitude cheaper.

**f) Where is WASM clearly better, and where is Docker still right?**

WASM wins for high-density, multi-tenant serverless/edge (thousands of tiny
handlers, scale-to-zero, low-ms cold start), untrusted plugin execution, and
per-request isolation with one portable artifact. Docker is still right for apps
that need the full POSIX/syscall surface, unmodified existing binaries, complex
runtime dependencies (databases, daemons, cgo, threads, GPU), or the complete Go
stdlib — TinyGo's gaps (tzdata, reflection, parts of `net`) alone disqualify many
programs — and for long-running stateful services where cold start is irrelevant.

**g) Multi-tenant safety: what concrete attack does WASM make harder?**

Container escape via a kernel exploit. Containers share the host kernel, so a
single kernel/syscall vulnerability (a Dirty-Pipe-class bug, a bad `ioctl`) can
let a malicious tenant break out of its namespace onto the host and into other
tenants. A WASM guest has *no* direct syscall access — it can only call the
explicit, narrow set of host imports (wasi-http here), and its memory is a
bounds-checked linear sandbox, so there is no syscall to exploit and no
out-of-bounds path to the host's address space. That makes kernel-syscall-based
escape and cross-tenant memory access dramatically harder.

---

## Bonus Task — Two WASM Execution Models

The same Moscow-time logic was rebuilt as a standalone WASI CLI module (no Spin
SDK): it reads `REQUEST_METHOD` / `PATH_INFO` from the environment and prints the
JSON to stdout — the CGI-over-WASM / WAGI-shaped model.

### Build + run

```
$ tinygo build -o main.wasm -target=wasi -no-debug ./main.go
$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
{"unix":1784115617,"iso":"2026-07-15T14:40:17+03:00","hour_minute":"14:40","timezone":"Europe/Moscow","utc_offset":"+03:00"}
```

CLI module size: **196,929 bytes (192 KB)** — smaller than the Spin wasi-http
component (362 KB), since it carries no SDK/wasi-http handler machinery.

### The Spin component cannot run under bare wasmtime — demonstrated

```
$ wasmtime run ~/moscow-time/main.wasm
# exit 0, no output — the c-shared reactor has no command entrypoint to do work

$ wasmtime serve ~/moscow-time/main.wasm
Error: The serve command currently requires a component
```

### Size + cold-start comparison

| Model                              | Artifact | Cold start (p50) | When it's paid |
|------------------------------------|---------:|-----------------:|----------------|
| `wasmtime run` (per-invocation)    | 192 KB   | 25.6 ms          | every request  |
| Spin persistent wasi-http server   | 362 KB   | 27 ms (once)     | once, then ~17 ms warm |

`wasmtime run` samples: mean 25.9 ± 1.4 ms (hyperfine, 50 runs, full
instantiate→run→teardown each call).

### Design Questions

**h) Why can't the Task 1 component run under bare `wasmtime run`?**

It is a `-buildmode=c-shared` **reactor** module (wasip1): it exports a handler
for a wasi-http host to invoke and runs `_initialize`, but it has no `_start`
command that does the work. `wasmtime run` expects a command — so it runs
`_initialize` and exits with no output (observed: exit 0, empty stdout). And
`wasmtime serve` (a wasi-http host) rejects it — `"The serve command currently
requires a component"` — because the TinyGo output is a core wasip1 *module*, not
a WASM *Component*; Spin adapts/wraps it internally. Neither bare mode can host
it: `run` has no command to run, `serve` needs a component.

**i) Spin uses wasmtime internally — what does Spin add?**

The wasi-http server loop (binds `:3000`, accepts HTTP, marshals requests into
the guest handler ABI), the manifest/routing layer (`spin.toml` maps `/time` →
component), instance pre-instantiation/pooling for low warm latency, the
capability and outbound-host policy enforcement (`allowed_outbound_hosts`), the
componentization/adapter that bridges the TinyGo wasip1 module to wasi-http, plus
scaffolding and logging. Bare wasmtime only instantiates and runs one module.

**j) Two execution models — when does each fit?**

*Per-invocation `wasmtime run` (CGI-like):* pays full instantiation (~26 ms) on
every call and keeps nothing resident between calls, giving perfect per-call
isolation. Fits one-shot / infrequent work: cron and batch jobs, CLI tools, a
nightly report generator. *Spin persistent server:* pays instantiation once
(~27 ms) then serves warm (~17 ms p50), amortizing startup across many requests.
Fits sustained request-serving workloads: web APIs and microservices like this
`/time` endpoint.

---

## Files

- `wasm/` — Spin component: `main.go`, `spin.toml`, `go.mod`, `go.sum`, and the built `main.wasm` (362 KB) as evidence
- `wasm-cli/` — standalone WASI CLI module: `main.go`, `go.mod`, and the built `main.wasm` (192 KB)

## Acceptance Criteria — Evidence Map

| Criterion | Evidence |
|-----------|----------|
| Scaffolded from `spin new -t http-go` | SDK `spin-go-sdk/v2 v2.2.1`, `-buildmode=c-shared` build cmd |
| `spin build` produces `main.wasm` | "Finished building all Spin components", 362 KB |
| `spin up` serves `/time` → Moscow JSON | HTTP 200, `application/json`, `+03:00` body above |
| Design questions a–d | answered |
| Full perf table, real numbers | size / cold / warm p50 / warm p95 table |
| Cold + warm + size captured | yes, with method + rig documented |
| Design questions e–g | answered |
| Standalone WASI module under `wasmtime run` | JSON output above, 192 KB |
| Two execution models compared | size + cold-start table |
| Design questions h–j | answered |
