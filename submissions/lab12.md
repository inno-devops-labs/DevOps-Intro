# Lab 12 — WebAssembly Containers: A QuickNotes Endpoint on Spin

**Toolchain (pinned):** Spin 3.6.3 (88d51cf) · TinyGo 0.41.1 (Go 1.24.4, LLVM 20.1.1) ·
`github.com/spinframework/spin-go-sdk/v2` v2.2.1 · wasmtime 46.0.1 · hyperfine 1.18.0

**Test rig:** 11th Gen Intel Core i5-1135G7 @ 2.40 GHz (4 cores) · 7 GB RAM ·
WSL2 (Linux 6.18.33.2-microsoft-standard-WSL2, x86_64) on Windows · Docker Engine 29.2.0

---

## Task 1 — WASM Endpoint with the Spin SDK

Scaffolded with `spin new -t http-go moscow-time --accept-defaults` rather than hand-writing the
manifest. The Spin 3.6.3 template emitted the current SDK path
(`github.com/spinframework/spin-go-sdk/v2`, the CNCF org — not `fermyon`), the correct TinyGo build
command, and `allowed_outbound_hosts = []` already set. No `executor` key appears anywhere: WAGI is
gone from Spin 3.x, confirming the lab's warning. The only edit to the generated `spin.toml` was the
route, from the catch-all `/...` to `/time`.

### `spin.toml`

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json
spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["Ivan Alpatov <ivanalpatov2003@gmail.com>"]

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

### `main.go`

```go
package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

// Moscow is UTC+3 year-round: Russia abolished DST in 2011, so a fixed
// offset is exact, not an approximation. We construct the zone by hand
// rather than calling time.LoadLocation("Europe/Moscow"), because TinyGo
// ships no embedded tzdata and that call fails at runtime.
var moscow = time.FixedZone("MSK", 3*60*60)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.Header().Set("Allow", "GET")
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		now := time.Now().In(moscow)

		// Hand-rolled JSON via fmt.Sprintf rather than encoding/json on a
		// map[string]any: TinyGo's reflection support is partial, and the
		// interface-typed map is exactly the case that trips it.
		body := fmt.Sprintf(
			`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":%q,"utc_offset_hours":%d}`,
			now.Unix(),
			now.Format(time.RFC3339),
			now.Format("15:04"),
			"Europe/Moscow",
			3,
		)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, body)
	})
}

// main is required by the Go toolchain but never called: Spin's host
// invokes the handler registered in init() through the exported
// wasi-http entrypoint that -buildmode=c-shared produces.
func main() {}
```

### Build

```
$ spin build
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
go: downloading github.com/spinframework/spin-go-sdk/v2 v2.2.1
go: downloading github.com/julienschmidt/httprouter v1.3.0
Finished building all Spin components

$ ls -la main.wasm
-rw-r--r-- 1 alpatovia alpatovia 353507 Jul 10 17:31 main.wasm
```

**353,507 bytes (345 KB).**

### Run + verify

```
$ spin up
Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000/time

$ curl -s -i http://127.0.0.1:3000/time | head -3
HTTP/1.1 200 OK
content-type: application/json
content-length: 124

$ curl -s http://127.0.0.1:3000/time | python3 -m json.tool
{
    "unix": 1783693924,
    "iso": "2026-07-10T17:32:04+03:00",
    "hour_minute": "17:32",
    "timezone": "Europe/Moscow",
    "utc_offset_hours": 3
}
```

Host UTC time at that moment was 14:32:04 — the `+03:00` offset checks out.

### Design questions

**a) Browser WASM vs server WASM: `go build -target=js/wasm` vs `tinygo build -target=wasip1`. What's missing in the server target, and what do you gain?**

The two targets differ in what the module is allowed to assume exists outside itself.

`js/wasm` compiles against a JavaScript host. The module has no syscalls of its own; everything —
timers, fetch, console, the DOM — arrives by calling out into JS through the `syscall/js` bridge.
Go's runtime is fully present (goroutines, the scheduler, GC), so `net/http`'s client works, but only
because JS's `fetch` is doing the actual I/O. There is no filesystem, no sockets, no `os.Args`, no
process concept. The artifact is also large: Go's own toolchain emits several megabytes for a hello
world because the whole runtime ships along.

`wasip1` compiles against WASI preview 1: a small, POSIX-flavoured syscall interface the host
implements directly. What's *missing* relative to `js/wasm` is the entire browser: no DOM, no JS
interop, no `fetch`. What's also missing relative to *native* Go is more consequential — WASI p1 has
no sockets, so `net.Listen` cannot work; threads are absent, so goroutines are cooperatively
scheduled onto one thread (TinyGo implements this with asyncify stack switching, visible as the
`asyncify_*` exports in our module); and TinyGo's stdlib is partial (see (d)).

What you gain is the reason the lab exists. The module becomes a first-class server-side artifact:
it runs under any WASI host — Spin, wasmtime, WasmEdge, wasmCloud — with no browser, no Node, no
JS engine. It is small (345 KB here versus ~2 MB+ for `js/wasm` of equivalent logic, and versus
15.1 MB for the Docker image). It starts in tens of milliseconds. And it is sandboxed by
construction: the host grants capabilities explicitly rather than the module inheriting ambient
process authority. `js/wasm` targets a document; `wasip1` targets a machine.

**b) Why does the build command need `-buildmode=c-shared`? (Try removing it and see what `spin up` does.)**

The lab predicts that removing it yields HTTP 500 with empty component logs. On this toolchain —
**Spin 3.6.3, TinyGo 0.41.1, SDK v2.2.1** — it does not. `spin up` served `/time` with a normal
`200 OK` from a module built without the flag. Rather than assume the lab is simply wrong or that
the flag is pointless, I dumped the WebAssembly export section of both binaries to see what actually
changes.

Nineteen exports each. Eighteen are identical, including the handler itself
(`spin_http_handle_http_request`, `handle-http-request`), the allocator shims, and the asyncify
machinery. **Exactly one export differs:**

```
$ diff exports-cshared.txt exports-nocshared.txt
11c11
<    [func] _initialize
---
>    [func] _start
```

That single symbol is the whole of the flag's effect, and it encodes a real distinction in the WASI
specification. `_start` marks a **command** module: the host calls it once, `main()` runs to
completion, the instance is finished. `_initialize` marks a **reactor** module: the host calls it to
run initialization (here, our `init()`, which registers the handler with the SDK), and the instance
then *stays alive* so the host can invoke its exported functions repeatedly. A long-lived HTTP
handler is a reactor; `-buildmode=c-shared` is how TinyGo is told to emit one.

So the flag's purpose is not "export the handler" — the handler is exported either way, because the
SDK's `//export` directives don't depend on build mode. Its purpose is to declare the module's
*lifecycle contract* to the host. Spin 3.6.3 evidently tolerates the mismatch: it finds the handler
export and calls it regardless of which entrypoint symbol is present. Spin 3.4, which the lab was
validated against, apparently did not. This is a runtime becoming more forgiving across a minor
version, not the flag becoming unnecessary — a command module that a host *does* call `_start` on
would run `main()` (which is empty here) and exit, which is exactly the failure the lab describes.

Keeping the flag remains correct: it states the intended contract, and relying on a host's tolerance
for a mis-declared module is precisely the kind of thing that breaks on the next upgrade.

**c) `allowed_outbound_hosts = []` — explain the capability-based security model and compare it to Docker's `--network none`.**

The distinction is *ambient authority* versus *explicit capability*.

A Linux process holds authority by virtue of existing: it can call `connect(2)` to any address the
kernel will route, open any path its UID can read, and the only question is whether something —
namespaces, seccomp, AppArmor, iptables — intervenes to stop it. Security is subtractive. You start
with a process that can do everything and remove capabilities until the remainder is tolerable.
`--network none` is a good example: it removes the network namespace's routes, so the syscall still
exists, still gets made, and simply fails. The process *tried*.

A WASM component holds no authority at all. It cannot make a syscall, because there is no syscall
instruction in the WebAssembly instruction set — only calls to functions the host explicitly imported
into its instance. If the host imports no socket-opening function, the module has no expressible way
to open a socket; the capability is not denied, it is *absent from the module's vocabulary*. Security
is additive. `allowed_outbound_hosts = []` means Spin instantiates the module with no outbound HTTP
capability wired in, so `spinhttp.Post(...)` fails at the host boundary before any packet exists.

Three practical consequences follow. Granularity: `--network none` is all-or-nothing per container,
whereas `allowed_outbound_hosts = ["https://api.example.com"]` grants exactly one host — Docker has
no equivalent without a sidecar proxy or iptables rules the container itself could not have written.
Auditability: the manifest *is* the policy, sitting in version control next to the code, rather than
being distributed across a Dockerfile, a compose file, and the orchestrator's network config.
Blast radius on compromise: a container escape means arbitrary code with the container's ambient
authority against the kernel's ~350 syscalls, a well-documented attack surface (CVE-2019-5736,
CVE-2022-0185, and friends). A WASM escape means finding a bug in wasmtime's compiler or in the
handful of host functions actually imported — a far smaller surface, and one that carries no
authority even when reached.

The honest caveat: this compares WASM's model against Docker's *default*. `--network none` plus a
tight seccomp profile plus gVisor or Kata closes much of the gap. What it cannot easily reproduce is
per-host outbound policy expressed declaratively in the application's own manifest.

**d) TinyGo stdlib gaps: which part of upstream Go's stdlib does TinyGo not fully support that you hit during this lab?**

Two, both flagged in the lab's pitfalls and both actually load-bearing here.

*Time-zone data.* `time.LoadLocation("Europe/Moscow")` compiles but fails at runtime under TinyGo —
there is no embedded tzdata and no `/usr/share/zoneinfo` inside the WASI sandbox to fall back on. The
workaround is `time.FixedZone("MSK", 3*60*60)`. This is exact rather than approximate for Moscow
specifically: Russia abolished DST in 2011, so UTC+3 holds year-round. For a zone with DST the same
workaround would be wrong half the year, and the fix would be importing `time/tzdata` to embed the
database into the binary — at a size cost that matters when the whole artifact is 345 KB.

*Reflection.* TinyGo implements a subset of `reflect`, and `encoding/json`'s marshalling of
`map[string]any` is exactly the case that leans hardest on it: the encoder must inspect each
interface value's dynamic type at runtime. Rather than build the artifact and discover this at the
first request, I sidestepped it by formatting the JSON with `fmt.Sprintf` and `%q` verbs, which
handles quoting and escaping correctly for these values. Marshalling a *concrete struct* would likely
have worked, since the type is known statically — but `%q` on five fields is less code than a struct
with tags, and immune to whichever reflection corner TinyGo has not implemented this release.

Worth noting for scope: the lab explicitly warns against porting all of QuickNotes to WASM, and this
is why. The full app uses `net/http`'s `Server` (no sockets under WASI p1), file-backed persistence,
and strict JSON decoding of unknown-field structs. One endpoint is a reasonable demonstration; the
whole service would be a fight.

---

## Task 2 — Perf Comparison vs the Lab 6 Container

### Methodology, and one correction to it

The naive measurement — `hyperfine --warmup 5 --runs 50 'curl … /time'` versus the same against
`/health` — produced this:

| command | mean |
|---|---:|
| `curl … :3000/time` (Spin) | 5.9 ms |
| `curl … :8080/health` (Docker) | 5.2 ms |
| `curl … :9999/nothing` (nothing listening) | 4.3 ms |

The third row is the control I added, and it invalidates the first two. With no server at all, the
command still takes 4.3 ms — that is `fork`, `exec`, shell startup, and curl's own initialization.
hyperfine even warns that it cannot calibrate below ~5 ms. Roughly three quarters of each
"measurement" is the harness. Reporting 5.9 vs 5.2 ms as a latency comparison would be reporting
noise with two significant figures.

Everything below therefore uses `curl -w '%{time_total}'`, which reports the request time from
inside the already-running curl process, excluding process startup. 20 warmup requests, then 200
measured, percentiles computed from the raw sample.

Cold start is measured as wall time from the launch command to the first HTTP response that returns
success, polling every 5 ms. Seven samples each; the runtime is fully killed between samples.

### Results

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin | Ratio |
|------------------------|-------------:|-----------------:|------:|
| Artifact size | 15.1 MB | 345 KB | **WASM 44× smaller** |
| Cold start (p50) | 332.5 ms | 44.9 ms | **WASM 7.4× faster** |
| Warm latency p50 | 0.833 ms | 1.499 ms | Docker 1.8× faster |
| Warm latency p95 | 1.109 ms | 2.031 ms | Docker 1.8× faster |

Cold start, full samples (ms):

```
Spin:    41.7  44.2  44.4  44.9  45.2  45.5  50.6     n=7  p50=44.9   mean=45.2   sd=2.7
Docker: 314.3 318.9 331.8 332.5 339.2 348.6 364.4     n=7  p50=332.5  mean=335.7  sd=17.2
```

Warm latency, n=200 each:

```
spin     p50=1.499 ms  p95=2.031 ms  p99=2.513 ms  mean=1.593 ms  min=1.339 ms
docker   p50=0.833 ms  p95=1.109 ms  p99=1.581 ms  mean=0.906 ms  min=0.605 ms
```

### The warm-latency result runs against the usual narrative, so I checked it

WASM is routinely sold as "lighter and faster." Here it is decisively lighter and decisively faster
to start, and roughly **twice as slow per warm request**. Before writing that down I tested the two
obvious ways the measurement could be lying.

*Are the endpoints doing comparable work?* `/time` formats an RFC3339 timestamp and builds JSON;
`/health` returns a near-constant. Maybe I was measuring `strconv`, not the runtime. So I also
benchmarked Docker's `/metrics`, which formats a Prometheus text exposition:

```
docker /health    p50=0.833 ms
docker /metrics   p50=0.804 ms
```

Indistinguishable. The handler's work is not what separates the two platforms.

*Are the network paths comparable?* They are not — and the asymmetry favours Spin. Docker Desktop
proxies `localhost:8080` from Windows into a VM; Spin listens natively inside WSL2. To quantify the
container's share, I ran the same Go binary natively in WSL2:

| stack | p50 | p95 | overhead vs native |
|---|---:|---:|---:|
| Go, native in WSL2 | 0.454 ms | 0.642 ms | — |
| Go, in Docker | 0.833 ms | 1.109 ms | +0.38 ms |
| TinyGo/WASM, in Spin | 1.499 ms | 2.031 ms | +1.05 ms |

So the container costs ~0.38 ms per request, and the WASM sandbox costs ~1.05 ms — nearly three times
as much — *despite* Spin being measured on the more favourable network path. The result is real, and
if anything understated.

The mechanism is not mysterious. Each request crosses the wasi-http ABI boundary: the host serializes
the request into the module's linear memory, the guest allocates (note the exported `malloc`,
`canonical_abi_realloc`), the response is copied back out. TinyGo's goroutine support under WASI p1
is asyncify-based stack switching — the `asyncify_start_unwind` / `asyncify_stop_rewind` exports are
visible in the module — which is cheaper than threads but not free. And Spin instantiates or pools an
instance per request rather than keeping a warm goroutine on a listening socket. A container, once
started, is just a Linux process on a socket; the per-request cost is a namespace-crossing that the
kernel already optimizes hard.

### Design questions

**e) What dominates each platform's cold start?**

*Docker (332 ms).* The image is already pulled and its layers already extracted, so nothing is
downloading. What remains: the Docker CLI round-trips to the daemon over the socket; the daemon
prepares the container's overlayfs mount from the layer stack; it creates the network namespace,
allocates a veth pair, and wires it into the bridge; it publishes the port, which on Docker Desktop
also means configuring a proxy across the Windows/VM boundary; it creates the remaining namespaces
(pid, mount, uts, ipc), applies the cgroup, seccomp profile, and capability set; then `containerd`
finally `exec`s the process, which is a fresh Go runtime doing its own initialization — heap arenas,
GC setup, scheduler start. The measurement is dominated by orchestration, not by the program. That
the standard deviation is 17 ms, versus Spin's 2.7 ms, is itself evidence of how many moving parts
are involved.

*Spin (45 ms).* No namespaces, no filesystem preparation, no network setup beyond binding a socket in
the existing process. The cost is: the Spin process starts, parses `spin.toml`, reads the 345 KB
module, and hands it to wasmtime, which validates the bytecode and JIT-compiles it with Cranelift.
Compilation is the bulk of it — and it is a fixed cost proportional to module size, which is why the
tiny artifact matters twice over. The Go runtime initialization that Docker also pays is present here
too, but TinyGo's runtime is a fraction of upstream Go's.

The asymmetry generalizes: containers pay for isolation machinery the kernel provides; WASM pays for
compilation the runtime performs. Kernel namespace setup does not get much cheaper with a smaller
image. Cranelift compilation gets linearly cheaper with a smaller module, and disappears entirely
with AOT compilation (`wasmtime compile`) or an instance pool, which is what production Spin/Fermyon
Cloud does to reach sub-millisecond starts.

**f) For what workloads is WASM clearly better, and where is Docker still right?**

Read the table as a shape, not as a scoreboard: WASM's cost is per-request, Docker's cost is
per-start. Which one dominates depends entirely on the ratio of requests to starts.

*WASM wins where that ratio is low.* Serverless and edge functions: an instance handles a handful of
requests and dies, so a 288 ms cold-start penalty is paid on nearly every invocation while a 0.67 ms
per-request penalty is paid a handful of times. Scale-to-zero services, where the alternative to a
fast cold start is keeping a container warm and paying for idle. Multi-tenant plugin hosts —
Envoy filters, Shopify Functions, database UDFs — where thousands of untrusted tenants share one
process and a container each would be absurd. Anywhere the artifact must be distributed widely and
often: 345 KB versus 15.1 MB is a 44× reduction in registry bandwidth and edge-cache footprint.
And anywhere the deployment target is heterogeneous, since one `.wasm` runs on x86 and ARM without a
multi-arch build.

*Docker stays right where the ratio is high.* A long-running API server starts once and serves
millions of requests; the 288 ms is amortized to nothing within the first second, and the 0.67 ms
per-request tax compounds forever. It becomes the dominant cost. Beyond latency, Docker still wins on
capability: WASI p1 has no sockets, so anything that listens, dials a database, or speaks a custom
protocol needs host-specific extensions or does not work at all. Ecosystem maturity is the other
half — Kubernetes, service meshes, the whole observability stack, and every language runtime that
has never been ported to WASM. Stateful workloads that want the filesystem, and anything needing
threads or heavy CPU parallelism, are still container territory.

The line, stated compactly: if the process lives longer than a second and serves more than a few
thousand requests, the container is right. If it lives for one request, WASM is right by an order of
magnitude. The measurements above put the crossover, for this workload on this machine, at roughly
430 requests — below that, Spin's faster start more than pays for its slower requests.

**g) Multi-tenant safety: what concrete attack does a WASM platform make harder?**

**Container escape via kernel syscall exploitation.** A container is a Linux process; isolation is
namespaces plus cgroups plus seccomp filtering over an attack surface of roughly 350 syscalls. Any
memory-safety bug in any of them, reachable from an unprivileged process, is a candidate escape.
CVE-2022-0185 (an integer underflow in `legacy_parse_param`, reachable via `unshare` + `fsconfig`)
gave root on the host from inside a default container. CVE-2019-5736 had a container overwrite the
host's `runc` binary through `/proc/self/exe`. Dirty COW, Dirty Pipe, and the io_uring family are the
same story: the kernel is a shared, enormous, C-language TCB that every tenant is directly calling
into.

A WASM guest cannot call a syscall, because WebAssembly's instruction set has none. It can only call
functions the host explicitly imported into its instance — for our component with
`allowed_outbound_hosts = []`, that is the wasi-http handler contract and essentially nothing else.
To reach `fsconfig` a malicious module would first have to escape wasmtime's memory sandbox, and
wasmtime enforces linear-memory bounds structurally: every load and store is bounds-checked, or
placed inside a 4 GiB guard region where an out-of-bounds address faults by construction. There is no
pointer arithmetic that reaches host memory, no `int 0x80`, no way to name a kernel object. The
guest's whole vocabulary is what the manifest granted.

Two related attacks get harder for the same reason. *Cross-tenant reads*: two containers sharing a
kernel can attack each other through it; two WASM instances share only wasmtime, and each has its own
linear memory with no addressing scheme that can name another's. *Ambient-authority abuse*: a
compromised container inherits its process's ability to reach any routable address — the classic
pivot to the cloud metadata endpoint at `169.254.169.254` and thence to IAM credentials. Our
component cannot form a request to that address, because no function capable of opening an outbound
connection exists in its import table.

The honest bound on this claim: wasmtime's compiler is itself a large piece of Rust, and
miscompilation bugs have been found (GHSA-ff4p-7xrq-q5r8 among others). The TCB is smaller, not
absent. And a host that carelessly imports a broad capability — a `run_command` function, say —
hands back exactly the authority the model was supposed to withhold. The security property belongs
to the *host's import list*, not to WebAssembly as a format.

---

## Bonus Task — Two WASM Execution Models

### The standalone WASI CLI module

`wasm-cli/main.go` reimplements the same Moscow-time logic with no Spin SDK. It reads the request
from the environment (the CGI convention) and writes the response to stdout.

```go
package main

import (
	"fmt"
	"os"
	"time"
)

var moscow = time.FixedZone("MSK", 3*60*60)

// This is a WASI *command* module, not a reactor: wasmtime calls _start,
// main() runs once, the process exits. The request arrives through the
// environment rather than through a wasi-http host, and the response goes
// to stdout rather than to an http.ResponseWriter.
func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "" && method != "GET" {
		fmt.Println("Status: 405 Method Not Allowed")
		fmt.Println("Content-Type: text/plain")
		fmt.Println()
		fmt.Println("method not allowed")
		os.Exit(0)
	}

	if path != "" && path != "/time" {
		fmt.Println("Status: 404 Not Found")
		fmt.Println("Content-Type: text/plain")
		fmt.Println()
		fmt.Println("not found")
		os.Exit(0)
	}

	now := time.Now().In(moscow)
	body := fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":%q,"utc_offset_hours":%d}`,
		now.Unix(), now.Format(time.RFC3339), now.Format("15:04"), "Europe/Moscow", 3,
	)

	fmt.Println("Status: 200 OK")
	fmt.Println("Content-Type: application/json")
	fmt.Println()
	fmt.Println(body)
}
```

### Build and run

```
$ tinygo build -o main.wasm -target=wasi -no-debug ./main.go
$ ls -la main.wasm
-rw-r--r-- 1 alpatovia alpatovia 198173 Jul 10 18:16 main.wasm

$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
Status: 200 OK
Content-Type: application/json

{"unix":1783696627,"iso":"2026-07-10T18:17:07+03:00","hour_minute":"18:17","timezone":"Europe/Moscow","utc_offset_hours":3}

$ wasmtime run --env REQUEST_METHOD=POST --env PATH_INFO=/time main.wasm
Status: 405 Method Not Allowed
...

$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/nope main.wasm
Status: 404 Not Found
...
```

### Comparison

| | Spin component | wasmtime CLI module |
|---|---:|---:|
| Artifact size | 353,507 B (345 KB) | 198,173 B (194 KB) |
| Execution model | persistent wasi-http server | one process per invocation |
| Startup | 44.9 ms, paid once | — (indistinguishable from the request) |
| Per request | 1.499 ms (p50) | 7.5 ms ± 0.9 (mean, n=50, hyperfine) |
| Entrypoint export | `_initialize` (reactor) | `_start` (command) |

The CLI module is 44% smaller: no SDK, no `httprouter`, no wasi-http glue — just the TinyGo runtime
and five fields of `fmt.Sprintf`.

Note that `hyperfine` is the *right* tool here, where it was the wrong one in Task 2. In the CGI
model the process **is** the unit of work, so measuring the whole `wasmtime run` invocation —
process spawn, module load, Cranelift JIT, execute, exit — measures exactly what a request costs.
In Task 2's persistent-server model, the equivalent `curl` process spawn was pure harness overhead
and had to be excluded.

The three models line up on a single axis:

| | Artifact | Start (once) | Per request |
|---|---:|---:|---:|
| Docker | 15.1 MB | 332.5 ms | 0.833 ms |
| Spin (persistent) | 345 KB | 44.9 ms | 1.499 ms |
| `wasmtime run` (per-invocation) | 194 KB | — | 7.5 ms |

### Artifact provenance

The `.wasm` binaries are not committed (the Spin scaffold gitignores its own, and both rebuild from
source with one command). SHA-256 of the exact artifacts every number in this document was measured
against:

```
acc8807abdec487b85da1f926c1f3767de29d11d2355719e46d479dca369e0bf  wasm-cli/main.wasm
0c979665497ce05629640cfedc55d3a5a40fa52a19889d4eec84b4e1b99f7c04  wasm/moscow-time/main.wasm
```

These pin *which bytes were benchmarked*; they are not a reproducibility claim. TinyGo makes no
bit-reproducibility guarantee, so a rebuild — even from this commit, with these pinned tool versions
— will likely differ. Getting that property requires the machinery from Lab 11 (a sandboxed,
path-normalized, timestamp-fixed build), which is out of scope here.

### Design questions

**h) Why can't the Task 1 Spin component run under bare `wasmtime run`? (What does it export — a `_start` entrypoint, or a wasi-http handler?)**

It exports `_initialize`, not `_start` — the WebAssembly export section says so directly:

```
$ python3 wasm_exports.py wasm/moscow-time/main.wasm | grep -E '_start|_initialize'
   [func] _initialize
```

versus the CLI module, which exports `_start`. Those two symbols are how a WASI module declares its
lifecycle. A **command** exports `_start`: the host calls it, `main()` runs to completion, the
instance is done. A **reactor** exports `_initialize`: the host calls it to run initialization, and
the instance then persists so the host can invoke its other exports on demand. The Spin component is
a reactor whose real entrypoint is `spin_http_handle_http_request`, invoked by the host once per HTTP
request.

What actually happens is more interesting than a crash, and worth reporting precisely, because it is
not what the lab predicts. `wasmtime run` on the Spin module **succeeds**:

```
$ wasmtime run main.wasm > /tmp/out.txt 2> /tmp/err.txt; echo "exit: $?"
exit: 0
stdout: 0 bytes
stderr: 0 bytes
```

Exit 0, no output, no error. wasmtime finds no `_start`, calls `_initialize` instead, which runs our
`init()` — registering the handler with the SDK — and then returns. Nothing calls
`spin_http_handle_http_request`, because `wasmtime run` is a CLI launcher, not an HTTP host: there
is no request to hand it. The instance initialized correctly and exited correctly, having done
nothing observable. The module doesn't *fail* to run; it runs, and there is nobody to talk to.

The natural next question is whether `wasmtime serve`, which *is* an HTTP host, can drive it. It
cannot, for an orthogonal reason:

```
$ wasmtime serve main.wasm
Error: The serve command currently requires a component
```

`wasmtime serve` speaks the standard `wasi:http/incoming-handler` interface from the WebAssembly
Component Model (WASI preview 2). TinyGo's `-target=wasip1` emits a **core module** (WASI preview 1),
and Spin hosts it through its own legacy ABI — which is exactly what the export name
`spin_http_handle_http_request` reveals: a Spin-specific convention, not a standardized wasi-http
contract. So the module is doubly unrunnable under bare wasmtime: wrong lifecycle for `run`, wrong
module format *and* wrong interface for `serve`.

Two independent incompatibilities, one conclusion — but "prints nothing and exits 0" is a materially
different failure mode from "errors out", and it is the one a person will actually encounter.

**i) Spin uses wasmtime internally. So what does Spin add on top of bare wasmtime?**

Everything between "a runtime that can execute a `.wasm` file" and "a platform that serves HTTP."

*The server loop and the wasi-http boundary.* wasmtime executes a module; it does not listen on a
socket, parse HTTP, route, or marshal a request into guest linear memory. Spin binds the socket,
accepts the connection, serializes method/path/headers/body across the ABI boundary into the
instance, calls the handler export, and copies the response back out. The `malloc` /
`canonical_abi_realloc` exports in our module exist to serve that copying.

*Instance lifecycle and pooling.* A fresh `wasmtime run` pays Cranelift JIT compilation on every
invocation — the 7.5 ms measured above. Spin compiles once at startup and thereafter instantiates
from a pre-compiled module, which is most of why its per-request cost is 1.5 ms rather than 7.5 ms.
Production Spin goes further with pooling allocators and AOT compilation (`spin build --aot`,
`wasmtime compile`), pushing instantiation toward the microsecond range.

*The manifest, routing, and multi-component apps.* `spin.toml` maps routes to components. One
application can contain several components in different languages, each with its own file, and Spin
dispatches to the right one. Bare wasmtime has no concept of an application at all.

*Capability policy.* `allowed_outbound_hosts = []` is enforced by Spin, not by WebAssembly: Spin
decides which host functions to import into the instance and what its outbound-HTTP implementation
will permit. wasmtime provides the mechanism (imports are explicit); Spin provides the policy and its
declarative surface.

*Everything else a platform needs.* Component-scoped stdio logging to `.spin/logs/`, key-value and
SQLite host interfaces, variables and secrets, triggers other than HTTP (Redis, cron), templates and
`spin new`, plugins, and a deployment story. wasmtime is the engine. Spin is the car.

**j) Two execution models — when does each fit?**

The numbers state the trade-off exactly. `wasmtime run` pays 7.5 ms per invocation and nothing
otherwise. Spin pays 44.9 ms once and 1.499 ms per request thereafter. Setting those equal:

```
44.9 + 1.499·n  =  7.5·n     →     n ≈ 7.5 requests
```

Below roughly seven requests per instance lifetime, the per-invocation model wins outright. Above it,
the persistent server wins, and its margin grows without bound: at a thousand requests it is 6× more
efficient in aggregate.

*Per-invocation (`wasmtime run`) fits* work that is genuinely one-shot and where isolation between
invocations must be total. A batch job or scheduled task — invoked once, a fresh instance is free and
a persistent server is pure overhead. Untrusted user-submitted code in a CI or grading system, where
every submission must get a virgin heap and there is no state worth preserving. A `git` hook, a
build step, an image-transformation stage in a pipeline. Anything a person would have written as a
CGI script or a Unix filter: read env and stdin, write stdout, exit. The model's virtue is that
"process exited" is a complete and cheap cleanup story — no leaked memory, no poisoned globals, no
warm-instance state bleeding between tenants.

*Persistent (Spin) fits* anything HTTP-shaped and sustained. A public API endpoint handling a
continuous request stream — amortizing the 45 ms start over thousands of requests reduces it to
noise, while a 6 ms per-request saving compounds. A serverless function on a platform that keeps
instances warm between invocations (Fermyon Cloud, Fastly Compute), which is precisely the pooling
optimization that makes the model pay. Anything needing in-memory state across requests — a cache,
a connection pool, a compiled regex — which the per-invocation model must rebuild every time.

The dividing line is not "WASM vs WASM" but the same ratio that separated Docker from Spin in Task 2:
how many requests amortize one start. Docker's start costs 332 ms and breaks even against Spin at
~430 requests; wasmtime's per-invocation model has no start to amortize and loses to Spin after ~7.
The three sit on one continuum, and the workload's request-to-start ratio picks the point on it.
