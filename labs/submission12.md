# Lab 12 - WebAssembly Containers vs Traditional Containers

## Task 1 - Moscow Time Application (same source code)

Working directory used for all commands:
- `labs/lab12/`

Single source file used everywhere:
- `labs/lab12/main.go`

How one `main.go` works in three contexts:
- `MODE=once`: one-shot CLI JSON output (used for benchmarks in both traditional and WASM runs)
- Traditional container mode: standard `net/http` server on port `:8080`
- Spin WAGI mode: detects CGI env (`REQUEST_METHOD`) and prints HTTP headers/body to STDOUT

CLI mode output check:

```json
{
  "moscow_time": "2026-05-12 20:36:44 MSK",
  "timestamp": 1778607404
}
```

Server mode check:
- Verified by HTTP requests to app endpoint in containerized Go run.
- Because port `8080` was already occupied by IPFS from lab11, test ports were:
  - Go container server test: `18080`
  - Traditional container server test: `18081`

Artifacts:
- `labs/artifacts/lab12/go-mode-once.json`
- `labs/artifacts/lab12/go-server-home.http`
- `labs/artifacts/lab12/go-server-api.http`
- `labs/artifacts/lab12/go-server.log`

---

## Task 2 - Traditional Docker Container

Build/runtime artifact summary:

- Binary size:
  - `4.5M` (`4698112` bytes)
- Image size:
  - `docker images`: `4.7MB`
  - `docker image inspect`: `4.480469 MB`
- Startup benchmark (`5` CLI runs, `MODE=once`):
  - Runs (s): `2.586603, 2.192855, 1.718442, 2.188749, 1.582830`
  - Average: `2.053896 s`
- Memory usage (`docker stats --no-stream`, server mode):
  - `1.312MiB / 5.786GiB`

Traditional artifacts:
- `labs/artifacts/lab12/traditional-build.log`
- `labs/artifacts/lab12/traditional-mode-once.json`
- `labs/artifacts/lab12/traditional-binary-size.txt`
- `labs/artifacts/lab12/traditional-image-list.txt`
- `labs/artifacts/lab12/traditional-image-size-mb.txt`
- `labs/artifacts/lab12/traditional-startup-benchmark.txt`
- `labs/artifacts/lab12/traditional-docker-stats.txt`
- `labs/artifacts/lab12/traditional-server-home.http`
- `labs/artifacts/lab12/traditional-server-api.http`

---

## Task 3 - WASM Container via ctr + Wasmtime

TinyGo environment:
- `tinygo version 0.39.0 linux/amd64 (using go version go1.25.0 and LLVM version 19.1.2)`

WASM build details:
- Source: same `main.go`
- Output: `main.wasm`
- Size: `2.4M` (`2450459` bytes)
- File type: `WebAssembly (wasm) binary module version 0x1 (MVP)`

Note on compilation:
- `tinygo build -target=wasi main.go` timed out in this environment on crypto/FIPS init.
- Successful build used the same source with:
  - `tinygo build -o main.wasm -target=wasi -tags=netgo main.go`

Wasmtime runtime setup:
- Built `containerd-shim-wasmtime-v1` from `containerd/runwasi` source in a Rust builder container.
- Installed shim:
  - `/usr/local/bin/containerd-shim-wasmtime-v1`
- Containerd runtime block added in `/etc/containerd/config.toml` and daemon restarted.

WASM image + ctr:
- OCI archive built via `docker buildx` (`docker-container` driver) for `wasi/wasm`
- Imported into containerd as:
  - `docker.io/library/moscow-time-wasm:latest`
- `ctr images ls` entry size:
  - `819.9 KiB`

CLI mode test (`MODE=once`) via ctr:

```json
{
  "moscow_time": "2026-05-12 21:54:36 MSK",
  "timestamp": 1778612076
}
```

WASM startup benchmark (`5` CLI runs via `ctr run`):
- Runs (s): `3.955447, 1.895462, 2.258688, 1.528091, 1.981726`
- Average: `2.323883 s`

Server mode limitation under plain WASI/ctr:
- Attempt output:
  - `Server starting on :8080`
  - `Netdev not set`
- Conclusion: sockets/networking for this path are not available in this WASI execution model.

Memory usage note:
- `N/A via ctr` (different runtime/resource accounting model compared with `docker stats`).

WASM artifacts:
- `labs/artifacts/lab12/tinygo-version.txt`
- `labs/artifacts/lab12/wasm-binary-size.txt`
- `labs/artifacts/lab12/wasm-binary-file.txt`
- `labs/artifacts/lab12/wasmtime-shim-build.log`
- `labs/artifacts/lab12/wasmtime-shim-installed.txt`
- `labs/artifacts/lab12/ctr-images-wasm.txt`
- `labs/artifacts/lab12/wasm-once-output.json`
- `labs/artifacts/lab12/wasm-startup-benchmark.txt`
- `labs/artifacts/lab12/wasm-server-attempt.log`
- `labs/artifacts/lab12/wasm-memory-note.txt`

---

## Task 4 - Performance Comparison and Analysis

### Comparison Table

| Metric | Traditional Container | WASM Container | Improvement | Notes |
| --- | --- | --- | --- | --- |
| Binary Size | 4.5M (`4698112` bytes) | 2.4M (`2450459` bytes) | **47.84% smaller** | Same `main.go` |
| Image Size | 4.480469 MB | 819.9 KiB (~0.80 MB) | **82.13% smaller** | `docker inspect` vs `ctr images ls` |
| Startup Time (CLI, avg 5) | 2.053896 s | 2.323883 s | **0.88x** (WASM slower in this run) | First WASM run had cold/runtime overhead |
| Memory Usage | 1.312MiB (`docker stats`) | N/A via `ctr` | N/A | Different accounting model |
| Base Image | `scratch` | `scratch` | Same | Fair baseline |
| Source Code | `main.go` | `main.go` | Identical | Same code path |
| Server Mode | Works (`net/http`) | Not working via plain `ctr` WASI (`Netdev not set`) | N/A | Server mode should be done via Spin/WAGI |

### Analysis Questions

1. Why is the WASM binary smaller?
- TinyGo aggressively reduces runtime footprint and emits a much leaner output than full Go toolchain static binaries.
- In this run, WASM binary is ~47.8% smaller than the traditional static ELF binary.

2. Why startup is not faster here?
- This environment includes `ctr + wasmtime shim + sudo` overhead and a pronounced cold first run for WASM.
- Warm runs are much closer to traditional runs; cold overhead dominated average.
- So practical result depends on runtime setup, cache state, and benchmark method.

3. When to choose WASM vs traditional containers?
- Choose WASM when image footprint, distribution size, sandboxing, and portability are priorities.
- Choose traditional containers when full POSIX/network behavior and mature operational tooling are required immediately.
- For HTTP server-mode WASM, use a platform abstraction (e.g., Spin/WAGI), not plain WASI Preview1 socket assumptions.

### Recommendation

From this lab run:
- WASM clearly wins on binary/image size.
- Startup latency in this specific local setup was slightly worse on average due cold/runtime overhead.
- For production decisions, benchmark in your exact target platform (local ctr, k8s runtime, or Spin cloud), not only one local run profile.

---

## Bonus

Bonus was executed with Fermyon Cloud using the same `main.wasm`.

Spin/Fermyon details:
- Spin version: `spin 3.6.3 (88d51cf 2026-04-09)`
- App name: `moscow-time-krasand-lab12-0512224300`
- Deploy time: `24.85 s`
- Cloud URL: `https://moscow-time-krasand-lab12-0512224300-18hw0skj.fermyon.app`
- API check: `GET /api/time` returned valid Moscow time JSON

Spin benchmarks:
- Local (`spin up` on VM, avg 5): `0.004143 s`
  - Runs: `0.006804, 0.004565, 0.003138, 0.002993, 0.003215`
- Cloud cold (avg 5): `0.757594 s`
  - Runs: `0.752950, 0.756390, 0.762791, 0.749956, 0.765884`
- Cloud warm (avg 5): `0.780523 s`
  - Runs: `0.752099, 0.754617, 0.768045, 0.846931, 0.780923`

Bonus artifacts:
- `labs/artifacts/lab12/bonus/spin-version.txt`
- `labs/artifacts/lab12/bonus/spin-install.log`
- `labs/artifacts/lab12/bonus/spin-login-status.json`
- `labs/artifacts/lab12/bonus/spin.cloud.toml`
- `labs/artifacts/lab12/bonus/spin-deploy.log`
- `labs/artifacts/lab12/bonus/spin-deploy-time-seconds.txt`
- `labs/artifacts/lab12/bonus/spin-app-info.json`
- `labs/artifacts/lab12/bonus/spin-url.txt`
- `labs/artifacts/lab12/bonus/spin-cloud-api-time.json`
- `labs/artifacts/lab12/bonus/local-runs.txt`
- `labs/artifacts/lab12/bonus/local-average-seconds.txt`
- `labs/artifacts/lab12/bonus/cloud-cold-runs.txt`
- `labs/artifacts/lab12/bonus/cloud-cold-average-seconds.txt`
- `labs/artifacts/lab12/bonus/cloud-warm-runs.txt`
- `labs/artifacts/lab12/bonus/cloud-warm-average-seconds.txt`
- `labs/artifacts/lab12/bonus/bonus.done`

---

## Final Conclusion

Lab 12 was completed with the same `main.go` source used for:
- traditional Docker container
- WASM module (`main.wasm`) and `ctr` execution via wasmtime

All required Task 1-4 metrics were collected and documented with reproducible artifacts.
Bonus (Fermyon Cloud) was also completed with deploy and cloud benchmark evidence.
