# Lab 6 Submission - Containers: Dockerize QuickNotes

---

## Task 1 - Multi-Stage Dockerfile

### 1.1 Dockerfile

```dockerfile
# --- Stage 1: builder ----------------------------------------------------
FROM golang:1.24-alpine AS builder

WORKDIR /src

# Copy dependency files first to maximize layer cache reuse.
# go.mod changes less frequently than source code —
# so if only source changes, the go mod download layer is reused.
COPY go.mod ./
RUN go mod download

# Copy source code after dependencies are cached
COPY . .

# Build a static binary:
# CGO_ENABLED=0 - disables C bindings, produces a fully static binary
# -trimpath     - removes local file paths from the binary (reproducibility)
# -ldflags='-s -w' - strips debug symbols and DWARF info (smaller binary)
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /quicknotes .

# Build a minimal static healthcheck binary.
# distroless/static has no shell, curl, or wget — this tiny Go program
# does GET /health and exits 0 on HTTP 200, 1 otherwise.
RUN printf 'package main\nimport ("net/http";"os")\nfunc main(){r,e:=http.Get("http://localhost:8080/health");if e!=nil{os.Exit(1)};if r.StatusCode!=200{os.Exit(1)}}\n' \
    > /tmp/healthcheck.go && \
    CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /healthcheck /tmp/healthcheck.go

# Pre-create /data owned by nonroot (uid 65532).
# When Docker mounts a fresh named volume here, it seeds the volume with
# this directory including ownership — so the nonroot process can write to it
# without a separate init container.
RUN mkdir -p /data

# --- Stage 2: runtime ----------------------------------------------------
# Distroless static image: no shell, no apt, no package manager, minimal CVEs.
# The :nonroot tag sets the default user to uid 65532 (nonroot).
FROM gcr.io/distroless/static:nonroot

# Copy only the compiled binary from the builder stage
COPY --from=builder /quicknotes /quicknotes

# Copy the healthcheck binary (distroless has no shell/curl/wget)
COPY --from=builder /healthcheck /healthcheck

# Copy /data with nonroot ownership so named volumes inherit correct permissions
COPY --from=builder --chown=65532:65532 /data /data

# Copy the seed data file needed by QuickNotes on startup
COPY seed.json /seed.json

# Document that the container listens on port 8080
EXPOSE 8080

# Run as nonroot user (uid 65532) — never as root
USER nonroot

# Use exec form (not shell form) so the process gets PID 1 directly.
# Shell form would require sh which doesn't exist in distroless.
ENTRYPOINT ["/quicknotes"]
```

### 1.2 Image size

```text
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   862b131225de       15.4MB         3.32MB 
```

Final image: **15.4 MB**

Base image size for comparison:
```text
$ docker images golang:1.24-alpine
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
golang:1.24-alpine   8bee1901f1e5        390MB         83.5MB 
```

### 1.3 docker inspect Config excerpt

```text
User:         nonroot
ExposedPorts: {"8080/tcp": {}}
Entrypoint:   ["/quicknotes"]
```

### 1.4 Design Questions

**a) Why does layer order matter?**
Dockerfile layers are cached by content. If `COPY . .` comes before `go mod download`, every source code change invalidates the dependency download layer, forcing a full re-download on every build. By copying `go.mod` first, running `go mod download`, then copying the source, the dependency layer is only invalidated when `go.mod` changes, not when source changes. Result: rebuilds go from ~30s to ~5s.

**b) Why `CGO_ENABLED=0`?**
By default, Go uses CGO to link against the host's C standard library (`libc`) for certain operations. A dynamically-linked binary requires `libc` to be present at runtime. `distroless/static` contains no C library. If you forget `CGO_ENABLED=0`, the container will fail with `no such file or directory` when trying to load the missing dynamic linker (`/lib/ld-linux-x86-64.so.2`). Setting `CGO_ENABLED=0` produces a fully static binary that carries everything it needs.

**c) What is `gcr.io/distroless/static:nonroot`?**
It is a Google-maintained base image containing only the absolute minimum needed to run a static binary: CA certificates, timezone data, and a minimal `/etc/passwd`. It has no shell (`sh`, `bash`), no package manager (`apt`, `apk`), no `libc`, no utilities. The `:nonroot` tag additionally sets the default user to `uid 65532` (named `nonroot`). This matters for CVEs because every package in a container is a potential vulnerability surface. With distroless, there are typically zero HIGH/CRITICAL CVEs in the base image because there is almost nothing to scan.

**d) `-ldflags='-s -w'` and `-trimpath`**
- `-ldflags='-s -w'`: `-s` strips the symbol table; `-w` strips DWARF debug info. Together they shrink the binary by ~30%. The cost: you cannot attach a debugger (`gdb`, `dlv`) to the binary or get useful stack traces with source line numbers. For a production release binary, this trade-off is acceptable.
- `-trimpath`: removes the local build path from the binary (e.g. `/home/mackay/DevOps-Intro/app/main.go` becomes `app/main.go`). This makes builds reproducible, the same source produces bit-for-bit identical binaries regardless of where on disk it was built. The cost: none in practice.

---

## Task 2 - Compose + Healthcheck + Persistent Volume

### 2.1 compose.yaml

```yaml
services:
  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: /data/notes.json
      SEED_PATH: /seed.json
    volumes:
      - quicknotes-data:/data
    tmpfs:
      - /tmp
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    cap_drop:
      - ALL
    read_only: true
    security_opt:
      - no-new-privileges:true
    restart: unless-stopped

volumes:
  quicknotes-data:
```

### 2.2 Persistence test

```text
# Step 1: POST a durable note
$ docker run --rm --network devops-intro_default alpine \
    wget -qO- --header='Content-Type: application/json' \
    --post-data='{"title":"durable","body":"survive a restart"}' \
    http://quicknotes:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-24T10:54:20.905439015Z"}

# Step 2: Verify it exists
$ docker run --rm --network devops-intro_default alpine \
    wget -qO- http://quicknotes:8080/notes | grep durable
"title":"durable"

# Step 3: Restart WITHOUT destroying the volume
$ docker compose down && docker compose up -d
$ sleep 4
$ docker run --rm --network devops-intro_default alpine \
    wget -qO- http://quicknotes:8080/notes | grep durable
"title":"durable"    - note survived

# Step 4: Destroy the volume with -v
$ docker compose down -v && docker compose up -d
$ sleep 4
$ docker run --rm --network devops-intro_default alpine \
    wget -qO- http://quicknotes:8080/notes | grep durable
(no output)          - note is gone, volume was destroyed
```

### 2.3 Design Questions

**e) Distroless has no shell — how do you healthcheck it?**
The strategy used here is to build a minimal static Go binary (`/healthcheck`) in the builder stage and copy it into the final image alongside the main binary. This tiny program does a single `GET /health`, exits 0 if the response is HTTP 200, and exits 1 on any error. Since it is compiled with `CGO_ENABLED=0` it is fully static and runs fine in `distroless/static` with no shell or libc needed.

Other options considered:
- **`["NONE"]`** disables healthcheck entirely, Docker only monitors that PID 1 is alive. Simple but gives no application-level health signal.
- **`wget` from busybox** - copy `/bin/wget` from a busybox image. Works but depends on a specific busybox image tag being available and pulls in a shell tool that is otherwise unused.
- **Sidecar container** - a second service that polls the first. More complexity than needed for a single-service app.

**f) Why does a named volume survive `docker compose down`?**
A named volume (`quicknotes-data:/data`) is managed by Docker independently of the container lifecycle. `docker compose down` stops and removes containers but leaves volumes intact by design — volumes are treated as persistent data, not ephemeral container state. The only commands that destroy a named volume are `docker compose down -v` (removes volumes declared in compose.yaml) or `docker volume rm <name>`. This design reflects the principle that data outlives the process serving it.

**g) `depends_on` without `condition: service_healthy` — what does it wait for?**
Without a condition, `depends_on` only waits for the container to start (i.e. the process to be launched), not for it to be ready to accept connections. The bug this causes: if QuickNotes depends on a database and starts before the DB is accepting connections, it will fail with a connection refused error even though the DB container is "running". The fix is `condition: service_healthy` combined with a proper `healthcheck:` on the dependency then `depends_on` waits for the healthcheck to pass before starting the dependent service.

---
