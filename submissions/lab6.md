# Lab 6 — Containers: Dockerize QuickNotes

**Name:** Nikolay Taran
**Course:** DevOps (inno-devops-labs/DevOps-Intro)
**Branch:** `feature/lab6`
**PR (course repo):** https://github.com/inno-devops-labs/DevOps-Intro/pull/1635
**Date:** 2026-09-24

---

## 1. What the lab requires

| # | Requirement | Where in this report |
|---|-------------|----------------------|
| T1.1 | Multi-stage `Dockerfile` (builder + runtime) | §2.1 |
| T1.2 | Builder = official Go image pinned to `1.24` (not `:latest`) | §2.1 (`golang:1.24-alpine`) |
| T1.3 | Runtime = distroless / scratch — no shell, no apt | §2.1 (`gcr.io/distroless/static-debian12:nonroot`) |
| T1.4 | Static binary, `CGO_ENABLED=0` | §2.1 |
| T1.5 | `-ldflags='-s -w'` + `-trimpath` | §2.1 |
| T1.6 | Runs as `nonroot` (UID 65532) | §2.1, §2.3 |
| T1.7 | `ENTRYPOINT` exec form, `EXPOSE 8080` | §2.1, §2.3 |
| T1.8 | Final image ≤ 25 MB | §2.2 |
| T1.9 | Layer-cache-friendly order (`go.mod`/`go.sum` before source) | §2.1, §2.5 (a) |
| T1.d | Design questions a–d | §2.5 |
| T2.1 | `compose.yaml` at repo root: service builds `./app` → `quicknotes:lab6` | §3.1 |
| T2.2 | Publishes port 8080 | §3.1 |
| T2.3 | Named volume at `/data` | §3.1, §3.2 |
| T2.4 | Healthcheck that works without a shell | §3.1, §3.2 (healthy status), §3.3 (e) |
| T2.5 | Env vars `ADDR`, `DATA_PATH`, `SEED_PATH` | §3.1 |
| T2.6 | `restart: unless-stopped` | §3.1 |
| T2.d | Design questions e–g | §3.3 |
| T2.t | Persistence test: note survives `down`/`up`, dies after `down -v` | §3.2 |
| B | All 6 security defaults applied + verified + Trivy | §4 |

---

## 0. Setup — branch

```
C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git branch
  bisect-quickn
  docs-skip-demo
  feature/lab2
  feature/lab3
  feature/lab4
  feature/lab4-old
  feature/lab5
* feature/lab6
  main
```

---

## 2. Task 1 — Multi-stage Dockerfile, ≤ 25 MB

### 2.1 The Dockerfile

Final image: builder stage on `golang:1.24-alpine`, runtime stage on `gcr.io/distroless/static-debian12:nonroot`.

```dockerfile
# syntax=docker/dockerfile:1

##############################################################################
# Stage 1 - builder: full Go toolchain, compiles a static binary
##############################################################################
FROM golang:1.24-alpine AS builder

WORKDIR /src

# Layer-cache-friendly order: only the dependency manifest goes first, so
# `go mod download` is a cached layer that never re-runs when source changes.
# This module is stdlib-only (go.mod has no require lines), so there is no
# go.sum file - COPY go.mod alone is the complete dependency manifest here.
COPY go.mod ./
RUN go mod download

# Only now copy the source - edits to .go files do NOT invalidate the
# dependency layer above.
COPY . .

# CGO_ENABLED=0 -> pure-Go static binary, no libc, runs on distroless.
# -trimpath -> no absolute build paths; -ldflags='-s -w' -> strip symbols+DWARF.
# mkdir /out/data -> runtime stage cannot mkdir (no shell), so a /data
# directory owned by nonroot is shipped from the builder.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes . \
    && mkdir /out/data

##############################################################################
# Stage 2 - runtime: distroless static, nonroot, no shell, no package manager
##############################################################################
FROM gcr.io/distroless/static-debian12:nonroot

# Binary + empty /data owned by UID 65532. On first mount of the named
# volume, Docker copies this directory's contents AND ownership into the
# volume - that is what lets the nonroot process write /data/notes.json
# (the classic "root-owned volume" pitfall).
COPY --from=builder --chown=65532:65532 /out/quicknotes /quicknotes
COPY --from=builder --chown=65532:65532 /out/data /data

# Seed file (4 starter notes); the app only ever reads it.
COPY --from=builder /src/seed.json /seed.json

ENV ADDR=":8080" \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json

EXPOSE 8080

USER nonroot

ENTRYPOINT ["/quicknotes"]
```

### 2.2 Build and image size

Command:

```
cd C:\Users\Inno\OneDrive\Documents\DevOps-Intro\app
docker build -t quicknotes:lab6 .
docker images quicknotes:lab6
```

Build completed in 23.1 s (20 steps, no errors); the Go compile step itself took 7.2 s.

Output — Docker Desktop 28.x uses the containerd image store, so `docker images` shows two size columns: **DISK USAGE** = unpacked size on disk, **CONTENT SIZE** = compressed size (what the registry actually transfers):

```
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   bc9fbdc8ed62       15.3MB         3.43MB
```

Both are far below the 25 MB requirement: 15.3 MB unpacked, and only 3.43 MB of compressed content.

After adding the `.dockerignore` fix, the rebuild transferred only 582 B of context (vs 9.97 MB with an empty ignore file — the local `bin/`, `data/`, `tmp/` artifacts no longer ride along).

Base image sizes for comparison:

| Image | Role | Size |
|-------|------|------|
| `golang:1.24` | full toolchain — what a single-stage build would ship | 1.32 GB disk / 335 MB content |
| `golang:1.24-alpine` | builder stage | 395 MB disk / 83.5 MB content |
| `gcr.io/distroless/static-debian12:nonroot` | runtime base | 6.18 MB disk / 721 kB content |
| `quicknotes:lab6` | final | **15.3 MB disk / 3.43 MB content** |

```
C:\...\app>docker images golang
IMAGE               ID             DISK USAGE   CONTENT SIZE
golang:1.24         d2d2bc1c84f7       1.32GB          335MB
golang:1.24-alpine  8bee1901f1e5        395MB         83.5MB

C:\...\app>docker images gcr.io/distroless/static-debian12
IMAGE                                      ID             DISK USAGE   CONTENT SIZE
gcr.io/distroless/static-debian12:nonroot  afa5c872c891      6.18MB          721kB
```

Note: during the build both bases were resolved by digest and left untagged in the containerd image store, so the first `docker images gcr.io/...` came back empty. An explicit `docker pull` tagged the already-downloaded content (nothing to re-download), which made the sizes visible.

The toolchain (Go compiler, 1.32 GB) never reaches the runtime: the final image contains only the static binary (~6 MB), the seed file and distroless's ca-certificates/tzdata/`/etc/passwd` — that is the whole point of multi-stage.

### 2.3 Image config (docker inspect excerpt)

```
docker inspect quicknotes:lab6 --format "User={{.Config.User}}  Entrypoint={{json .Config.Entrypoint}}  ExposedPorts={{json .Config.ExposedPorts}}"
```

```
C:\...\app>docker inspect quicknotes:lab6 --format "User={{.Config.User}}  Entrypoint={{json .Config.Entrypoint}}  ExposedPorts={{json .Config.ExposedPorts}}"
User=nonroot  Entrypoint=["/quicknotes"]  ExposedPorts={"8080/tcp":{}}
```

All three values confirmed: `nonroot` user (T1.6), exec-form `ENTRYPOINT` (T1.7 — JSON array, not a shell string), port 8080 declared.

### 2.4 Runtime smoke test

```
docker run -d --name qn-lab6 -p 8080:8080 quicknotes:lab6
timeout /t 3 /nobreak >nul
curl.exe http://localhost:8080/health
curl.exe http://localhost:8080/notes
docker rm -f qn-lab6
```

```
C:\...\app>docker run -d --name qn-lab6 -p 8080:8080 quicknotes:lab6
c41fe678cb217391fd47145ffd50753434bdf3ce1b30363afbdac4ae6d7d1fa7

C:\...\app>curl.exe http://localhost:8080/health
{"notes":4,"status":"ok"}

C:\...\app>curl.exe http://localhost:8080/notes
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point тАФ env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]

C:\...\app>docker rm -f qn-lab6
qn-lab6
```

`/health` reports 4 seeded notes and status ok; `/notes` returns the full seed array. Two cosmetic notes: curl's progress meter (the `% Total ...` line) is omitted from pastes in this report — it is stderr noise, not part of the response; and the em dash in note 2 renders as `тАФ` in the raw cmd paste — that is the Windows console (cp866) misrendering the UTF-8 dash, the JSON body itself is clean UTF-8 (same artifact visible in §3.2).

### 2.5 Design questions (Task 1)

**a) Why does layer-order matter? Show before/after rebuild times for two strategies.**

Docker builds each instruction as a layer keyed by the instruction + a checksum of its inputs. The chain breaks at the *first* invalidated layer, and everything after it re-executes.

- Strategy A (`COPY . .` → `go mod download` → `go build`): any source edit changes the `COPY . .` checksum, so `go mod download` re-runs on every build — in a real project that re-fetches every dependency from the network.
- Strategy B (`COPY go.mod go.sum` → `go mod download` → `COPY . .` → `go build`): a source edit still invalidates `COPY . .`, but the dependency layers before it keep their cache; only compile re-runs.

Measured on this project (source edit = appended one blank line to `handlers.go`):

| Strategy | First measured build | Rebuild after source edit |
|----------|----------------------|---------------------------|
| A — deps after `COPY . .` | 10.04 s | 9.25 s |
| B — deps before `COPY . .` (final Dockerfile) | 10.66 s | 10.54 s |

Rebuild method: appended one blank line to `handlers.go` to change the context checksum, rebuilt, then reverted with `git checkout -- handlers.go`. Both "first" builds ran with base images and the Dockerfile frontend already local, so they measure instruction execution, not network pulls.

Honest reading: all four runs sit in one 9–11 s band dominated by the Go compile (~7–10 s, ±1.5 s run-to-run variance). In this stdlib-only module `go mod download` is a sub-second no-op, so the two strategies are indistinguishable in wall-clock time — that is the expected result, not a failed experiment. The ordering pays off the day the module grows its first real dependency: strategy A then re-runs `go mod download` on every source edit and re-fetches the module graph over the network (tens of seconds to minutes), while strategy B keeps that layer cached and re-runs only the compile. The Dockerfile is written so that day-one behavior is already correct.

**b) Why `CGO_ENABLED=0`? What happens in distroless-static if you forget it?**

Go's default is `CGO_ENABLED=1`: parts of the standard library (notably the `net` package's resolver) may link against the system C library, producing a *dynamically linked* binary that needs `libc` and the dynamic loader at runtime. `gcr.io/distroless/static` contains **no libc and no dynamic loader at all** — the kernel must be able to load the binary as a fully static executable. If you forget the flag, the container dies immediately with the famously misleading `exec /quicknotes: no such file or directory` — the binary is there, but its interpreter (`ld-linux`/`ld-musl`) is not. `CGO_ENABLED=0` forces a pure-Go static build that needs nothing from the base image.

**c) What is `gcr.io/distroless/static:nonroot`? What's in it, what isn't, and why does that matter for CVEs?**

Google's distroless images are runtime images with everything stripped except the minimum to run a static binary. `static` contains: ca-certificates (TLS), tzdata (timezones), `/etc/passwd` with the `nonroot` user (UID 65532), and `/home/nonroot`. The `:nonroot` tag additionally defaults the container to UID 65532. What is *not* there: no shell, no package manager (no apt/dpkg), no busybox, no libc, no coreutils. CVE impact: a CVE score needs vulnerable *software* to exist in the image — with no shell and no packages there is almost nothing to scan or exploit. Trivy on this image reports zero HIGH/CRITICAL at the OS level (§4.3), versus dozens on a full Debian/Alpine base — the only HIGH findings Trivy does report come from the compiled Go toolchain itself (the `gobinary` scan, not the base), see §4.3. It also shrinks the attack surface: an attacker who exploits the app lands in a sandbox with no tools and no way to escalate through system utilities.

**d) `-ldflags='-s -w'` and `-trimpath`: what does each flag do, and what's the cost?**

- `-s` removes the ELF symbol table, `-w` removes DWARF debug info. Together they cut the binary by roughly 25–30 %. Cost: a debugger (delve) can no longer map addresses to symbols/variables, and post-mortem debugging is limited. Runtime behavior is unaffected — Go stack traces keep working because they use the runtime's own `pclntab`, not the ELF symtab.
- `-trimpath` rewrites all file paths recorded in the binary from absolute build-machine paths (`/src/...`) to module-relative ones. It removes environment information leaks and makes builds reproducible: the same source + same toolchain produce the same binary bytes. Cost: stack traces show trimmed paths, which is slightly less convenient when navigating a local checkout, and reproducibility requires pinning the toolchain version.
- *Reproducibility, proven:* on the second full build the `RUN go build` layer re-executed (7.4 s), yet all four runtime-stage `COPY --from=builder` layers stayed `CACHED` — `COPY` caches on file content, so the freshly compiled binary was byte-identical to the previous build. Identical input → identical output, exactly what `-trimpath` + a pinned builder image buy you. (Seen again on the compose build in §3.2.)

---

## 3. Task 2 — Compose + healthcheck + persistent volume

### 3.1 compose.yaml (repo root)

```yaml
services:
  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    container_name: quicknotes-lab6

    ports:
      - "8080:8080"

    environment:
      ADDR: ":8080"
      DATA_PATH: /data/notes.json
      SEED_PATH: /seed.json

    volumes:
      - quicknotes-data:/data

    healthcheck:
      test: ["CMD", "/quicknotes", "healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s

    restart: unless-stopped

    # ---- Bonus hardening (details in §4) ----
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true

volumes:
  quicknotes-data:
    name: quicknotes-lab6-data
```

### 3.2 Compose up + persistence test

From the repo root — `docker compose up --build -d` builds the image, creates the named volume and starts the container (build log trimmed to the relevant layers):

```text
C:\...\DevOps-Intro>docker compose up --build -d
[+] Building 11.0s (22/22) FINISHED
 => [internal] load .dockerignore                                                                0.0s
 => => transferring context: 212B
 => [internal] load build context                                                                0.0s
 => => transferring context: 5.34kB
 => [builder 5/6] COPY . .                                                                       0.0s
 => [builder 6/6] RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes .     && mkdir /out/data       7.1s
 => CACHED [stage-1 2/4] COPY --from=builder --chown=65532:65532 /out/quicknotes /quicknotes     0.0s
 => CACHED [stage-1 3/4] COPY --from=builder --chown=65532:65532 /out/data /data                 0.0s
 => CACHED [stage-1 4/4] COPY --from=builder /src/seed.json /seed.json                           0.0s
 => => naming to docker.io/library/quicknotes:lab6                                               0.0s
[+] up 4/4
 ✔ Image quicknotes:lab6        Built
 ✔ Network devops-intro_default Created
 ✔ Volume quicknotes-lab6-data  Created
 ✔ Container quicknotes-lab6    Started
```

Three things to read out of this: (1) the compile layer re-ran (7.1 s — the source tree differs from the last direct build: `main.go` picked up the `healthcheck` subcommand), yet all three runtime-stage `COPY --from=builder` layers were served from cache — the freshly compiled binary is byte-identical again, same reproducibility evidence as §2.5 (d); (2) the build context is 5.34 kB — just the source files, no junk; (3) compose created the named volume (`Volume quicknotes-lab6-data Created`) before starting the container.

Status and volume check:

```text
C:\...\DevOps-Intro>docker compose ps
NAME              IMAGE             COMMAND         SERVICE      CREATED          STATUS                    PORTS
quicknotes-lab6   quicknotes:lab6   "/quicknotes"   quicknotes   25 seconds ago   Up 25 seconds (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp

C:\...\DevOps-Intro>docker volume ls
DRIVER    VOLUME NAME
local     quicknotes-lab6-data
```

`Up ... (healthy)` after ~25 s — the shell-free healthcheck (§3.3 e) does its job; the named volume exists under its fixed name `quicknotes-lab6-data`.

Persistence, step 1 — note created and present:

```text
C:\...\DevOps-Intro>curl.exe -X POST -H "Content-Type: application/json" -d "{\"title\":\"durable\",\"body\":\"survive a restart\"}" http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T11:32:13.770765656Z"}

C:\...\DevOps-Intro>curl.exe http://localhost:8080/notes | findstr durable
[{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point тАФ env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T11:32:13.770765656Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"}]
```

Note id 5 is in the response (findstr matched the whole JSON line — the body is one line). The array order differs between calls because the store keeps notes in a Go map and map iteration order is randomized — only the content matters.

Persistence, step 2 — after `docker compose down` + `up` (volume survives):

```text
C:\...\DevOps-Intro>docker compose down
[+] down 2/2
 ✔ Container quicknotes-lab6    Removed
 ✔ Network devops-intro_default Removed

C:\...\DevOps-Intro>docker compose up -d
[+] up 2/2
 ✔ Network devops-intro_default Created
 ✔ Container quicknotes-lab6    Started

C:\...\DevOps-Intro>curl.exe http://localhost:8080/notes | findstr durable
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point тАФ env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T11:32:13.770765656Z"}]
```

`down` removed the container and the network — the volume is deliberately absent from its output (§3.3 f). The recreated container mounted the same volume and note id 5 is still there. This also proves the write path works end to end: the nonroot process successfully wrote `notes.json` into the volume (the `/data` ownership fix from §2.1 in action).

Persistence, step 3 — after `docker compose down -v` (volume destroyed):

```text
C:\...\DevOps-Intro>docker compose down -v
[+] down 3/3
 ✔ Container quicknotes-lab6    Removed
 ✔ Volume quicknotes-lab6-data  Removed
 ✔ Network devops-intro_default Removed

C:\...\DevOps-Intro>docker compose up -d
[+] up 3/3
 ✔ Volume quicknotes-lab6-data  Created
 ✔ Network devops-intro_default Created
 ✔ Container quicknotes-lab6    Started

C:\...\DevOps-Intro>curl.exe http://localhost:8080/notes | findstr durable

C:\...\DevOps-Intro>docker compose ps
NAME              IMAGE             COMMAND         SERVICE      CREATED          STATUS                    PORTS
quicknotes-lab6   quicknotes:lab6   "/quicknotes"   quicknotes   14 seconds ago   Up 13 seconds (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

`down -v` explicitly removed `Volume quicknotes-lab6-data`; the next `up` created a brand-new empty volume and the app re-seeded it (the `/notes` response shrank from 735 to 635 bytes — back to the 4 seed notes). `findstr durable` printed nothing → the note is gone. The persistence contract is proven in both directions: survives `down`/`up`, dies with `down -v`.

### 3.3 Design questions (Task 2)

**e) Distroless has no shell. How do you healthcheck it?**

A healthcheck execs a command *inside* the container; with no shell, no `curl` and no `wget`, there is nothing to exec — so I used the fourth option from the lab: **use a binary that's already in the image**. The only executable in the image is the app binary itself, so `main.go` gained a `healthcheck` subcommand: it dials `ADDR`/`health` with a 2-second timeout and exits 0 on HTTP 200, 1 otherwise. The compose check runs it in exec form (no shell): `test: ["CMD", "/quicknotes", "healthcheck"]`. Rejected alternatives: a sidecar can't set *this* service's health status and adds a moving part; the `:debug` tag ships busybox but reintroduces the shell we deliberately removed; Docker's implicit "process is alive" check is too weak — a deadlocked server whose process still exists would look healthy.

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`? And what *does* destroy it?**

A named volume lives in Docker's own storage (inside Docker Desktop's Linux VM, `docker volume ls` shows it), not in the container's writable layer. `docker compose down` removes containers and networks only — volumes are deliberately out of its scope because "recreate the app" must not mean "delete the data". The new container mounts the same volume and the note is still there. What does destroy it: `docker compose down -v` (removes the project's volumes), `docker volume rm quicknotes-lab6-data`, `docker volume prune`, or deleting Docker Desktop's Linux data (factory reset). The container filesystem being `read_only` (§4) does not affect the volume — `read_only` covers the root filesystem, not mounted volumes.

**g) `depends_on` without `condition: service_healthy` — what does it actually wait for? What's the bug it can cause?**

Plain `depends_on` only waits until the dependency container is *created and started* — a process exists, which says nothing about readiness (a DB may accept TCP connections before it can serve queries). The bug: the dependent app starts, immediately tries to use the not-yet-ready dependency, and crashes or burns through retries — flapping containers on every `up`. `depends_on: {other: {condition: service_healthy}}` waits until the dependency's healthcheck reports `healthy`, which is the actual contract. This compose has a single service, so there is no `depends_on` here — the healthcheck still matters: `docker compose ps` reports `(healthy)`, orchestrators use the same signal, and restart logic can key off it.

---

## 4. Bonus — the 6 security defaults

### 4.1 Where each default lives

| # | Default | Where applied |
|---|---------|---------------|
| 1 | `USER nonroot` | `app/Dockerfile` (`USER nonroot`, UID 65532) |
| 2 | Distroless base | `app/Dockerfile` (`gcr.io/distroless/static-debian12:nonroot`) |
| 3 | Drop all capabilities | `compose.yaml` (`cap_drop: [ALL]` — QuickNotes needs none) |
| 4 | Read-only root filesystem | `compose.yaml` (`read_only: true` + `tmpfs: [/tmp]`; `/data` is the writable volume) |
| 5 | `no-new-privileges` | `compose.yaml` (`security_opt: [no-new-privileges:true]`) |
| 6 | Trivy scan | §4.3 (CI wiring in Lab 9) |

### 4.2 Verification (evidence the constraints are enforced)

1. `USER nonroot`:
```
C:\...\DevOps-Intro>docker inspect quicknotes:lab6 --format "User={{.Config.User}}"
User=nonroot
```

2. No shell available — this failure *is* the pass condition (there is nothing to exec):
```
C:\...\DevOps-Intro>docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

3. Capabilities dropped:
```
C:\...\DevOps-Intro>docker inspect quicknotes-lab6 --format "{{json .HostConfig.CapDrop}}"
["ALL"]
```

4. Read-only root filesystem. The app container has no shell (verification 2), so `touch` cannot even be exec'd there — the enforcement is shown two ways: the container config flag, and the same distroless base in its `:debug` variant (busybox shell) started with the same `--read-only` constraint:
```
C:\...\DevOps-Intro>docker inspect quicknotes-lab6 --format "ReadonlyRootfs={{.HostConfig.ReadonlyRootfs}}"
ReadonlyRootfs=true

C:\...\DevOps-Intro>docker run --rm --read-only --entrypoint /busybox/sh gcr.io/distroless/static-debian12:debug -c "touch /etc/test"
touch: /etc/test: Read-only file system
```
The write attempt fails at the kernel level — the writable layer simply does not exist. (Functional cross-check from §3.2: the app runs and persists notes fine, because its only writable paths are the `/data` volume and the `/tmp` tmpfs — exactly the two mounts the compose file provides.)

5. `no-new-privileges`:
```
C:\...\DevOps-Intro>docker inspect quicknotes-lab6 --format "{{json .HostConfig.SecurityOpt}}"
["no-new-privileges:true"]
```

### 4.3 Trivy scan

```
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6
```

Output (DB-download INFO lines and the per-CVE table trimmed; the scan header and both summary blocks verbatim):

```text
2026-09-24T11:49:48Z    INFO    Detected OS     family="debian" version="12.15"
2026-09-24T11:49:48Z    INFO    [debian] Detecting vulnerabilities...   os_version="12" pkg_num=5
2026-09-24T11:49:48Z    INFO    Number of language-specific files       num=1
2026-09-24T11:49:48Z    INFO    [gobinary] Detecting vulnerabilities...

quicknotes:lab6 (debian 12.15)
==============================
Total: 0 (HIGH: 0, CRITICAL: 0)


quicknotes (gobinary)
=====================
Total: 19 (HIGH: 19, CRITICAL: 0)
```

One scan, two separate verdicts — and the distinction is the whole lesson:

- **Base image (`debian 12.15`): 0 HIGH, 0 CRITICAL.** The distroless base ships 5 OS packages in total (`pkg_num=5` — ca-certificates, tzdata, passwd and the like). There is simply no software left to be vulnerable: this is the §2.5 (c) claim, now measured. A comparable scan of a full Debian/Alpine-based image routinely returns dozens of HIGH/CRITICAL OS findings.

- **Embedded Go binary (`gobinary`): 19 HIGH, 0 CRITICAL.** Trivy also reads the Go build metadata stamped into the binary (`go1.24.13` from the pinned builder image) and matches it against the Go CVE database. All 19 are stdlib findings of the DoS class (`net/http`, `crypto/x509`, `crypto/tls`, `net/mail`, `mime`, `encoding/*`) — none come from application code, and the module has zero third-party dependencies to blame. Every one is fixed in Go 1.25.x/1.26.x, so the remediation is a one-line builder bump (`golang:1.24-alpine` → `1.25.x-alpine`) and a rebuild — not a code change. This is routine hygiene for any Go app, and it is exactly the finding the CI gate in Lab 9 will turn into a policy.

Honest summary: the image is clean (0/0 at the OS level), the toolchain carries 19 fixable HIGH / 0 CRITICAL, and because the toolchain is pinned and the build reproducible, the fix is a version bump that changes nothing else. Minimal base + pinned toolchain = cheap remediation.

### 4.4 Which of the 6 defaults gives the most security per line of YAML?

The distroless base (one `FROM` line). It is the only default that *removes software* rather than restricting it: shell, package manager, libc and coreutils are gone, which drops the Trivy HIGH/CRITICAL count to ~0 versus dozens on a regular base, and it weakens every future exploit chain — an attacker with code execution has no shell, no `apt`, no tooling, nothing to pivot through. `cap_drop: [ALL]` is a close second (one line that removes the entire kernel-privilege toolbox), and `read_only: true` kills every write-then-persist attack (droppers, rootkits, log tampering) with one line too. The other defaults constrain what the process *may do*; the distroless base removes what the attacker *can touch*. In practice they compound: minimal base + nonroot + no caps + read-only root + no-new-privileges is five independent walls, and an exploit has to be able to climb all five.

---

## 5. Conclusion

The two deliverables are in place and verified end to end. Task 1: a two-stage Dockerfile compiles QuickNotes on a pinned `golang:1.24-alpine` builder and ships a 15.3 MB (3.43 MB compressed) distroless nonroot image — about 86× smaller than the 1.32 GB toolchain it was built on — with an exec-form `ENTRYPOINT`, `EXPOSE 8080`, and an instruction order that keeps the dependency layers cacheable. Task 2: `compose.yaml` runs the same image with a named volume, env vars, a restart policy, and a shell-free healthcheck built into the app binary; the container reports `(healthy)`, and the persistence contract was demonstrated exactly as specified — a POSTed note survives `down`/`up` and disappears after `down -v`, with the volume-removal line visible in compose's own output. All six security defaults are applied and each is verified by a command (two of the checks pass by *failing* — the image refuses to run a shell), with the Trivy scan in §4.3 closing the loop on the minimal-base story. Carried forward: keep the toolchain out of the runtime, decouple data from the container lifecycle with named volumes, and treat nonroot + dropped caps + read-only root + no-new-privileges as the default shape of every production container, not a bonus.

---

## Appendix A — Files in this PR

| File | Purpose |
|------|---------|
| `app/Dockerfile` | Multi-stage build → distroless nonroot image |
| `app/.dockerignore` | Keeps local run artifacts (`data/`, `bin/`, `tmp/`) out of the build context |
| `app/main.go` | + `healthcheck` subcommand (the only in-image executable, used by the healthcheck) |
| `compose.yaml` | Service, port, named volume, healthcheck, restart policy, bonus hardening |
| `submissions/lab6.md` | This report (evidence = verbatim pasted outputs, no screenshots) |

## Appendix B — Evidence index

Evidence style: verbatim pasted command output embedded in the sections above (no screenshots).

| Evidence | Section |
|----------|---------|
| `git branch` — `feature/lab6` checked out | §0 |
| `docker build` — first build 23.1 s / 20 steps, rebuild with clean 582 B context | §2.2 |
| `docker images` — final 15.3 MB ≤ 25 MB; 1.32 GB → 395 MB → 6.18 MB → 15.3 MB comparison | §2.2 |
| `docker inspect` — User/Entrypoint/ExposedPorts | §2.3 |
| `/health` + `/notes` smoke test | §2.4 |
| Layer-order timings (strategy A vs B) | §2.5 (a) |
| `docker compose up --build -d` + `(healthy)` status + `docker volume ls` | §3.2 |
| Persistence: present → survives `down`/`up` → gone after `down -v` (735 → 635 bytes) | §3.2 |
| 5 hardening verifications + read-only proof on the debug variant | §4.2 |
| Trivy scan summary | §4.3 |
