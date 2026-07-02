# Lab 12 Submission

## Task 1 — Spin SDK /time Endpoint (4 pts)

### 1.1 main.go

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
		if r.URL.Path != "/time" {
			http.NotFound(w, r)
			return
		}

		now := time.Now().UTC().Add(3 * time.Hour)
		unix := now.Unix()
		iso := now.Format(time.RFC3339)
		hourMinute := now.Format("15:04")

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"unix":%d,"iso":"%s","hour_minute":"%s"}`+"\n", unix, iso, hourMinute)
	})
}
```

### 1.2 spin.toml

```toml
spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"

[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
allowed_outbound_hosts = []
[component.moscow-time.build]
command = "tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm ."
```

### 1.3 Build & Run

- `spin build` → main.wasm (362 KB)
- `spin up` → http://127.0.0.1:3000/time
- Response: `{"unix":1783010372,"iso":"2026-07-02T16:39:32Z","hour_minute":"16:39"}`

### 1.4 Design Questions

**a) Browser WASM vs server WASM.**
Missing: DOM, `window`, `document`. Gain: system interfaces (WASI — files, sockets, clocks). Server WASM runs outside the browser with real OS capabilities sandboxed.

**b) Why -buildmode=c-shared?**
Spin host expects the module to export a wasi-http handler via a shared library ABI, not a standalone `_start` function. Without it, `spin up` can't find the entrypoint.

**c) allowed_outbound_hosts = [] vs Docker --network none.**
WASM capability model: the module cannot even name a host. Docker --network none: no network interface, but the process can still attempt syscalls. WASM sandbox is at the API level — the module literally cannot call `wasi:sockets` functions.

**d) TinyGo stdlib gaps.**
`time.LoadLocation("Europe/Moscow")` fails — no embedded tzdata. Used `time.Now().UTC().Add(3*time.Hour)` instead. `encoding/json` with `map[string]any` has reflection limits; used `fmt.Fprintf` with raw JSON string.

---

## Task 2 — Perf Comparison (4 pts)

### 2.1 Measurements

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|-----------|-------------:|-----------------:|
| Artifact size | 19.2 MB | 362 KB |
| Cold start | ~1s | ~0.05s |
| Warm latency (mean) | 18.3 ms | 20.5 ms |
| Warm latency (min) | 13.4 ms | 13.3 ms |
| Warm latency (max) | 26.4 ms | 45.5 ms |

*Cold start: Spin — instant (no container init). Docker — image extract + namespace setup.*

### 2.2 Design Questions

**e) What dominates cold start?**
Docker: image layers extract + network namespace init + process start. Spin: wasm module load + wasmtime instantiation (milliseconds, no namespaces).

**f) WASM better vs Docker better?**
WASM: short-lived functions, edge computing, high-density multi-tenant. Docker: long-running services, complex networking, full Linux userspace needed.

**g) Multi-tenant safety?**
WASM capability sandbox makes arbitrary code execution harder — no syscalls, no filesystem unless explicitly granted. Docker namespaces can be escaped via kernel bugs; WASM has a formally verified sandbox.

