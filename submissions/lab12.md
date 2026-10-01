# Lab 12 - WebAssembly Containers with Spin

## Environment

Build tooling was pinned and installed locally because the 1 GB Vagrant VM was too memory-constrained for the first TinyGo compile.

```text
Spin: 3.4.0
TinyGo: 0.41.0
Go used for TinyGo: 1.26.2
Binaryen wasm-opt: version_133
Runtime/bench host: Vagrant Ubuntu 22.04 VM
Docker Engine: 29.8.1
hyperfine: 1.12.0
```

The component was scaffolded with:

```bash
mkdir -p wasm
cd wasm
spin templates install --git https://github.com/spinframework/spin --branch v3.4.0 --upgrade
spin new -t http-go moscow-time --accept-defaults
```

## main.go

```go
package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		now := time.Now().UTC().Add(3 * time.Hour)

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(
			w,
			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":\"Europe/Moscow\",\"utc_offset\":\"+03:00\"}\n",
			now.Unix(),
			now.Format(time.RFC3339),
			now.Format("15:04"),
		)
	})
}
```

## spin.toml

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["vagrant"]
description = ""

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

## Build and Run Proof

`spin build` output:

```text
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components

main.wasm 367473 bytes
```

`spin up --listen 0.0.0.0:3000` served:

```text
Serving http://0.0.0.0:3000
Available Routes:
  moscow-time: http://0.0.0.0:3000/time
```

`curl http://127.0.0.1:3000/time`:

```json
{"unix":1790385003,"iso":"2026-09-26T01:10:03Z","hour_minute":"01:10","timezone":"Europe/Moscow","utc_offset":"+03:00"}
```

## Task 1 Design Questions

a) Browser WASM targets JavaScript host APIs (`js/wasm`) and assumes a browser event loop, DOM/JS imports, and JS glue. Server WASM with `wasip1` does not have browser APIs or ambient OS access; it gets WASI capabilities instead. The gain is a smaller, host-neutral server module with a clearer sandbox and explicit imports.

b) Spin hosts a wasi-http component and expects exported component ABI functions, not a normal CLI `_start`. `-buildmode=c-shared` makes TinyGo emit the exports that the Spin Go SDK and Spin host need for HTTP request handling.

c) `allowed_outbound_hosts = []` gives the component no outbound network capability. In a capability model, the host grants only specific powers and the guest cannot ask the kernel for arbitrary network access. Docker's `--network none` also blocks networking, but it relies on Linux namespaces around a full process; WASM starts from no ambient host access and adds capabilities explicitly.

d) I avoided two common TinyGo gaps: timezone database loading and reflection-heavy JSON encoding. The handler uses `time.Now().UTC().Add(3 * time.Hour)` instead of `time.LoadLocation("Europe/Moscow")`, and formats JSON with `fmt.Fprintf` instead of `encoding/json` over `map[string]any`.

## Task 2 Measurements

Test rig: both services ran inside the Ubuntu 22.04 Vagrant VM. Spin served the `main.wasm` component on port 3000. Docker served the Lab 6 QuickNotes image on port 8080. Warm latency used:

```bash
hyperfine --warmup 5 --runs 50 \
  'curl -fsS http://127.0.0.1:3000/time >/dev/null' \
  'curl -fsS http://127.0.0.1:8080/health >/dev/null'
```

Cold start was measured as start command to first successful local `curl`, five samples each.

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|---|---:|---:|
| Artifact size | 22,555,564 bytes | 367,473 bytes |
| Cold start samples | 406, 419, 383, 367, 395 ms | 53, 54, 52, 56, 57 ms |
| Cold start p50 | 395 ms | 54 ms |
| Warm latency p50 | 6.844 ms | 8.731 ms |
| Warm latency p95 | 8.022 ms | 9.563 ms |

Warm hyperfine output:

```text
curl -fsS http://127.0.0.1:3000/time >/dev/null
  mean 8.842 ms, min 7.955 ms, max 10.160 ms

curl -fsS http://127.0.0.1:8080/health >/dev/null
  mean 6.964 ms, min 5.548 ms, max 8.593 ms
```

## Task 2 Design Questions

e) Docker cold start is dominated by container creation: setting up namespaces, cgroups, filesystem layers, process startup, and the Go service boot path. Spin cold start is dominated by loading and instantiating the WASM component in wasmtime plus setting up the wasi-http request path. With local artifacts, Spin was much faster in this lab.

f) WASM is clearly better for small request handlers, plugin systems, edge-style functions, and multi-tenant extension points where startup time and sandboxing matter. Docker is still right for full services, legacy binaries, apps needing broad OS APIs, long-running processes with mature observability, and software that depends on libc, filesystems, or language runtimes TinyGo/WASI cannot cover cleanly yet.

g) WASM makes host escape through accidental syscalls much harder because the guest cannot directly invoke arbitrary Linux syscalls. For example, a compromised WASM component without filesystem or outbound-network capabilities cannot simply open `/etc/passwd`, connect to the metadata service, or scan internal networks unless the host explicitly grants those capabilities.

## Bonus Task

The standalone `wasmtime run` bonus was not attempted in this PR. This submission covers Task 1 and Task 2.
