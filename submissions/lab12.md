# Lab 12 Submission

## Tooling versions

```bash
spin --version
tinygo version
wasmtime --version
hyperfine --version
```
Output:
```text
spin 3.4.0 (4f671be 2025-08-26)
tinygo version 0.41.1 windows/amd64 (using go version go1.26.4 and LLVM version 20.1.1)
wasmtime 46.0.1 (823d1b8f2 2026-06-24)
hyperfine 1.20.0
```

Templates installed from the canonical repo (no hand-written `spin.toml`):

```
spin templates install --git https://github.com/spinframework/spin --update
```

## Task 1: Build a WASM Endpoint with the Spin SDK

### Scaffold

```
mkdir wasm && cd wasm
spin new -t http-go moscow-time --accept-defaults
```

This generated `go.mod` (SDK `github.com/spinframework/spin-go-sdk/v2 v2.2.1`), `spin.toml`, and a stub `main.go`. The only manifest edit I made was the route (`/...` to `/time`); `allowed_outbound_hosts = []` and the build command were already correct from the scaffold.

### main.go

See at [`wasm/moscow-time/main.go`](/wasm/moscow-time/main.go) and pasted here for reference:

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
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		// TinyGo ships no embedded tzdata, so time.LoadLocation("Europe/Moscow")
		// fails at runtime. Moscow has been a fixed UTC+3 offset since 2014, so
		// shifting the UTC wall clock is the robust substitute.
		now := time.Now().UTC()
		moscow := now.Add(3 * time.Hour)

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"unix":%d,"iso":%q,"hour_minute":%q}`+"\n",
			now.Unix(),
			moscow.Format("2006-01-02T15:04:05")+"+03:00",
			moscow.Format("15:04"),
		)
	})
}
```

### spin.toml

See at [`wasm/moscow-time/spin.toml`](/wasm/moscow-time/spin.toml) and pasted here for reference:

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["G-Akleh <ghadeer_akleh@hotmail.com>"]
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

### Build

```bash
spin build
```
output:
```
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components
```

```bash
Get-Item main.wasm | Select-Object Name, Length
```
output:
```
Name      Length
----      ------
main.wasm 368632
```

`main.wasm` is 368,632 bytes, about 360 KB.

### Run and verify

```bash
spin up
```

```bash
curl.exe -s http://127.0.0.1:3000/time
```

```json
{"unix":1784145857,"iso":"2026-07-15T23:04:17+03:00","hour_minute":"23:04"}
```

```bash
curl.exe -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:3000/time
```

```
HTTP 200
```

### Design Questions

**a) Browser WASM vs server WASM**

`js/wasm` needs a JS host: it links against `wasm_exec.js` and reaches the DOM/browser only through `syscall/js`, with no native filesystem or network syscalls. `wasip1` targets WASI instead, so the module runs standalone under Spin/wasmtime with host-granted capabilities (clocks, files, wasi-http), but loses anything depending on `syscall/js`, the DOM, or a browser event loop.

**b) Why does the build command need `-buildmode=c-shared`?**

Removing the flag broke the build with `wasm-ld: error: undefined symbol: main.main`, since without it TinyGo defaults to a WASI command module requiring a `func main()` entrypoint, and this handler only has `init()`. `-buildmode=c-shared` instead builds a library that exports named functions, the ABI Spin's wasi-http host actually calls per request.

**c) `allowed_outbound_hosts = []` and capability-based security vs `--network none`**

The component model is deny-by-default: a component only reaches a host capability if the manifest lists it, so `allowed_outbound_hosts = []` blocks network access before any packet is sent, checked at the import level. Docker's `--network none` is coarser, removing the whole network namespace at the kernel level, so allowing just one host normally needs extra tooling (egress proxy, iptables) instead of a one-line manifest entry.

**d) TinyGo stdlib gaps**

`time.LoadLocation("Europe/Moscow")` fails at runtime with `unknown time zone Europe/Moscow` since TinyGo ships no tzdata, confirmed by building and running a test component; that's why the handler uses a fixed UTC+3 offset instead. I also tested the lab's other flagged gotcha, `json.Encode` of `map[string]any`, and it built and ran fine under TinyGo 0.41.1, so that particular limitation didn't reproduce here.

---

## Task 2: Perf Comparison vs Lab 6 Container

### Test rig

Windows 11 Pro, Intel Core i5-11400H @ 2.70GHz, 16 GB RAM. Docker Desktop backend: WSL2 (kernel `5.15.153.1-microsoft-standard-WSL2`). Spin runs as a native Windows process; the Docker container runs inside the WSL2 VM, so every `/health` request crosses the Windows-to-WSL2 network boundary (Docker Desktop's NAT), which is not overhead a native Linux host would pay. That gap is a real property of this environment, not just container-vs-WASM cost, and is mentioned again in question (f).

Both services were booted and confirmed healthy before measuring:

```bash
docker compose up --build -d
curl.exe -s http://localhost:8080/health
```
Output:
```json
{"notes":4,"status":"ok"}
```

```bash
spin up
curl.exe -s http://127.0.0.1:3000/time
```
Output:
```
HTTP 200
```

### Warm latency

```bash
hyperfine --warmup 5 --runs 50 \
  --command-name "spin-time" "curl.exe -s -o NUL http://127.0.0.1:3000/time" \
  --command-name "docker-health" "curl.exe -s -o NUL http://localhost:8080/health" \
  --export-json warm-latency.json
```
Output:
```
Benchmark 1: spin-time
  Time (mean ± σ):      28.8 ms ±   5.4 ms    [User: 9.8 ms, System: 17.1 ms]
  Range (min … max):    24.8 ms …  53.7 ms    50 runs

Benchmark 2: docker-health
  Time (mean ± σ):     236.8 ms ±   6.8 ms    [User: 14.8 ms, System: 15.0 ms]
  Range (min … max):   228.3 ms … 254.9 ms    50 runs

Summary
  spin-time ran
    8.23 ± 1.57 times faster than docker-health
```

p50/p95 computed from the raw per-run times in the JSON export:

| Command       | p50 (ms) | p95 (ms) |
|---------------|---------:|---------:|
| spin /time    |    26.91 |    40.62 |
| docker /health|   234.92 |   251.39 |

### Cold start

Spin: kill the process, restart, poll until the first successful response, 5 runs.

```bash
for i in 1 2 3 4 5; do
  taskkill //F //IM spin.exe
  start=$(date +%s%N)
  spin up --listen 127.0.0.1:3000 &
  until curl.exe -s -o NUL http://127.0.0.1:3000/time; do sleep 0.01; done
  end=$(date +%s%N)
  echo "run $i: $(( (end-start)/1000000 )) ms"
done
```
Output:
```
run 1: 602 ms
run 2: 617 ms
run 3: 596 ms
run 4: 586 ms
run 5: 591 ms
```

Docker: `compose down` (containers only, volume kept), `compose up -d`, poll until first successful response, 5 runs.

```bash
for i in 1 2 3 4 5; do
  docker compose down
  start=$(date +%s%N)
  docker compose up -d
  until curl.exe -s -o NUL http://localhost:8080/health; do sleep 0.02; done
  end=$(date +%s%N)
  echo "run $i: $(( (end-start)/1000000 )) ms"
done
```
Output:
```
run 1: 2407 ms
run 2: 2806 ms
run 3: 2460 ms
run 4: 2480 ms
run 5: 2493 ms
```

Median cold start: Spin 596 ms, Docker 2480 ms.

### Artifact size

```bash
docker images quicknotes:lab6 --format "{{.Size}}"
ls -la wasm/moscow-time/main.wasm
```
Output:
```
13.7MB
-rw-r--r-- 1 Ghadeer 197121 368647 Jul 15 23:14 main.wasm
```

`main.wasm` is 368,647 bytes versus the image's 13,657,327 bytes, about 37x smaller.

### Table

| Dimension              | Lab 6 Docker |    Lab 12 WASM/Spin |
|------------------------|-------------:|---------------------:|
| Artifact size           |     13.7 MB |               360 KB |
| Cold start (p50)        |    2,480 ms |                596 ms |
| Warm latency p50        |     234.9 ms |               26.9 ms |
| Warm latency p95        |     251.4 ms |               40.6 ms |

### Design Questions

**e) What dominates each platform's cold start?**

Docker's ~2.5s is dominated by container/image setup: creating the network and volume mounts, the `volume-init` sidecar running to completion, then the distroless process starting, all happening inside the WSL2 VM Docker Desktop uses on this machine. Spin's ~600ms is wasmtime engine startup plus compiling the wasm module (no ahead-of-time cache), which is why it is roughly 4x faster despite that WSL2 crossing not applying to it.

**f) For what workloads is WASM clearly better, and where is Docker still right?**

WASM/Spin wins for latency-sensitive, bursty, or scale-to-zero workloads (edge functions, request handlers with irregular traffic) where its sub-second cold start and single-digit-millisecond warm latency matter. Docker is still the right choice when the workload needs a full OS surface (arbitrary binaries, shells, complex networking, existing containerized dependencies) or when TinyGo's stdlib gaps (question d) would force awkward workarounds.

**g) Multi-tenant safety: what concrete attack does a WASM platform make harder?**

WASM's capability model denies a component any host access (filesystem, network, syscalls) unless the manifest explicitly grants it, checked at the import boundary rather than relying on kernel enforcement. This makes container-escape-style attacks (breaking out of a Linux namespace to reach the host kernel or other tenants) much harder, since a WASM component has no syscall interface to attack in the first place, only the narrow set of host functions it was explicitly given.

---

## Bonus Task: Two WASM Execution Models

### main.go

File in [`wasm-cli/main.go`](/wasm-cli/main.go) and pasted here for reference:

```go
package main

import (
	"fmt"
	"os"
	"time"
)

// Standalone WASI CLI module: no Spin SDK. Mirrors the older CGI-over-WASM
// (WAGI) model, reading the "request" from environment variables and
// writing the response body straight to stdout.
func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "GET" || path != "/time" {
		fmt.Printf(`{"error":"not found","method":%q,"path":%q}`+"\n", method, path)
		return
	}

	now := time.Now().UTC()
	moscow := now.Add(3 * time.Hour)

	fmt.Printf(`{"unix":%d,"iso":%q,"hour_minute":%q}`+"\n",
		now.Unix(),
		moscow.Format("2006-01-02T15:04:05")+"+03:00",
		moscow.Format("15:04"),
	)
}
```

### Build

```bash
cd wasm-cli
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
```
Output:
```
(no output, exit 0)
```

```bash
ls -la main.wasm
```
Output:
```
-rw-r--r-- 1 Ghadeer 197121 194451 Jul 15 23:44 main.wasm
```

### Run

Windows/Git Bash note: a leading `/` in an argument gets auto-translated to a Windows path by MSYS before reaching a native `.exe` (`/time` became `C:/Program Files/Git/time`). `MSYS_NO_PATHCONV=1` disables that translation.

```bash
MSYS_NO_PATHCONV=1 wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
```
Output:
```json
{"unix":1784148319,"iso":"2026-07-15T23:45:19+03:00","hour_minute":"23:45"}
```

```bash
MSYS_NO_PATHCONV=1 wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/notes main.wasm
MSYS_NO_PATHCONV=1 wasmtime run --env REQUEST_METHOD=POST --env PATH_INFO=/time main.wasm
```
Output:
```
{"error":"not found","method":"GET","path":"/notes"}
{"error":"not found","method":"POST","path":"/time"}
```

### Comparison

**Trying the Task 1 component under bare wasmtime**, to see the failure directly rather than assume it:

```bash
wasmtime run wasm/moscow-time/main.wasm
```
Output:
```
(no output, exit 0)
```

```bash
wasmtime run --invoke _start wasm/moscow-time/main.wasm
```
Output:
```
Error: failed to run main module `main.wasm`

Caused by:
    no func export named `_start` found
```

```bash
wasmtime serve --addr 127.0.0.1:3020 wasm/moscow-time/main.wasm
```
Output:
```
Error: The serve command currently requires a component
```

```bash
xxd -l 8 wasm/moscow-time/main.wasm
```
Output:
```
00000000: 0061 736d 0100 0000                      .asm....
```

**Per-invocation cold start**, `wasmtime run` on `wasm-cli/main.wasm`, 5 runs:

```bash
for i in 1 2 3 4 5; do
  start=$(date +%s%N)
  MSYS_NO_PATHCONV=1 wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm >/dev/null
  end=$(date +%s%N)
  echo "run $i: $(( (end-start)/1000000 )) ms"
done
```
Output:
```
run 1: 285 ms
run 2: 108 ms
run 3: 118 ms
run 4: 104 ms
run 5: 108 ms
```

| Dimension                | Spin (Task 1)          | Standalone WASI CLI (Bonus) |
|--------------------------|------------------------:|-----------------------------:|
| Module size              | 368,647 bytes           | 194,451 bytes                |
| Cold start                | ~596 ms (once, persistent server) | ~108 ms (median, every invocation) |
| Per-request cost after cold start | ~27 ms (warm, p50) | ~108 ms (no warm state, pays full cost again) |

### Design Questions

**h) Why can't the Task 1 Spin component run under bare `wasmtime run`?**

Two separate reasons, both confirmed above: `wasmtime run` looks for a `_start` command entrypoint, which this module does not export (built with `-buildmode=c-shared`, not a WASI command module), so it silently does nothing. It also is not a real Component-Model binary (the header's version field is `01 00 00 00`, a core module, not the `0d 00 01 00` a component would have), which is why `wasmtime serve` rejects it outright with "requires a component." Only Spin's own host knows how to adapt this core module's exports into the wasi-http world.

**i) Spin uses wasmtime internally. So what does Spin add on top of bare wasmtime?**

Spin adds the adaptation layer that turns the TinyGo core module's C-ABI exports into a real wasi-http component, instance pooling and reuse across requests, the persistent wasi-http server loop (bare wasmtime only gets this via `serve`, and only for genuine components), the `spin.toml` manifest/routing layer mapping paths to components, and enforcement of `allowed_outbound_hosts`.

**j) Two execution models: when does each fit?**

Per-invocation `wasmtime run` fits short-lived, infrequent, or one-shot jobs (a CLI tool, a cron-style batch task, a build step) where paying the full ~108ms every time is fine because there is no warm state to lose between calls. Spin's persistent wasi-http server fits request-serving workloads with any meaningful volume: the ~596ms cost is paid once, then every request after that is ~27ms, so it wins as soon as more than a handful of requests arrive.
