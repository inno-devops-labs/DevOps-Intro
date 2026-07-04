# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-Stage Dockerfile, ≤ 25 MB

### Dockerfile

```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /build

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build \
    -ldflags='-s -w' \
    -trimpath \
    -o /qn \
    .

RUN CGO_ENABLED=0 go build \
    -ldflags='-s -w' \
    -trimpath \
    -o /healthcheck \
    ./healthcheck

RUN mkdir /data


FROM gcr.io/distroless/static:nonroot

COPY --from=builder --chown=65532:65532 /data /data
COPY --from=builder /qn /qn
COPY --from=builder /healthcheck /healthcheck
COPY --from=builder /build/seed.json /seed.json

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/healthcheck"]

ENTRYPOINT ["/qn"]
```

### `docker images quicknotes:lab6`

```
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
quicknotes   lab6      cbdeef4afc56   38 seconds ago   21.6MB
```

### `docker inspect quicknotes:lab6` — Config excerpt

```json
{
  "User": "65532",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/qn"
  ],
  "Healthcheck": {
    "Interval": 10000000000,
    "Retries": 3,
    "StartPeriod": 5000000000,
    "Test": [
      "CMD",
      "/healthcheck"
    ],
    "Timeout": 3000000000
  }
}
```

### Builder base image size (for comparison)

```
REPOSITORY   TAG           IMAGE ID       CREATED        SIZE
golang       1.24-alpine   8bee1901f1e5   4 months ago   388MB
```

Builder: **388 MB** → final image: **21.6 MB** (94% reduction via multi-stage build)

### Design Questions

**a) Why does layer order matter?**

Docker caches layers: each instruction is only re-executed when its content or any preceding layer changes. If you write `COPY . . && go mod download && go build`, any single-line edit to a `.go` file invalidates the `COPY . .` layer and forces a full `go mod download` — re-fetching every dependency over the network. With the correct order:

```dockerfile
COPY go.mod ./
RUN go mod download   # cached unless go.mod changes
COPY . .
RUN go build          # only source changes invalidate this
```

the dependency download layer is only re-executed when `go.mod` changes — typically once per sprint rather than on every rebuild. In practice this turns a 2-3 minute rebuild into a 10-second one for a typical Go project.

**b) Why `CGO_ENABLED=0`?**

CGO is the bridge that lets Go call C code via `libc`. When enabled (the default), the linker produces a dynamically linked binary that expects `libc`, `libpthread`, and the ELF dynamic linker (`/lib/ld-linux.so`) to be present at runtime. `gcr.io/distroless/static:nonroot` contains none of these — it is intentionally minimal (CA certs and timezone data only). Running a dynamically linked binary there produces `exec /qn: no such file or directory` because the dynamic linker itself is missing — not the binary. `CGO_ENABLED=0` forces the Go toolchain to produce a fully static binary that carries all of its runtime in the `.text` segment, with no external shared library dependencies.

**c) What is `gcr.io/distroless/static:nonroot`?**

Google's distroless images are built to contain only what a running application needs — no shell, no package manager, no libc, no debug utilities. The `static` variant adds:
- CA certificate bundle (so HTTPS client calls work)
- Timezone data (`zoneinfo`)
- A pre-created non-root user (`nonroot`, UID 65532 / GID 65532)

It is absent of: `bash`, `sh`, `apt`, `wget`, `curl`, `libc`, `gcc`, and essentially every OS package. This matters for CVEs because the vast majority of container vulnerability scanners flag packages installed via `apt` (glibc, openssl, bash versions, etc.). With distroless-static there is nothing to scan and nothing to exploit: even if an attacker achieves remote code execution inside the container, there is no shell to drop into and no package manager to install further tools with.

**d) `-ldflags='-s -w'` and `-trimpath`**

- `-s` removes the Go symbol table from the binary. The symbol table is used by debuggers and `go tool nm` but is not needed at runtime. Removing it typically saves 10-20% of binary size.
- `-w` removes DWARF debug information (line numbers, type layouts, variable info). Also not needed at runtime; saves another 15-25%.
- `-trimpath` replaces all absolute build paths embedded in the binary (e.g. `/Users/irina/Desktop/.../main.go`) with module-relative paths (`quicknotes/main.go`). Without it, full host filesystem paths appear in panic stack traces, leaking your directory structure. The cost: stack traces in production logs won't show host-absolute paths — but module-relative paths are still useful for debugging, so this is a net win.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

### compose.yaml

```yaml
services:
  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      start_period: 5s
      retries: 3
    restart: unless-stopped

volumes:
  quicknotes-data:
```

### Persistence test

```bash
# 1. Start and POST a new note
docker compose up --build -d
sleep 5
curl -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes
curl -s http://localhost:8080/notes | grep durable
```

```
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T11:55:39.929656839Z"}
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T11:55:39.929656839Z"}
```

```bash
# 2. Down (no -v) + up → note must survive
docker compose down
docker compose up -d
sleep 5
curl -s http://localhost:8080/notes | grep durable
```

```
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T11:55:39.929656839Z"}
```

```bash
# 3. Down -v + up → note gone (volume destroyed)
docker compose down -v
docker compose up -d
sleep 5
curl -s http://localhost:8080/notes | grep durable || echo "note gone (expected)"
```

```
note gone (expected)
```

### Design Questions

**e) Distroless has no shell — how do you healthcheck it?**

I compiled a minimal static Go binary (`app/healthcheck/main.go`) in the builder stage alongside the main binary, and copied it into the final image. The healthcheck program makes an HTTP GET to `http://localhost:8080/health` and exits 0 on a 200 response, 1 otherwise. In compose.yaml and the Dockerfile HEALTHCHECK directive the exec form is used — `["CMD", "/healthcheck"]` — which requires no shell. This approach keeps the healthcheck inside the container's network namespace (same as external callers), tests the actual HTTP stack, and adds only ~5 MB to the image while avoiding any shell dependency.

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`?**

Named volumes in Docker are managed by the Docker daemon's volume subsystem independently of any container. `docker compose down` stops and removes containers and their anonymous storage (layers written to the container's writable layer), but named volumes are treated as user data and are preserved. This is by design — you'd lose your database on every deploy otherwise. The volume is destroyed by `docker compose down -v` (the `--volumes` flag), or explicitly with `docker volume rm devops-intro_quicknotes-data`.

**g) `depends_on` without `condition: service_healthy` — what does it actually wait for?**

Without a condition, `depends_on` only waits for the dependency container to *start* (i.e., the Docker daemon transitions it to the `running` state — the process launched). It does NOT wait for the service to be *ready*. The bug this causes: if service A starts as soon as service B's container is running, but B takes 3-10 seconds to initialize (open its port, run migrations, etc.), A's startup requests to B will fail. If A crashes-on-failed-connection, Docker may restart it via the restart policy, eventually succeeding — masking the underlying ordering bug. The safe pattern is `condition: service_healthy`, which waits for B's healthcheck to pass before launching A.
