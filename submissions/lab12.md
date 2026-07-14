# Lab 12 — WebAssembly Containers: a QuickNotes Endpoint on Spin

**Test rig:** Windows 11 host → WSL2 (Ubuntu) for Spin/TinyGo/wasmtime; Docker
Desktop for the Lab 6 container.
**Pinned tooling:** Spin **3.4.0**, TinyGo **0.41.1** (using Go 1.24.4, LLVM 20.1.1),
wasmtime **46.0.1**, hyperfine **1.18.0**, SDK `github.com/spinframework/spin-go-sdk/v2 v2.2.1`.

> **A note on tooling churn (the lab warned about exactly this).** I first
> installed the latest Spin (**4.0.2**). Its `http-go` template has *already moved
> off TinyGo*: it scaffolds SDK **v3** and builds with `go tool componentize-go
> build` — and that template is broken out of the box (`Error: failed to read path
> for WIT [wit]` — it expects a `wit/` directory the scaffold never creates, and
> `componentize-go` has no `--wit` flag). I therefore pinned **Spin 3.4.0**, the
> version this lab was validated against, whose template produces exactly the
> TinyGo build the spec describes.

---

## Task 1 — A WASM Endpoint with the Spin SDK

Scaffolded with `spin new -t http-go moscow-time --accept-defaults`.

### `spin.toml` ([`../wasm/moscow-time/spin.toml`](../wasm/moscow-time/spin.toml))

```toml
[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []          # least privilege: no outbound network at all
[component.moscow-time.build]
command = "tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm ."
```

### `main.go` ([`../wasm/moscow-time/main.go`](../wasm/moscow-time/main.go))

Registers the handler via `spinhttp.Handle` (SDK v2). Moscow time comes from
`time.FixedZone("MSK", 3*60*60)` — **not** `time.LoadLocation`, because TinyGo
embeds no tzdata. The response is a concrete struct (not `map[string]any`) to stay
inside TinyGo's reflection limits.

### Build + run

```text
$ spin build
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components

$ ls -l main.wasm
515910 bytes  (~504 KB)

$ spin up --listen 127.0.0.1:3000
Serving http://127.0.0.1:3000

$ curl -s http://127.0.0.1:3000/time
{"unix":1784066567,"iso":"2026-07-15T01:02:47+03:00","hour_minute":"01:02",
 "moscow":"2026-07-15 01:02:47","zone":"Europe/Moscow (UTC+3)"}
# HTTP/1.1 200 OK ; content-type: application/json
```

### 1.4 Design questions

**a) Browser WASM (`js/wasm`) vs server WASM (`wasip1`) — what's missing, what do you gain?**
`GOOS=js GOARCH=wasm` targets a **browser**: the module can't do anything on its
own — it needs the `wasm_exec.js` glue and reaches the world only through
JavaScript (`syscall/js`, the DOM, `fetch`). `tinygo build -target=wasip1` targets
a **WASI host**: what's *missing* is the entire JS/DOM bridge (no `syscall/js`, no
DOM, no JS `fetch`). What you *gain* is a host-agnostic module that runs outside a
browser on any WASI runtime, with POSIX-ish capabilities — clocks, env vars,
preopened files, and (via wasi-http) sockets — **granted explicitly by the host**.
It's also far smaller and starts far faster, because there's no JS engine in the
loop.

**b) Why does the build need `-buildmode=c-shared`?**
Spin's host doesn't want a program to *run*; it wants a module that **exports a
handler it can call per HTTP request**. `-buildmode=c-shared` makes TinyGo emit a
shared-library-shaped module that **exports** the SDK's HTTP handler symbol,
instead of a WASI *command* module whose only entrypoint is `_start`. Drop the
flag and you get a command module with no exported handler: `spin up` loads it,
can't find the export, and answers **HTTP 500 with empty component logs**. Our
Bonus experiment shows the mirror image: the c-shared component under bare
`wasmtime run` **exits 0 and prints nothing**, because `_start` (our deliberately
empty `main()`) is the only thing bare wasmtime knows how to call.

**c) `allowed_outbound_hosts = []` — capability security vs Docker's `--network none`.**
WASM/WASI is **capability-based**: a module begins with **zero ambient authority**
— no filesystem, no sockets, no env — and the host hands it each capability
explicitly. `allowed_outbound_hosts = []` grants *no* outbound-network capability,
so the module literally **cannot construct a socket**: the function to do so was
never imported into it. Docker's `--network none` is a **namespace** restriction:
the process is still a full OS binary that *can* call `socket()`; the kernel just
gives it an empty network namespace. The syscall surface remains, so a kernel bug
or a namespace misconfiguration can still leak. WASM denies by **absence of the
ability** (the module's import list *is* the sandbox); Docker denies by
**configuration on a shared kernel**.

**d) Which TinyGo stdlib gaps did you hit?**
Two, exactly as the pitfalls predicted:
1. **No tzdata.** `time.LoadLocation("Europe/Moscow")` cannot work — TinyGo embeds
   no timezone database. Fixed by `time.FixedZone("MSK", 3*60*60)` (Moscow has been
   a fixed UTC+3 with no DST since 2014).
2. **Limited reflection.** `encoding/json` over `map[string]any` is a known rough
   edge, so the response is a **concrete struct with json tags**, which marshals
   cleanly. More broadly TinyGo is a *subset*: heavy reflection, parts of `net`,
   `os/exec`, and full scheduler semantics are where it diverges from upstream Go.

---

## Task 2 — Perf Comparison vs the Lab 6 Container

Both served locally; `hyperfine --warmup 5 --runs 50`; cold start = 5 samples each
(kill → restart → time to first 200).

| Dimension              | Lab 6 Docker | Lab 12 WASM/Spin |
|------------------------|-------------:|-----------------:|
| Artifact size          |  **8.61 MB** | **0.49 MB** (515,910 B) |
| Cold start (p50)       |   **480 ms** |        **83 ms** |
| Warm latency p50       |  **6.53 ms** |      **8.54 ms** |
| Warm latency p95       |      7.77 ms |          9.71 ms |

Raw cold-start samples — Docker: 496 / 499 / 473 / 465 / 480 ms · Spin: 142 / 88 /
62 / 64 / 83 ms.

**WASM is ~17× smaller and cold-starts ~6× faster — but the container is ~25%
faster once warm.** That inversion is the honest headline: a natively compiled Go
binary beats a sandboxed WASM module on steady-state per-request work, while WASM
wins decisively on start-up cost and footprint.

*Measurement caveat:* hyperfine times the whole `curl` invocation, so ~4–5 ms of
process spawn is included in **both** columns; and the Docker request crosses
Docker Desktop's WSL port-forward while Spin is native in WSL. The size and
cold-start figures are unaffected by this.

### 2.3 Design questions

**e) What dominates each platform's cold start?**
- **Docker (480 ms):** almost none of it is the app. It's container plumbing —
  creating namespaces and cgroups, assembling the (already-local) image layers,
  starting the init process — and only then the Go runtime booting and binding a
  listener.
- **Spin/WASM (83 ms):** starting the `spin` host process, initializing the
  wasmtime engine, loading + compiling the ~504 KB module, instantiating it, and
  binding the listener. There is **no OS-level namespace or filesystem setup at
  all** — the isolation boundary is the module's import list, not the kernel — so
  there's simply far less to build.
- Bare `wasmtime run` (19 ms per invocation, from the Bonus) isolates the pure
  WASM part: engine + module instantiation with no server layer.

**f) Where is WASM clearly better, and where is Docker still right?**
**WASM wins** for short-lived, bursty, event-driven work — serverless/edge
functions, per-request handlers, scale-to-zero. A 6× faster cold start and a 17×
smaller artifact make cold scale-out and dense packing cheap (thousands of modules
per host). It's also the right answer for **untrusted multi-tenant plugin code**,
thanks to the capability sandbox. **Docker is still right** for long-running
services that need a real OS surface: native libraries/CGO, arbitrary syscalls, a
filesystem, exec'ing other processes, and the whole mature ecosystem (databases,
sidecars, existing images). And — per our own numbers — for a steady
high-throughput service, the native container is simply **faster per request**;
there the WASM sandbox is overhead, not savings.

**g) Multi-tenant safety — what concrete attack does WASM make harder?**
**Container escape through the kernel syscall surface.** Containers share one
kernel: a hostile tenant can probe 300+ syscalls, and a single kernel/runtime bug
(the runc CVEs, dirty-COW-class flaws, a sloppy namespace or cgroup config) breaks
them out onto the host and into other tenants. A WASM module **has no syscalls at
all** — it can only call the functions the host explicitly imported. There is no
`ptrace`, no `/proc`, no raw socket, no filesystem unless a directory was
preopened. Even a *fully compromised* module is confined to its granted
capabilities, so kernel-level escape isn't merely blocked — it's structurally
unavailable. The attack surface shrinks from "the entire Linux ABI" to "the host's
small, auditable import list."

---

## Bonus — Two WASM Execution Models

Same Moscow-time logic, rebuilt as a **standalone WASI CLI module** (no Spin SDK):
request arrives in env vars, response goes to stdout, module exits — the
CGI-over-WASM shape. Source: [`../wasm-cli/main.go`](../wasm-cli/main.go).

```text
$ tinygo build -o main.wasm -target=wasi -no-debug ./main.go
$ ls -l main.wasm
379154 bytes  (~370 KB)

$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
Content-Type: application/json

{"unix":1784066828,"iso":"2026-07-15T01:07:08+03:00","hour_minute":"01:07",
 "moscow":"2026-07-15 01:07:08","zone":"Europe/Moscow (UTC+3)"}
```

And the Task 1 component under bare wasmtime:

```text
$ wasmtime run wasm/moscow-time/main.wasm
exit=0            # ...and no output whatsoever
```

### Comparison of the two models

| | Spin component (wasi-http) | WASI CLI module (`wasmtime run`) |
|--|---------------------------:|---------------------------------:|
| Module size            | 515,910 B (504 KB) | **379,154 B (370 KB)** |
| Execution model        | persistent wasi-http server | one process per invocation |
| Per-request cost       | **8.5 ms** (warm, pooled instance) | **19 ms** (full instantiate every call) |
| Cold start             | 83 ms (once, then amortized) | 19 ms — but paid *every* invocation |
| Runs under bare `wasmtime run`? | **No** (exits 0, no output) | Yes |

The CLI module is smaller because it carries none of the wasi-http/SDK machinery.
But it pays a full engine + module instantiation (~19 ms) on **every** request,
whereas Spin instantiates once and pools — which is exactly why a warm Spin request
(8.5 ms) beats a fresh `wasmtime run` (19 ms).

### B.3 Design questions

**h) Why can't the Task 1 Spin component run under bare `wasmtime run`?**
Because it is **not a CLI program**. Built with `-buildmode=c-shared`, it *exports*
a wasi-http handler for a host to invoke per request; its `main()` is deliberately
empty. Bare `wasmtime run` only knows how to call the WASI **command** entrypoint
`_start` — so it loads the module, runs the empty `main`, and **exits 0 having
printed nothing** (exactly what we measured). Nothing is served because bare
wasmtime never speaks wasi-http to the module. To host it you need a wasi-http
host: Spin, or `wasmtime serve`.

**i) Spin embeds wasmtime — so what does Spin *add*?**
The whole application layer around the engine: **a wasi-http server loop** (accept
TCP, translate HTTP into the component's wasi-http interface and the response
back); **instance pooling / pre-instantiation**, so a request doesn't pay a full
module instantiate each time — measurably, warm Spin 8.5 ms vs fresh
`wasmtime run` 19 ms; **the manifest + routing layer** (`spin.toml` → routes →
components); **capability and outbound-host policy** (`allowed_outbound_hosts`,
key-value/SQLite stores); and the developer tooling (`spin new`, `spin build`,
`spin up`).

**j) When does each execution model fit?**
- **Per-invocation `wasmtime run` (CGI-shaped):** batch and one-shot work — a
  nightly report generator, a git hook, a sandboxed plugin invoked occasionally, a
  one-off data transform. Every run is fully isolated, no state survives, and there
  is no server to operate. The cost — ~19 ms of instantiation *per call* — makes it
  the wrong shape for a high request rate.
- **Spin's persistent wasi-http server:** an HTTP API or edge function under
  continuous traffic — precisely our `/time` endpoint. The host stays up, modules
  are pre-instantiated and pooled, so per-request cost drops to ~8.5 ms and a steady
  stream is absorbed cheaply. The cost is running a server process.
