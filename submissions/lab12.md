# Lab 12 Submission

Branch for this lab:

```text
git checkout feature/lab11
git checkout -b feature/lab12
```

Working setup used for this lab:

- host: macOS 26.0.1, arm64, Apple M4
- Spin: `4.0.2`
- TinyGo: `0.41.1`
- Wasmtime: `46.0.1`
- Hyperfine: `1.20.0`
- Docker baseline image: `quicknotes:lab6`

Version note:

The lab text was written around Spin 3.4 and `spin-go-sdk/v2`, but my installed toolchain is newer. I followed the current `spin new -t http-go` scaffold from Spin 4.0.2, which generated a Go component project on `github.com/spinframework/spin-go-sdk/v3` and uses `go tool componentize-go build` instead of the older TinyGo command shown in the lab text. This matches the acceptance criterion that says to scaffold from the current template for the installed Spin version.

Artifacts saved in:

- `artifacts/lab12/spin-warm.json`
- `artifacts/lab12/docker-warm.json`
- `artifacts/lab12/spin-cold.txt`
- `artifacts/lab12/spin-cold-summary.txt`
- `artifacts/lab12/docker-cold.txt`
- `artifacts/lab12/docker-cold-summary.txt`
- `artifacts/lab12/wasmtime-run.txt`
- `artifacts/lab12/wasmtime-run-summary.txt`
- `artifacts/lab12/spin-cold-1.log` to `artifacts/lab12/spin-cold-5.log`
- `artifacts/lab12/docker-cold-1.log` to `artifacts/lab12/docker-cold-5.log`

## Task 1 - Build a WASM endpoint with the Spin SDK

### 1.1 Scaffold and implementation

Scaffold command:

```text
mkdir -p wasm && cd wasm
spin new -t http-go moscow-time --accept-defaults
```

Important implementation note:

The generated Spin 4 project was correct in principle, but in my local setup `go tool componentize-go build` also needed a version-matched `componentize-go.toml` and `wit/world.wit`. I added those files from the installed `spin-go-sdk/v3` module so that the build stayed aligned with the scaffolded SDK version instead of switching to an old tutorial layout.

Relevant files:

- [main.go](/Users/tatyana/Documents/DevOps-Intro/wasm/moscow-time/main.go)
- [spin.toml](/Users/tatyana/Documents/DevOps-Intro/wasm/moscow-time/spin.toml)
- [componentize-go.toml](/Users/tatyana/Documents/DevOps-Intro/wasm/moscow-time/componentize-go.toml)
- [world.wit](/Users/tatyana/Documents/DevOps-Intro/wasm/moscow-time/wit/world.wit)

Handler behavior:

- registers with `spinhttp.Handle(...)`
- accepts only `GET /time`
- returns Moscow time as JSON
- sets `Content-Type: application/json`
- keeps `allowed_outbound_hosts = []`

### 1.2 `spin.toml`

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["Tatyana Shmykova <limefox413@gmail.com>"]
description = ""

[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []
[component.moscow-time.build]
command = "go tool componentize-go build"
watch = ["**/*.go", "go.mod"]
```

Analysis:

This is the current Spin 4 scaffold style. The route and outbound policy match the lab requirements. The build command is different from the older Spin 3 text, but it is the correct command for the installed version and the generated SDK project.

### 1.3 Build proof

Commands:

```text
cd wasm/moscow-time
spin build
stat -f '%z bytes %N' main.wasm
shasum -a 256 main.wasm
```

Output:

```text
Building component moscow-time with `go tool componentize-go build`
Note: /opt/homebrew/Cellar/go/1.26.4/libexec/bin/go does not support async operation; will use downloaded version.
See https://github.com/golang/go/pull/76775 for details.
Using /Users/tatyana/Library/Caches/componentize-go/v2/go-darwin-arm64-bootstrap/bin/go.
Finished building all Spin components

4828182 bytes main.wasm
aca513c7a4fbfc455a59b7b450e88052aafca16a212c04f0df40c762eabba0f4  main.wasm
```

Analysis:

The component built successfully and produced a reproducible artifact hash for this source state. The WASM component is much smaller than the Lab 6 Docker image, but still larger than a raw TinyGo WASI CLI module because the Spin component includes the component model bindings and wasi-http interface glue.

### 1.4 Run and verification

I used an alternate listen port during verification because another local service already occupied `3000` in this workspace.

Commands:

```text
cd wasm/moscow-time
spin up --listen 127.0.0.1:3001
curl -s http://127.0.0.1:3001/time | python3 -m json.tool
curl -i -s http://127.0.0.1:3001/other
```

Output:

```json
{
    "unix": 1784033907,
    "iso": "2026-07-14T15:58:27+03:00",
    "hour_minute": "15:58",
    "timezone": "UTC+3"
}
```

```text
HTTP/1.1 404 Not Found
content-length: 0
date: Tue, 14 Jul 2026 12:58:26 GMT
```

Analysis:

The component returns valid JSON for `GET /time` and correctly rejects a different path with `404 Not Found`. The Moscow time is produced with a fixed UTC+3 zone, which avoids TinyGo time-zone database issues.

### 1.5 Design answers

#### a) Browser WASM vs server WASM

`go build -target=js/wasm` targets the browser JavaScript host. It depends on JavaScript glue and browser APIs, not the server-side WASI environment. `tinygo build -target=wasi` or the current Spin component build targets a server runtime where there is no DOM, no browser event loop, and no JavaScript bridge. What I gain on the server side is a small sandboxed artifact with a clear capability boundary and fast startup inside a WASM runtime.

#### b) Why the build command needs `-buildmode=c-shared`

In the older Spin 3 TinyGo flow, Spin expected the module to export the ABI symbols required by the host runtime, not just a normal CLI `_start` entrypoint. `-buildmode=c-shared` shapes the exports in the way the host expects. In the current Spin 4 scaffold, this detail is hidden behind `go tool componentize-go build`, but the idea is the same: the runtime needs a component that exports the right host-facing interface, not a plain standalone executable module.

#### c) Why `allowed_outbound_hosts = []` matters

Spin uses capability-based security. A component can only use resources that the host explicitly grants in the manifest. With `allowed_outbound_hosts = []`, this component has no permission to call external HTTP services. This is similar in spirit to `docker run --network none`, but the model is tighter: the restriction is described as an explicit capability grant for the component rather than only as a network namespace setting around a whole container.

#### d) TinyGo stdlib gaps I hit

The main issue was not core HTTP logic, but platform support around the WASM build flow. For time handling, I avoided `time.LoadLocation("Europe/Moscow")` because TinyGo and WASI builds often do not have embedded tzdata. I also built the JSON manually with `fmt.Fprintf(...)` instead of relying on a more reflection-heavy encoding path. That keeps the code simple and avoids the common TinyGo pain points described in the lab.

## Task 2 - Perf comparison vs Lab 6 container

### 2.1 Baseline container

The comparison target was the Lab 6 Docker image already present on the machine.

Command:

```text
docker image inspect quicknotes:lab6 --format 'size={{.Size}} id={{.Id}}'
```

Output:

```text
size=5198572 id=sha256:1084306438af7a05ea47907b6995ae7f0d784c4ee109ee8b0115ad1654c62c75
```

To run it locally I used:

```text
docker run -d --name lab12-quicknotes \
  -e DATA_PATH=/tmp/data/notes.json \
  -e SEED_PATH=/seed.json \
  -p 18080:8080 \
  quicknotes:lab6
```

Health check output:

```json
{
    "notes": 4,
    "status": "ok"
}
```

Analysis:

This image is already quite small for Docker because Lab 11 produced a minimal reproducible image. That makes the WASM comparison stricter and more interesting.

### 2.2 Warm latency

Commands:

```text
hyperfine --warmup 5 --runs 50 --export-json artifacts/lab12/spin-warm.json \
  'curl -s -o /dev/null http://127.0.0.1:3001/time'

hyperfine --warmup 5 --runs 50 --export-json artifacts/lab12/docker-warm.json \
  'curl -s -o /dev/null http://127.0.0.1:18080/health'
```

Measured summary:

```text
spin-warm.json p50_ms=3.978 p95_ms=4.703 min_ms=3.399 max_ms=5.390
docker-warm.json p50_ms=6.638 p95_ms=7.606 min_ms=5.783 max_ms=9.474
```

Analysis:

In the warm state, the Spin endpoint was slightly faster on this machine. Both services are already very fast, so the absolute difference is small, but Spin kept the lower median and lower tail latency.

### 2.3 Cold start

Method:

- Spin: start `spin up`, poll `/time` until the first HTTP 200, then stop the process
- Docker: start a fresh container on port `18081`, poll `/health` until the first HTTP 200, then remove the container
- sample count: 5 each

Raw summaries:

```text
spin cold:
samples_ms=154.948, 71.624, 72.810, 70.278, 71.494
p50_ms=71.624
min_ms=70.278
max_ms=154.948

docker cold:
samples_ms=167.347, 98.008, 80.462, 98.538, 94.183
p50_ms=98.008
min_ms=80.462
max_ms=167.347
```

Analysis:

Spin started faster than Docker in the median case on this laptop. The Docker results also showed a wider spread, especially on the slowest sample, which is expected because container startup includes more host runtime work around process and networking setup.

### 2.4 Comparison table

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|---|---:|---:|
| Artifact size | 5,198,572 bytes | 4,828,182 bytes |
| Cold start p50 | 98.008 ms | 71.624 ms |
| Warm latency p50 | 6.638 ms | 3.978 ms |
| Warm latency p95 | 7.606 ms | 4.703 ms |

### 2.5 Design answers

#### e) What dominates each platform's cold start

For Docker, the cold path includes container runtime setup, namespace and cgroup preparation, filesystem mounting, and network plumbing before the service can answer. For Spin, the main cost is loading and instantiating the WebAssembly component inside Wasmtime plus starting the HTTP serving loop. That is less work than a full container start, so the median startup was lower in my measurements.

#### f) When WASM is better and when Docker is still right

WASM is clearly attractive for small sandboxed plugins, edge handlers, policy modules, request filters, and other short-lived code where startup speed and strong isolation matter. Docker is still the right choice for large general-purpose services that need the normal Linux userspace, mature debugging tooling, broader language and library support, background processes, and complex networking or storage integration.

#### g) Multi-tenant safety

A WASM platform makes several tenant-escape paths harder because the module does not start with ambient filesystem, process, or network access. For example, a malicious plugin cannot simply spawn shell commands or scan the host network unless the runtime grants those capabilities. In a container platform, a bad kernel bug or an overly broad container configuration can expose much more host surface.

## Bonus task - two WASM execution models

### B.1 Standalone WASI CLI module

Files:

- [main.go](/Users/tatyana/Documents/DevOps-Intro/wasm-cli/main.go)
- [go.mod](/Users/tatyana/Documents/DevOps-Intro/wasm-cli/go.mod)

Build command:

```text
cd wasm-cli
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
```

Run command:

```text
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
```

Output:

```json
{"unix":1784033809,"iso":"2026-07-14T15:56:49+03:00","hour_minute":"15:56","timezone":"UTC+3"}
```

Artifact size:

```text
195075 bytes
833197ebd4121e29984fbf2ea6992c29066985688e672ddeb59e0104f3e83691  main.wasm
```

Analysis:

The standalone WASI CLI module is much smaller than the Spin component because it is just a plain WASI program with `_start`. It does not carry the wasi-http component interface and it does not integrate with Spin's routing layer.

### B.2 Why the Spin component does not run under bare `wasmtime run`

Command:

```text
cd wasm/moscow-time
wasmtime run ./main.wasm
```

Output:

```text
Error: failed to run main module `./main.wasm`

Caused by:
    0: component imports instance `wasi:http/types@0.3.0-rc-2026-03-15`, but a matching implementation was not found in the linker
    1: instance export `fields` has the wrong type
    2: resource implementation is missing
```

Analysis:

This is the expected failure mode for a wasi-http component under a plain CLI launcher. The Spin artifact is waiting for a host that implements the wasi-http interfaces. Bare `wasmtime run` expects a standalone program with `_start`, so the two execution models are not interchangeable.

### B.3 Per-invocation Wasmtime timing

Method:

- run `wasmtime run` 10 times
- each invocation is a cold start because the runtime loads the module again for every process

Summary:

```text
samples_ms=20.754, 7.051, 7.092, 8.583, 9.757, 8.338, 6.745, 6.809, 6.233, 6.686
p50_ms=7.072
min_ms=6.233
max_ms=20.754
```

Comparison:

| Runtime model | Artifact | Size | Startup / invocation p50 |
|---|---|---:|---:|
| Spin persistent server | `wasm/moscow-time/main.wasm` | 4,828,182 bytes | 74.757 ms cold server start |
| Wasmtime CLI per invocation | `wasm-cli/main.wasm` | 195,075 bytes | 7.072 ms per run |

Analysis:

The numbers are not directly identical because they measure different things. Spin's figure includes launching the server process and making the first HTTP response available. The Wasmtime CLI figure is the cost of one standalone WASI process invocation that prints JSON to stdout. The CLI module is much smaller and very fast per run, but it does not provide a ready-to-serve HTTP host by itself.

### B.4 Design answers

#### h) Why the Task 1 Spin component cannot run under bare `wasmtime run`

The Task 1 artifact is a component that exports and imports the wasi-http interface expected by an HTTP-capable host. It is not a plain WASI executable with `_start` as its main contract. `wasmtime run` launches CLI-style WASI programs, so it does not provide the routing, request objects, or resource implementations that the component needs.

#### i) What Spin adds on top of bare Wasmtime

Spin adds the HTTP server loop, route matching from `spin.toml`, manifest-driven capability policy, component wiring for wasi-http, and a developer workflow around `spin build` and `spin up`. Wasmtime is the execution engine; Spin is the higher-level application platform around it.

#### j) When each execution model fits

Per-invocation `wasmtime run` fits batch-style filters, one-shot tools, or CGI-like transformations where each request can map to one process run. Spin's persistent server fits HTTP APIs, edge handlers, and service endpoints that must stay ready to accept requests without paying full runtime setup on every call.

## Conclusion

Lab 12 is complete for all three parts. I built a Spin-based Moscow time endpoint, measured it against the Lab 6 Docker image, and then rebuilt the same logic as a standalone WASI CLI module to show why a Spin component and a raw Wasmtime program solve different problems even though both use WebAssembly.
