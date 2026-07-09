# Lab 12 — WebAssembly Containers: a QuickNotes /time endpoint on Spin

> Tooling note: the *current* `spin new -t http-go` template (Spin CLI 3.4.0 / 4.x)
> scaffolds the new **`spin-go-sdk/v3` + `componentize-go`** path, but that
> template's `componentize-go build` failed here (`failed to read path for WIT`) —
> a rough edge in the bleeding-edge tooling. So I used the lab's *validated* path:
> **`spin-go-sdk/v2` + TinyGo 0.41.1**, with the classic
> `tinygo build -target=wasip1 -buildmode=c-shared` command. Everything below is
> real output.
>
> Test rig: WSL2 Ubuntu 24.04 on Windows 11, Docker 29, Spin 3.4.0, TinyGo 0.41.1,
> wasmtime 46.0.1. Files: [`wasm/`](../wasm) (Spin component), [`wasm-cli/`](../wasm-cli) (bonus).

---

## Task 1 — WASM endpoint with the Spin SDK

[`wasm/main.go`](../wasm/main.go) registers a `spinhttp.Handle` that returns
Moscow-time JSON; [`wasm/spin.toml`](../wasm/spin.toml) routes it at `/time`, sets
`allowed_outbound_hosts = []`, and builds with
`tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -o main.wasm .`.

```
$ spin build
Building component moscow-time with `tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -o main.wasm .`
Finished building all Spin components        # main.wasm = 1992 KB
$ spin up
Serving http://127.0.0.1:3000  →  moscow-time: /time
$ curl -s http://127.0.0.1:3000/time
{"hour_minute":"13:10","iso":"2026-07-09T13:10:53+03:00","timezone":"Europe/Moscow (UTC+3)","unix":1783591853}
```
`unix`, `iso` (RFC3339), `hour_minute`, and Moscow (UTC+3) all present; `Content-Type: application/json`.

### 1.4 Design questions

**a) Browser WASM (`js/wasm`) vs server WASM (`tinygo … wasip1`).** `js/wasm`
targets a **browser JS host**: it needs the JS glue runtime, has DOM/JS interop,
and runs inside a JS engine (bigger). `wasip1` targets **WASI**: no JS, the module
reaches files/env/clock/stdio through host-provided WASI calls, runs in
wasmtime/Spin, and is much smaller. The server target *drops* the DOM/JS bindings
(and TinyGo trims the Go stdlib); what you *gain* is a portable, sandboxed,
capability-secured binary that runs outside a browser under any WASI host.

**b) Why `-buildmode=c-shared`?** The Spin (wasi-http) host expects the module to
**export the HTTP handler**, not to have a `main`/`_start` that runs and exits.
`c-shared` makes TinyGo emit a shared-library-style module with `_initialize`
(instead of `_start`) that exports the handler the SDK registered, so the host can
call it per request. Remove it → TinyGo builds a CLI module with `_start` that runs
`main()` and exits → Spin finds no exported handler → `spin up` returns HTTP 500 /
empty component logs. (The newer `componentize-go` template achieves the same
export via the component model instead of `c-shared`.)

**c) `allowed_outbound_hosts = []`.** This is Spin's **capability-based** security:
a component gets *no* capability it wasn't explicitly granted, so an empty list
means the component **cannot make any outbound network call** — to reach an API
you'd have to name its exact host. Versus Docker's `--network none`: Docker's knob
is all-or-nothing at the *network-namespace* level (no interface, or a full one).
Spin's is **fine-grained, default-deny per host** at the WASI capability layer —
you allow `api.example.com:443` and nothing else, without re-enabling all
networking. Least privilege by construction.

**d) TinyGo stdlib gaps.** TinyGo doesn't ship the full Go stdlib — notably **no
embedded tzdata**, so `time.LoadLocation("Europe/Moscow")` fails; I used
`time.FixedZone("MSK", 3*3600)` for UTC+3. Reflection-heavy paths are also limited
(here `encoding/json` of `map[string]any` happened to work). With the newer
standard-Go `componentize-go` path these gaps vanish — but its WIT setup was broken
in the version I had, hence the TinyGo route.

---

## Task 2 — Perf comparison vs the Lab 6 container

Measured with `hyperfine --warmup 5 --runs 50` (warm), a restart-timing loop (cold,
5 samples), and file/image sizes. Rig as above.

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|-----------|-------------:|-----------------:|
| Artifact size | 22.7 MB | **2.0 MB** (1992 KB) |
| Cold start (p50) | ~0.66 s | **~0.16 s** |
| Warm latency p50 | 12.0 ms | 16.5 ms |
| Warm latency p95 | 16.9 ms | 21.1 ms |

WASM/Spin is ~**11× smaller** and cold-starts ~**4× faster**; warm latency is
comparable (both are dominated by the `curl` process spawn, and Spin does a small
per-request instantiation so it's marginally higher).

### 2.3 Design questions

**e) What dominates each cold start?** *Docker*: image layer extraction / overlay
mount + Linux namespace & cgroup init + process exec (~0.66 s). *Spin/WASM*:
wasmtime instantiation + loading/compiling the module (~0.16 s). The container pays
OS-level setup the WASM sandbox skips entirely.

**f) Where WASM is clearly better, and where Docker is still right.** WASM wins for
bursty, short-lived, fast-scaling, multi-tenant **edge/serverless** work — tiny
artifacts, sub-100 ms cold starts, strong per-instance isolation, portable across
CPU archs. Docker is still right for **stateful services, apps needing the full
OS/syscall surface or native libraries, long-running processes, and mature-ecosystem
needs** — WASM's stdlib gaps (TinyGo), missing threads/full POSIX, and younger
tooling limit it for heavy general-purpose apps.

**g) Multi-tenant safety — what WASM makes harder.** WASM is deny-by-default (no
ambient file/network/syscall access) and its linear-memory model with no raw host
pointers removes the kernel attack surface. Concretely it makes a **container /
namespace escape** far harder: a Docker tenant shares the host kernel and can try to
exploit a syscall or kernel bug to break out to the host or a neighbour; a WASM
guest can issue **no arbitrary syscalls** — only the capabilities the host granted —
so there's no kernel to pivot through.

---

## Bonus — two WASM execution models

[`wasm-cli/main.go`](../wasm-cli/main.go) is the same Moscow-time logic as a
**standalone WASI CLI module** (no Spin SDK): reads `REQUEST_METHOD`/`PATH_INFO`
from the env, writes JSON to stdout, exits.

```
$ tinygo build -o main.wasm -target=wasip1 -no-debug ./main.go     # 375 KB
$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
{"hour_minute":"13:14","iso":"2026-07-09T13:14:31+03:00","path":"/time","timezone":"Europe/Moscow (UTC+3)","unix":1783592071}
```

| | Spin wasi-http component | Standalone WASI CLI |
|--|--|--|
| Size | 1992 KB | **375 KB** |
| Cold start | ~0.16 s (server wake) | ~**0.04 s** per `wasmtime run` |
| Model | persistent server, instance-per-request | per-invocation, exits each time |

`wasmtime run wasm/main.wasm` (the Spin component) produces no HTTP response — it's
a wasi-http component exporting a handler, not a CLI module.

### B.3 Design questions

**h) Why can't the Task 1 Spin component run under bare `wasmtime run`?** It's a
**wasi-http component** — built `-buildmode=c-shared`, it exports an HTTP handler
via `_initialize`, **not** a `_start` command entrypoint. `wasmtime run` expects a
CLI command module with `_start` to run to completion; the Spin component has
nothing to "run" — it waits to be *invoked* by a wasi-http host. You'd host it with
Spin or `wasmtime serve`. The bonus CLI module *does* have `_start`, so
`wasmtime run` works on it.

**i) What does Spin add on top of bare wasmtime?** The **wasi-http server loop**
(accept HTTP → call the component's handler), **instance pooling/lifecycle** (a
fresh instance per request for isolation), the **manifest/routing** layer
(`spin.toml` routes → components), **outbound-host capability policy** enforcement,
and host services (key-value, etc.). Bare wasmtime just instantiates and runs one
module; Spin is the application server around it.

**j) When does each execution model fit?** Per-invocation `wasmtime run` (CGI-like,
cold every time, ~40 ms, no persistent state) fits **infrequent, isolated one-shot
tasks** — a nightly report generator, a cron job, untrusted batch execution where a
fresh instance is desirable. Spin's **persistent wasi-http server** (warm, pooled
instances) fits **high-throughput HTTP APIs** where per-request latency matters —
e.g. a public `/time` JSON endpoint under load.
