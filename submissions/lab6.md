# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-Stage Dockerfile (≤ 25 MB)

### Dockerfile

See [`app/Dockerfile`](../app/Dockerfile). Multi-stage: a `golang:1.24-alpine` builder produces a static, stripped binary; the runtime stage is `gcr.io/distroless/static:nonroot` and contains only the binary + seed file.

### `docker images` output

```
REPOSITORY   TAG    SIZE
quicknotes   lab6   15.5MB
```

15.5 MB — well under the 25 MB limit. (Docker Desktop also reports CONTENT SIZE ~3.55 MB.)

### `docker inspect` config excerpt

```
User=nonroot:nonroot  Ports=map[8080/tcp:{}]  Entrypoint=[/quicknotes]
```

Runs as nonroot, exposes 8080, uses exec-form entrypoint.

### Base image size comparison

The builder base `golang:1.24-alpine` is ~250-350 MB; the final runtime image is 15.5 MB — the multi-stage build keeps the Go toolchain out of the shipped artifact.

### Design questions

**a) Why does layer-order matter? (before/after rebuild times)**

Docker caches each instruction as a layer and reuses the cache until an instruction (or a file it copies) changes; everything after the first changed layer is rebuilt. If you `COPY . .` before `go mod download`, then any source edit invalidates the copy layer, which forces `go mod download` to re-run on every single rebuild — even when dependencies didn't change. Putting `COPY go.mod ./ && go mod download` *before* `COPY . .` isolates dependency download in its own layer that only busts when `go.mod` changes, so ordinary code edits reuse the cached deps and rebuild much faster. In our build, after the first build all dependency/build layers showed `CACHED` on an unrelated rebuild, so a code-only edit skips `go mod download` entirely and only re-runs the `go build` layer.

**b) Why `CGO_ENABLED=0`? What happens in distroless-static if you forget it?**

`CGO_ENABLED=0` forces a pure-Go static binary with no dependency on the system C library (libc). With cgo enabled, Go may link dynamically against libc, so the binary expects a dynamic linker and `.so` files at runtime. `gcr.io/distroless/static` contains no libc and no dynamic linker, so a dynamically-linked binary fails to start there — typically with a confusing `no such file or directory` on the binary itself (it's the missing linker, not the binary). Setting `CGO_ENABLED=0` guarantees the binary is self-contained and runs on the static distroless base.

**c) What is `gcr.io/distroless/static:nonroot`?**

It's a minimal Google-maintained base image that contains only what a static binary needs at runtime: CA certificates, timezone data, `/etc/passwd` with a `nonroot` user (UID 65532), and `/etc/nsswitch.conf` — and nothing else. It has no shell, no package manager, no busybox, no libc. That tiny surface is what matters for CVEs: scanners find issues in OS packages and system libraries, and since there essentially aren't any here, the OS-level HIGH/CRITICAL count is zero (confirmed by Trivy below — the debian layer reported 0/0).

**d) `-ldflags='-s -w'` and `-trimpath`: what does each do, and the cost?**

`-s` drops the symbol table and `-w` drops DWARF debug information, which together shrink the binary noticeably. `-trimpath` removes local filesystem paths (like `/home/ivan/...`) from the compiled binary, so the build is reproducible and doesn't leak the builder's directory layout. The cost: with `-s -w` you lose the ability to use a symbolic debugger (gdb/delve) or get fully-symbolized stack traces, and `-trimpath` makes some path-based debugging slightly harder — all acceptable for a production artifact.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

### compose.yaml

See [`compose.yaml`](../compose.yaml) at the repo root. Note the `init-data` one-shot service: because the named volume is created owned by root but the app runs as nonroot (65532), a busybox init container `chown`s `/data` before the app starts, and `quicknotes` waits for it via `depends_on: condition: service_completed_successfully`. This keeps the stack reproducible from a clean `docker compose up` with no manual steps.

### Persistence test output

```
--- after POST ---            {"id":5,"title":"durable",...}        present
--- after down && up ---      {"id":5,"title":"durable",...}        STILL present ✅
--- after down -v && up ---   durable gone (correct)                ✅
```

The note survives `docker compose down && up` (named volume persists) and is destroyed only by `docker compose down -v`.

### Design questions

**e) Distroless has no shell. How do you healthcheck it?**

I compiled a healthcheck mode into the application: running `quicknotes -healthcheck` makes the binary perform an HTTP GET on its own `/health` endpoint and exit 0 (healthy) or 1 (unhealthy). The compose healthcheck uses exec form `["CMD", "/quicknotes", "-healthcheck"]`, invoking the same binary that's already in the image — no shell, curl, or wget needed, and the image stays minimal. Verified: `docker exec ... /quicknotes -healthcheck` returned exit code 0, and `docker compose ps` shows the container as `(healthy)`. This beats the alternatives: a wget-only debug image bloats the image and re-adds attack surface; a sidecar adds a whole extra container; "process is alive" doesn't verify the app can actually serve requests.

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`? What destroys it?**

A named volume is a Docker-managed object independent of any container's lifecycle — `docker compose down` removes containers and the network but leaves named volumes intact, so data persists and re-attaches on the next `up`. What destroys it: `docker compose down -v` (the `-v` flag removes named volumes), or `docker volume rm` / `docker volume prune` directly. That separation is the point: containers are disposable, the volume is the durable state.

**g) `depends_on` without `condition: service_healthy` — what does it wait for, and the bug?**

Plain `depends_on: [x]` only waits for container `x` to be *started* (running) — not for the service inside it to be *ready*. The bug: a dependent service can start hitting `x` before it has finished booting (e.g. a DB still initializing), causing connection-refused errors and crash loops. Adding a `condition` fixes this: `service_healthy` waits for `x`'s healthcheck to pass, and `service_completed_successfully` (used here for `init-data`) waits for a one-shot container to exit 0 before the dependent service starts.

---

## Bonus Task — The 6 Security Defaults

### Hardened `services.quicknotes` block

See `compose.yaml`: `user: "65532:65532"`, `cap_drop: [ALL]`, `read_only: true` + `tmpfs: [/tmp]`, `security_opt: [no-new-privileges:true]`, distroless base (Dockerfile), Trivy scan (below).

### B.2 — Verification outputs

```
1. USER             docker inspect quicknotes:lab6 --format '{{.Config.User}}'
                    -> nonroot:nonroot

2. No shell         docker compose exec quicknotes sh
                    -> OCI runtime exec failed: exec: "sh": executable file not
                       found in $PATH         (failure = success: no shell exists)

3. CapDrop          docker inspect devops-intro-quicknotes-1 --format '{{.HostConfig.CapDrop}}'
                    -> [ALL]

4. ReadonlyRootfs   docker inspect devops-intro-quicknotes-1 --format '{{.HostConfig.ReadonlyRootfs}}'
                    -> true

5. SecurityOpt      docker inspect devops-intro-quicknotes-1 --format '{{.HostConfig.SecurityOpt}}'
                    -> [no-new-privileges:true]
```

### B.3 — Trivy scan

```
docker run --rm -v //var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6

quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 12 (HIGH: 12, CRITICAL: 0)   -- all in Go stdlib v1.24.13, all DoS-class, all fixed in Go 1.25.8+/1.26.x
```

**Analysis of the Trivy result.** The result splits cleanly into two parts, and the split is the whole lesson. The **OS layer (debian) reports 0 HIGH / 0 CRITICAL** — that is exactly the payoff of the distroless-static base: there are essentially no OS packages, so there is nothing for the scanner to flag. The **12 HIGH come from the Go standard library** baked into the binary (`stdlib v1.24.13`), not from the image: they are all denial-of-service-class issues in `net/url`, `crypto/x509`, `crypto/tls`, `net/http`, etc., with **zero CRITICAL** and **all already fixed** in Go 1.25.8+ / 1.26.x. Lab Task 1 pins the toolchain to Go **1.24**, and those fixes only landed in 1.25+, so these findings are expected for a 1.24 build rather than a packaging mistake. In real production the remediation is a one-line bump to a patched Go minor and a rebuild; here we keep 1.24 to honor the lab requirement and document the trade-off. (The lab notes the count is "often zero" — distroless removes the OS-package class of CVEs entirely; the remaining surface is purely whatever your own toolchain version carries.)

### B.4 — Most security per line of YAML

Of the six, `read_only: true` arguably gives the most security per line: one line makes the entire root filesystem immutable, neutralizing a whole class of attacks (dropping a binary, tampering with config, persisting a foothold) in a single stroke. `cap_drop: [ALL]` is a close second — one line removes every Linux capability, shrinking what a compromised process can do to almost nothing. The distroless base does the heaviest lifting overall (it's why the OS layer shows zero HIGH/CRITICAL), but that's a base-image choice rather than a line of compose YAML; among the actual YAML lines, `read_only` and `cap_drop` are the highest-leverage.

---

## Summary

| Task | Status |
|------|--------|
| Task 1 — multi-stage Dockerfile, 15.5 MB, distroless+nonroot | ✅ |
| Task 2 — compose: volume + healthcheck + persistence verified | ✅ |
| Bonus — 6 hardening defaults verified + Trivy documented | ✅ |
