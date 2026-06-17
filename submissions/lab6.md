# Lab 6 — Containers: Dockerize QuickNotes

## Deliverables

- Branch: `feature/lab6`
- Dockerfile: [`app/Dockerfile`](../app/Dockerfile)
- Compose file: [`compose.yaml`](../compose.yaml)

---

# Task 1 — Multi-Stage Dockerfile, ≤ 25 MB

## Final Dockerfile

```dockerfile
# syntax=docker/dockerfile:1.7

FROM golang:1.24.13-alpine AS builder

WORKDIR /src

# Copy dependency metadata first to preserve the module-cache layer.
COPY go.mod ./
RUN go mod download

# Copy application source after dependencies.
COPY *.go ./

RUN mkdir -p /out/data && \
    CGO_ENABLED=0 GOOS=linux go test ./... && \
    CGO_ENABLED=0 GOOS=linux go build \
      -trimpath \
      -ldflags="-s -w" \
      -o /out/quicknotes \
      .

# Build a static healthcheck executable because distroless has no shell,
# curl, wget, or package manager.
RUN <<'BUILD_HEALTHCHECK'
cat > /tmp/healthcheck.go <<'GO'
package main

import (
    "net/http"
    "os"
    "time"
)

func main() {
    client := http.Client{
        Timeout: 2 * time.Second,
    }

    response, err := client.Get("http://127.0.0.1:8080/health")
    if err != nil {
        os.Exit(1)
    }
    defer response.Body.Close()

    if response.StatusCode != http.StatusOK {
        os.Exit(1)
    }
}
GO

CGO_ENABLED=0 GOOS=linux go build \
  -trimpath \
  -ldflags="-s -w" \
  -o /out/healthcheck \
  /tmp/healthcheck.go
BUILD_HEALTHCHECK

FROM gcr.io/distroless/static-debian12:nonroot AS runtime

WORKDIR /

COPY --from=builder --chown=65532:65532 /out/quicknotes /quicknotes
COPY --from=builder --chown=65532:65532 /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY --chown=65532:65532 seed.json /seed.json

ENV ADDR=:8080 \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json

EXPOSE 8080

USER 65532:65532

ENTRYPOINT ["/quicknotes"]
```

The project has no external module dependencies, so there is no `go.sum` file. The available dependency metadata, `go.mod`, is copied before the Go source files to preserve the dependency-cache layer.

## Build output

Final rebuild using Go `1.24.13`:

```text
[+] Building 63.9s (22/22) FINISHED
...
=> naming to docker.io/library/quicknotes:lab6
[+] build 1/1
✔ Image quicknotes:lab6 Built

real    1m4.585s
user    0m0.646s
sys     0m0.599s
```

## Final image size

```text
ID=sha256:6d6b29505898d30b690489c457f64136f00a5cdd00a277fcd7b49610e6537246
SizeBytes=13538083
User=65532:65532
Entrypoint=["/quicknotes"]
ExposedPorts={"8080/tcp":{}}
```

```text
12.91 MiB
```

The final image is below the required 25 MB limit.

## Image configuration excerpt

Equivalent `docker inspect` configuration evidence:

```text
User=65532:65532
Entrypoint=["/quicknotes"]
ExposedPorts={"8080/tcp":{}}
```

## Builder image comparison

```text
Image=golang:1.24.13-alpine
SizeBytes=262329113
```

```text
250.18 MiB
```

The final runtime image is 12.91 MiB, while the Go builder image is 250.18 MiB. The compiler, source code, Go toolchain, and build cache do not leak into the runtime image.

## Direct `docker run` verification

The final image was started directly, independently of Compose, on host port `18081`:

```text
Image=sha256:6d6b29505898d30b690489c457f64136f00a5cdd00a277fcd7b49610e6537246
User=65532:65532
Status=running
Ports={"8080/tcp":[{"HostIp":"0.0.0.0","HostPort":"18081"},{"HostIp":"::","HostPort":"18081"}]}
```

Health endpoint:

```json
{"notes":4,"status":"ok"}
```

Notes endpoint:

```json
[
  {
    "id": 1,
    "title": "Welcome to QuickNotes",
    "body": "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.",
    "created_at": "2026-01-15T10:00:00Z"
  },
  {
    "id": 2,
    "title": "Read app/main.go first",
    "body": "Start by understanding the entry point — env vars, signal handling, graceful shutdown.",
    "created_at": "2026-01-15T10:05:00Z"
  },
  {
    "id": 3,
    "title": "DevOps mantra",
    "body": "If it hurts, do it more often.",
    "created_at": "2026-01-15T10:10:00Z"
  },
  {
    "id": 4,
    "title": "Endpoint cheat-sheet",
    "body": "GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics",
    "created_at": "2026-01-15T10:15:00Z"
  }
]
```

Container log:

```text
2026/06/17 18:58:05 quicknotes listening on :8080 (notes loaded: 4)
```

## Static binary and distroless verification

The QuickNotes executable was verified as a stripped, statically linked Linux binary. `ldd` reported:

```text
not a dynamic executable
```

A shell could not be executed:

```text
OCI runtime exec failed: exec failed: unable to start container process:
exec: "sh": executable file not found in $PATH
```

## Design questions

### a) Why does Dockerfile layer order matter?

Docker caches each instruction as an image layer. A layer can be reused only when the instruction and all of its inputs are unchanged. In the poor strategy, `COPY . .` happens before `go mod download`, so every source-code modification invalidates the source-copy layer, dependency-download layer, and build layer. In the cache-friendly strategy, module metadata is copied first, dependencies are downloaded in their own layer, and source code is copied afterwards, allowing source-only edits to reuse the dependency layer.

Measured results:

| Strategy | Initial build | Source-only rebuild |
|---|---:|---:|
| `COPY . .` before `go mod download` | 49.53 s | 55.37 s |
| Module metadata before source | 50.62 s | 52.55 s |

The cache-friendly source-only rebuild was 2.82 seconds faster, approximately 5.1%. The difference was small because this project has no external module dependencies, but the ordering remains correct and becomes more valuable as dependencies grow.

### b) Why use `CGO_ENABLED=0`?

`CGO_ENABLED=0` produces a Go binary that does not require the system C library or a dynamic linker. The selected `distroless/static` runtime is designed for static executables and does not contain the normal dynamic-linking environment of a complete Linux distribution. If the binary were dynamically linked, it could fail at startup with a misleading `no such file or directory` error because the required loader or shared library would be absent.

### c) What is `gcr.io/distroless/static:nonroot`?

A distroless static image is a minimal runtime image intended for statically compiled applications. It contains the essential runtime filesystem components but does not include a shell, package manager, compiler, or ordinary administrative utilities. The `nonroot` variant provides a predefined unprivileged user. Removing unnecessary programs and packages reduces image size and attack surface and also reduces the number of operating-system packages that can contain vulnerabilities.

This implementation uses the Debian 12 equivalent:

```text
gcr.io/distroless/static-debian12:nonroot
```

### d) What do `-ldflags="-s -w"` and `-trimpath` do, and what is the cost?

`-ldflags="-s -w"` removes the symbol table and DWARF debugging information, reducing the binary size. Its trade-off is reduced debugging and post-mortem analysis information. `-trimpath` removes local filesystem paths from the compiled binary, improving reproducibility and avoiding disclosure of build-machine paths. Its trade-off is less detailed path information during debugging.

---

# Task 2 — Compose, Healthcheck, and Persistent Volume

## Final `compose.yaml`

```yaml
services:
  quicknotes:
    image: quicknotes:lab6
    build:
      context: ./app
      dockerfile: Dockerfile
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
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 3s
    restart: unless-stopped
    user: "65532:65532"
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,nodev,size=16m
    security_opt:
      - no-new-privileges:true

volumes:
  quicknotes-data:
```

## Compose validation

```text
PASS: compose.yaml is valid
```

Resolved configuration confirmed:

- Service: `quicknotes`
- Build context: `./app`
- Image: `quicknotes:lab6`
- Published port: `8080`
- Named volume target: `/data`
- Healthcheck command: `/healthcheck`
- Required environment variables present
- Restart policy: `unless-stopped`

## Running service

```text
NAME                             IMAGE             COMMAND         SERVICE      STATUS
devops-intro-lab6-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   Up (healthy)
```

Health endpoint:

```json
{"notes":4,"status":"ok"}
```

## Three-stage persistence test

### 1. Create and confirm the note

```text
=== CREATE DURABLE NOTE ===
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-17T18:40:04.978700286Z"}

=== VERIFY NOTE EXISTS ===
"title":"durable"
```

### 2. Normal `down` and `up`

Commands:

```bash
docker compose down
docker compose up -d
```

Result:

```text
=== VERIFY DURABLE NOTE SURVIVED ===
"title":"durable"
```

The note survived normal container and network removal because the named volume remained.

### 3. `down -v` and `up`

Commands:

```bash
docker compose down -v
docker compose up -d
```

Docker removed and recreated the volume:

```text
Volume devops-intro-lab6_quicknotes-data Removed
Volume devops-intro-lab6_quicknotes-data Created
```

Final result:

```text
=== HEALTH ===
{"notes":4,"status":"ok"}

=== VERIFY DURABLE NOTE IS ABSENT ===
PASS: durable note disappeared after docker compose down -v
```

## Design questions

### e) Distroless has no shell. How is it healthchecked?

The builder compiles a small static Go healthcheck executable and copies it to `/healthcheck` in the runtime image. Compose invokes it using exec form:

```yaml
healthcheck:
  test: ["CMD", "/healthcheck"]
```

The binary performs an HTTP request to `http://127.0.0.1:8080/health`, applies a two-second timeout, and returns a nonzero exit status if the request fails or the response status is not HTTP 200. This provides an application-level healthcheck without adding a shell, `curl`, `wget`, or a package manager.

### f) Why does the named volume survive `docker compose down`, and what destroys it?

A named volume has a lifecycle independent of the service container. `docker compose down` removes the service container and network but preserves named volumes by default, so `/data/notes.json` remains available when the stack starts again. The volume is removed by `docker compose down -v`, an explicit `docker volume rm`, or an applicable unused-volume pruning operation.

### g) What does `depends_on` wait for without `condition: service_healthy`?

Without `condition: service_healthy`, `depends_on` waits for the dependency container to be created and started. It does not guarantee that the application inside that container is ready to accept traffic. A dependent service may therefore start too early and fail its initial database or API connection even though the dependency process is running.

---

# Bonus Task — The Six Security Defaults

## Applied controls

1. Non-root runtime user: `65532:65532`
2. Distroless static runtime
3. All Linux capabilities dropped
4. Read-only root filesystem with `/tmp` as `tmpfs` and `/data` as a named volume
5. `no-new-privileges:true`
6. Image scanned with Trivy `0.59.1`

## Hardened service block

```yaml
services:
  quicknotes:
    image: quicknotes:lab6
    build:
      context: ./app
      dockerfile: Dockerfile
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
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 3s
    restart: unless-stopped
    user: "65532:65532"
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,nodev,size=16m
    security_opt:
      - no-new-privileges:true
```

## Five verification outputs

### 1. Non-root user

```text
User=65532:65532
```

### 2. No shell available

```text
OCI runtime exec failed: exec failed: unable to start container process:
exec: "sh": executable file not found in $PATH
```

### 3. Capabilities dropped

```text
DroppedCapabilities=["ALL"]
```

### 4. Read-only root enforced

A temporary container was started with `DATA_PATH=/etc/notes.json` and a read-only root filesystem. It failed when the application attempted to write:

```text
2026/06/17 18:24:30 seed: open /etc/notes.json: read-only file system
```

The regular service keeps its writable application state in the `/data` named volume and uses a restricted RAM-backed `/tmp` mount:

```text
ReadOnlyRootFilesystem=true
Tmpfs={"/tmp":"rw,noexec,nosuid,nodev,size=16m"}
Mounts=[{"Type":"volume","Name":"devops-intro-lab6_quicknotes-data","Destination":"/data","RW":true}]
```

### 5. No new privileges

```text
SecurityOptions=["no-new-privileges:true"]
```

Additional runtime evidence:

```text
RestartPolicy=unless-stopped
Healthcheck={"Test":["CMD","/healthcheck"],"Interval":5000000000,"Timeout":3000000000,"StartPeriod":3000000000,"Retries":5}
```

## Exact Trivy 0.59.1 scan

Command:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image \
  --severity HIGH,CRITICAL \
  --no-progress \
  quicknotes:lab6
```

Summary:

```text
quicknotes:lab6 (debian 12.14)
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
Total: 12 (HIGH: 12, CRITICAL: 0)

quicknotes (gobinary)
Total: 12 (HIGH: 12, CRITICAL: 0)
```

The distroless Debian runtime layer had zero High or Critical findings. The remaining findings were associated with the Go standard library embedded in the two static binaries. Updating the builder from Go `1.24.5` to `1.24.13` removed the earlier Critical finding, while Trivy listed the remaining fixes in later Go `1.25.x` and `1.26.x` releases. Because Task 1 requires the builder to remain pinned to the Go `1.24` series, the patched `1.24.13` builder was retained and the remaining findings are documented transparently.

## Security reflection

Dropping all Linux capabilities provides substantial security for only two lines of Compose configuration because QuickNotes needs no privileged kernel operations. The read-only root filesystem is similarly valuable because it prevents persistent modification of the container image and forces writable state into explicitly declared mounts. Distroless removes the shell, package manager, and unnecessary tools that could be abused after a compromise. These controls work best together with non-root execution, `no-new-privileges`, and continuous vulnerability scanning rather than as isolated protections.

---

# Final Checklist

- Multi-stage Dockerfile: complete
- Official Go builder pinned to `1.24.13`: complete
- Distroless static runtime: complete
- Static stripped binary with `-trimpath`: complete
- Non-root UID/GID `65532:65532`: complete
- Exec-form entrypoint and `EXPOSE 8080`: complete
- Final image size `12.91 MiB`: passed
- Cache-friendly Dockerfile order: complete
- Direct `/health` and `/notes` verification: passed
- Design questions a–d: answered
- Root-level Compose service: complete
- Named-volume persistence: passed
- Volume destruction with `down -v`: passed
- Healthcheck, environment, and restart policy: complete
- Design questions e–g: answered
- All six Bonus security defaults: applied
- Five Bonus enforcement checks: captured
- Exact Trivy `0.59.1` scan: captured
- Security reflection: included
