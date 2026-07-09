# Lab 12 - WebAssembly Containers: QuickNotes-Style Time Endpoint

## Repository freshness

I checked the public course repo before starting. `inno-devops-labs/DevOps-Intro` `main` was still:

```text
8de962e7b49a7056104cc366609053f518eb2f70 refs/heads/main
```

`feature/lab12` was created from local `upstream/main` at that same commit.

## Implemented files

- [`wasm/moscow-time/main.go`](../wasm/moscow-time/main.go)
- [`wasm/moscow-time/go.mod`](../wasm/moscow-time/go.mod)
- [`wasm/moscow-time/go.sum`](../wasm/moscow-time/go.sum)
- [`wasm/moscow-time/spin.toml`](../wasm/moscow-time/spin.toml)
- [`wasm/moscow-time/main.wasm`](../wasm/moscow-time/main.wasm)
- [`wasm-cli/main.go`](../wasm-cli/main.go)
- [`wasm-cli/go.mod`](../wasm-cli/go.mod)
- [`wasm-cli/main.wasm`](../wasm-cli/main.wasm)
- [`security/lab12/lab6-baseline.Dockerfile`](../security/lab12/lab6-baseline.Dockerfile)
- [`security/lab12/summary.json`](../security/lab12/summary.json)
- [`security/lab12/spin-hyperfine.json`](../security/lab12/spin-hyperfine.json)
- [`security/lab12/docker-hyperfine.json`](../security/lab12/docker-hyperfine.json)
- [`security/lab12/cold-start.json`](../security/lab12/cold-start.json)
- [`security/lab12/wasmtime-cold.json`](../security/lab12/wasmtime-cold.json)
- [`security/lab12/wasmtime-hyperfine.json`](../security/lab12/wasmtime-hyperfine.json)

## Test rig

```text
OS: Microsoft Windows 11 Pro 10.0.26200, 64-bit
CPU: AMD Ryzen 7 5800H, 8 cores / 16 logical processors
RAM: 17,024,741,376 bytes
Docker: client 29.2.0, server 29.2.0
Spin: 3.4.0
TinyGo: 0.41.0 via tinygo/tinygo:0.41.0
TinyGo image digest: sha256:0376cd2d957e7304a1a653e2f7ef44cc27e1caa3a445073dfb09731ad4c19fec
Wasmtime: 46.0.1
Hyperfine: 1.20.0
```

## Task 1 - Spin SDK endpoint

The project was scaffolded with the current Spin template:

```text
spin templates install --git https://github.com/spinframework/spin --update
mkdir -p wasm && cd wasm
spin new -t http-go moscow-time --accept-defaults
```

The handler uses `spinhttp.Handle(...)` from the generated SDK import path, `github.com/spinframework/spin-go-sdk/v2/http`. It returns Moscow time using a fixed UTC+3 zone so the RFC3339 value carries `+03:00` without relying on TinyGo time-zone data.

Build evidence:

```text
spin build
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components

main.wasm size: 369,708 bytes
```

`spin.toml` key settings:

```toml
[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []

[component.moscow-time.build]
command = "tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm ."
```

Runtime proof:

```text
spin up --listen 127.0.0.1:3000
curl -s http://127.0.0.1:3000/time
{"unix":1783593281,"iso":"2026-07-09T13:34:41+03:00","hour_minute":"13:34","timezone":"Europe/Moscow (UTC+3)"}
```

### Design answers a-d

**a) Browser WASM vs server WASM**

`GOOS=js GOARCH=wasm` targets a browser JavaScript host. It assumes `wasm_exec.js`, browser APIs, and a JS event loop. TinyGo's `wasip1` target produces a server-side WASI module: there is no DOM, no browser storage, and no JS host API, but the module gets a portable system-interface ABI for server runtimes such as Spin and Wasmtime.

**b) Why `-buildmode=c-shared`**

Spin does not call a CLI-style `_start` function for HTTP components. It hosts a component that exports the ABI entry points expected by the Spin/wasi-http adapter and generated SDK. `-buildmode=c-shared` makes TinyGo emit the exported symbols the Spin host expects; without it, the module can build in the wrong shape and fail at request time.

**c) `allowed_outbound_hosts = []`**

Spin uses a capability model: a component receives only the host capabilities granted in the manifest. An empty outbound-host list means the component cannot open arbitrary network connections even if the code tries. Docker's `--network none` removes the container's network namespace access more broadly. Spin's model is narrower and more declarative: the manifest can allow no network, one host, or a small host allowlist.

**d) TinyGo stdlib gaps hit**

I avoided `time.LoadLocation("Europe/Moscow")` because TinyGo/WASI does not ship the normal host time-zone database. I used `time.FixedZone("MSK", 3*60*60)` instead. I also built the JSON with `fmt.Sprintf` rather than `encoding/json` over `map[string]any`, which avoids reflection-heavy paths that are more fragile in TinyGo.

## Task 2 - Perf comparison vs Docker

The Docker baseline is a Lab 6-style scratch image built from [`security/lab12/lab6-baseline.Dockerfile`](../security/lab12/lab6-baseline.Dockerfile). It runs the same QuickNotes app and exposes `/health`.

Docker baseline evidence:

```text
docker build --no-cache -f security/lab12/lab6-baseline.Dockerfile -t qn-lab12-docker:baseline app
docker image inspect qn-lab12-docker:baseline
id=sha256:68588dcd3f814470422b1c5b45efe4479db2052f760314ac17445c87e7385a3e
size=2506341
user=65532:65532
entrypoint=["/quicknotes"]

curl -s http://127.0.0.1:18082/health
{"notes":4,"status":"ok"}
```

Warm latency commands:

```text
hyperfine --warmup 5 --runs 50 --export-json security/lab12/spin-hyperfine.json "curl.exe -s -o NUL http://127.0.0.1:3000/time"
hyperfine --warmup 5 --runs 50 --export-json security/lab12/docker-hyperfine.json "curl.exe -s -o NUL http://127.0.0.1:18082/health"
```

Cold start method: stop the runtime, start it, poll until the first successful response, repeat 5 times.

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|---|---:|---:|
| Artifact size | 2,506,341 bytes | 369,708 bytes |
| Cold start p50 | 515.4 ms | 522.5 ms |
| Cold start p95 | 550.1 ms | 646.4 ms |
| Warm latency p50 | 23.24 ms | 23.14 ms |
| Warm latency p95 | 29.01 ms | 32.08 ms |

Cold start samples:

```text
Spin:   646.4 ms, 522.8 ms, 520.5 ms, 522.5 ms, 521.9 ms
Docker: 520.7 ms, 507.0 ms, 550.1 ms, 479.1 ms, 515.4 ms
```

### Design answers e-g

**e) Cold-start dominators**

For Docker, the cold path is container creation: namespace/cgroup setup, process start, port publishing, and application initialization. Image extraction was already cached locally. For Spin, the cold path is host startup, manifest load, Wasmtime module instantiation, and the first wasi-http request path.

**f) Where WASM is better vs Docker**

WASM is strong for tiny request handlers, plugins, multi-tenant edge workloads, and code that benefits from fast instantiation with a strict capability sandbox. Docker is still right for full applications, background workers, services that need broad OS APIs, large language/runtime ecosystems, or workloads that expect normal Linux process/container semantics.

**g) Multi-tenant safety**

WASM makes host escape through ambient OS access harder. A compromised component cannot just invoke arbitrary syscalls, inspect `/proc`, open raw sockets, or fork helper processes unless the host explicitly grants those capabilities. That is a stronger default boundary for running untrusted tenant code than relying only on Linux namespaces and seccomp.

## Bonus Task - Two WASM execution models

The standalone CLI module lives in [`wasm-cli/`](../wasm-cli/). It has no Spin SDK and reads `REQUEST_METHOD` and `PATH_INFO` from the environment.

Build and run commands:

```text
cd wasm-cli
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
{"unix":1783593330,"iso":"2026-07-09T13:35:30+03:00","hour_minute":"13:35","timezone":"Europe/Moscow (UTC+3)"}
```

Bonus size and cold-start comparison:

| Dimension | Spin wasi-http component | Bare Wasmtime CLI |
|---|---:|---:|
| Module size | 369,708 bytes | 196,189 bytes |
| Cold/per-invocation p50 | 522.5 ms to start Spin and first HTTP response | 25.6 ms per `wasmtime run` |
| Cold/per-invocation p95 | 646.4 ms | 1185.4 ms, including first-run host/cache outlier |
| Warm/process p50 | 23.14 ms HTTP request through persistent Spin server | 25.37 ms per process invocation |

Wasmtime samples:

```text
wasmtime run samples: 1185.4 ms, 23.4 ms, 24.3 ms, 27.2 ms, 25.6 ms
hyperfine p50: 25.37 ms
hyperfine p95: 40.45 ms
```

### Design answers h-j

**h) Why the Spin component cannot run under bare `wasmtime run`**

The Spin component is a wasi-http component hosted by Spin's trigger system. It exports an HTTP handler shape, not a standalone `_start` CLI entrypoint. Bare `wasmtime run` expects a command-style WASI module, so the Spin component needs a wasi-http host such as Spin rather than the plain CLI runner.

**i) What Spin adds over bare Wasmtime**

Spin adds the HTTP server loop, manifest parsing, route matching, component loading, wasi-http integration, outbound-host policy, logging, and runtime management. It uses Wasmtime internally, but it turns a component into an HTTP application platform.

**j) When each execution model fits**

Per-invocation `wasmtime run` fits batch-style jobs, filters, command hooks, and CGI-shaped request handlers where startup-per-request is acceptable. Spin's persistent wasi-http model fits API endpoints and edge services where routing, policy, and repeated HTTP requests should be handled by a long-lived host.
