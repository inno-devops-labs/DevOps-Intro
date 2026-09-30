# Lab 12 — WebAssembly Containers

## Environment

Ubuntu 24.04.5 LTS, Linux 7.0.0-34-generic, Intel Core i7-12650H (16 logical CPUs), 15 GiB RAM. Go 1.27.1; Spin 3.6.3; TinyGo 0.42.0 (Go 1.27.1, LLVM 22.1.4); Spin Go SDK `github.com/spinframework/spin-go-sdk/v2 v2.2.1`; hyperfine 1.18.0; Wasmtime 49.0.1; Docker 29.8.1.

## Task 1 — Spin Go WASM endpoint

Scaffolded with `spin new -t http-go moscow-time --accept-defaults` using templates from Spin v3.6.3. The source is [wasm/moscow-time/main.go](../wasm/moscow-time/main.go), and the manifest is [wasm/moscow-time/spin.toml](../wasm/moscow-time/spin.toml). The manifest routes `/time`, grants no outbound hosts, and runs `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`.

`cd wasm/moscow-time && spin build` completed successfully and created `main.wasm` (383835 bytes, `du -h`: 376K). The generated binary stays local. Port 3000 was occupied by another Docker service, so the test used `spin up --listen 127.0.0.1:3100`. `curl -si http://127.0.0.1:3100/time` returned HTTP 200, `content-type: application/json`, and:

```json
{"unix":1790796513,"iso":"2026-09-30T22:28:33+03:00","hour_minute":"22:28"}
```

The ISO value, numeric Unix epoch, `hour_minute`, UTC+3 offset, and proximity to the host clock were checked programmatically. See [build evidence](../evidence/lab12/01-spin-build.txt) and [runtime evidence](../evidence/lab12/02-spin-runtime.txt).

### Design questions

**a) Browser versus server WASM.** The browser `js/wasm` target uses the JavaScript host and Go's JS support; those imports are unavailable to a bare WASI host. TinyGo `wasip1` uses WASI imports instead, allowing a compact module to run in server runtimes with explicitly granted host capabilities. The HTTP behavior here also depends on Spin's component adapter and `wasi-http` host.

**b) `-buildmode=c-shared`.** The scaffold selects this mode to export the SDK handler through the interface expected by Spin's component adapter. I removed only that flag and tested the result: with Spin 3.6.3 and TinyGo 0.42.0, both `spin build` and `spin up` still succeeded, and `/time` returned HTTP 200. The current toolchain did not reproduce the HTTP 500 suggested in the assignment. I restored the generated command and repeated a successful build and request.

**c) Capabilities.** `allowed_outbound_hosts = []` grants the component no outbound HTTP destinations through Spin. The host enforces this at its interface; the module cannot simply request arbitrary host network access. Docker `--network none` removes the container's normal network interfaces, while Spin's setting describes allowed outbound destinations for the component. Both reduce network reachability through different interfaces; neither alone addresses every possible host vulnerability.

**d) TinyGo standard library gap.** A separate TinyGo 0.42.0 `wasip1` probe called `time.LoadLocation("Europe/Moscow")` under `wasmtime run` and printed `zone=UTC error=unknown time zone Europe/Moscow`. Its runtime lacked that time-zone database. The handler therefore uses a fixed UTC+3 offset and does not depend on installed zone data. No `encoding/json` failure was observed or claimed.

## Task 2 — Performance versus Lab 6 Docker

Baseline: `quicknotes:lab6`, image ID `sha256:d55f30efdb6d97d1782581fb7f0d546cc1778715e46311872506597ab743b99b`, HTTP `/health` on port 3101. Spin served `/time` on port 3100. Both ran locally on the machine listed above.

Warm latency used `hyperfine --warmup 5 --runs 50 --export-json` with `curl -fsS -o /dev/null` for each endpoint. The samples include `curl` process and shell overhead. Hyperfine warned that some commands completed in under 5 ms, reducing precision at this scale. p50 is the median of 50 samples; p95 is nearest rank (sorted sample 48 of 50). Cold start used seven complete runtime starts each, timed with `time.perf_counter()` from process/container launch until the first valid HTTP 200. The module and image were prebuilt and local; no build, pull, or extract time was included. Docker cold time includes the Docker CLI and container creation.

Spin cold samples (ms): 34.155, 34.666, 34.852, 34.858, 35.506, 35.154, 35.303.

Docker cold samples (ms): 381.049, 365.818, 367.445, 416.318, 328.492, 320.437, 374.593.

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|---|---:|---:|
| Artifact size | 14345326 B (13.681 MiB) | 383835 B (374.839 KiB) |
| Cold start p50 | 367.445 ms | 34.858 ms |
| Warm latency p50 | 5.736 ms | 7.266 ms |
| Warm latency p95 | 8.081 ms | 10.134 ms |

All 50 warm samples for each service and all cold samples are recorded in [Spin benchmark evidence](../evidence/lab12/03-spin-benchmark.txt) and [Docker benchmark evidence](../evidence/lab12/04-docker-benchmark.txt). Exact artifact bytes are in [size evidence](../evidence/lab12/05-size-comparison.txt).

### Design questions

**e) Cold-start work.** The measured Docker path created a container from an already local image, set up its namespaces, cgroups, and filesystem mounts, then started the QuickNotes process before `/health` could answer. The measured Spin path started the runtime, loaded and instantiated the component, set up the HTTP trigger, and bound the route before `/time` answered. The seven-sample medians were 367.445 ms for Docker and 34.858 ms for Spin. No image download or extraction occurred inside these timed runs.

**f) Workload fit.** Small stateless HTTP functions, edge handlers, and sandboxed plugins can benefit from a small portable WASM artifact and quick runtime start. Docker remains appropriate when an application needs a full Linux userspace, native dependencies, ordinary process/network behavior, or a long-lived stateful service such as a database. The warm figures here include client startup overhead and show Docker `/health` faster than Spin `/time` on this machine; the endpoints do different work, so these numbers are a practical baseline rather than a pure runtime-only comparison.

**g) Multi-tenant safety.** A component without a preopened directory or outbound-host grant cannot use the normal WASI interfaces to walk the host filesystem or send requests to arbitrary external hosts. This makes filesystem traversal and unauthorized outbound calls harder for an untrusted tenant. Docker namespaces and `--network none` also restrict access, but a container still uses the host Linux kernel syscall surface. Neither isolation model guarantees safety against implementation vulnerabilities.

## Bonus — Standalone WASI with Wasmtime

### Design questions

**h) Bare `wasmtime run` and the Spin handler.** Running `wasmtime run wasm/moscow-time/main.wasm` on this machine exited 0 without JSON output or an HTTP listener. The handler is registered for Spin's HTTP trigger and needs a host to invoke its request interface; a bare command invocation supplies no `/time` request. The separately built CLI module has explicit environment-variable input and stdout output for this invocation model.

**i) What Spin adds.** Wasmtime executes WebAssembly. Spin also reads `spin.toml`, starts the HTTP listener, matches `/time` to the component, invokes the HTTP handler with `wasi-http` integration, manages the component's request lifecycle and possible reuse, and enforces the declared outbound-host policy. No specific instance pooling behavior was assumed in the measured results.

**j) Workload fit.** A short batch transform or isolated hook fits a new `wasmtime run` invocation: inputs can arrive through environment variables or stdin, and the result goes to stdout. A frequently called HTTP API fits Spin's persistent server: it accepts many requests through a stable route without restarting the listener for each request.

### Build, run, and measurements

Source: [wasm-cli/main.go](../wasm-cli/main.go). It reads `REQUEST_METHOD` and `PATH_INFO` and has no Spin SDK dependency. TinyGo 0.42.0 supports the assignment target `wasi`, so the exact build command was `cd wasm-cli && tinygo build -o main.wasm -target=wasi -no-debug ./main.go`. The local module is 188934 bytes (`du -h`: 188K) and is excluded from Git.

Run command: `wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time wasm-cli/main.wasm` using Wasmtime 49.0.1. The validated output was:

```json
{"unix":1790797360,"iso":"2026-09-30T22:42:40+03:00","hour_minute":"22:42"}
```

Ten independent `wasmtime run` subprocesses were timed with `time.perf_counter()` from invocation to process exit. Each returned valid JSON with a matching UTC+3 ISO timestamp, epoch, and hour/minute. No warmup was used. Raw samples (ms): 6.348, 4.814, 6.554, 6.435, 5.657, 5.572, 5.849, 5.516, 4.728, 6.502. Median: 5.753 ms. See [Bonus evidence](../evidence/lab12/06-wasmtime-bonus.txt).

| Model | Module size | Cold operation p50 |
|---|---:|---:|
| Spin HTTP component | 383835 B (374.839 KiB) | 34.858 ms to start server and first HTTP 200 |
| Standalone WASI CLI | 188934 B (184.506 KiB) | 5.753 ms for fresh invocation to JSON output |

The standalone module is 194901 bytes smaller. These cold measurements cover different operations: Spin starts a persistent HTTP server and routes requests to a `wasi-http` handler; the standalone module starts a fresh Wasmtime command process for each request-shaped invocation and writes stdout. The CLI is not an HTTP server.
