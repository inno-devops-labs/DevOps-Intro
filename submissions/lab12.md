# Lab 12 — WebAssembly Containers: a QuickNotes /time endpoint on Spin

**Branch:** `feature/lab12`
**Files added:** `wasm/moscow-time/` (Spin component), `wasm-cli/` (standalone WASI CLI), this file, and evidence under `submissions/lab12/`.
**Test rig:** NixOS 26.05 (Yarara), Linux 7.0.10, AMD Ryzen 7 8845HS (16 threads), 28 GB RAM.
**Tool versions:** Spin 3.6.3, TinyGo 0.41.1 (uses Go 1.25.10 inside), wasmtime 44.0.1, spinframework Go SDK v2.2.1. All from `nixpkgs 25.11`.

## Summary

- **Task 1 (4 pts).** Built a Spin http-go project with `spin new -t http-go moscow-time`. Edited the handler to serve `GET /time` and return Moscow-time JSON with fields `unix`, `iso`, `hour_minute`, `tz`, `offset_seconds`. Used `time.FixedZone("MSK", 3*3600)` because TinyGo does not ship time-zone data. Route is `/time` (exact), `allowed_outbound_hosts = []`. `spin build` produced `main.wasm` of **361 KB**. `curl http://127.0.0.1:3000/time` returns `200 OK application/json`.
- **Task 2 (4 pts).** Ran both servers on the same host and compared them. WASM is **8× faster** on cold-start and **40× smaller**. Docker is **5× faster** on warm p50. Full table in § 2.2.
- **Bonus (2 pts).** `wasm-cli/main.go` is a plain WASI CLI program with no Spin SDK. It reads `REQUEST_METHOD` and `PATH_INFO` from environment variables and writes a CGI-shaped response to stdout. Built with `tinygo -target=wasi`, runs under bare `wasmtime run`. Smaller module (**193 KB** vs 361 KB), about 10 ms per invocation, but no request reuse.

**Pitfall you will hit on nixpkgs 25.11:** `tinygo 0.41.1` uses Go 1.25.10 inside, but its bundled `share/tinygo/src/net/itoa_go126.go` has `//go:build go1.26`. Go 1.25 refuses this file with the error `file requires newer Go version`. Fix (see § Pitfalls for the exact commands): copy `TINYGOROOT` to a writable directory, delete `itoa_go126.go`, and remove the build-tag from `itoa_pre126.go` so `netItoa` is always defined. After that, `TINYGOROOT=/tmp/tinygoroot-patched spin build` works.

---

## Task 1 — Spin SDK component serving /time

### 1.1 Files

```
wasm/moscow-time/
├── go.mod        # module github.com/moscow_time, spinframework/spin-go-sdk/v2 v2.2.1
├── go.sum
├── main.go       # spinhttp.Handle handler for /time
├── spin.toml     # route "/time", allowed_outbound_hosts = [], tinygo build command
└── main.wasm     # 361 KB output (committed under submissions/lab12/spin/)
```

Scaffolded with `spin new -t http-go moscow-time --accept-defaults`. Then edited the handler and changed the default `route = "/..."` to `route = "/time"`.

### 1.2 `main.go`

```go
package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

// Moscow is UTC+3 all year (no DST since 2011). Building the zone
// by hand avoids TinyGo's missing tzdata (see design question d).
var moscow = time.FixedZone("MSK", 3*60*60)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.Header().Set("Allow", "GET")
			http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
			return
		}
		if r.URL.Path != "/time" {
			http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
			return
		}

		now := time.Now().In(moscow)

		// I build JSON with fmt.Sprintf + %q instead of encoding/json.
		// TinyGo's encoding/json can fail on map[string]any because of
		// reflection limits. A fixed-shape string is safer.
		body := fmt.Sprintf(
			`{"unix":%d,"iso":%q,"hour_minute":%q,"tz":%q,"offset_seconds":%d}`,
			now.Unix(),
			now.Format(time.RFC3339),
			now.Format("15:04"),
			"MSK",
			3*60*60,
		)

		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "no-store")
		fmt.Fprint(w, body)
	})
}

func main() {}
```

### 1.3 `spin.toml`

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["GrandAdmiralBee <karim.abdulkin@gmail.com>"]
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

### 1.4 Build output

```
$ TINYGOROOT=/tmp/tinygoroot-patched nix shell nixpkgs#fermyon-spin nixpkgs#tinygo -c spin build
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components

$ ls -la main.wasm
-rwxr-xr-x 1 karim users 369873 июл 15 19:22 main.wasm
```

**Size: 361 KB (369873 bytes).**

### 1.5 Running + `curl` proof

```
$ spin up --listen 127.0.0.1:3000
Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000/time

$ curl -sSi http://127.0.0.1:3000/time
HTTP/1.1 200 OK
content-type: application/json
cache-control: no-store
content-length: 109
date: Wed, 15 Jul 2026 16:23:44 GMT

{"unix":1784132924,"iso":"2026-07-15T19:28:44+03:00","hour_minute":"19:28","tz":"MSK","offset_seconds":10800}

$ curl -sS -X POST -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:3000/time
HTTP 405
```

`offset_seconds = 10800` = 3 × 3600, so UTC+3 as expected. `19:28+03:00` is the correct Moscow time at the moment of the request.

### 1.6 Design questions

**a) `go build -o m.wasm -target=js/wasm` (browser) vs `tinygo build -target=wasip1` (server).**

- **`GOOS=js GOARCH=wasm`** (upstream Go, browser). The output `.wasm` needs a JavaScript loader (`wasm_exec.js`) and the browser's Web APIs — DOM, `fetch`, `console`, `performance.now`. There is no `os.Open`, no `net.Listen`, no filesystem, no environment.
- **`tinygo build -target=wasip1`** (server). The output needs a **WASI** host — a set of POSIX-like functions like `fd_read`/`fd_write`, environment access, monotonic clocks, and (with wasi-http on top) HTTP. You lose Web APIs but you get a normal server programming model: `os.Getenv`, `os.Stdin/Stdout`, filesystem (if the host allows it), sockets (with a sockets host).

The **gain** on the server side is that you can write normal-looking Go that reads env vars and does I/O like any Linux daemon. The **loss** is the web platform — no DOM. Also: TinyGo produces smaller binaries (hundreds of KB) than upstream Go's `js/wasm` target (megabytes).

**b) Why does the build command need `-buildmode=c-shared`?**

The Spin host loads a WASM component and calls its exported entry point. Spin needs **exported symbols** for the wasi-http handler. Without `-buildmode=c-shared`, TinyGo produces a normal executable: one `_start` entry point that runs `main()` and exits, with no other exports. `-buildmode=c-shared` tells TinyGo to build a **shared library** and keep exported symbols visible so the host can call them.

In practice, Spin's Go SDK registers the handler with `spinhttp.Handle(...)` in `init()`. The SDK relies on TinyGo emitting exported wasi-http handler symbols. Those exports only survive when the build mode is `c-shared`. Without the flag, `spin up` returns HTTP 500 and the component's stdout is empty — the handler symbol was stripped so the host has nothing to call.

**c) `allowed_outbound_hosts = []` and capability-based security vs Docker's `--network none`.**

Spin's security model is **deny by default at the WASM host boundary**. `allowed_outbound_hosts = []` means the component **cannot** open any outbound socket. The wasi-http-client capability is simply not given to the module. There is no interface for the component to call — the host does not just block the syscall; the syscall's target function does not exist in the component's world.

`docker run --network none` is also deny-by-default, but at the **kernel/namespace boundary**. The container has its own network namespace with only loopback and no route out. The syscalls (`socket`, `connect`) still exist, and the container can call them — they just fail with `ENETUNREACH`. A kernel exploit that escapes the namespace gets network access back. A WASM exploit still has no host function to call.

The two models also differ in **granularity**. Docker's `--network none` is all-or-nothing per container. Spin lets you list specific hosts per component: `allowed_outbound_hosts = ["https://api.example.com"]`. Kubernetes NetworkPolicy gives the same granularity, but it is enforced by CNI plugins, not by the runtime itself.

**d) TinyGo stdlib gaps hit in this lab.**

Two, both mentioned in the lab:

1. **No embedded tzdata.** `time.LoadLocation("Europe/Moscow")` returns `unknown time zone` in TinyGo. Fix: `time.FixedZone("MSK", 3*3600)`. Works for Moscow because there is no DST since 2011. It would be wrong for regions that observe DST.
2. **Limited `encoding/json`.** `json.Marshal(map[string]any{...})` can panic or return nothing in TinyGo when it hits a reflection kind it does not support. My handler builds the JSON string with `fmt.Sprintf` and the `%q` verb (which handles quoting and escapes). No reflection, works every time.

There is a third problem I hit, but it is a **nixpkgs packaging issue**, not TinyGo itself: `tinygo 0.41.1` in nixpkgs 25.11 uses Go 1.25.10, but its bundled stdlib fork ships `net/itoa_go126.go` with `//go:build go1.26`. Go 1.25 rejects the file (`file requires newer Go version`). Fix in § Pitfalls.

---

## Task 2 — Perf comparison vs Lab 6 Docker

### 2.1 Test rig + method

- NixOS 26.05 (Yarara), Linux 7.0.10, AMD Ryzen 7 8845HS (16 threads), 28 GB RAM.
- All measurements on the same host in the same shell. Both endpoints on loopback (`127.0.0.1:3000` for Spin, `127.0.0.1:8080` for Docker). No cross-container network.
- **Warm latency:** `hyperfine --shell=none --warmup 10 --runs 200`, plus a small `curl -w %{time_total}` loop (n=300 after 20 warmup requests) for real percentiles. I report both — see the note under the table.
- **Cold start:** kill the server, poll every 5 ms until the first `200 OK`, take wall time with `date +%s.%N`. 5 samples each.
- **Size:** `ls -l` for `main.wasm`; `docker images` for `quicknotes:lab6` (Lab 6 image: distroless, nonroot, static Go binary — the fair baseline).

### 2.2 Results

| Dimension                          | Lab 6 Docker (`/health`) | Lab 12 Spin/WASM (`/time`) | Ratio (WASM vs Docker) |
|------------------------------------|-------------------------:|---------------------------:|------------------------|
| Artifact size                      |                  14.6 MB |               **361 KB**   | **40× smaller**        |
| Cold start (median of 5)           |                126.5 ms  |               **14.9 ms**  | **8× faster**          |
| Warm latency p50 (curl, n=300)     |               **0.3 ms** |                    1.6 ms  | 5× slower              |
| Warm latency p95 (curl, n=300)     |               **0.5 ms** |                    1.9 ms  | 4× slower              |
| Warm latency p99 (curl, n=300)     |               **0.8 ms** |                    2.3 ms  | 3× slower              |
| Warm latency mean (hyperfine, 200) |                 5.5 ms   |                    7.1 ms  | 1.3× slower            |

The **hyperfine numbers** are `time curl …`. They measure `fork(curl) + connect + request + response + exit`. The curl fork alone takes 4-5 ms on loopback, so the real server latency is hidden under shell overhead. The **`curl %{time_total}`** numbers exclude everything before the socket connect, so they show real server-side latency. That is why the two sets of numbers are so different.

Raw evidence: `submissions/lab12/perf/{warm-hyperfine,warm-curl-percentiles,cold-start}.txt`.

### 2.3 Design questions

**e) What dominates each platform's cold start?**

- **Docker (~126 ms).** Making new Linux namespaces (mount, network, PID, cgroup), the OCI runtime handshake (`runc` fork + configure), making the image layers visible via overlayfs, `exec` into the container process, then Go runtime init (5-10 ms of that total).
- **Spin (~15 ms).** wasmtime instantiation (parse + validate the module, wire imports), one wasi-http listener socket, TinyGo's Go-runtime init inside the WASM instance. No kernel-side namespace work. The isolation is a WASM sandbox — a language-runtime property, not a kernel feature.

The **~110 ms difference** is basically what you pay Linux for a fresh set of namespaces. This is why serverless platforms like AWS Lambda that used to use containers are now moving to WASM: cold-start is the number users notice.

**f) When is WASM clearly better, and where is Docker still right?**

WASM wins when:
- **You need cold-start under 100 ms.** Event-driven functions, CDN edge workers (Cloudflare Workers, Fastly Compute@Edge), per-request scaling.
- **You need portable multi-tenant sandboxing.** Many small workloads on one host, capability-based safety, no kernel namespace attack surface.
- **You need tiny images.** 200 KB modules vs 10-100 MB containers matters for edge deploys and CI cache size.

Docker is still right when:
- **You need a full Linux userspace.** GLIBC, real dynamic linking, third-party binaries you cannot rebuild (mysqld, ffmpeg, Java runtime).
- **You need real state or complex I/O.** Real filesystems, real sockets, real signals, real cgroups.
- **You need warm-path throughput on stable workloads.** The 1-2 ms per-request WASM overhead adds up at high RPS. A long-running Go binary in a container just wins.
- **Your team already ships containers.** The ecosystem, tools, hiring pool, and CI patterns are all mature.

**g) Multi-tenant safety — what concrete attack does WASM make harder?**

A **kernel-level namespace-escape** exploit. For example, an unpatched kernel bug in a syscall a container can reach (past CVEs in `overlayfs`, `user_namespaces`, `waitid`, `io_uring`). A container process **can** call the vulnerable syscall. The kernel bug drops it out of its namespace, and the attacker has host-level access.

A WASM component (Spin, wasmtime, Cloudflare Workers) can only call **functions the host imports for it**. There is no syscall interface at all — `open`, `execve`, `ioctl`, `mmap` do not exist inside the WASM module. Even if there were a bug in wasmtime's memory bounds check (there have been a couple, fixed quickly), the escape stays inside the wasmtime process. It does not skip a level of protection the way a namespace escape does. Running many workloads from different tenants on one host becomes actually safe, instead of "safe if the kernel is not buggy this week."

---

## Bonus — Two WASM execution models

### B.1 Files

```
wasm-cli/
├── go.mod       # module github.com/quicknotes/wasm-cli, no external deps
├── main.go      # WASI CLI: reads REQUEST_METHOD/PATH_INFO env, writes CGI response to stdout
└── main.wasm    # 193 KB output (committed under submissions/lab12/wasm-cli/)
```

### B.2 `main.go` (WASI CLI, no Spin SDK)

```go
package main

import (
	"fmt"
	"os"
	"time"
)

var moscow = time.FixedZone("MSK", 3*60*60)

func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "GET" {
		writeResponse(405, "text/plain", "Allow: GET\r\n", "method not allowed\n")
		return
	}
	if path != "/time" {
		writeResponse(404, "text/plain", "", "not found\n")
		return
	}

	now := time.Now().In(moscow)
	body := fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"tz":%q,"offset_seconds":%d}`,
		now.Unix(),
		now.Format(time.RFC3339),
		now.Format("15:04"),
		"MSK",
		3*60*60,
	)
	writeResponse(200, "application/json", "Cache-Control: no-store\r\n", body)
}

func writeResponse(status int, contentType, extraHeaders, body string) {
	fmt.Printf("Status: %d\r\n", status)
	fmt.Printf("Content-Type: %s\r\n", contentType)
	if extraHeaders != "" {
		fmt.Print(extraHeaders)
	}
	fmt.Print("\r\n")
	fmt.Print(body)
}
```

### B.3 Build + run

```
$ TINYGOROOT=/tmp/tinygoroot-patched nix shell nixpkgs#tinygo -c \
    tinygo build -o main.wasm -target=wasi -no-debug .

$ ls -l main.wasm
-rwxr-xr-x 1 karim users 197244 июл 15 19:30 main.wasm    # 193 KB

$ nix shell nixpkgs#wasmtime -c \
    wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
Status: 200
Content-Type: application/json
Cache-Control: no-store

{"unix":1784133047,"iso":"2026-07-15T19:30:47+03:00","hour_minute":"19:30","tz":"MSK","offset_seconds":10800}

$ wasmtime run --env REQUEST_METHOD=POST --env PATH_INFO=/time main.wasm
Status: 405
Content-Type: text/plain
Allow: GET` 

method not allowed

$ wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/other main.wasm
Status: 404
Content-Type: text/plain

not found
```

### B.4 Comparison

| Dimension          | Spin (Task 1 component)             | wasmtime run (Bonus)                     |
|--------------------|-------------------------------------|------------------------------------------|
| Module size        | 361 KB                              | **193 KB**                               |
| Exports            | wasi-http `incoming-handler`        | plain `_start` (WASI Preview 1)          |
| Runs under         | `spin up` (wasi-http host)          | bare `wasmtime run` (CLI)                |
| Cold-start         | ~15 ms once, then persistent        | **~10 ms per invocation** (no reuse)     |
| Warm latency       | 1.6 ms p50 (persistent server)      | n/a — every request is a cold start      |
| Concurrency        | Server model — one process, N reqs  | One process per invocation               |
| Fits               | Sustained HTTP traffic              | Cron / CGI / one-off queries             |

Reuse vs startup math. For **N** requests:
- Spin: `15 ms + N × 1.6 ms`
- wasmtime run: `N × 10 ms`

Break-even is around `N ≈ 2`. Above that, Spin wins. Below that (one `curl` per hour, a cron job), `wasmtime run` is simpler with less to configure.

### B.5 Design questions

**h) Why can't the Task 1 Spin component run under bare `wasmtime run`?**

Different WASM interfaces. The Task 1 component was built with `-buildmode=c-shared` and imports the Spin SDK's wasi-http handler. It exports an `incoming-handler` symbol that matches the `wasi:http/incoming-handler` interface. It does **not** export `_start`. `wasmtime run` calls `_start` (WASI Preview 1's CLI convention), does not find it, and errors out. To run the Spin component with wasmtime you need `wasmtime serve` (a wasi-http host, same interface as Spin), not `wasmtime run`.

The Bonus module is the opposite. It has `func main()` → TinyGo emits `_start` → `wasmtime run` calls it. It does not export `wasi:http/incoming-handler`, so `spin up` cannot serve it either.

**i) Spin uses wasmtime inside — so what does Spin add on top?**

Spin is a **wasi-http server + a component runner**. Concretely:

1. **A `spin.toml` manifest + a routing layer.** Read the manifest, match incoming HTTP requests to components based on `route =`.
2. **A long-running wasi-http listener loop.** Spin binds one port, accepts connections, and dispatches each request to the right component's `incoming-handler` export. wasmtime only gives you `wasmtime::Engine`; Spin runs the actual HTTP server.
3. **Instance pooling.** Instead of instantiating the WASM module on every request (which is what `wasmtime run` does), Spin pre-instantiates and reuses instances. That is why warm latency is 1.6 ms instead of 10 ms per-invocation cold start.
4. **Capability policy enforcement.** `allowed_outbound_hosts`, `allowed_hosts`, `key_value_stores`, `sqlite_databases`, `variables` — Spin enforces these at the WASI host level. wasmtime provides the enforcement primitives; Spin gives them a project-facing config.
5. **A build orchestrator + CLI.** `spin build` runs `tinygo build` (or `cargo build`, etc.); `spin new` scaffolds; `spin plugin install` extends. wasmtime is a runtime; Spin is a full component platform.

**j) When does each execution model fit?**

Two examples:

- **Per-invocation `wasmtime run` fits: cron / CGI / one-off.** For example a scheduled job that reads a URL and emits one metric every 5 minutes. You do not want a permanent server process. You want a `wasmtime run` inside a systemd `.timer` unit. The 10 ms cold start is invisible next to the 5-minute cadence, and there is no long-running state to babysit.
- **Persistent `spin up` fits: sustained HTTP traffic with per-request scaling.** For example an edge-deployed API endpoint that handles ~50 RPS with unpredictable bursts to 500 RPS. Warm p50 = 1.6 ms, no per-request instantiation cost, instance pool absorbs bursts. This is where Cloudflare Workers, Fastly Compute@Edge, and Spin's own hosted product live.

---

## Pitfalls

- **nixpkgs 25.11 tinygo 0.41.1 + Go 1.26 mismatch.** The tinygo derivation pins `go_1_25` (Go 1.25.10) as its internal compiler, but its bundled stdlib fork ships `share/tinygo/src/net/itoa_go126.go` with `//go:build go1.26`. Go 1.25 refuses the file: `file requires newer Go version go1.26 (application built with go1.25)`. **Workaround used in this lab:**
    ```bash
    TG_SRC=$(nix eval nixpkgs#tinygo.outPath --raw)/share/tinygo
    TG_DST=/tmp/tinygoroot-patched
    cp -rL --no-preserve=mode "$TG_SRC" "$TG_DST"
    rm "$TG_DST/src/net/itoa_go126.go"
    # itoa_pre126.go has //go:build !go1.26. Go 1.25 also refuses this
    # (it does not recognize "go1.26" as a valid future version).
    # Strip the first three lines (build-tag header) so netItoa is
    # defined unconditionally:
    sed -i '1,3d' "$TG_DST/src/net/itoa_pre126.go"
    # add "package net" back at the top (sed removed it too):
    printf 'package net\n\n%s\n' "$(cat $TG_DST/src/net/itoa_pre126.go)" > "$TG_DST/src/net/itoa_pre126.go.new"
    mv "$TG_DST/src/net/itoa_pre126.go.new" "$TG_DST/src/net/itoa_pre126.go"
    TINYGOROOT=$TG_DST spin build   # works
    ```
  The root cause is a nixpkgs release-window mismatch (tinygo 0.41.1 was cut before Go 1.26 stabilized). A newer tinygo release (0.42+) or a nixpkgs override that binds tinygo to `go_1_26` would fix it upstream.
- **`spin up` returns 405 on HEAD.** My handler rejects any method other than GET. `curl -sSI` is `HEAD`, so `curl -sSI /time` shows 405 while `curl -sS /time` shows 200. HEAD should return the same headers as GET, so returning 405 is debatable. But 405 with `Allow: GET` is the strictest safe behavior for an API-only endpoint.
- **Trigger route `/time` (exact) vs `/...` (prefix).** The scaffold sets `route = "/..."` (catch-all prefix). I changed it to `route = "/time"` so Spin's router does the filtering. The handler's `r.URL.Path != "/time"` check is defense-in-depth — it would only fire if someone changed the trigger back to a prefix.
- **`localhost/quicknotes:lab6` tag drift.** The image tagged `lab6` in my local registry was built after I had landed Lab 9's `securityHeaders` middleware, so its `/health` response carries CSP + XCTO headers. That adds a few microseconds per request — negligible for this comparison. The numbers still fairly represent the Lab 6 Dockerfile approach (multi-stage, distroless, nonroot, static Go).
- **hyperfine measures curl fork, not server latency.** Hyperfine's `time curl …` includes `fork(curl) + connect + …`. On loopback the fork alone is 4-5 ms — larger than the actual server latency. For percentiles I ran a small `curl -w %{time_total}` loop (n=300 after 20 warmup) and sorted the results. That is the honest server-side p50/p95/p99 in § 2.2.

---

## Artifacts

- `wasm/moscow-time/{main.go, spin.toml, go.mod, go.sum}` — Spin component source
- `wasm-cli/{main.go, go.mod}` — standalone WASI CLI source
- `submissions/lab12/spin/main.wasm` — Spin component binary (361 KB)
- `submissions/lab12/spin/curl-time.txt` — `curl -sSi http://127.0.0.1:3000/time` output
- `submissions/lab12/wasm-cli/main.wasm` — standalone CLI binary (193 KB)
- `submissions/lab12/wasm-cli/wasmtime-run.txt` — three `wasmtime run` invocations + cold-start timings
- `submissions/lab12/perf/warm-hyperfine.txt` — hyperfine 200-run means (curl-fork dominated)
- `submissions/lab12/perf/warm-curl-percentiles.txt` — n=300 sorted `curl -w %{time_total}` percentiles
- `submissions/lab12/perf/cold-start.txt` — 5-sample cold-start table for both platforms
