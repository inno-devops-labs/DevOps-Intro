# Lab 12 submission

## Task 1 — Build a WASM Endpoint with the Spin SDK

### Toolchain versions used

```sh
$ spin --version
spin 4.0.2 (bfc7543 2026-06-23)

$ tinygo version
tinygo version 0.41.1 darwin/arm64 (using go version go1.24.4 and LLVM version 20.1.1)
```

Note: these are newer than the lab's May-2026 pin (Spin 3.4). `spin new -t http-go` on
Spin 4.0.2 scaffolds a *different* default toolchain than the one the lab describes —
see the note under 1.1 below.

### 1.1: Scaffold

```sh
mkdir -p wasm && cd wasm
spin new -t http-go moscow-time --accept-defaults
```

**Deviation from the lab's expected scaffold:** on Spin 4.0.2 the `http-go` template no
longer generates a TinyGo build command. It generates:

```toml
[component.moscow-time.build]
command = "go tool componentize-go build"
```

with `go.mod` requiring `go 1.25.5` and depending on `github.com/bytecodealliance/componentize-go`
(native Go `wasip1` + component adapter, no TinyGo at all) and SDK
`github.com/spinframework/spin-go-sdk/v3`. This is Spin's newer, TinyGo-free path for Go
components. Running `spin build` with this default failed on my machine: componentize-go
downloads its own patched Go toolchain, and that toolchain errored on
`runtime.wasiOnIdle.wrapinfo: relocation target runtime.wasiOnIdle not defined` — a broken
bootstrap build, not something fixable from my end without pinning to specific known-good
toolchain releases.

Since the lab explicitly asks for the **TinyGo** path (`-buildmode=c-shared`, design question b),
I reverted the scaffold to that model by hand:
- `go.mod`: pinned SDK to `github.com/spinframework/spin-go-sdk/v2 v2.2.1` (note: `v2.2.0`'s
  tagged `go.mod` doesn't declare the `/v2` suffix and fails module resolution — `v2.2.1` fixes
  this), `go 1.24`.
- `spin.toml` build command: `tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -no-debug -o main.wasm .`
- Route changed from the scaffold default `/...` to `/time` per the lab's requirement.

This is itself a live example of the lab's own warning: "WASM tooling moves fast — pin your
versions." Even the *current* `http-go` template drifted between when the lab was written and
when I ran it.

### 1.2 / 1.3: `main.go` and `spin.toml`

`wasm/moscow-time/main.go`:

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
		if r.URL.Path != "/time" || r.Method != http.MethodGet {
			http.NotFound(w, r)
			return
		}

		now := time.Now().UTC()
		moscow := now.Add(3 * time.Hour) // Europe/Moscow, UTC+3 (no DST) — TinyGo has no embedded tzdata

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"unix":%d,"iso":%q,"hour_minute":%q,"moscow_time":%q}`,
			now.Unix(),
			moscow.Format("2006-01-02T15:04:05")+"+03:00",
			moscow.Format("15:04"),
			moscow.Format("2006-01-02 15:04:05")+" MSK",
		)
	})
}

// main function must be included for the compiler but is not executed.
func main() {}
```

`wasm/moscow-time/spin.toml`:

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["ilnarkhasanov <4sitescarp@gmail.com>"]
description = ""

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

### 1.6: Run + verify

```sh
$ spin build
Building component moscow-time with `tinygo build -target=wasip1 -gc=leaking -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components

$ ls -lh main.wasm
-rw-r--r--  1 ilnarkhasanov  staff   292K Jul 15 14:21 main.wasm

$ spin up
Logging component stdio to ".spin/logs/"

Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000/time
```

```sh
$ curl -s http://127.0.0.1:3000/time | python3 -m json.tool
{
    "unix": 1784114497,
    "iso": "2026-07-15T14:21:37+03:00",
    "hour_minute": "14:21",
    "moscow_time": "2026-07-15 14:21:37 MSK"
}
```

HTTP 200, valid JSON, correct Moscow (UTC+3) time.

### 1.4: Design questions

**a) Browser WASM vs server WASM**

`go build -target=js/wasm` produces a module that expects a **JavaScript host**: it imports
`env`/`gojs` glue functions the browser's `wasm_exec.js` provides (DOM access, `syscall/js`
bindings, a JS-driven event loop) and has no notion of sockets, filesystem, or a standalone
process model — it's inert without a browser tab running the glue script around it.

`tinygo build -target=wasip1` instead targets **WASI Preview 1**: the module imports
POSIX-like syscalls (`fd_write`, `fd_read`, `clock_time_get`, `random_get`, ...) that any WASI
host (wasmtime, Spin, wasmer) implements natively, no JavaScript involved. What's *missing*
compared to the browser target is anything DOM/JS-specific — there's no `syscall/js`, no way to
touch a webpage. What you *gain* is a hermetic, host-agnostic, capability-scoped executable: it
runs identically under any WASI runtime, its imports are declared and inspectable ahead of time
(instead of "whatever JS glue happens to be loaded"), and it's the shape wasi-http hosts expect
components to have.

**b) Why `-buildmode=c-shared`?**

Spin's wasi-http host doesn't run a `_start`/`main()` entrypoint like a CLI binary — it calls
into the module as a *library*, invoking exported functions per incoming request (in this SDK's
case, the componentized handler that `spinhttp.Handle` wires up plus the WASI cabi
alloc/realloc/free exports the host uses to pass request/response bytes across the wasm/host
boundary). `-buildmode=c-shared` tells TinyGo to build a shared-library-style module that
**exports** those symbols instead of building an executable with an implicit `_start` that the
host would just run once and exit.

I removed the flag and rebuilt to see the real failure:

```sh
$ tinygo build -target=wasip1 -gc=leaking -no-debug -o main.wasm .
$ spin up
...
$ curl -i http://127.0.0.1:3000/time
HTTP/1.1 500 Internal Server Error
```

Spin's log:

```
ERROR spin_trigger_http::server: Error processing request: error while executing at wasm backtrace:
    0:  0x3a545 - main!canonical_abi_realloc
    1:  0x4d156 - <unknown>!allocate_stack
    2:  0x4a672 - <unknown>!cabi_export_realloc

Caused by:
    wasm trap: wasm `unreachable` instruction executed
```

The module still *built* and *loaded*, but its cabi realloc export led into TinyGo's
non-shared-mode runtime init path, which hits an `unreachable` trap instead of behaving as a
library the host can call into repeatedly — exactly the "HTTP 500, empty logic executed"
behavior the lab's pitfalls section describes.

**c) `allowed_outbound_hosts = []` vs Docker `--network none`**

WASM's capability model is **deny-by-default and object-capability-based**: the component has
*no* ambient authority to do anything outside what the host explicitly grants at instantiation
time. `allowed_outbound_hosts = []` isn't a network policy bolted on after the fact — outbound
HTTP simply isn't a capability this component was ever handed, so from inside the sandbox
there's no socket API to call in the first place, only the specific host-provided imports Spin
chose to wire up (and it wired up none for outbound `wasi-http`).

`docker --network none` is enforcement at a *lower, coarser* layer: the container still runs as
a normal Linux process with the full Linux syscall surface (`socket()`, `connect()`, raw
sockets, etc. are all still callable) — it's just that the kernel's network namespace has no
interfaces to route through beyond loopback. A container process can still call `socket()`; it
just gets `ENETUNREACH`/nothing to connect to. It's a perimeter restriction on an otherwise
fully-privileged process, whereas the WASM sandbox restricts what the process *can even express
as a call* — the difference between "the door is locked" and "there is no door."

**d) TinyGo stdlib gaps hit in this lab**

- **Time-zone data**: `time.LoadLocation("Europe/Moscow")` fails under TinyGo/wasip1 — no
  embedded IANA tzdata and no filesystem to load `/usr/share/zoneinfo` from inside the sandbox
  (and `allowed_outbound_hosts = []` means no fetching it either). Worked around with
  `time.Now().UTC().Add(3 * time.Hour)`, per the lab's suggested pitfall fix, since Moscow has
  had no DST since 2014.
- **Reflection-heavy JSON**: I avoided `encoding/json.Marshal` on a `map[string]any` up front
  (per the pitfalls list) and built the JSON body directly with `fmt.Fprintf` and `%q` verbs
  instead — simpler and avoids TinyGo's known reflection limitations in `encoding/json`.

---

## Task 2 — Perf Comparison vs Lab 6 Container

### Test rig

- MacBook Pro, Apple Silicon (arm64), macOS 26.5.1 (Darwin 25.5.0)
- Docker Desktop 28.3.0 (Linux VM backend on macOS — not a native Linux kernel; adds a
  virtualization + port-proxy hop that a native Linux host wouldn't have)
- Spin 4.0.2, `spin up` run natively (no VM) — this asymmetry (native process vs VM'd container)
  favors Spin on this specific machine and is itself part of the answer to design question (e)
- `quicknotes:lab6` is the pre-built Lab 6 image (5.51 MB, `scratch` base, static Go binary)
- `moscow-time` is the Task 1 Spin component (`main.wasm`, 292 KB TinyGo/wasip1 build)

### 2.1: Measurements

**Setup.** Docker container needs an explicit named volume owned by uid 65532 (the `scratch`
image's nonroot user) for `/data`, plus `ADDR`/`DATA_PATH` env vars — `docker run` with no
extra flags exits immediately with `mkdir data: permission denied`. Spin needs no such setup.

```sh
docker volume create quicknotes-test-data
docker run --rm -v quicknotes-test-data:/data busybox chown -R 65532:65532 /data
docker run -d --name quicknotes-lab6-test -p 18080:8080 \
  -e ADDR=:8080 -e DATA_PATH=/data/notes.json \
  -v quicknotes-test-data:/data quicknotes:lab6

spin up --listen 127.0.0.1:3001   # from wasm/moscow-time
```

**Warm latency** (`hyperfine --warmup 5 --runs 50`, `curl -s -o /dev/null <url>`; both
endpoints already up and serving):

```sh
$ hyperfine --warmup 5 --runs 50 'curl -s -o /dev/null http://127.0.0.1:3001/time'
Time (mean ± σ):       8.8 ms ±   0.8 ms    [User: 3.2 ms, System: 2.9 ms]
Range (min … max):     7.9 ms …  13.1 ms    50 runs

$ hyperfine --warmup 5 --runs 50 'curl -s -o /dev/null http://localhost:18080/health'
Time (mean ± σ):       9.7 ms ±   1.4 ms    [User: 3.0 ms, System: 2.6 ms]
Range (min … max):     8.5 ms …  16.1 ms    50 runs
```

p50/p95 computed from hyperfine's `--export-json` raw sample times:

| | Spin `/time` | Docker `/health` |
|---|---:|---:|
| p50 | 8.67 ms | 9.17 ms |
| p95 | 9.89 ms | 11.97 ms |

Caveat: most of this ~9 ms is `curl` process-spawn + macOS loopback overhead common to both
targets, not server-side work — the *relative* gap (Docker ~10-20% slower at p95) is the
meaningful signal, not the absolute numbers.

**Cold start** (kill/remove, restart, time from launch command to first successful response;
5 samples each, `date +%s%N` wall-clock):

```sh
# Spin: spin up (fresh process) -> poll curl until 200
run 1: 142 ms   # first run, cold page cache for the wasm file
run 2: 52 ms
run 3: 49 ms
run 4: 50 ms
run 5: 50 ms
# median: 50 ms

# Docker: docker run -d (fresh container) -> poll curl until 200
run 1: 205 ms
run 2: 312 ms
run 3: 250 ms
run 4: 237 ms
run 5: 266 ms
# median: 250 ms
```

**Artifact size:**

```sh
$ docker image inspect quicknotes:lab6 --format='{{.Size}}'
5505208
$ ls -la wasm/moscow-time/main.wasm
298943
```

### 2.2: Table

| Dimension              | Lab 6 Docker |    Lab 12 WASM/Spin |
|-------------------------|-------------:|---------------------:|
| Artifact size           |     5.51 MB |             292 KB (~18.4× smaller) |
| Cold start (p50/median) |      250 ms |                 50 ms (5× faster) |
| Warm latency p50        |      9.17 ms |               8.67 ms |
| Warm latency p95        |     11.97 ms |               9.89 ms |

### 2.3: Design questions

**e) What dominates each platform's cold start?**

For Docker on this rig, the dominant cost is **container/VM machinery**, not image extraction
(the image is already pulled and its layers cached locally): `docker run` has to allocate a new
container, set up its network namespace and the Docker Desktop Linux-VM port-proxy that forwards
`18080` on the macOS host into the VM's network namespace, mount the named volume, then exec
the entrypoint. None of that is "cold-start the app" — it's "cold-start the isolation
boundary." On native Linux this would be cheaper (no VM hop), but namespace/cgroup setup and
the OCI runtime handshake (`containerd` → `runc`) still add a fixed per-container tax that a
plain process doesn't pay.

For Spin, cold start is **wasmtime instantiating the module**: mmap-ing/validating the 292 KB
wasm binary, compiling it (or loading a cached compilation artifact) and initializing its linear
memory, then Spin's HTTP trigger routing the request to the instance. There's no VM, namespace,
or separate network stack to stand up — `spin up` is itself a normal host process, so its
"cold start" is closer to "cold-start a normal binary" than "cold-start a container."

**f) For what workloads is WASM clearly better, and where is Docker still right?**

WASM/Spin is the better fit for **short-lived, high-fan-out, latency-sensitive request
handlers** — exactly this lab's shape: a stateless endpoint that needs to spin up fast (or scale
to zero and cold-start on demand), sandboxed with minimal blast radius, and where the whole app
fits the "single function, single trigger" component model (edge functions, webhook handlers,
plugin/extension execution, multi-tenant SaaS logic where each tenant's code must be
strictly isolated from every other tenant's).

Docker is still the right tool once the workload needs **things the WASM/WASI component model
doesn't give you well today**: long-running stateful processes, arbitrary outbound networking
and non-HTTP protocols, a full POSIX/filesystem surface, existing binaries/libraries you can't
recompile to wasm (native deps, cgo, GPU/driver access), or a large existing ops ecosystem
(sidecars, service mesh, `docker compose` multi-service topologies) that isn't yet
component-model-native. QuickNotes itself — a full CRUD service with a JSON file store, health
checks, and a `docker-compose.yml`-shaped deployment — is squarely in Docker's comfort zone;
only the single stateless `/time` slice was worth porting to WASM in this lab.

**g) Multi-tenant safety: what concrete attack does WASM make harder?**

**Cross-tenant memory/syscall confusion via a kernel or container-runtime escape.** Linux
namespace/cgroup isolation still shares one kernel across all tenants' containers; a kernel bug
(e.g. a namespace-escape or `runc`-class CVE) or a misconfigured capability/mount lets one
tenant's container reach another's process, filesystem, or host resources — this class of bug
recurs regularly (CVE-2019-5736, various `runc`/`containerd` breakouts). WASM's sandbox is
enforced by the **language-level type system and linear-memory bounds checking of the wasm
runtime itself**, not by kernel-level process/namespace separation: a component literally cannot
form a pointer or syscall to memory or a host capability it wasn't explicitly imported (this
lab's `allowed_outbound_hosts = []` is exactly that capability grant, made explicit and static
per-tenant in the manifest, versus a container's implicit "everything the kernel allows unless
you remembered to drop it"). That makes the specific attack of "escape my sandboxed unit and
touch another tenant's data or the host" structurally harder — it requires a bug in the wasm
runtime's own compiler/verifier (a much smaller, more auditable trust base than an entire Linux
kernel), not a namespace misconfiguration or kernel privilege-escalation bug.
