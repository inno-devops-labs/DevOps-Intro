# Lab 6 - Containers: Dockerize QuickNotes

## Environment

- Host: MacBook Air, Apple M3 (arm64), macOS
- Docker 29.6.1 (the lab mentions 28.x), Docker Compose v5.1.4
- The image is built for linux/arm64

## Task 1 - Multi-Stage Dockerfile, at most 25 MB

### Dockerfile

Path: `app/Dockerfile` (https://github.com/Kulichcom/DevOps-Intro/blob/feature/lab6/app/Dockerfile)

```dockerfile
# syntax=docker/dockerfile:1

# ---- builder stage ----
FROM golang:1.24-alpine AS builder
WORKDIR /src

# Dependency files first, so this layer is cached until go.mod/go.sum change
COPY go.mod go.sum* ./
RUN go mod download

# Source code after that
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/quicknotes . \
 && CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./healthcheck \
 && mkdir /data

# ---- runtime stage ----
FROM gcr.io/distroless/static:nonroot
WORKDIR /app
COPY --from=builder /out/quicknotes /app/quicknotes
COPY --from=builder /out/healthcheck /app/healthcheck
COPY seed.json /app/seed.json
# /data owned by nonroot (65532), so a named volume mounted there is writable
COPY --from=builder --chown=65532:65532 /data /data

ENV ADDR=:8080 DATA_PATH=/data/notes.json SEED_PATH=/app/seed.json
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["/app/quicknotes"]
```

A `.dockerignore` keeps the local binary, the `data/` folder, tests and docs out of the build context.

### Image size

```
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   cd978a613102       21.9MB         5.36MB

$ docker images golang:1.24-alpine
IMAGE                ID             DISK USAGE   CONTENT SIZE
golang:1.24-alpine   8bee1901f1e5        388MB         80.1MB
```

The final image is 21.9 MB on disk (5.36 MB compressed), under the 25 MB limit. The builder base image is 388 MB, so the multi-stage build removes the whole Go toolchain from the final image.

### Run and inspect

```
$ docker run -d --name qn-test -p 8080:8080 quicknotes:lab6
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}

$ docker inspect quicknotes:lab6 --format 'User={{json .Config.User}} Ports={{json .Config.ExposedPorts}} Entrypoint={{json .Config.Entrypoint}}'
User="65532:65532" Ports={"8080/tcp":{}} Entrypoint=["/app/quicknotes"]
```

### Design questions

**a) Layer order.** Docker reuses a cached layer only if that layer and every layer before it are unchanged. If `go.mod` and `go.sum` are copied and downloaded first, the dependency layer is reused when only the source code changes. With `COPY . .` first, any source edit invalidates the layer, so the dependencies are downloaded again. My measurements (rebuild after a small change in `main.go`, with the base images already pulled):
- Good order (`COPY go.mod go.sum*` first): 7.6 s
- Bad order (`COPY . .` first): 4.6 s

The bad order was not slower here. QuickNotes has no external dependencies, so `go mod download` has nothing to fetch, and the difference is just noise. The good order pays off in a project with real dependencies, where the bad order would download all of them again after every code change.

**b) Why `CGO_ENABLED=0`?** With cgo enabled, a Go binary can be linked dynamically against the C library (for example for DNS lookups). `distroless/static` has no libc and no dynamic linker, so such a binary fails to start with an error like `exec /app/quicknotes: no such file or directory`, even though the file exists. With `CGO_ENABLED=0` the binary is fully static and runs without anything from the OS.

**c) What is `gcr.io/distroless/static:nonroot`?** It is a minimal Google base image. It contains only what a static binary needs: CA certificates, timezone data, a basic `/etc/passwd` with the `nonroot` user (UID 65532), and `/tmp`. It does not contain a shell, a package manager, libc, or any common tools. This matters for CVEs because vulnerability scanners find issues in installed packages, and an image with almost no packages has almost nothing to report. It also leaves an attacker with no shell or tools to use.

**d) `-ldflags='-s -w'` and `-trimpath`.** `-s` removes the symbol table and `-w` removes DWARF debug information, so the binary is smaller. The cost is that debuggers and profilers get less information. `-trimpath` removes local file system paths from the binary, so builds are reproducible across machines and do not leak paths like `/Users/...`. The cost is that paths in stack traces are less convenient for local debugging.

## Task 2 - Compose + Healthcheck + Persistent Volume

### compose.yaml

Path: `compose.yaml` at the repo root.

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
      SEED_PATH: /app/seed.json
    volumes:
      - quicknotes-data:/data
    healthcheck:
      test: ["CMD", "/app/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped

volumes:
  quicknotes-data:
```

The healthcheck runs a small Go program, `app/healthcheck/main.go`, which is built into the image. It requests `http://127.0.0.1:8080/health` with a 2 second timeout and exits with 0 if the answer is 200, otherwise 1.

### Persistence test

Start and health status (the `healthy` status shows the healthcheck works):
```
$ docker compose up --build -d
 ✔ Image quicknotes:lab6               Built
 ✔ Network devops-intro_default        Created
 ✔ Volume devops-intro_quicknotes-data Created
 ✔ Container devops-intro-quicknotes-1 Started

$ docker compose ps
NAME                        IMAGE             COMMAND             SERVICE      CREATED         STATUS                   PORTS
devops-intro-quicknotes-1   quicknotes:lab6   "/app/quicknotes"   quicknotes   9 seconds ago   Up 8 seconds (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

Step 1: create the note and check it exists (present):
```
$ curl -X POST -H 'Content-Type: application/json' -d '{"title":"durable","body":"survive a restart"}' http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T20:52:55.352029504Z"}

$ curl -s http://localhost:8080/notes | grep durable
[{"id":1,"title":"Welcome to QuickNotes", ... ,{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T20:52:55.352029504Z"}]
```
(The response is one line, so `grep` prints the whole list. It is shortened here and ends with the `durable` note.)

Step 2: `docker compose down` (without `-v`), then `up`, and the note is still present:
```
$ docker compose down
 ✔ Container devops-intro-quicknotes-1 Removed
 ✔ Network devops-intro_default        Removed

$ docker compose up -d
 ✔ Network devops-intro_default        Created
 ✔ Container devops-intro-quicknotes-1 Started

$ curl -s http://localhost:8080/notes | grep durable
[{"id":1,"title":"Welcome to QuickNotes", ... ,{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T20:52:55.352029504Z"}]
```

Step 3: `docker compose down -v` deletes the volume, and the note is gone:
```
$ docker compose down -v
 ✔ Container devops-intro-quicknotes-1 Removed
 ✔ Network devops-intro_default        Removed
 ✔ Volume devops-intro_quicknotes-data Removed

$ docker compose up -d
 ✔ Network devops-intro_default        Created
 ✔ Volume devops-intro_quicknotes-data Created
 ✔ Container devops-intro-quicknotes-1 Started

$ curl -s http://localhost:8080/notes | grep durable || echo "NOT FOUND (expected)"
NOT FOUND (expected)
```

### Design questions

**e) Healthcheck without a shell.** I chose to build a tiny health probe into the image, as a second Go program (`/app/healthcheck`). Compose runs it with the exec form `["CMD", "/app/healthcheck"]`, which needs no shell. It checks `/health` over HTTP, is cheap, and has no side effects. Alternatives: a sidecar container adds another service and network path; a debug image with `wget` brings a shell and tools back into the image and defeats the point of distroless; checking only that the process is alive would not notice a hung server. The trade-off of my choice is one extra small binary in the image and a hard-coded port.

**f) Why the named volume survives `docker compose down`.** A named volume is a separate Docker object, stored outside the container's filesystem. `down` removes containers and networks only, so the volume and its data stay, and the next `up` mounts the same volume again. It is destroyed by `docker compose down -v`, `docker volume rm`, `docker volume prune`, or `docker system prune --volumes`.

**g) `depends_on` without `condition: service_healthy`.** It only waits until the dependency container has been started, not until the application inside is ready to accept requests. The bug is a race condition: the dependent service can start while the database or API is still booting, then fail to connect and crash or return errors. With a healthcheck and `condition: service_healthy`, Compose waits for the dependency to report healthy first.