# Lab 12 — Bonus: WebAssembly Containers

> Lab was done on my MacBook Air M4 (macOS, arm64). Toolchain: Spin 4.0.2,
> TinyGo 0.41.1 (using go version go 1.26.4), wasmtime 46.0.1 for the bonus. 

What I have done?

---

## Task 1 — Spin component serving /time

### main.go

```
package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v3/http"
)

var msk = time.FixedZone("MSK", 3*60*60)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		now := time.Now().In(msk)
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w,
			`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow (UTC+3)"}`,
			now.Unix(),
			now.Format(time.RFC3339),
			now.Format("15:04"),
		)
	})
}

func main() {}
```

Note the shape: the handler registers in `init()` via `spinhttp.Handle`, `main()` is
empty, because  Spin host calls the exported handler, there is no server loop of mine.

### spin.toml

```
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

Route locked to `/time`; `allowed_outbound_hosts = []` — the component can't open a
single outbound connection, least privilege by default.

> Toolchain reality check (Spin 4.x). The spec is written for Spin 3.x and its
> TinyGo `-buildmode=c-shared` build command. Spin 4.x's `http-go` template scaffolds
> a different toolchain: the build command is `go tool componentize-go build`, which
> compiles with the standard Go compiler (go1.26 here) targeting the WASM
>  component model, not TinyGo. Two  effects I hit: the SDK import moved to
> `spin-go-sdk/v3` (my first draft used the older `/v2`, which pulls an incompatible
> build path that demands a `wit/` dir — the fix was simply v3, matching the
> template), and there is no `-buildmode=c-shared` flag to discuss anymore.

### Build + run

```
ephy@Starless-night moscow-time % spin build
Building component moscow-time with `go tool componentize-go build`
Finished building all Spin components
ephy@Starless-night moscow-time % ls -lh main.wasm
-rw-r--r--  1 ephy  staff   4.6M Jul 11 11:38 main.wasm
ephy@Starless-night moscow-time % spin up &
ephy@Starless-night moscow-time % curl -s http://127.0.0.1:3000/time
{"unix":1783759207,"iso":"2026-07-11T11:40:07+03:00","hour_minute":"11:40","timezone":"Europe/Moscow (UTC+3)"}
```

Valid Moscow-time JSON, `iso` correctly at `+03:00`. Note the size: **4.6 MB** — the
standard-Go component-model build is much fatter than a TinyGo `.wasm` would be
(TinyGo trades stdlib completeness for tiny binaries). That contrast shows up sharply
in the Bonus, where the TinyGo CLI module is a fraction of this.

### Design questions

**a) Browser WASM (`js/wasm`) vs server WASM (`wasip1`) — what's missing, what's gained?**
The `js/wasm` target assumes a JavaScript host: system calls are shimmed through
JavaScript, and the module gets the browser event loop and DOM APIs — useless outside
a browser. The `wasip1` (server) target drops all of that and speaks WASI instead: a
small, capability-based system interface (files, clocks, env, stdout). What's
missing in the server target is the implicit browser/JS ambient world; what you
gain is a host-independent, sandboxed artifact that runs under any WASI runtime
(wasmtime, Spin, …) with no browser in sight.

This lab shows the split twice: my CLI module targets bare `wasip1` and runs under
`wasmtime run`, while the Spin component targets the richer `wasi-http` world and
needs a host that implements it (Spin 4) — same WASI lineage, different interface
level.

**b) Why `-buildmode=c-shared`? (and what Spin 4.x does instead)**
The premise: the Spin host doesn't want a program, it wants a library. A plain
WASI build exports `_start` — run `main`, exit. Spin's wasi-http model instead
instantiates the module once and calls an exported HTTP handler per request, so the
module has to be a reactor (exported functions, no run-once `main`) rather than a
command. On the Spin 3.x TinyGo path that's exactly what `-buildmode=c-shared`
produced. The current Spin 4.x template reaches the same goal through
`go tool componentize-go build` and Spin Go SDK v3. It produces a WebAssembly
component exporting the `wasi-http` handler interface, so there is no separate
`-buildmode=c-shared` flag. `main()` remains present for the Go compiler but is not
used as an HTTP server loop. Spin owns the listener and may create, pool, or reuse
component instances according to its runtime settings; it does not guarantee one
instance for the entire application lifetime.

**c) `allowed_outbound_hosts = []` — capability model vs `--network none`.**
Same spirit, different granularity and different default. In the capability model
the component can do nothing it wasn't explicitly granted. Docker's `--network none` is an opt-in removal: the container by default
gets a network stack, and I have to remember to take it away; and it's all-or-nothing
per container. Spin can say "this component may talk to api.example.com and nothing
else" — per-component, declarative, reviewable in git. Deny-by-default beats
subtract-what-you-remember.

**d) Which TinyGo stdlib gap did I hit?**
On Task 1 — none, and that's itself the interesting part: Spin 4.x builds with the
standard Go compiler via `componentize-go`, not TinyGo, so full tzdata and
reflection-heavy `encoding/json` are all available here. The gap becomes real in the
Bonus, which does use real TinyGo (`tinygo build -target=wasip1`): there
`time.LoadLocation("Europe/Moscow")` fails because TinyGo embeds no tzdata. I wrote
both variants against `time.FixedZone("MSK", 3*3600)` from the start — portable
across both toolchains (Moscow has no DST since 2014), and building the JSON with
`fmt.Fprintf`/`%q` instead of `encoding/json` over `map[string]any` sidesteps
TinyGo's partial reflection too. So the same source compiles cleanly on both the
standard-Go component path and the TinyGo CLI path.

---

## Task 2 — perf vs the lab 6 container

Targets measured with the same
hyperfine/curl method 

| Dimension              | Lab 6 Docker | Lab 12 WASM/Spin |
|------------------------|-------------:|-----------------:|
| Artifact size          | 21.7 MB image (5.32 MB content) | 4.6 MB main.wasm |
| Cold start (median of 5) | ~760 ms | 53 ms |
| Warm latency p50       | 6.1 ms | 3.9 ms |
| Warm latency p95       | 12.4 ms | 7.9 ms |

```
Warm (hyperfine, 50 runs):
  curl … :3000/time   (Spin/WASM)    mean 4.5 ms ± 2.0   -> p50 3.9, p95 7.9
  curl … :8080/health (Lab 6 Docker) mean 6.7 ms ± 2.4   -> p50 6.1, p95 12.4

Cold (kill -> restart -> time to first 200, 5 samples each):
  Spin:   53, 48, 77, 50, 54 ms                 -> median 53 ms
  Docker: 26177, 702, 767, 704, 760 ms          -> median 760 ms (steady)
```

Two comments here.

 The warm gap is modest (detail below).  The cold gap is the real
story — Spin is ~14× faster cold (53 ms vs 760 ms). Note the Docker outlier: the
first cold run took 26 seconds, because that was Docker Desktop's own daemon/VM
warming from idle, the four steady runs then settle at ~700-760 ms. Spin has no such
warm-up — there's no daemon, no image extraction, no namespace/network setup, just
wasmtime instantiating a 4.6 MB module.

Warm, the Spin component is ~1.6× faster than the container — both are sub-10 ms, so
this is really measuring the two runtimes' request paths (wasmtime instance already
warm vs the container's network/proxy hop). hyperfine flagged that both dip under
5 ms, i.e. curl/shell startup is a real chunk of each number — but since both columns
are measured identically, the relative gap holds.

On size: the Spin artifact is a single 4.6 MB `.wasm` module; the Docker deliverable
is a 21.7 MB image (a whole filesystem — distroless base + binary + seed). WASM ships
just the module, the runtime lives on the host. (Worth noting the 4.6 MB is fat for
WASM — it's the standard-Go component build; a TinyGo module would be far smaller, as
the Bonus shows.)

### Design questions

**e) What dominates each cold start?**
Docker: everything around the process — pull/extract layers into a filesystem,
create namespaces + cgroups, set up the network bridge and port mapping, then run
the binary (and my compose adds a healthcheck cadence on top). The app itself is
ready in milliseconds: the container preparation costs the rest. 

Spin: read one .wasm
file, wasmtime compiles/instantiates the module (or loads a precompiled one), wire
the HTTP trigger — no image, no namespaces, no virtual NIC. That's why WASM cold
start sits an order of magnitude (or two) below containers.

**f) Where is WASM clearly better; where is Docker still right?**
WASM wins where cold starts are frequent and density matters: FaaS / edge handlers,
per-request scale-to-zero, thousands of tenants per box, plugin systems inside a
host app. Docker stays right for everything that is an operating-system process:
QuickNotes itself (needs a real filesystem for notes.json), databases, anything
multi-threaded, anything leaning on the full stdlib/OS (tzdata! reflection!), or
just software you don't get to recompile. Rule of thumb from Reading 12: WASM ships
functions, containers ship systems. This lab is the demo — porting one endpoint
was pleasant, porting all of QuickNotes would be a fight with TinyGo.

**g) What attack does the WASM sandbox make harder than namespaces?**
Kernel attack surface. A container process talks to the shared kernel directly —
hundreds of syscalls; one kernel bug (dirty-pipe-style) or a misconfigured mount and
you've escaped to the host. A WASM module can't make a syscall at all: it calls
host functions the runtime chose to expose, inside linear memory with bounds
checks. Concretely harder: container-escape via kernel exploit — the classic
multi-tenant nightmare — because the guest never touches the kernel interface;
its entire world is the handful of capabilities in the manifest.

---

## Bonus — two execution models: Spin vs bare wasmtime

### The CLI variant

`wasm-cli/main.go` — same Moscow-time logic, zero SDK: reads `REQUEST_METHOD` /
`PATH_INFO` from env (CGI-style), prints JSON to stdout:

```go
package main

import (
	"fmt"
	"os"
	"time"
)

var msk = time.FixedZone("MSK", 3*60*60)

func main() {
	if os.Getenv("REQUEST_METHOD") != "GET" || os.Getenv("PATH_INFO") != "/time" {
		fmt.Println(`{"error":"only GET /time is served"}`)
		os.Exit(1)
	}
	now := time.Now().In(msk)
	fmt.Printf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow (UTC+3)"}`+"\n",
		now.Unix(), now.Format(time.RFC3339), now.Format("15:04"),
	)
}
```

Built with real TinyGo this time (`-target=wasip1`), and it shows in the size:

```
ephy@Starless-night wasm-cli % tinygo build -o main.wasm -target=wasip1 -no-debug .
ephy@Starless-night wasm-cli % ls -lh main.wasm
-rw-r--r--  1 ephy  staff   190K Jul 11 11:51 main.wasm
ephy@Starless-night wasm-cli % wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
{"unix":1783759908,"iso":"2026-07-11T11:51:48+03:00","hour_minute":"11:51","timezone":"Europe/Moscow (UTC+3)"}
```

190 KB — vs the 4.6 MB Spin component. Same logic, ~25× smaller, because this is
TinyGo

And the counter-proof — the Task 1 component refuses to run under bare `wasmtime run`:

```
ephy@Starless-night wasm-cli % wasmtime run ../wasm/moscow-time/main.wasm ; echo "exit=$?"
Error: failed to run main module `../wasm/moscow-time/main.wasm`

Caused by:
    0: component imports instance `wasi:http/types@0.3.0-rc-2026-03-15`, but a matching implementation was not found in the linker
    1: instance export `fields` has the wrong type
    2: resource implementation is missing
exit=1
```

The error is precise: the Spin component imports the `wasi:http/types` world and
expects the host to provide it. `wasmtime run` is a plain WASI-command host — it has
no wasi-http implementation to link, so it refuses. Only a wasi-http host — `spin up`,
or in principle `wasmtime serve` — can drive it, and only if the host's wasi-http
version matches the one the component imports (`0.3.0-rc-2026-03-15`). `spin up` is
the host I used, and it drives it fine.

| | size | execution model | latency |
|---|---:|---|---:|
| Spin component (`main.wasm`) | 4.6 MB | persistent wasi-http server — instantiated once, serves many | ~53 ms cold once, then ~4 ms warm |
| WASI CLI (`wasm-cli/main.wasm`) | 190 KB | per-invocation — every `wasmtime run` = fresh instantiate + exit | ~5.4 ms **every** call |

```
Benchmark: wasmtime run … wasm-cli/main.wasm
  Time (mean ± σ):   5.4 ms ± 1.3 ms   Range: 4.3 … 8.4 ms   20 runs
```

The interesting twist: 5.4 ms per full instantiate is barely above Spin's 4 ms warm —
because this module is tiny (190 KB), instantiation is nearly free, so the
"pay-every-time" model costs almost nothing here. The two models diverge as the module
(and its instantiate cost) grows: Spin amortizes one ~53 ms instantiate across
thousands of warm requests, while the CLI re-pays instantiation on every single call.
At 190 KB that's cheap; at 4.6 MB (the Spin component's size) per-invocation would
hurt and the persistent server clearly wins.

### Design questions

**h) Why can't the Spin component run under bare `wasmtime run`?**

`wasmtime run` executes a WASI command with a run-once `_start` entry point. The
Task 1 artifact is a `wasi-http` component and imports request/response resources
from `wasi:http/types`. It therefore requires a host implementing that exact
interface version.

Spin 4 supplies that interface version, which is the host I used. (`wasmtime serve`
is a wasi-http host too, but it only drives the component if its wasi-http version
matches the one imported — I didn't rely on it here.) The CLI module, by contrast,
imports only base WASI facilities — environment variables, clocks, stdout — so it
runs correctly through `wasmtime run`.

**i) Spin uses wasmtime inside — what does Spin add?**
Wasmtime is just the engine. Spin adds the server around it: the long-running HTTP
front that listens, the manifest (`spin.toml`) mapping routes → components, instance
pooling / pre-instantiation so warm requests don't pay setup, the capability policy
(`allowed_outbound_hosts`), build integration (`spin build`), and the app lifecycle
(`spin up`, deploy targets). Basically wasmtime : Spin ≈ container runtime :
docker-compose — engine vs application platform on top of it.

**j) When does each execution model fit?**
Per-invocation `wasmtime run` (CGI model): rare, bursty, isolation-above-all jobs —
a CI step, a batch transform, an untrusted user-submitted job where you want a
fresh sandbox per run and don't care about ms-level overhead per call. Persistent
wasi-http server (Spin): actual request traffic — an API endpoint, an edge function —
where paying instantiation once and serving thousands of warm requests is the whole
point. Same binary format, opposite amortization.
