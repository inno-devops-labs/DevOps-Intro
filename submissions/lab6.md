# Lab 6 — Containers: Dockerize QuickNotes

## Objective

Write a multi-stage `Dockerfile` that produces a small (≤ 25 MB) distroless,
nonroot image of QuickNotes, and a `compose.yaml` that runs it with a
healthcheck and a persistent named volume.

## Environment

| Component | Version / value          |
|-----------|--------------------------|
| Host OS   | Windows 10               |
| Docker    | 28.2.2                   |
| Builder   | `golang:1.24.5`          |
| Runtime   | `gcr.io/distroless/static:nonroot` |
| App       | QuickNotes (`./app`)     |

---

## Task 1 — Multi-stage Dockerfile

### The Dockerfile (`app/Dockerfile`)

```dockerfile
# syntax=docker/dockerfile:1

# ─── builder stage ───
FROM golang:1.24.5 AS builder
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /quicknotes .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /healthcheck ./cmd/healthcheck
RUN mkdir -p /data

# ─── runtime stage ───
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /data /data
COPY seed.json /seed.json
ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"
EXPOSE 8080
USER nonroot
ENTRYPOINT ["/quicknotes"]
```

QuickNotes has no third-party dependencies, so there is no `go.sum`; only
`go.mod` is copied before the source for cache discipline.

### Image size (`docker images quicknotes:lab6`)

```text
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
quicknotes   lab6      c5af68923e37   ...             22.7MB
```

22.7 MB — under the 25 MB budget. Base-image sizes for comparison:

| Image                               | Size    |
|-------------------------------------|--------:|
| `golang:1.24.5` (builder)           | 1.25 GB |
| `gcr.io/distroless/static:nonroot`  | 6.38 MB |
| **`quicknotes:lab6` (final)**       | **22.7 MB** |

### `docker inspect` config excerpt

```text
User=nonroot
Entrypoint=[/quicknotes]
ExposedPorts=map[8080/tcp:{}]
Env=[... ADDR=:8080 DATA_PATH=/data/notes.json SEED_PATH=/seed.json]
```

### Run + verify

```text
$ docker run --rm -p 8080:8080 quicknotes:lab6   (via `docker compose up -d`)
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

### Design questions

**a) Why does layer-order matter?**
Each `COPY`/`RUN` is a cached layer; a layer's cache is invalidated when its
inputs change, which also busts every layer after it. If you `COPY . .` *before*
`go mod download`, any source edit invalidates the dependency layer and forces a
re-download every build. Copying `go.mod` first keeps the dependency layer
stable across source changes. Measured on this project:

| Strategy                              | Build time |
|---------------------------------------|-----------:|
| `--no-cache` (cold, downloads + builds) | ~7.6 s |
| Cached rebuild (no changes)             | ~2.3 s |

On rebuild the build log shows `go mod download` and the deps layers as
`CACHED`. (QuickNotes has zero external deps, so its download layer is tiny and
the absolute saving is modest; on a real dependency tree the difference is large.)

**b) Why `CGO_ENABLED=0`?**
It produces a statically linked binary with no libc / dynamic-linker
dependency. `distroless/static` contains no libc and no dynamic loader, so a
CGO-enabled (dynamically linked) binary would fail at startup with
`no such file or directory` even though the file exists — the missing piece is
the loader.

**c) What is `gcr.io/distroless/static:nonroot`?**
A minimal base image that contains only what a static binary needs: CA
certificates, `/etc/passwd`, timezone data, and a non-root user (UID 65532). It
has **no shell, no package manager, no busybox, no libc**. Because there is
almost nothing installed, there is almost no attack surface and almost nothing
for CVE scanners to flag — most OS-package CVEs simply don't apply.

**d) `-ldflags='-s -w'` and `-trimpath`.**
`-s` strips the symbol table, `-w` strips DWARF debug info — together they
shrink the binary (the cost: harder debugging / no stack symbols in a debugger).
`-trimpath` removes absolute filesystem paths from the binary, making builds
reproducible across machines (the cost: build paths no longer appear in panics,
which is usually desirable anyway).

---

## Task 2 — Compose + healthcheck + persistent volume

### `compose.yaml` (repo root)

```yaml
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
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped

volumes:
  quicknotes-data:
```

Healthcheck status after `docker compose up`:

```text
NAME                        IMAGE             SERVICE      STATUS
devops-intro-quicknotes-1   quicknotes:lab6   quicknotes   Up (healthy)
```

### Persistence test

```text
# 1. POST a note, confirm present
$ curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"title":"durable","body":"survive a restart"}' http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T20:53:27Z"}
$ curl -s http://localhost:8080/notes | grep durable
... "id":5,"title":"durable" ...                       # present ✅

# 2. down (NOT -v), then up — note survives
$ docker compose down
$ docker compose up -d
$ curl -s http://localhost:8080/notes | grep durable
... "id":5,"title":"durable" ...                       # STILL present ✅

# 3. down -v (destroys the volume), then up — note is gone
$ docker compose down -v
$ docker compose up -d
$ curl -s http://localhost:8080/notes | grep durable
(no match)                                             # gone ✅
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}                              # back to 4 seed notes
```

### Design questions

**e) Distroless has no shell — how do you healthcheck it?**
I ship a tiny **static healthcheck binary** (`app/cmd/healthcheck`) built in the
builder stage and copied into the image, and call it with the exec-form test
`["CMD", "/healthcheck"]`. It does a single `GET /health` and exits 0 on HTTP
200, else 1. This avoids the shell entirely (so it works in distroless) and
needs no extra sidecar or debug image. It is verified working: the container
reaches `(healthy)` status, and `docker compose exec quicknotes sh` fails with
`exec: "sh": executable file not found`, proving there is no shell.

**f) Why does `quicknotes-data:/data` survive `docker compose down`?**
`docker compose down` removes containers and the default network but **not named
volumes**. The volume `quicknotes-data` lives in Docker's volume store
(`/var/lib/docker/volumes/`) independently of any container, so the next `up`
re-attaches the same volume with its data intact. What destroys it:
`docker compose down -v`, `docker volume rm`, or `docker volume prune`.

**g) `depends_on` without `condition: service_healthy`.**
Plain `depends_on` only waits for the dependency container to be **started**
(process launched) — not for it to be **ready**. The bug: the dependent service
can connect before the dependency is actually accepting requests (e.g. a DB
still initializing), causing flaky startup failures. Adding
`condition: service_healthy` makes it wait for the dependency's healthcheck to
pass first.

---

## Notes

- A small supporting file was added: `app/cmd/healthcheck/main.go` — the static
  healthcheck helper required because distroless has no shell/wget/curl.
- The data directory is pre-created in the image owned by UID 65532 so the fresh
  named volume is writable by the nonroot user (otherwise the volume is
  root-owned and the app crashes with `permission denied` — the exact pitfall
  the lab warns about).
- Bonus (6 security defaults) was intentionally not attempted.
