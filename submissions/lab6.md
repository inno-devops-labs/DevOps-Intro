# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-Stage Dockerfile

### Dockerfile

```dockerfile
# syntax=docker/dockerfile:1

# ---- Builder stage ----
FROM golang:1.24-alpine AS builder

WORKDIR /src

# Copy dependency files first to maximize layer cache reuse.
COPY go.mod ./
RUN go mod download

# Copy application source.
COPY . .

# Build a static, stripped, reproducible binary.
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/quicknotes . && \
    mkdir -p /out/data && \
    chown 65532:65532 /out/data

# ---- Runtime stage ----
FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /app/quicknotes
COPY --from=builder /src/seed.json /app/seed.json
COPY --from=builder --chown=65532:65532 /out/data /data

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/app/quicknotes"]
```

### Image size

```text
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   5279459c8802       14.5MB         3.16MB
```

The final QuickNotes image uses 14.5 MB of disk space, which is below the required 25 MB limit.

For comparison, the Go builder image is significantly larger:

```text
IMAGE                ID             DISK USAGE   CONTENT SIZE
golang:1.24-alpine   8bee1901f1e5        388MB         79.9MB
```

### Image configuration

```text
User=nonroot:nonroot | ExposedPorts={"8080/tcp":{}} | Entrypoint=["/app/quicknotes"]
```

The runtime image therefore runs as a non-root user, exposes TCP port 8080, and uses an exec-form entrypoint.

### Runtime verification

The image was run with port 8080 published and persistent storage mounted at `/data`.

The application started successfully:

```text
quicknotes listening on :8080 (notes loaded: 4)
```

The health endpoint returned HTTP 200:

```json
{"notes":4,"status":"ok"}
```

The `/notes` endpoint also returned the seeded notes successfully.

### Design questions

#### a) Why does layer order matter?

Docker can reuse a cached layer only while the layers it depends on remain unchanged. If `COPY . .` is placed before `go mod download`, changing an application source file invalidates the `COPY` layer and therefore also causes the dependency-download step to execute again.

I compared two strategies after changing `main.go`.

Bad ordering:

```dockerfile
COPY . .
RUN go mod download
RUN go build ...
```

Result:

```text
COPY . .             rebuilt
RUN go mod download  rebuilt (0.1s)
RUN go build          rebuilt (2.9s)

Total rebuild time: 5.104s
```

Optimized ordering:

```dockerfile
COPY go.mod ./
RUN go mod download
COPY . .
RUN go build ...
```

Result:

```text
COPY go.mod ./        CACHED
RUN go mod download   CACHED
COPY . .              rebuilt (0.1s)
RUN go build           rebuilt (3.0s)

Total rebuild time: 4.960s
```

This project has no `go.sum` because it currently has no external Go module dependencies. The time difference is therefore small, but the cache behavior demonstrates the advantage: changing application source code does not invalidate the dependency layer in the optimized version.

#### b) Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` builds QuickNotes without dependencies on C libraries, producing a static Go binary suitable for the distroless static runtime. If a binary depends on dynamically linked C libraries, a minimal distroless-static image may not contain the required dynamic linker or libraries and the application may fail to start.

#### c) What is `gcr.io/distroless/static:nonroot`?

The distroless static image contains only the minimal runtime files required to execute a static binary. It does not contain a normal shell, package manager, compiler, or other development utilities.

The `nonroot` variant provides a non-root execution environment. Removing unnecessary runtime tools and packages reduces the image size and the number of components that can contain vulnerabilities or be used by an attacker.

#### d) What do `-ldflags="-s -w"` and `-trimpath` do?

`-ldflags="-s -w"` removes symbol-table and DWARF debugging information from the compiled Go binary, reducing its size.

`-trimpath` removes local filesystem paths from the compiled output, improving reproducibility and preventing build-machine paths from being embedded in the binary.

The trade-off is reduced debugging information in the production binary.

---

## Task 2 — Compose, Healthcheck and Persistent Volume

### compose.yaml

```yaml
services:
  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/app/seed.json"
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    restart: unless-stopped
    cap_drop:
      - ALL
    read_only: true
    security_opt:
      - no-new-privileges:true

  healthcheck:
    image: curlimages/curl:8.12.1
    depends_on:
      - quicknotes
    command:
      - /bin/sh
      - -c
      - |
        while true; do
          curl -fsS http://quicknotes:8080/health || exit 1
          sleep 30
        done
    restart: unless-stopped

volumes:
  quicknotes-data:
```

Compose configuration validation:

```text
compose valid
```

### Persistence test

QuickNotes was started with Compose and a new note was created:

```text
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T14:09:12.101511671Z"}
```

The note was visible through `/notes`.

After:

```bash
docker compose down
docker compose up -d
```

the `durable` note was still present, proving that the named volume survived container recreation.

The volume was then explicitly removed:

```bash
docker compose down -v
```

Output included:

```text
Volume devops-intro_quicknotes-data Removed
```

After starting Compose again, a new volume was created:

```text
Volume devops-intro_quicknotes-data Created
```

Searching `/notes` for `durable` then produced no output. This confirms that the data persisted across normal `down`/`up`, but was removed by `down -v`.

### Design questions

#### e) How do you healthcheck a distroless container with no shell?

The QuickNotes runtime is distroless and does not contain `sh`, `curl`, or `wget`. I therefore used a separate `curlimages/curl` sidecar service.

The sidecar periodically requests:

```text
http://quicknotes:8080/health
```

and exits with a failure if the HTTP request fails. This avoids adding debugging/networking utilities to the minimal QuickNotes runtime image.

The sidecar verifies application availability, but it does not set Docker's native `healthy` status on the QuickNotes container itself.

#### f) Why does the named volume survive `docker compose down`?

`quicknotes-data:/data` is a Docker named volume. `docker compose down` removes the Compose containers and network but preserves named volumes by default, so `notes.json` remains available when the service is recreated.

Running:

```bash
docker compose down -v
```

explicitly removes the named volume and therefore destroys the persisted QuickNotes data.

#### g) What does `depends_on` without `condition: service_healthy` wait for?

Basic `depends_on` controls service startup order, but it does not guarantee that the dependency's application is ready to serve requests.

Therefore, the dependent container can start while QuickNotes is still initializing. This can cause a startup race in which the first request to QuickNotes fails even though its container has already started.

---

## Bonus — Container Security Defaults

The QuickNotes service applies the requested container-hardening defaults.

### 1. Non-root user

Command:

```bash
docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
```

Output:

```text
nonroot:nonroot
```

### 2. Distroless runtime / no shell

Command:

```bash
docker compose exec quicknotes sh
```

Output:

```text
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

This confirms that the runtime image does not contain a shell.

### 3. Linux capabilities dropped

Command:

```bash
docker inspect devops-intro-quicknotes-1 --format '{{ .HostConfig.CapDrop }}'
```

Output:

```text
[ALL]
```

QuickNotes does not require additional Linux capabilities.

### 4. Read-only root filesystem

Command:

```bash
docker inspect devops-intro-quicknotes-1 --format 'ReadonlyRootfs={{ .HostConfig.ReadonlyRootfs }}'
```

Output:

```text
ReadonlyRootfs=true
```

Application data remains writable through the dedicated `/data` named volume.

### 5. No new privileges

Command:

```bash
docker inspect devops-intro-quicknotes-1 --format '{{ .HostConfig.SecurityOpt }}'
```

Output:

```text
[no-new-privileges:true]
```

### 6. Trivy vulnerability scan

The image was scanned with Trivy 0.59.1:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image \
  --severity HIGH,CRITICAL \
  --no-progress \
  quicknotes:lab6
```

Runtime OS result:

```text
quicknotes:lab6 (debian 13.7)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)
```

Go binary result:

```text
app/quicknotes (gobinary)
=========================
Total: 19 (HIGH: 19, CRITICAL: 0)
```

The distroless runtime itself reported zero HIGH or CRITICAL vulnerabilities. Trivy separately identified 19 HIGH vulnerabilities in the Go standard library embedded in the binary built with Go v1.24.13. The scan result is documented as observed rather than suppressed or modified.

### Security reflection

For this application, dropping all Linux capabilities provides strong protection for a single line of Compose configuration because QuickNotes does not require any additional capabilities. Running as non-root and enabling `no-new-privileges` further restrict what a compromised process could do. A read-only root filesystem limits filesystem modification, while the named `/data` volume keeps only the required application state writable. The distroless runtime also reduces the available attack surface by excluding tools such as shells and package managers.