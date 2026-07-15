# Lab 12 Submission

## Task 1 - Build a WASM Endpoint with the Spin SDK

### Tool versions

Commands:

```bash
go version
tinygo version
spin --version
```

Output:

```text
go version go1.24.13 linux/amd64
tinygo version 0.41.1 linux/amd64 (using go version go1.24.13 and LLVM version 20.1.1)
spin 3.4.1 (3ab5404 2025-08-28)
```

### Implementation

#### `main.go`

Path: [`wasm/moscow-time/main.go`](../wasm/moscow-time/main.go)

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
		w.Header().Set("Content-Type", "application/json")

		if r.Method != http.MethodGet {
			w.Header().Set("Allow", http.MethodGet)
			w.WriteHeader(http.StatusMethodNotAllowed)
			fmt.Fprintln(w, `{"error":"method not allowed"}`)
			return
		}

		now := time.Now()
		moscow := now.UTC().Add(3 * time.Hour)
		iso := moscow.Format("2006-01-02T15:04:05") + "+03:00"

		fmt.Fprintf(
			w,
			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q}\n",
			now.Unix(),
			iso,
			moscow.Format("15:04"),
		)
	})
}
```

The handler registers through `spinhttp.Handle`, accepts `GET` requests, and
returns the current Moscow time as JSON. Other HTTP methods receive a `405
Method Not Allowed` response.

#### `spin.toml`

Path: [`wasm/moscow-time/spin.toml`](../wasm/moscow-time/spin.toml)

```toml
#:schema https://schemas.spinframework.dev/spin/manifest-v2/latest.json

spin_manifest_version = 2

[application]
name = "moscow-time"
version = "0.1.0"
authors = ["MostafaKhaled2017 <m.kira@innopolis.university>"]
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

The manifest exposes only `/time`, grants no outbound network hosts, and keeps
the scaffolded TinyGo `wasip1` and `c-shared` build configuration.

### Build and artifact size

Command:

```bash
spin build
```

Output:

```text
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components
```

Commands:

```bash
ls -lh main.wasm
stat -c '%n: %s bytes' main.wasm
```

Output:

```text
-rw-rw-r-- 1 mostafa nix-users 354K Jul 15 13:28 main.wasm
main.wasm: 361854 bytes
```

The generated WebAssembly component is 361,854 bytes (approximately 354 KiB).

### Runtime verification

The application was started with:

```bash
spin up
```

Relevant output:

```text
Logging component stdio to ".spin/logs/"

Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000/time
```

Command:

```bash
curl -i http://127.0.0.1:3000/time
```

Output:

```text
HTTP/1.1 200 OK
content-type: application/json
content-length: 76
date: Wed, 15 Jul 2026 10:30:09 GMT

{"unix":1784111409,"iso":"2026-07-15T13:30:09+03:00","hour_minute":"13:30"}
```

The response is valid JSON. The HTTP date is `10:30:09 GMT`, while the returned
Moscow timestamp is `13:30:09+03:00`, confirming the UTC+3 offset.

Pretty-printed response:

```bash
curl -sS http://127.0.0.1:3000/time | python3 -m json.tool
```

```json
{
    "unix": 1784111420,
    "iso": "2026-07-15T13:30:20+03:00",
    "hour_minute": "13:30"
}
```

Non-GET requests are rejected:

```bash
curl -i -X POST http://127.0.0.1:3000/time
```

```text
HTTP/1.1 405 Method Not Allowed
allow: GET
content-type: application/json
content-length: 31
date: Wed, 15 Jul 2026 10:30:28 GMT

{"error":"method not allowed"}
```

### Design question a: Browser WASM versus server WASM

A `js/wasm` build targets a JavaScript host and relies on JavaScript glue and
browser-provided APIs. A server-side `wasip1` module does not have browser
objects such as the DOM, `window`, or other Web APIs.

In return, the WASI target gains a portable system interface designed for WASM
runtimes outside the browser. The host controls which system capabilities are
available, so the same component can run in a server-side WASI host without a
browser or JavaScript runtime.

### Design question b: Why is `-buildmode=c-shared` required?

The default WASI command model provides a `_start` entry point, runs once, and
then exits. Spin needs a reusable component whose HTTP handler can be invoked
for multiple requests.

With `-buildmode=c-shared`, TinyGo builds a reactor/library-style module with an
initialization export rather than a one-shot command. This allows the Spin host
to initialize the Go runtime and invoke the handler export registered by the
Spin SDK. Without this build mode, the module does not provide the execution
model and exports expected by the Spin HTTP host.

### Design question c: Capability-based security

WASM components can only use host capabilities explicitly granted to them. The
setting `allowed_outbound_hosts = []` grants this component no permission to
make outbound network requests. Code inside the component cannot obtain that
capability if the host does not expose it.

Docker's `--network none` places a container in a network namespace without an
external network interface, which also blocks normal outbound traffic. The
difference is the isolation boundary: Docker still exposes a Linux process and
a filtered set of kernel system calls, filesystems, namespaces, and
capabilities. A WASM component instead interacts with the host through a much
narrower set of imported interfaces. Both configurations deny outbound
networking, but WASM expresses the permission directly as an absent host
capability.

### Design question d: TinyGo standard-library gaps

The relevant TinyGo limitation is incomplete support for parts of the upstream
Go standard library that depend on runtime data or reflection. In particular,
WASI builds do not normally include the IANA time-zone database needed by
`time.LoadLocation("Europe/Moscow")`. Reflection-heavy JSON encoding, such as
encoding a `map[string]any`, can also encounter TinyGo limitations.

The final handler avoids both problem areas. It calculates Moscow time from UTC
using the fixed UTC+3 offset and constructs the small JSON object with formatted
output rather than reflection over `map[string]any`. The earlier
`internal/stringslite` build failure was a separate Go/TinyGo version mismatch,
not one of these standard-library limitations; using Go 1.24.13 with TinyGo
0.41.1 resolved it.
