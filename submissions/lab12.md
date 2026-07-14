# Lab 12 — WebAssembly Containers: QuickNotes `/time` on Spin

**Toolchain (pinned, [`versions.txt`](lab12/versions.txt)):** Spin 4.0.2 (bfc7543 2026-06-23) · spin-go-sdk **v3.0.0** · componentize-go 0.3.3 · Go 1.26.1 · TinyGo 0.41.1 (Bonus module) · wasmtime 46.0.1 · hyperfine 1.20.0
**Test rig ([`rig.txt`](lab12/rig.txt)):** MacBook Pro, Apple **M4 Pro**, 24 GiB RAM, macOS 26.5.2 (25F84), Docker Desktop 28.3.0 (`desktop-linux`)

> **Toolchain drift note.** The lab was validated (May 2026) on Spin 3.4 + TinyGo + `spin-go-sdk/v2`, building with `tinygo build -target=wasip1 -buildmode=c-shared`. One month later the Spin **4.0** `http-go` template scaffolds `spin-go-sdk/v3` and builds with **`go tool componentize-go build`** — standard Go compiled to a wasip1 module and wrapped into a wasi-http *component* by [componentize-go](https://github.com/bytecodealliance/componentize-go); TinyGo is gone from the template. Per the lab's own instruction ("always scaffold from `spin new -t http-go` for whatever Spin version you have"), this submission uses the current scaffold and answers the TinyGo-specific design questions against both toolchains (TinyGo is still exercised first-hand in the Bonus). The churn itself is the lab's ⚠️ warning demonstrated live.

---

## Task 1 — WASM endpoint with the Spin SDK (4 pts)

### Files

- [`wasm/main.go`](../wasm/main.go) — handler registered via `spinhttp.Handle(...)` from `github.com/spinframework/spin-go-sdk/v3/http`; Moscow time via `time.FixedZone("MSK", 3*3600)`; JSON built with `fmt.Fprintf` + `%q`
- [`wasm/spin.toml`](../wasm/spin.toml) — scaffolded by `spin new -t http-go` (Spin 4.0.2); single edit: `route = "/..."` → `route = "/time"`. `allowed_outbound_hosts = []` is the Spin 4 scaffold default (kept — least privilege), and the build command stays verbatim as scaffolded: `go tool componentize-go build`

### Build

Two live pitfalls hit on the way (both cousins of the lab's "tooling moves fast" warning): the first `spin build` failed with `failed to read path for WIT [wit]` — componentize-go discovers WIT via `componentize-go.toml` inside the SDK dependency, which wasn't in the Go module cache yet (fix: `go mod download` first); the build then downloads a **patched Go toolchain** (`dicej/go go1.25.5-wasi-on-idle-v2`, async-WASI support pending in [golang/go#76775](https://github.com/golang/go/pull/76775)) — a ~100 MB fetch that timed out once before succeeding.

```text
$ spin build            # submissions/lab12/spin-build.txt
Building component moscow-time with `go tool componentize-go build`
Note: /opt/homebrew/Cellar/go/1.26.1/libexec/bin/go does not support async operation; will use downloaded version.
See https://github.com/golang/go/pull/76775 for details.
Downloading patched Go from https://github.com/dicej/go/releases/download/go1.25.5-wasi-on-idle-v2/go-darwin-arm64-bootstrap.tbz.
Extracting patched Go to /Users/dmitrijnaumov/Library/Caches/componentize-go/v2.
Using /Users/dmitrijnaumov/Library/Caches/componentize-go/v2/go-darwin-arm64-bootstrap/bin/go.
Finished building all Spin components

$ ls -l wasm/main.wasm
-rw-r--r--@ 1 dmitrijnaumov  staff  4827172 Jul 14 10:53 wasm/main.wasm   # 4.6 MiB
```

(The 4.6 MiB module is a big-Go component — the TinyGo toolchain the lab was validated on produced ~0.1–0.5 MiB modules; the Bonus's TinyGo-built CLI module shows that contrast first-hand.)

### Verify

```text
$ curl -si http://127.0.0.1:3000/time       # submissions/lab12/curl-time.txt
HTTP/1.1 200 OK
content-type: application/json
transfer-encoding: chunked
date: Tue, 14 Jul 2026 07:54:41 GMT

{"unix":1784015681,"iso":"2026-07-14T10:54:41+03:00","hour_minute":"10:54","timezone":"Europe/Moscow (UTC+3)"}
```

`10:54 +03:00` against the response's own `07:54 GMT` date header — Moscow offset verified in one screenshotable line.

### Design questions

**a) Browser WASM (`go build -target=js/wasm`) vs server WASM (`tinygo build -target=wasip1`).**
The `js/wasm` target assumes a JavaScript host: the module is loaded by `wasm_exec.js` glue, and every "syscall" (time, random, fs, network) is a call back into JS APIs — it cannot run outside a browser/Node event loop. The `wasip1` target instead imports the standardized **WASI** interface (`wasi_snapshot_preview1`): clocks, random, environment, stdio, preopened files — no JS anywhere. What's *missing* in the server target: the DOM and all JS interop, and a full network stack (wasip1 has no general sockets — networking must be granted by the host, e.g. Spin's wasi-http). What you *gain*: the same `.wasm` artifact runs in any WASI runtime (wasmtime, Spin, wasmCloud, containerd shims) on any CPU architecture, with a tiny, capability-scoped host surface instead of a whole browser runtime.

**b) Why does the build need `-buildmode=c-shared`?**
Because the Spin host doesn't run the module like a program — it treats it as a **library (reactor module)**: instantiate once, then call an exported handler per request. A default `tinygo build -target=wasip1` produces a **command module**: it exports `_start`, which runs `main()` and exits — nothing for Spin to call on each request. `-buildmode=c-shared` flips TinyGo to the reactor shape: an `_initialize` export (runs `init()`, which is where `spinhttp.Handle` registers the handler) plus the handler export Spin's wasi-http executor invokes. Without it, `spin up` finds no handler export and every request dies with HTTP 500 and empty component logs — the lab's pitfall verbatim.
*Our Spin 4 scaffold shows where that flag went:* `go tool componentize-go build` performs the same transformation internally — it compiles with big Go and wraps the output into a **component exporting `wasi:http/incoming-handler`** instead of a `_start`-style command. The reactor-vs-command requirement didn't disappear; it moved out of a hand-passed compiler flag into the componentizer tool.

**c) `allowed_outbound_hosts = []` vs Docker `--network none`.**
WASM security is **capability-based, deny-by-default**: a module can literally do nothing except call the imports the host chose to give it. Networking isn't a syscall the sandbox filters — it's a host function that simply *isn't provided* unless the manifest grants it. With `allowed_outbound_hosts = []`, the outbound-HTTP host function refuses every destination; there is no other path to a socket, because the guest has no socket API at all. Docker's `--network none` is the inverse model: the process keeps the **full Linux syscall interface** (ambient authority) and the kernel filters the result — the netns has no interface, but `socket()`/`connect()` still exist, loopback inside the netns still works, and any kernel bug in that surface is reachable. Capability model: "you can call these 5 functions." Namespace model: "you can call all ~350 syscalls, but we rearranged what they see."

**d) TinyGo stdlib gaps hit in this lab.**
1. **No tzdata:** under TinyGo `time.LoadLocation("Europe/Moscow")` fails because no timezone database is embedded. Notably the problem doesn't vanish under big Go on wasip1 either — `LoadLocation` wants to read `/usr/share/zoneinfo`, and the WASI sandbox preopens no such directory (you'd have to pay ~450 KB for `import _ "time/tzdata"`). Solved uniformly with `time.FixedZone("MSK", 3*60*60)` — safe because Moscow has had no DST since 2014.
2. **Reflection-limited `encoding/json`:** marshalling `map[string]any` relies on full reflection that TinyGo doesn't guarantee — hit in the Bonus's TinyGo-built CLI module and avoided in both modules by building the JSON with `fmt.Fprintf` and `%q` verbs.
3. **Meta-gap:** the gaps are severe enough that between May and June 2026 the Spin project moved its Go template *off TinyGo entirely* (componentize-go + big Go) — the strongest evidence that TinyGo's stdlib coverage was the ecosystem's pain point.

---

## Task 2 — Perf comparison vs Lab 6 container (4 pts)

**Method:** warm latency via `hyperfine -N --warmup 5 --runs 50` against `GET /time` (Spin, `127.0.0.1:3300`) and `GET /health` (Docker, `127.0.0.1:8081`) — each sample includes a constant few-ms `curl` process spawn, identical for both columns, so the relative comparison is fair. Cold start = time from launch command to first successful HTTP 200, 5 samples each, measured by [`coldstart.zsh`](lab12/coldstart.zsh). Sizes from `docker image ls` and `ls -l main.wasm`. A first measurement attempt was discarded: host port 8080 turned out to be held by the lab 8 monitoring stack's *own* QuickNotes container (and port 3000 by an unrelated Langfuse stack) — the benchmark had silently measured the wrong container. The monitoring stack was stopped and both benchmark targets moved to squatter-free ports; a reminder that on a shared machine you verify *what* answered, not just that something did.

| Dimension | Lab 6 Docker (`quicknotes:lab6`) | Lab 12 WASM/Spin (`main.wasm`) |
|---|---:|---:|
| Artifact size | 15.1 MB (image) | 4.6 MiB (4 827 172 B) — **3.3× smaller** |
| Cold start (p50 of 5) | 122 ms | 50 ms — **2.4× faster** |
| Warm latency p50 | 6.1 ms | 5.1 ms |
| Warm latency p95 | 7.0 ms | 6.8 ms |

Cold-start samples (ms): Spin `129, 46, 50, 48, 51` — the 129 ms first sample is wasmtime's compilation cache warming up, later starts reuse it; Docker `128, 117, 122, 117, 127` (image already local, Docker Desktop VM already running — this measures pure container setup, not image pull).

Raw data: [`hyperfine-docker.json`](lab12/hyperfine-docker.json), [`hyperfine-spin.json`](lab12/hyperfine-spin.json), [`percentiles.txt`](lab12/percentiles.txt), [`cold-spin.txt`](lab12/cold-spin.txt), [`cold-docker.txt`](lab12/cold-docker.txt), [`sizes.txt`](lab12/sizes.txt).

### Design questions

**e) What dominates each platform's cold start?**
Docker (image already local): the container runtime path — `dockerd`/containerd API round-trips, creating the overlayfs snapshot for the container layer, setting up namespaces + cgroups + the netns/port-forward plumbing (on macOS, plus the Docker Desktop VM port-proxy), spawning `runc`, and only then `exec`ing the binary (which itself starts in ~ms — the Go binary is not the bottleneck). That machinery costs a steady **117–128 ms** in our samples with near-zero variance, because none of it depends on the payload. Spin: process start plus **wasmtime engine init and module load**; compilation is the expensive part, and the measurements show it exactly once — the first start paid **129 ms** (Cranelift compiling 4.6 MiB of wasm into the on-disk cache), every subsequent start mmap'ed the cached machine code and came up in **46–51 ms**. So: container cold start is dominated by kernel/runtime *setup*, WASM cold start by *compilation* — which is cacheable, and per-request instantiation inside a running Spin is another three orders of magnitude cheaper still (µs — that's why warm p50 is flat).

**f) Where WASM wins, where Docker stays right.**
WASM (per Reading 12's trade-offs table): scale-to-zero/edge/FaaS request handlers, multi-tenant SaaS plugin execution, IoT — anywhere ~ms cold starts, MB-sized arch-neutral artifacts, and a hard sandbox matter more than ecosystem breadth. Docker: long-running stateful services, workloads needing arbitrary OS deps (`apt install`, shells, native libs), heavy DB clients, multi-process/multi-threaded servers — the "single-process, no arbitrary syscalls" WASM model simply doesn't fit those, and the container ecosystem (images, registries, k8s tooling) is mature where WASM's is still rough.

**g) Multi-tenant safety: what concrete attack gets harder?**
**Kernel attack surface exploitation / container escape.** A tenant inside a container can issue any syscall; every container on the node shares one kernel, so a single kernel vulnerability (e.g. Dirty Pipe–class bugs, or any of the recurring nf_tables/io_uring privescs) reachable through the syscall interface lets one tenant escape its namespaces and read neighbors' data. A WASM guest **cannot issue syscalls at all** — it can only call the handful of typed host functions it was granted (here: wasi-http in, nothing out). The shared-kernel syscall surface, `/proc`, side-channel-rich device nodes — none of it is addressable from inside the sandbox, so the classic escape route simply has no entry point. (Spectre-style hardware side channels remain, but the OS-level escape class is gone.)

---

## Bonus — Two WASM execution models (2 pts)

Same Moscow-time logic, no Spin SDK — a plain `main()` reading `REQUEST_METHOD`/`PATH_INFO` from env and printing JSON to stdout (the CGI/WAGI shape): [`wasm-cli/main.go`](../wasm-cli/main.go). Built with **TinyGo** this time, which makes the toolchain contrast measurable.

```text
$ tinygo build -o main.wasm -target=wasip1 -no-debug .   # wasip1 = current name of the wasi target
$ ls -l main.wasm                                        # submissions/lab12/cli-build.txt
-rw-r--r--@ 1 dmitrijnaumov  staff  195027 Jul 14 11:06 main.wasm

$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm   # submissions/lab12/cli-run.txt
{"unix":1784016419,"iso":"2026-07-14T11:06:59+03:00","hour_minute":"11:06","timezone":"Europe/Moscow (UTC+3)"}
```

| | Spin component (`wasm/main.wasm`, big Go) | CLI module (`wasm-cli/main.wasm`, TinyGo) |
|---|---:|---:|
| Size | 4 827 172 B (4.6 MiB) | 195 027 B (190 KiB) — **25× smaller** |
| Cold start | 50 ms server boot **once**, then µs per request | 24.4 ms ± 0.9 ms **per invocation** ([`cli-cold.txt`](lab12/cli-cold.txt), hyperfine, 20 runs) |

Both numbers tell the same story from opposite ends: the persistent server pays instantiation once and amortizes it; the CGI model pays a fresh wasmtime + module load on *every* request — fine at 1 rps, ruinous at 1000 rps.

Evidence that the Spin component is not a CLI program ([`wasmtime-run-spin-fail.txt`](lab12/wasmtime-run-spin-fail.txt)):

```text
$ wasmtime run wasm/main.wasm
Error: failed to run main module `wasm/main.wasm`

Caused by:
    0: component imports instance `wasi:http/types@0.3.0-rc-2026-03-15`, but a matching implementation was not found in the linker
    1: instance export `fields` has the wrong type
```

### Design questions

**h) Why can't the Task 1 component run under bare `wasmtime run`?**
`wasmtime run` executes **command** modules/components: it instantiates and calls `_start` (or the component-model `wasi:cli/run` export). The Spin component exports neither — it's a **wasi-http** component exporting an incoming-request handler, a function a *server host* calls once per request. There's nothing for `run` to invoke, and the actual error (above) shows a second layer of the same story: the component *imports* `wasi:http/types@0.3.0-rc-2026-03-15` — a release-candidate snapshot of the **async** wasi-http interface (the very feature that forced componentize-go to download a patched Go) — which `wasmtime run`'s CLI linker doesn't provide. The wasi-http-aware way to host such a component under bare wasmtime is `wasmtime serve`, which supplies the server loop and the http interfaces — provided its wasmtime version implements the RC snapshot the component targets; Spin ships its own wasmtime precisely so host and SDK move in lockstep.

**i) Spin uses wasmtime internally — so what does Spin add?**
The application layer above the raw runtime: the `spin.toml` manifest with **routing** (many components, one listener, route→component dispatch); the persistent **wasi-http server loop** with per-request instantiation from **pre-instantiated/pooled** instances (that's why per-request overhead is ~µs, not a full module load); **outbound-host policy** enforcement (`allowed_outbound_hosts`); host services (key-value, SQLite, variables); and the dev toolchain (`spin new/build/up`, templates, OCI distribution of apps).

**j) When does each execution model fit?**
Per-invocation `wasmtime run` (CGI-shaped): jobs where isolation-per-run and zero idle footprint beat latency — batch/one-shot data transforms, CI plugin steps, cron-style webhooks: nothing lingers between runs and a fresh sandbox each time is a security feature. Persistent wasi-http server (Spin): latency-sensitive endpoints under sustained traffic — e.g. this `/time`-style API at the edge — where you amortize engine/module setup once and serve each request from a pooled instance in microseconds.

---

## Artifacts

- [`versions.txt`](lab12/versions.txt) — pinned toolchain
- [`rig.txt`](lab12/rig.txt) — test machine
- [`spin-build.txt`](lab12/spin-build.txt), [`curl-time.txt`](lab12/curl-time.txt) — Task 1 evidence
- [`sizes.txt`](lab12/sizes.txt), [`percentiles.txt`](lab12/percentiles.txt), [`hyperfine-*.json`](lab12/), [`cold-*.txt`](lab12/) — Task 2 raw data
- [`cli-build.txt`](lab12/cli-build.txt), [`cli-run.txt`](lab12/cli-run.txt), [`cli-cold.txt`](lab12/cli-cold.txt), [`wasmtime-run-spin-fail.txt`](lab12/wasmtime-run-spin-fail.txt) — Bonus evidence
