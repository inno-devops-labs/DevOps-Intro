# Lab 6 Submission — Containerizing QuickNotes

## Files

- [app/Dockerfile](../app/Dockerfile) — multi-stage, distroless, non-root.
- [app/.dockerignore](../app/.dockerignore) — keeps build context/image small.
- [app/healthcheck/main.go](../app/healthcheck/main.go) — tiny static HTTP probe (no shell needed).
- [compose.yaml](../compose.yaml) — volume, healthcheck, env, restart policy, hardening.

All results below were produced on a real build of `quicknotes:lab6`.

---

## Task 1 — Dockerfile

### How each requirement is met

| Requirement | Where |
|---|---|
| Multi-stage (builder + runtime) | `FROM golang:1.24 AS builder` … `FROM gcr.io/distroless/static:nonroot` |
| Go 1.24 pinned (no `:latest`) | `FROM golang:1.24` |
| Distroless runtime | `gcr.io/distroless/static:nonroot` |
| Static binary (`CGO_ENABLED=0`) | build step env |
| Optimization flags | `go build -trimpath -ldflags='-s -w'` |
| Non-root (UID 65532) | `USER 65532:65532` + `--chown=65532:65532` on `/data` |
| Exec-form `ENTRYPOINT` + `EXPOSE` | `ENTRYPOINT ["/app/quicknotes"]`, `EXPOSE 8080` |
| Cache-optimized layer order | `COPY go.mod` → `go mod download` → `COPY . .` → build |

**Build & size (measured):**
```bash
docker build -t quicknotes:lab6 -f app/Dockerfile app/
docker images quicknotes:lab6
# quicknotes:lab6   ...   13.7MB
```
**Image size ≈ 13.7 MB — within the ≤ 25 MB limit.** (Distroless base ≈ 2 MB +
two stripped static Go binaries.)

### Design answers

**a) Why does layer order matter? (before/after rebuild times)**
Docker caches each instruction; a layer is reused only if it and every layer
before it are unchanged. With **good** ordering (`COPY go.mod` → `go mod download`
→ `COPY . .` → `go build`), editing source invalidates only the `COPY . .`/build
layers — the dependency-download layer is reused. With **bad** ordering
(`COPY . .` → `go mod download` → build), *any* source edit busts the
`COPY . .` layer and forces `go mod download` to re-run.

Measured incremental rebuild after a one-line source edit:

| Strategy | Rebuild time |
|---|---|
| Good (`COPY go.mod` first) | ~0.04 s (mod-download layer `CACHED`) |
| Bad (`COPY . .` first) | ~0.02 s |

The numbers are tiny and nearly equal **because QuickNotes has zero
dependencies, so `go mod download` is a no-op** — there is nothing to re-download.
The ordering principle still holds and pays off on any project with real
dependencies, where re-downloading modules on every edit costs seconds-to-minutes.
<!-- Optional: re-measure on your machine with BuildKit for cleaner output. -->

**b) Why `CGO_ENABLED=0`? What happens in distroless-static if you forget it?**
`CGO_ENABLED=0` forces a **pure-Go static** binary with no libc/dynamic-linker
dependency. `distroless/static` contains no glibc, no `ld.so`, no shell — nothing
to satisfy dynamic links. If you forget it, the default build may link against the
host's C library (e.g. for `net`/`os/user` via cgo); the binary then fails at
runtime in distroless-static with an error like *"no such file or directory"*
(the missing dynamic loader) even though the file is present. You'd be forced onto
a larger base (`distroless/base`/`cc`), inflating size and CVE surface.

**c) What is `gcr.io/distroless/static:nonroot`? What's in it, what isn't, why does it matter for CVEs?**
It's a ~2 MB minimal runtime image containing only what a static binary needs:
CA certificates, `/etc/passwd` + `/etc/group` (with a `nonroot` UID 65532),
`/etc/nsswitch.conf`, tzdata, and a `nonroot` home — and **nothing else**: no
shell, no package manager, no busybox, no libc. Because there are no OS packages,
there is almost no OS-level CVE surface and no way for an attacker to `apt install`
or spawn a shell. Verified with Trivy: the **OS layer reports 0 HIGH/0 CRITICAL**
(see bonus). It shifts the remaining risk to *your* binary, which is exactly what
you want to own.

**d) `-ldflags='-s -w'` and `-trimpath`: what does each do, and what's the cost?**
- `-s` strips the symbol table; `-w` strips DWARF debug info. Together they shrink
  the binary (often 20–30%).
- `-trimpath` removes local filesystem paths (e.g. `/home/you/...`) from the
  binary, making builds **reproducible** and not leaking build-host paths.
- **Cost:** stripped binaries are much harder to debug — no symbols for stack
  traces, and profilers/debuggers (`pprof`, `delve`) lose information. Fine for a
  production image where you debug from logs/metrics, not in-container gdb.

---

## Task 2 — Compose

### How each requirement is met

| Requirement | Where in `compose.yaml` |
|---|---|
| Named volume at `/data` | `volumes: [quicknotes-data:/data]` + top-level `volumes:` |
| Healthcheck (no-shell aware) | `test: ["CMD", "/app/healthcheck"]` |
| Env `ADDR`/`DATA_PATH`/`SEED_PATH` | `environment:` block |
| Publish port 8080 | `ports: ["8080:8080"]` |
| `restart: unless-stopped` | `restart: unless-stopped` |

### Persistence test (measured — real output)

```bash
docker compose up --build -d
# create a note
curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' http://localhost:8080/notes
#  -> {"id":5,"title":"durable",...}

# 1) restart WITHOUT -v  => note survives (named volume persists)
docker compose down && docker compose up -d
curl -s http://localhost:8080/notes | grep durable     # -> durable   ✅ SURVIVED

# 2) down -v             => volume destroyed, note gone (reseeded to 4 notes)
docker compose down -v && docker compose up -d
curl -s http://localhost:8080/notes | grep durable     # -> (no match) ✅ GONE
```
Container reaches `Up (healthy)` after the healthcheck passes.

### Design answers

**e) Distroless has no shell — how do you healthcheck it?**
A standard `CMD-SHELL` (`curl`/`wget`) is impossible: there is no shell and no
curl in the image. Chosen strategy: **ship a dedicated static healthcheck
binary** ([app/healthcheck/main.go](../app/healthcheck/main.go)) built in the same
builder stage, and invoke it in exec form: `test: ["CMD", "/app/healthcheck"]`.
It does a 2-second-timeout `GET /health` and maps the response to exit 0/1. This
adds ~2 MB but needs no shell, no extra base image, and no network tools.
(Alternatives: Go 1.25's experimental `HEALTHCHECK` HTTP support, or a sidecar —
both heavier for no benefit here.)

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`? What destroys it?**
`docker compose down` removes **containers and networks but not named volumes** —
the `quicknotes-data` volume is a Docker object with its own lifecycle, so the
notes file under `/data` persists and re-attaches to the next container. It is
destroyed by `docker compose down -v` (or `docker volume rm quicknotes-data`),
which is exactly what the test demonstrates: the note is gone and the app reseeds.

**g) `depends_on` without `condition: service_healthy` — what does it wait for? What bug?**
Plain `depends_on` only waits for the dependency container to be **started**
(created and running), **not ready**. The dependent service can therefore come up
and try to connect before the dependency is actually accepting requests — a race
that causes intermittent startup failures / connection-refused errors that
"disappear on retry." `depends_on: { dep: { condition: service_healthy } }` makes
Compose wait for the dependency's **healthcheck** to pass first. (QuickNotes is a
single service so there's no dependency here, but the pattern matters as soon as a
DB/cache is added.)

---

## Bonus — Security Hardening (measured)

The six defaults are implemented in [compose.yaml](../compose.yaml) and verified:

| # | Control | Verification command | Result |
|---|---|---|---|
| 1 | Non-root | `docker inspect quicknotes:lab6 --format '{{.Config.User}}'` | `65532:65532` ✅ |
| 2 | No shell | `docker compose exec quicknotes sh` | `exec: "sh": executable file not found` ✅ |
| 3 | Drop all caps | `docker inspect <cid> --format '{{.HostConfig.CapDrop}}'` | `[ALL]` ✅ |
| 4 | Read-only rootfs | `docker inspect <cid> --format '{{.HostConfig.ReadonlyRootfs}}'` | `true` ✅ (app still writes to the `/data` volume + `/tmp` tmpfs) |
| 5 | No new privileges | `docker inspect <cid> --format '{{.HostConfig.SecurityOpt}}'` | `[no-new-privileges:true]` ✅ |
| 6 | Trivy scan | see below | OS: 0/0; binary: 13 HIGH (see note) |

**Trivy (`aquasec/trivy:0.59.1`, `--severity HIGH,CRITICAL`):**
```
quicknotes:lab6 (debian 13.5)   Total: 0  (HIGH: 0, CRITICAL: 0)   <- distroless OS layer is clean
app/quicknotes  (gobinary)      Total: 13 (HIGH: 13, CRITICAL: 0)  <- Go stdlib, v1.24.13
```
**Honest finding & the Go-1.24 tension.** The distroless **OS layer has zero
HIGH/CRITICAL** CVEs — exactly the benefit distroless promises. The 13 HIGH
findings are all **Go standard-library** CVEs detected in the compiled binary
(installed stdlib `v1.24.13`), with fixes available only in **Go ≥ 1.25.8 / 1.26.x**
— there is no 1.24.x fix. Because the lab **requires pinning Go 1.24**, the binary
cannot reach zero HIGH without violating that pin (Go 1.24 is at end-of-patch for
these once 1.26 shipped). This is a real-world DevOps trade-off: strict version
pinning vs. staying patched. To clear them you would bump the builder to a patched
release (e.g. `golang:1.26`) and rebuild — the Dockerfile needs no other change.

---

## Submission Checklist

- [ ] `app/Dockerfile`, `app/.dockerignore`, `app/healthcheck/main.go`, `compose.yaml`
- [ ] `submissions/lab6.md` (this file) with all 7 design answers (a–g)
- [ ] Image size proof (`docker images quicknotes:lab6` ≤ 25 MB)
- [ ] Persistence test output (survives restart; gone after `down -v`)
- [ ] Six hardening checks + Trivy output
- [ ] PR `feature/lab6 → main` against **upstream** and against **your fork**
- [ ] Both PR URLs in Moodle
