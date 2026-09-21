# Lab 6 submission

Author: Telman Nuruzov (`Telman3000`)
Branch: `feature/lab6`
Fork: https://github.com/Telman3000/DevOps-Intro
Host: Windows 10 + Docker Engine **29.4.3** (Compose v2)

Course PR: _(fill after open)_

---

## Task 1 — Multi-stage Dockerfile ≤ 25 MB

### `app/Dockerfile`

```dockerfile
# syntax=docker/dockerfile:1
# Lab 6 — multi-stage QuickNotes (≤ 25 MB, distroless nonroot)

# ─── builder ───
FROM golang:1.24-alpine AS builder
WORKDIR /src

# Cache deps before copying source (maximize layer reuse)
COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/quicknotes .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./cmd/healthcheck
# Pre-create /data owned by distroless nonroot (UID 65532) so named volumes inherit writable perms
RUN mkdir -p /out/data && chown 65532:65532 /out/data

# ─── runtime ───
FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY seed.json /seed.json

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

EXPOSE 8080
USER nonroot:nonroot

# Distroless has no shell/wget — use our static healthcheck binary
HEALTHCHECK --interval=5s --timeout=2s --start-period=3s --retries=3 \
  CMD ["/healthcheck"]

ENTRYPOINT ["/quicknotes"]
```

Notes:
- No `go.sum` in the tree (module has **zero** external deps); only `go.mod` is copied for the dep layer.
- Extra static binary `app/cmd/healthcheck` hits `GET /health` — needed because distroless has no shell/`wget`/`curl`.

### Image size

```text
REPOSITORY   TAG       SIZE      IMAGE ID
quicknotes   lab6      22.6MB    5026a99308c5
```

Builder vs runtime base (for comparison):

```text
golang:1.24-alpine                              toolchain base (hundreds of MB)
quicknotes:lab6                                 22.6MB  (≤ 25 MB ✅)
```

Multi-stage discards the Go toolchain; only the static binaries + distroless rootfs remain.

### `docker inspect` Config excerpt

```text
User=nonroot:nonroot
ExposedPorts={"8080/tcp":{}}
Entrypoint=["/quicknotes"]
Env=[...,"ADDR=:8080","DATA_PATH=/data/notes.json","SEED_PATH=/seed.json"]
```

### Smoke test

```text
$ docker run --rm -p 8080:8080 -v qn-data:/data quicknotes:lab6
$ curl -s http://127.0.0.1:8080/health
{"notes":4,"status":"ok"}
```

### Design questions (1.2)

**a) Why does layer-order matter?**

Docker caches each instruction. If you `COPY . .` *before* `go mod download`, any source edit invalidates the dependency layer and re-downloads modules. Ordering `COPY go.mod` → `go mod download` → `COPY . .` → `go build` keeps the dep layer cached when only app code changes.

Measured rebuild after touching only `main.go` (no real external modules, so wall-clock gap is small; cache lines matter):

| Strategy | `go mod download` on rebuild | Wall clock |
|----------|------------------------------|------------|
| Bad: `COPY . .` then `go mod download` | **re-run** (`DONE 0.2s`, not CACHED) | **7.69 s** |
| Good: `go.mod` first, then source | **CACHED** | **6.31 s** |

With real dependencies the bad order would re-fetch the module graph every edit; the good order pays that cost once.

**b) Why `CGO_ENABLED=0`?**

Forces a fully static binary (no `libc` / dynamic linker). Distroless `static` has no dynamic linker (`ld-linux.so`). If you forget `CGO_ENABLED=0`, the binary is dynamically linked and fails at start with something like `no such file or directory` even though the file exists.

**c) What is `gcr.io/distroless/static:nonroot`?**

Google Distroless **static** image: CA certs, timezone data, `/etc/passwd`/`group` with a `nonroot` user (UID **65532**), and almost nothing else — **no shell, no package manager, no apt**. Fewer packages ⇒ fewer OS CVEs and a much smaller attack surface. We used `static-debian12:nonroot` (pinned Debian 12 lineage).

**d) `-ldflags='-s -w'` and `-trimpath`**

- `-s` — omit symbol table; `-w` — omit DWARF debug info → smaller binary, harder to debug with gdb/delve.
- `-trimpath` — strip local filesystem paths from the binary for reproducible builds across machines.

Cost: slightly harder production debugging / stack-symbolization unless you keep separate debug artifacts.

---

## Task 2 — Compose + healthcheck + volume

### `compose.yaml`

```yaml
# Lab 6 — QuickNotes Compose (volume + healthcheck + hardening bonus)
services:
  quicknotes:
    build: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    volumes:
      - quicknotes-data:/data
    tmpfs:
      - /tmp
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 5s
      timeout: 2s
      retries: 3
      start_period: 5s

volumes:
  quicknotes-data:
```

### Persistence test

```text
# POST durable note
{"id":5,"title":"durable","body":"survive a restart",...}

# After docker compose down && up  → still present
... "title":"durable" ...

# After docker compose down -v && up → gone (only seed notes 1–4)
```

Artifacts: `submissions/lab6-artifacts/persist-*.txt`.

`docker compose ps` showed `Up ... (healthy)`.

### Design questions (2.2)

**e) Distroless has no shell. How do you healthcheck it?**

Strategy: ship a tiny **static Go binary** `/healthcheck` in the image that does `GET http://127.0.0.1:8080/health` and exits 0/1. Compose/Dockerfile healthcheck uses exec form `["CMD", "/healthcheck"]` — no shell required. Alternatives (sidecar, `:debug` + wget, process-alive only) are weaker or larger; a binary already in the image is the clean fit for distroless.

**f) Why does the named volume survive `docker compose down`?**

`down` removes containers and the default network; **named volumes are kept** unless you pass `-v` / `--volumes`. `down -v` deletes `quicknotes-data`, so `notes.json` is wiped and the next `up` re-seeds from `SEED_PATH`.

**g) `depends_on` without `condition: service_healthy`**

Classic `depends_on` only waits until the dependency container has **started** (process launched), not until it is ready. A dependent service can race and fail connecting to a still-booting peer. Fix: Compose `depends_on: { svc: { condition: service_healthy } }` (or retries/backoff in the client).

---

## Bonus — 6 security defaults

All six applied (Dockerfile + compose). Evidence:

### 1. `USER nonroot`

```text
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
nonroot:nonroot
```

### 2. Distroless / no shell

```text
$ docker compose exec quicknotes sh
OCI runtime exec failed: ... exec: "sh": executable file not found in $PATH
```

### 3. Drop all capabilities

```text
$ docker inspect <container> --format '{{ .HostConfig.CapDrop }}'
[ALL]
```

### 4. Read-only root filesystem + tmpfs

Compose: `read_only: true`, `tmpfs: [/tmp]`, writable named volume on `/data`.

```text
$ docker inspect <container> --format '{{ .HostConfig.ReadonlyRootfs }}'
true
```

Cannot `touch` inside distroless (no shell). Equivalent check with the same Docker flag:

```text
$ docker run --rm --read-only alpine:3.20 touch /etc/test
touch: /etc/test: Read-only file system
```

### 5. `no-new-privileges`

```text
$ docker inspect <container> --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
```

### 6. Trivy scan

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
  quicknotes:lab6
```

Summary:

| Target | HIGH | CRITICAL |
|--------|-----:|---------:|
| OS packages (debian 12.15 distroless) | **0** | **0** |
| `quicknotes` gobinary (Go stdlib) | 19 | 0 |
| `healthcheck` gobinary (Go stdlib) | 19 | 0 |

Distroless OS surface is clean (0 HIGH/CRITICAL). Remaining findings are **Go stdlib** CVEs baked into binaries built with the `golang:1.24-alpine` toolchain — fix path is rebuilding with a patched Go minor when available (Lab 9 CI wiring). Full output: `submissions/lab6-artifacts/trivy.txt`.

### Which default gives the most security per YAML line?

**`read_only: true` (+ a named volume / tmpfs for needed writes)** is the highest leverage single line: even if an attacker gets RCE, they cannot rewrite the image filesystem, drop malware into `/usr`, or persist via the rootfs. Combined with distroless (no shell) and `cap_drop: [ALL]`, the blast radius shrinks dramatically for almost no operational cost.

---

## How to reproduce

```bash
docker compose up --build -d
curl -s http://127.0.0.1:8080/health
# persistence + bonus checks as above
docker compose down   # keep volume
# docker compose down -v  # wipe volume
```
