# Lab 12 - Bonus: WebAssembly Containers

## Summary

This lab implements a QuickNotes-style Moscow time endpoint in two WebAssembly shapes:

- `wasm/moscow-time`: a Spin `wasi-http` component served by `spin up` at `GET /time`.
- `wasm-cli`: a standalone WASI CLI module run with `wasmtime run`, using the older CGI/WAGI-shaped environment-variable model.

The implementation intentionally keeps the endpoint small. It avoids `time.LoadLocation("Europe/Moscow")` because TinyGo/WASI builds usually do not include IANA tzdata, and it avoids `encoding/json` reflection over `map[string]any` by formatting a fixed JSON response directly.

## Test rig and tool versions

Machine:

```text
MacBook Pro (MacBookPro18,3), Apple M1 Pro, 8 cores, 16 GB RAM.
```

OS:

```text
ProductName:        macOS
ProductVersion:     14.3.1
BuildVersion:       23D60
```

Tool versions:

```console
$ spin --version
spin 4.0.2 (bfc7543 2026-06-23)

$ tinygo version
tinygo version 0.41.1 darwin/arm64 (using go version go1.26.4 and LLVM version 20.1.1)

$ go version
go version go1.26.4 darwin/arm64

$ hyperfine --version
hyperfine 1.20.0

$ wasmtime --version
wasmtime 46.0.1 (823d1b8f2 2026-06-24)

$ docker --version
Docker version 29.2.1, build a5c7197
```

## Task 1 - Spin endpoint

### Files

The Spin component lives in `wasm/moscow-time`.

`wasm/moscow-time/main.go`:

```go
package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

var moscow = time.FixedZone("MSK", 3*60*60)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		if r.Method != http.MethodGet {
			w.Header().Set("Allow", http.MethodGet)
			w.WriteHeader(http.StatusMethodNotAllowed)
			_, _ = w.Write([]byte(`{"error":"method not allowed"}`))
			return
		}

		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(moscowTimeJSON(time.Now())))
	})
}

func main() {}

func moscowTimeJSON(now time.Time) string {
	local := now.In(moscow)
	return fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":%q,"utc_offset":%q}`,
		local.Unix(),
		local.Format(time.RFC3339),
		local.Format("15:04"),
		"Europe/Moscow",
		"+03:00",
	)
}
```

`wasm/moscow-time/spin.toml`:

```toml
spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["kuji"]
description = "Lab 12 Moscow time endpoint compiled as a Spin WebAssembly component."

[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []

[component.moscow-time.build]
command = "tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -no-debug -o main.wasm ."
watch = ["**/*.go", "go.mod"]
```

### Build and run evidence

```console
$ cd wasm/moscow-time
$ spin build
Building component moscow-time with `tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components

$ ls -lh main.wasm
-rw-r--r--  1 kuji  staff   304K Jul  3 03:44 main.wasm

$ stat -f '%z bytes' main.wasm
311771 bytes

$ spin up --listen 127.0.0.1:3000
Logging component stdio to ".spin/logs/"

Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000/time
```

Verification:

```console
$ curl -i http://127.0.0.1:3000/time
HTTP/1.1 200 OK
content-type: application/json
content-length: 124
date: Fri, 03 Jul 2026 00:45:11 GMT

{"unix":1783039511,"iso":"2026-07-03T03:45:11+03:00","hour_minute":"03:45","timezone":"Europe/Moscow","utc_offset":"+03:00"}

$ curl -s http://127.0.0.1:3000/time | python3 -m json.tool
{
    "unix": 1783039511,
    "iso": "2026-07-03T03:45:11+03:00",
    "hour_minute": "03:45",
    "timezone": "Europe/Moscow",
    "utc_offset": "+03:00"
}
```

Expected JSON shape:

```json
{
    "unix": 1783051200,
    "iso": "2026-07-03T03:00:00+03:00",
    "hour_minute": "03:00",
    "timezone": "Europe/Moscow",
    "utc_offset": "+03:00"
}
```

### Design questions

#### a) Browser WASM vs server WASM

`go build -o m.wasm -target=js/wasm` produces a browser-oriented module that expects JavaScript glue and browser/JS host APIs. That is the wrong ABI for a server runtime such as Spin or wasmtime.

`tinygo build -target=wasip1` produces a WASI module: it uses WASI imports for system capabilities such as clocks, random, stdio, and preopened resources. The server target does not have the browser DOM, JavaScript event loop, or browser APIs. In exchange, it gains a small portable server-side artifact with explicit runtime capabilities instead of ambient browser integration.

#### b) Why `-buildmode=c-shared`?

Spin's Go SDK adapts the handler into exports that the Spin host can call as a `wasi-http` component. TinyGo's `-buildmode=c-shared` is what exposes the expected ABI symbols instead of building only a normal `_start`-style command module. Without it, the module can compile but Spin cannot call the HTTP handler correctly, usually surfacing as a runtime HTTP 500 or a component export error.

#### c) `allowed_outbound_hosts = []`

Spin uses a capability-based model: the component starts with no ambient network access and the manifest grants only the outbound hosts it needs. `allowed_outbound_hosts = []` is the strictest setting, so this time endpoint cannot call the network at all.

Docker's `--network none` also blocks network access, but it is a container-level Linux networking configuration. Spin's policy is part of the component manifest and fits the WASI model where host interactions are explicit imports/capabilities. Both can deny network access; Spin makes that denial part of the component's declared capability contract.

#### d) TinyGo stdlib gap hit in this lab

The relevant gap is time-zone data. `time.LoadLocation("Europe/Moscow")` is not reliable in a TinyGo/WASI module because the IANA timezone database is not available by default. The implementation uses `time.FixedZone("MSK", 3*60*60)` instead, which gives the correct Moscow UTC+3 offset without filesystem tzdata.

I also avoided reflection-heavy JSON generation with `map[string]any`. A fixed response built with `fmt.Sprintf` and `%q` is simpler and more robust under TinyGo.

## Task 2 - Perf comparison against Lab 6 Docker

### Commands

Run Spin:

```bash
cd wasm/moscow-time
spin build
spin up
```

Run the Lab 6 container in a second terminal:

```bash
docker run --rm --name quicknotes-lab6 -p 8080:8080 quicknotes:lab6
```

If the image is missing, rebuild it from the Lab 6 branch first:

```bash
git worktree add ../DevOps-Intro-lab6 feature/lab6
docker build -t quicknotes:lab6 ../DevOps-Intro-lab6/app
```

For these local measurements I built a non-submission tag from the same Lab 6 branch to avoid overwriting the existing local `quicknotes:lab6` image:

```console
$ git worktree add /tmp/DevOps-Intro-lab6 feature/lab6
$ docker build -t quicknotes:lab12-bench /tmp/DevOps-Intro-lab6/app
...
naming to docker.io/library/quicknotes:lab12-bench done

$ docker image inspect quicknotes:lab12-bench --format '{{.Size}}'
5313483

$ docker exec quicknotes-lab12-bench-260703 /healthcheck
# exited 0
```

For the final Docker timing run I bound the container explicitly to loopback on `127.0.0.1:18081`, which made Docker Desktop forwarding reliable:

```console
$ docker run -d --name quicknotes-lab12-recheck -p 127.0.0.1:18081:8080 quicknotes:lab12-bench

$ curl --noproxy '*' -v --connect-timeout 2 --max-time 4 http://127.0.0.1:18081/health
< HTTP/1.1 200 OK
{"notes":0,"status":"ok"}
```

Warm latency:

```bash
hyperfine --warmup 5 --runs 50 \
  'curl -fsS http://127.0.0.1:3000/time >/dev/null'

hyperfine --warmup 5 --runs 50 \
  'curl --noproxy "*" -fsS http://127.0.0.1:18081/health >/dev/null'
```

Artifact size:

```bash
ls -lh wasm/moscow-time/main.wasm
stat -f '%z bytes' wasm/moscow-time/main.wasm
docker image inspect quicknotes:lab12-bench --format '{{.Size}}'
```

Cold start sampling:

```bash
# Spin: repeat at least 5 times
/usr/bin/time -p sh -c 'cd wasm/moscow-time && spin up >/tmp/spin-lab12.log 2>&1 & pid=$!; until curl -fsS http://127.0.0.1:3000/time >/dev/null; do sleep 0.02; done; kill $pid'

# Docker: repeat at least 5 times
/usr/bin/time -p sh -c 'docker run --rm --name quicknotes-cold -p 127.0.0.1:18082:8080 quicknotes:lab12-bench >/tmp/docker-lab12.log 2>&1 & cid=$!; until curl --noproxy "*" -fsS http://127.0.0.1:18082/health >/dev/null; do sleep 0.02; done; docker stop quicknotes-cold >/dev/null; wait $cid || true'
```

### Results

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|-----------|-------------:|-----------------:|
| Artifact size | 5,313,483 bytes | 311,771 bytes |
| Cold start p50 | 0.159757 s | 0.024692 s |
| Warm latency p50 | 0.009492 s | 0.005988 s |
| Warm latency p95 | 0.015191 s | 0.006745 s |

Raw cold-start samples:

```text
Docker:
docker cold #1: 0.192349 s ok=True
docker cold #2: 0.172368 s ok=True
docker cold #3: 0.159757 s ok=True
docker cold #4: 0.147498 s ok=True
docker cold #5: 0.144922 s ok=True
p50=0.159757 s

Spin:
spin cold #1: 0.057574 s ok=True
spin cold #2: 0.024047 s ok=True
spin cold #3: 0.024692 s ok=True
spin cold #4: 0.026838 s ok=True
spin cold #5: 0.023557 s ok=True
p50=0.024692 s
```

### Design questions

#### e) What dominates each platform's cold start?

For Docker, cold start is dominated by container runtime work: resolving the image, preparing the container filesystem, configuring namespaces/cgroups/networking, then starting the Linux process. If the image is not cached locally, image pull/extract dominates even more.

For Spin, cold start is dominated by loading the `.wasm` module, compiling or instantiating it through wasmtime, and wiring the `wasi-http` host imports. The artifact is much smaller and the sandbox has less OS setup than a Linux container, so startup should be much lower.

#### f) Where WASM is better and where Docker is still right

WASM is clearly better for tiny request handlers, edge functions, plugin systems, untrusted multi-tenant extensions, and high-fan-out workloads where startup time, artifact size, and sandbox boundaries matter more than OS compatibility.

Docker is still the right default for long-running services, applications with mature database/network libraries, workloads that need arbitrary Linux syscalls or OS packages, and teams that need the full container ecosystem for debugging, observability, and deployment.

#### g) Multi-tenant safety

WASM makes attacks based on ambient host access harder. For example, a compromised plugin cannot simply open `/etc/passwd`, scan the filesystem, create raw sockets, or call unexpected kernel syscalls unless the host explicitly granted those WASI capabilities. A Docker container can be hardened, but it still shares the host kernel and depends heavily on namespace/seccomp/capability configuration.

## Bonus - Two WASM execution models

### Standalone WASI CLI module

`wasm-cli/main.go`:

```go
package main

import (
	"fmt"
	"os"
	"time"
)

var moscow = time.FixedZone("MSK", 3*60*60)

func main() {
	method := envOrDefault("REQUEST_METHOD", "GET")
	path := envOrDefault("PATH_INFO", "/time")

	fmt.Println("Content-Type: application/json")

	if method != "GET" {
		fmt.Println("Status: 405 Method Not Allowed")
		fmt.Println()
		fmt.Println(`{"error":"method not allowed"}`)
		return
	}
	if path != "/time" {
		fmt.Println("Status: 404 Not Found")
		fmt.Println()
		fmt.Println(`{"error":"not found"}`)
		return
	}

	fmt.Println("Status: 200 OK")
	fmt.Println()
	fmt.Println(moscowTimeJSON(time.Now()))
}

func envOrDefault(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func moscowTimeJSON(now time.Time) string {
	local := now.In(moscow)
	return fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":%q,"utc_offset":%q}`,
		local.Unix(),
		local.Format(time.RFC3339),
		local.Format("15:04"),
		"Europe/Moscow",
		"+03:00",
	)
}
```

Build:

```console
$ cd wasm-cli
$ tinygo build -o main.wasm -target=wasi -no-debug ./main.go
```

Run:

```console
$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
Content-Type: application/json
Status: 200 OK

{"unix":1783040328,"iso":"2026-07-03T03:58:48+03:00","hour_minute":"03:58","timezone":"Europe/Moscow","utc_offset":"+03:00"}
```

Command form:

```bash
cd wasm-cli
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
```

Run:

```bash
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
```

Expected output:

```text
Content-Type: application/json
Status: 200 OK

{"unix":1783051200,"iso":"2026-07-03T03:00:00+03:00","hour_minute":"03:00","timezone":"Europe/Moscow","utc_offset":"+03:00"}
```

### Size and cold-start comparison

```console
$ ls -lh wasm/moscow-time/main.wasm wasm-cli/main.wasm
-rw-r--r--  1 kuji  staff   304K Jul  3 03:44 wasm/moscow-time/main.wasm
-rw-r--r--  1 kuji  staff   191K Jul  3 03:58 wasm-cli/main.wasm

$ stat -f '%z bytes' wasm/moscow-time/main.wasm wasm-cli/main.wasm
311771 bytes
196005 bytes

$ hyperfine --warmup 5 --runs 50 \
  'cd wasm-cli && wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm >/dev/null'
Time (mean +/- sigma): 6.0 ms +/- 0.2 ms
```

| Dimension | Spin wasi-http component | Bare wasmtime CLI |
|-----------|-------------------------:|------------------:|
| Module size | 311,771 bytes | 196,005 bytes |
| Cold/per-invocation start p50 | 0.024692 s to first HTTP 200 | 0.005985 s per `wasmtime run` |

Bare wasmtime CLI p95 was 0.006423 s over 50 runs. Spin warm p50/p95 were 0.005988 s and 0.006745 s over 50 `curl` requests.

### Design questions

#### h) Why can't the Spin component run under bare `wasmtime run`?

The Spin component is a `wasi-http` component. Its useful entrypoint is an exported HTTP handler that expects a host implementing the `wasi-http` interfaces. Bare `wasmtime run` expects a command-style WASI module with a `_start` entrypoint. Because those imports/exports are different, the Spin component needs a `wasi-http` host such as Spin, not plain `wasmtime run`.

#### i) What does Spin add on top of wasmtime?

Spin uses wasmtime internally, but adds the HTTP server loop, manifest and routing layer, `wasi-http` host integration, component capability configuration such as `allowed_outbound_hosts`, logging/dev workflow, and runtime management such as efficient component loading and request handling. It turns a low-level WASM runtime into an application server for WASM components.

#### j) When does each execution model fit?

Per-invocation `wasmtime run` fits batch or command-style jobs: a policy check, file transformer, CI helper, or plugin that reads stdin/env and exits.

Spin's persistent `wasi-http` model fits request/response services: edge endpoints, webhooks, small APIs, and multi-tenant HTTP plugins where the platform should own routing, HTTP parsing, and capability policy.
