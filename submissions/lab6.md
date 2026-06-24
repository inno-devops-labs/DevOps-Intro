# Lab 6 — Task 1

## Dockerfile

File: `app/Dockerfile`

```dockerfile
FROM golang:1.24.0-alpine3.21 AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY *.go ./
COPY seed.json ./

RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/quicknotes .
RUN mkdir -p /out/data && cp /src/seed.json /out/data/notes.json

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json
COPY --from=builder --chown=65532:65532 /out/data /data

ENV ADDR=:8080 \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json

USER 65532:65532
EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

## Image size

```text
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
quicknotes   lab6      01506b43afce   About a minute ago   14.9MB
```

## `docker inspect` config excerpt

Equivalent excerpt from `docker inspect quicknotes:lab6`:

```json
{
  "User": "65532:65532",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/quicknotes"
  ]
}
```

## Builder image size comparison

```text
REPOSITORY   TAG                 IMAGE ID       CREATED         SIZE
golang       1.24.0-alpine3.21   2d40d4fc278d   16 months ago   385MB
```

The final runtime image is `14.9MB`, compared with `385MB` for the builder base image.

## Build and run verification

```text
$ docker run -d --rm -p 8080:8080 -v "$PWD/data:/data" quicknotes:lab6
$ curl -s http://localhost:8080/health
{"notes":7,"status":"ok"}
```

## Design answers

### a) Why does layer order matter?

Docker reuses cached layers only until the first instruction whose inputs change. If the Dockerfile does `COPY . .` before `go mod download`, then any source edit invalidates the `COPY . .` layer and forces Docker to run `go mod download` again, even though dependencies did not change.

If the Dockerfile copies `go.mod` first, runs `go mod download`, and only then copies the source files, a source-only change keeps the dependency layer cached. On this app the rebuild time difference is small because the module has no external dependencies, but the cache behavior is still correct.

Measured rebuilds after a source-only edit:

```text
Bad order:  COPY . . -> go mod download -> go build    real 8.36s
Good order: COPY go.mod -> go mod download -> COPY src -> go build    real 8.04s
```

Observed step behavior:

- Bad order: `COPY . .`, `RUN go mod download`, and `RUN go build` all reran.
- Good order: `COPY go.mod` and `RUN go mod download` stayed cached; only source copy and build reran.

In a real service with many downloaded modules, the good order saves much more time because it avoids network work on every source change.

### b) Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` forces a pure-Go static binary that does not need a dynamic linker or C runtime in the final image. That is exactly what a distroless static runtime expects.

If you forget it and the build produces a dynamically linked binary, the container usually fails to start in `gcr.io/distroless/static:nonroot` because the required loader or shared libraries are not present. The common symptom is an error like `no such file or directory` even though the binary file exists.

### c) What is `gcr.io/distroless/static:nonroot`?

It is a minimal runtime image for statically linked programs. It contains only the small set of runtime files needed to launch the application safely as a non-root user, such as basic identity metadata and CA certificates.

It does not contain a shell, package manager, compiler, or normal debugging tools. There is no `sh`, no `apt`, no `apk`, and no extra userland utilities.

That matters for CVEs because fewer installed packages means a much smaller attack surface and fewer OS-level vulnerabilities to scan, patch, or exploit. It does not remove bugs from the application itself, but it does remove a lot of unnecessary operating-system baggage.

### d) What do `-ldflags='-s -w'` and `-trimpath` do, and what is the cost?

`-ldflags='-s -w'` strips the symbol table and DWARF debug information from the binary. The main benefit is a smaller image. The cost is worse post-build debugging because the binary carries less debug metadata.

`-trimpath` removes local filesystem paths from the compiled binary. That improves reproducibility and avoids leaking machine-specific build paths. The cost is that stack traces and debug output are slightly less informative because absolute source paths are no longer embedded.

# Lab 6 - Task 2

## compose.yaml

File: `compose.yaml`

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
      test: ["CMD", "/quicknotes", "healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 3s
    cap_drop:
      - ALL
    read_only: true
    security_opt:
      - no-new-privileges:true
    restart: unless-stopped

volumes:
  quicknotes-data:
```

## Healthcheck verification

```text
NAME                        IMAGE             COMMAND         SERVICE      CREATED         STATUS                   PORTS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   5 seconds ago   Up 5 seconds (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

## Persistence test output

```text
$ docker compose up --build -d
[+] Running 4/4
 ✔ quicknotes:lab6                        Built
 ✔ Network devops-intro_default           Created
 ✔ Volume "devops-intro_quicknotes-data"  Created
 ✔ Container devops-intro-quicknotes-1    Started

$ curl -s -X POST -H 'Content-Type: application/json' -d '{"title":"durable","body":"survive a restart"}' http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T08:35:31.488789635Z"}

$ curl -s http://localhost:8080/notes | grep durable
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point - env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T08:35:31.488789635Z"}]

$ docker compose down
$ docker compose up -d

$ curl -s http://localhost:8080/notes | grep durable
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point - env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T08:35:31.488789635Z"}]

$ docker compose down -v
$ docker compose up -d

$ curl -s http://localhost:8080/notes | grep durable
durable absent
```

## Design answers

### e) Distroless has no shell. How do you healthcheck it?

I used a binary that is already in the image: the QuickNotes executable itself. I added a `healthcheck` mode, and Compose runs it with exec form:

```yaml
healthcheck:
  test: ["CMD", "/quicknotes", "healthcheck"]
```

That helper performs an HTTP GET to `http://127.0.0.1:8080/health` and exits non-zero on failure. This works in distroless because it does not require `sh`, `curl`, `wget`, or any package manager.

### f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`? What destroys it?

It survives `docker compose down` because named volumes are separate Docker objects from containers and networks. `down` removes the containers and the project network, but it leaves named volumes in place by default.

The volume is destroyed by `docker compose down -v`, or by explicit volume removal such as `docker volume rm devops-intro_quicknotes-data` or a broader cleanup like `docker volume prune`.

### g) What does `depends_on` without `condition: service_healthy` actually wait for? What bug can it cause?

Without `condition: service_healthy`, `depends_on` only waits for the dependent container process to start, not for the application inside it to become ready.

The bug is a startup race: a second service can start immediately after first, try to connect before it is ready to accept requests, and fail with connection errors even though Compose started containers in the declared order.

# Lab 6 - Bonus Task

## Hardened `services.quicknotes` snippet

```yaml
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
    test: ["CMD", "/quicknotes", "healthcheck"]
    interval: 10s
    timeout: 3s
    retries: 3
    start_period: 3s
  cap_drop:
    - ALL
  read_only: true
  security_opt:
    - no-new-privileges:true
  restart: unless-stopped
```

## Verification outputs

### 1) `USER nonroot`

`Dockerfile` already uses `USER 65532:65532`. Runtime proof:

```text
$ docker inspect quicknotes:lab6 --format '{{json .Config.User}}'
"65532:65532"
```

### 2) No shell available

`Dockerfile` already uses the distroless runtime image `gcr.io/distroless/static:nonroot`. Proof:

```text
$ docker compose exec -T quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH: unknown
```

### 3) Capabilities dropped

```text
$ docker inspect devops-intro-quicknotes-1 --format '{{json .HostConfig.CapDrop}}'
["ALL"]
```

### 4) Read-only root filesystem

Because the distroless image has no shell and no `touch` binary, I verified this at the Docker engine level instead of trying to run a fake write test command inside the container:

```text
$ docker inspect devops-intro-quicknotes-1 --format '{{.HostConfig.ReadonlyRootfs}}'
true
```

The writable locations are only the named volume at `/data` and the explicit tmpfs mount at `/tmp`.

### 5) `no-new-privileges`

```text
$ docker inspect devops-intro-quicknotes-1 --format '{{json .HostConfig.SecurityOpt}}'
["no-new-privileges:true"]
```

## Trivy summary

Command used:

```text
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6
```

Summary:

```text
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 17 (HIGH: 16, CRITICAL: 1)
```

Interpretation: the distroless static base did its job on the OS side, with zero HIGH/CRITICAL base-image findings. The remaining findings come from the Go binary built with `go1.24.0`, so they are application-runtime issues in the bundled standard library rather than extra packages from the container image.

## Most security per line of YAML

If I had to pick one line, `cap_drop: [ALL]` gives the most security per line of Compose. It removes the default Linux capabilities that many containers do not actually need, which sharply reduces the blast radius of a compromise. `read_only: true` is a close second because it blocks a lot of persistence and tampering paths with one flag, but dropping capabilities is the stronger general hardening default for this app. The real takeaway is that these controls stack well: distroless, nonroot, dropped capabilities, read-only root, and `no-new-privileges` each cover a different failure mode.