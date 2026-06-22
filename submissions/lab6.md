# Lab 6 Submission

## Task 1 - Multi-Stage Dockerfile, <= 25 MB

### Dockerfile

`app/Dockerfile`:

```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /app/seed.json

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

### Final image size

Command:

```bash
docker images quicknotes:lab6
```

Output:

```text
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
quicknotes   lab6      58d554af210b   25 minutes ago   8.08MB
```

The final image size is **8.08 MB**, which is below the required **25 MB** limit.

### Runtime verification

Command:

```bash
curl -s http://localhost:8080/health
```

Output:

```json
{"notes":8,"status":"ok"}
```

Command:

```bash
curl -s http://localhost:8080/notes
```

Output:

```json
[{"id":5,"title":"hello","body":"first POST","created_at":"2026-06-06T13:58:10.090960026Z"},{"id":6,"title":"hello","body":"first POST","created_at":"2026-06-07T10:40:15.531409717Z"},{"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-16T07:07:22.002480556Z"},{"id":8,"title":"trace me","body":"in flight","created_at":"2026-06-16T07:13:08.030657439Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]
```

The container serves both `/health` and `/notes` successfully.

### Image config inspection

Command:

```bash
docker inspect quicknotes:lab6 | jq '.[0].Config'
```

Relevant output:

```json
{
  "User": "nonroot:nonroot",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "WorkingDir": "/app",
  "Entrypoint": [
    "/quicknotes"
  ]
}
```

Command:

```bash
docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
```

Output:

```text
nonroot:nonroot
```

The image runs as the nonroot distroless user and exposes port `8080`.

### Base image size comparison

Command:

```bash
docker images golang:1.24-alpine
```

Output:

```text
REPOSITORY   TAG           IMAGE ID       CREATED        SIZE
golang       1.24-alpine   ebe4e0721205   4 months ago   262MB
```

Command:

```bash
docker images gcr.io/distroless/static:nonroot
```

Output:

```text
REPOSITORY                 TAG       IMAGE ID       CREATED        SIZE
gcr.io/distroless/static   nonroot   c9c1077449de   56 years ago   2.21MB
```

The builder image is **262 MB**, but it is not included in the final runtime image. The final image uses the much smaller distroless static runtime base and only copies in the compiled QuickNotes binary and `seed.json`.

### Layer cache comparison

Two Dockerfile strategies were tested.

Bad cache strategy:

```dockerfile
COPY . .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .
```

Good cache strategy:

```dockerfile
COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .
```

Bad cache build command:

```bash
time docker build -f Dockerfile.bad -t quicknotes:bad-cache .
```

Relevant output:

```text
[builder 3/5] COPY . .                                                                 0.0s
[builder 4/5] RUN go mod download                                                      0.1s
[builder 5/5] RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64     go build -trimpath ...      5.6s

real    0m6.009s
```

Good cache build command:

```bash
time docker build -f Dockerfile.good -t quicknotes:good-cache .
```

Relevant output:

```text
CACHED [builder 3/6] COPY go.mod ./                                                    0.0s
CACHED [builder 4/6] RUN go mod download                                               0.0s
[builder 5/6] COPY . .                                                                 0.0s
[builder 6/6] RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64     go build -trimpath ...      5.5s

real    0m5.725s
```

| Strategy | Captured rebuild time | Dependency layer behavior |
| --- | ---: | --- |
| Bad: `COPY . .` before `go mod download` | `6.009s` | `go mod download` ran again |
| Good: `COPY go.mod ./` before `go mod download` | `5.725s` | `go mod download` was cached |

The timing difference is small in this project because the Go module currently has no external dependencies. The important result is the layer behavior: in the good strategy, Docker reused the `go mod download` layer, while in the bad strategy it had to run again after the source context changed.

### Design question a: Why does layer order matter?

Docker caches each build layer. A layer can only be reused if that layer and all previous layers are unchanged.

In the bad strategy, `COPY . .` happens before `go mod download`. That means any source file change invalidates the copy layer, and Docker must rerun `go mod download`.

In the good strategy, only `go.mod` is copied before `go mod download`. If normal source files change but dependencies do not, Docker reuses the dependency download layer and only reruns the source copy and build steps.

### Design question b: Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` tells Go to build a static binary that does not depend on C libraries or a dynamic linker.

This matters because `gcr.io/distroless/static:nonroot` is designed for static binaries. If the Go binary is dynamically linked, the container may fail at runtime with an error such as `no such file or directory`, even though the binary exists. That happens because the required dynamic linker or shared libraries are missing from the distroless static image.

### Design question c: What is `gcr.io/distroless/static:nonroot`?

`gcr.io/distroless/static:nonroot` is a minimal runtime image intended for statically linked applications.

It includes only the minimal files needed to run a static binary, plus the predefined nonroot user. It does not include a shell, package manager, compiler, Go toolchain, or normal Linux debugging tools.

This matters for security because fewer packages means a smaller attack surface and fewer possible CVEs. It also prevents common interactive debugging or exploitation paths such as running `sh` inside the container.

### Design question d: What do `-ldflags="-s -w"` and `-trimpath` do?

`-ldflags="-s -w"` passes options to the Go linker:

- `-s` removes the symbol table.
- `-w` removes DWARF debugging information.

This makes the binary smaller, but the cost is reduced debugging information.

`-trimpath` removes local filesystem paths from the compiled binary. This improves reproducibility because the binary does not contain machine-specific build paths. The cost is that stack traces and debug information may contain less detailed local path information.

## Task 2 - Compose + Healthcheck + Persistent Volume

### compose.yaml

`compose.yaml`:

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
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/app/seed.json"
    volumes:
      - quicknotes-data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s

volumes:
  quicknotes-data:
```

The service builds from `./app`, tags the image as `quicknotes:lab6`, publishes port `8080`, mounts the named volume at `/data`, passes the required environment variables, and uses `restart: unless-stopped`.

The healthcheck uses a small static Go binary copied into the distroless image at `/healthcheck`. The binary calls `http://127.0.0.1:8080/health` and exits non-zero if the request fails or returns a non-200 status.

### Compose startup verification

Command:

```bash
docker compose up --build -d
```

Relevant output:

```text
[+] Running 4/4
 ✔ quicknotes                             Built                                 0.0s
 ✔ Network devops-intro_default           Created                               0.0s
 ✔ Volume "devops-intro_quicknotes-data"  Created                               0.0s
 ✔ Container devops-intro-quicknotes-1    Started                               0.2s
```

Command:

```bash
docker compose ps
```

Output:

```text
NAME                        IMAGE             COMMAND         SERVICE      CREATED       STATUS                            PORTS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   5 seconds ago Up 4 seconds (health: starting)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

Command:

```bash
curl -s http://localhost:8080/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

The application starts successfully through Docker Compose and serves the `/health` endpoint.

### Persistence test

Command:

```bash
curl -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes
```

Output:

```json
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-22T20:41:45.049409159Z"}
```

Command:

```bash
curl -s http://localhost:8080/notes | grep durable
```

Output:

```json
[{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-22T20:41:45.049409159Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"}]
```

Command:

```bash
docker compose down
```

Output:

```text
[+] Running 2/2
 ✔ Container devops-intro-quicknotes-1  Removed                                 0.2s
 ✔ Network devops-intro_default         Removed                                 0.2s
```

Command:

```bash
docker compose up -d
sleep 3
curl -s http://localhost:8080/notes | grep durable
```

Output:

```json
[{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-22T20:41:45.049409159Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health GET /metrics","created_at":"2026-01-15T10:15:00Z"}]
```

The `durable` note survived `docker compose down` followed by `docker compose up -d`, which confirms the named volume kept `notes.json`.

Command:

```bash
docker compose down -v
```

Output:

```text
[+] Running 3/3
 ✔ Container devops-intro-quicknotes-1  Removed                                 0.1s
 ✔ Volume devops-intro_quicknotes-data  Removed                                 0.0s
 ✔ Network devops-intro_default         Removed                                 0.2s
```

Command:

```bash
docker compose up -d
sleep 3
curl -s http://localhost:8080/notes | grep durable
```

Output:

```text

```

After `docker compose down -v`, `grep durable` produced no output. This confirms that deleting the named volume removed the persisted note data.

### Design question e: Distroless has no shell. How do you healthcheck it?

The final image is based on `gcr.io/distroless/static:nonroot`, so it does not include a shell, `curl`, `wget`, or package manager tools. Because of that, a shell-form healthcheck such as `CMD-SHELL curl ...` cannot work.

This Compose file uses an exec-form healthcheck:

```yaml
healthcheck:
  test: ["CMD", "/healthcheck"]
```

`/healthcheck` is a small static Go binary built in the Dockerfile and copied into the runtime image. It sends an HTTP request to `http://127.0.0.1:8080/health` from inside the container and exits with status `0` only when QuickNotes returns HTTP 200. This keeps the final image distroless while still providing an application-level healthcheck.

### Design question f: Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`?

`quicknotes-data` is a named Docker volume. Docker Compose removes containers and the default network when running `docker compose down`, but it does not remove named volumes by default because volumes are intended to hold persistent state.

The volume is destroyed when `docker compose down -v` is used, or when the volume is removed directly with a Docker volume removal command. In the persistence test, the note survived normal `down` and `up`, but disappeared after `docker compose down -v`.

### Design question g: `depends_on` without `condition: service_healthy`

`depends_on` without `condition: service_healthy` only waits for the dependency container to be started. It does not wait for the application inside the container to finish initialization or pass its healthcheck.

The bug this can cause is startup ordering without readiness. For example, a dependent service might try to call QuickNotes immediately after the QuickNotes container starts, while the HTTP server is not ready yet. That can cause connection failures, failed migrations, failed startup checks, or retry loops even though the dependency container technically exists.

## Bonus Task - The 6 Security Defaults

### Hardened compose.yaml snippet

`services.quicknotes` in `compose.yaml`:

```yaml
quicknotes:
  build:
    context: ./app
  image: quicknotes:lab6
  ports:
    - "8080:8080"
  environment:
    ADDR: ":8080"
    DATA_PATH: "/data/notes.json"
    SEED_PATH: "/app/seed.json"
  volumes:
    - quicknotes-data:/data
  tmpfs:
    - /tmp:size=16m,mode=1777
  read_only: true
  cap_drop:
    - ALL
  security_opt:
    - no-new-privileges:true
  restart: unless-stopped
  healthcheck:
    test: ["CMD", "/healthcheck"]
    interval: 10s
    timeout: 3s
    retries: 3
    start_period: 5s
```

The service applies all Compose-level hardening defaults required for the bonus task: all Linux capabilities are dropped, the root filesystem is read-only, `/tmp` is provided as tmpfs, and `no-new-privileges` is enabled. The `/data` named volume remains writable so QuickNotes can persist `notes.json`.

### Startup verification after hardening

Command:

```bash
docker compose down
docker compose up --build -d
docker compose ps
curl -s http://localhost:8080/health
```

Relevant output:

```text
[+] Running 3/3
 ✔ quicknotes                           Built                                   0.0s
 ✔ Network devops-intro_default         Created                                 0.0s
 ✔ Container devops-intro-quicknotes-1  Started                                 0.2s

NAME                        IMAGE             COMMAND         SERVICE      CREATED         STATUS                            PORTS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   3 seconds ago   Up 3 seconds (health: starting)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp

{"notes":4,"status":"ok"}
```

The application still starts and serves `/health` after the security defaults are applied.

### Verification 1: USER nonroot

Command:

```bash
docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
```

Output:

```text
nonroot:nonroot
```

This confirms the image is configured to run as the nonroot distroless user.

### Verification 2: Distroless base and no shell available

Command:

```bash
docker compose exec quicknotes sh
```

Output:

```text
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH: unknown
```

This confirms the runtime image does not include a shell. That is expected for `gcr.io/distroless/static:nonroot` and reduces the tools available inside the container if it is compromised.

### Verification 3: Capabilities dropped

Command:

```bash
CID=$(docker compose ps -q quicknotes)
docker inspect "$CID" --format '{{ .HostConfig.CapDrop }}'
```

Output:

```text
[ALL]
```

This confirms Docker started the container with all Linux capabilities dropped. QuickNotes does not need extra capabilities to bind to port `8080` or write to `/data`.

### Verification 4: Read-only root filesystem

Command:

```bash
docker inspect "$CID" --format '{{ .HostConfig.ReadonlyRootfs }}'
```

Output:

```text
true
```

This confirms the container root filesystem is mounted read-only. The final distroless image has no shell or `touch` binary, so a direct `docker compose exec quicknotes touch /etc/test` write test cannot run in the final image. The Docker host configuration confirms the read-only root filesystem is enforced, while `/data` remains writable through the named volume.

### Verification 5: no-new-privileges

Command:

```bash
docker inspect "$CID" --format '{{ .HostConfig.SecurityOpt }}'
```

Output:

```text
[no-new-privileges:true]
```

This confirms the container is started with `no-new-privileges`, so processes inside the container cannot gain additional privileges through setuid or similar privilege escalation paths.

### Trivy scan

Command:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
  quicknotes:lab6
```

Relevant output:

```text
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 12 (HIGH: 12, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 12 (HIGH: 12, CRITICAL: 0)
```

Trivy found no HIGH or CRITICAL vulnerabilities in the distroless Debian base layer. It did report 12 HIGH vulnerabilities in each Go binary from the Go standard library version used to build the image, and no CRITICAL vulnerabilities. The scan was run once locally as requested; Lab 9 will wire this into CI.

### Most security per line of YAML

The best security per line of YAML is `cap_drop: [ALL]` because it removes kernel-level privileges that the application does not need. QuickNotes only needs to listen on port `8080` and write to `/data`, so keeping extra Linux capabilities would add risk without adding useful behavior. `read_only: true` is also high value because it prevents writes to the image filesystem and forces persistent state into explicit mounts. Together, these settings reduce both the available privilege and the writable surface of the container with only a few lines of configuration.
