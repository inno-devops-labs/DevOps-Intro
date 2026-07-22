# Lab 6 Submission

## Task 1

### Dockerfile

See [app/Dockerfile](/Users/tatyana/Documents/DevOps-Intro/app/Dockerfile).

This Dockerfile is multi-stage:
- `golang:1.24.5-alpine` builds the binaries
- `gcr.io/distroless/static-debian12:nonroot` runs them

It also sets `CGO_ENABLED=0`, strips both binaries, uses `-trimpath`, exposes port `8080`, and runs as UID `65532`.

### `docker images quicknotes:lab6`

```text
REPOSITORY   TAG       SIZE
quicknotes   lab6      21.4MB
```

The final image is below the 25 MB limit.

### Runtime Check

```text
{"notes":4,"status":"ok"}
```

I ran the image with `docker run`, published the container port to the host, and requested `GET /health`. The app started correctly and returned a healthy status.

### `docker inspect` Excerpt

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

### Go Base Image Size

```text
REPOSITORY   TAG             SIZE
golang       1.24.5-alpine   387MB
```

The builder image is much larger than the final runtime image, which shows why the multi-stage build matters.

### Design Answers

#### a) Why layer order matters

Docker reuses cached layers only until one layer changes. If `COPY . .` happens before `go mod download`, then any source code change also invalidates the dependency layer, so Docker runs `go mod download` again even when dependencies did not change.

I compared two rebuild strategies after a source-only change:

```text
bad order:  COPY . . -> go mod download -> go build   real 15.91
good order: COPY go.mod ./ -> go mod download -> COPY . . -> go build   real 14.99
```

In this repository the difference is small because `go.mod` has no external dependencies, so `go mod download` prints "no module dependencies to download". The better order is still correct because it keeps the dependency layer reusable when the project grows.

#### b) Why `CGO_ENABLED=0`

`CGO_ENABLED=0` tells Go to build a static binary. This matters because the distroless static image does not include a dynamic linker or libc runtime.

If I forget this flag, the binary may depend on shared libraries that do not exist in the runtime image. In that case the container usually fails at startup with a runtime error such as `no such file or directory`, even when the binary file is present.

#### c) What `gcr.io/distroless/static-debian12:nonroot` is

It is a very small runtime image for static binaries. It contains only the minimal files needed to start the program and a non-root user, but it does not include a shell, package manager, or normal debugging tools.

That matters for security because fewer installed packages usually means fewer OS-level CVEs and a smaller attack surface. It also forces a cleaner runtime model because there is no `sh`, `apt`, or other extra tooling inside the container.

#### d) `-ldflags='-s -w'` and `-trimpath`

`-ldflags='-s -w'` removes symbol and debug information from the binary, which reduces size. The cost is worse debugging because stack traces and low-level inspection contain less information.

`-trimpath` removes local filesystem paths from the compiled binary. This helps reproducibility and avoids leaking build-machine paths into the artifact.

## Task 2

### Compose File

See [compose.yaml](/Users/tatyana/Documents/DevOps-Intro/compose.yaml).

I used:
- a `quicknotes` service that builds from `./app` and tags `quicknotes:lab6`
- a named volume `quicknotes-data` mounted at `/data`
- an exec-form healthcheck using `/healthcheck`
- `restart: unless-stopped`
- a one-shot `volume-init` service to give the named volume the correct ownership for UID `65532`

### Persistence Test

```text
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T13:31:04.87671172Z"}

-- notes after create --
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T13:31:04.87671172Z"}]

-- down --
Container devops-intro-quicknotes-1 Stopping
Container devops-intro-quicknotes-1 Stopped
Container devops-intro-quicknotes-1 Removing
Container devops-intro-quicknotes-1 Removed
Container devops-intro-volume-init-1 Stopping
Container devops-intro-volume-init-1 Stopped
Container devops-intro-volume-init-1 Removing
Container devops-intro-volume-init-1 Removed
Network devops-intro_default Removing
Network devops-intro_default Removed

-- up again --
Network devops-intro_default Creating
Network devops-intro_default Created
Container devops-intro-volume-init-1 Creating
Container devops-intro-volume-init-1 Created
Container devops-intro-quicknotes-1 Creating
Container devops-intro-quicknotes-1 Created
Container devops-intro-volume-init-1 Starting
Container devops-intro-volume-init-1 Started
Container devops-intro-volume-init-1 Waiting
Container devops-intro-volume-init-1 Exited
Container devops-intro-quicknotes-1 Starting
Container devops-intro-quicknotes-1 Started
[{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T13:31:04.87671172Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]

-- down -v --
Container devops-intro-quicknotes-1 Stopping
Container devops-intro-quicknotes-1 Stopped
Container devops-intro-quicknotes-1 Removing
Container devops-intro-quicknotes-1 Removed
Container devops-intro-volume-init-1 Stopping
Container devops-intro-volume-init-1 Stopped
Container devops-intro-volume-init-1 Removing
Container devops-intro-volume-init-1 Removed
Network devops-intro_default Removing
Volume devops-intro_quicknotes-data Removing
Volume devops-intro_quicknotes-data Removed
Network devops-intro_default Removed

-- up after volume delete --
Network devops-intro_default Creating
Network devops-intro_default Created
Volume devops-intro_quicknotes-data Creating
Volume devops-intro_quicknotes-data Created
Container devops-intro-volume-init-1 Creating
Container devops-intro-volume-init-1 Created
Container devops-intro-quicknotes-1 Creating
Container devops-intro-quicknotes-1 Created
Container devops-intro-volume-init-1 Starting
Container devops-intro-volume-init-1 Started
Container devops-intro-volume-init-1 Waiting
Container devops-intro-volume-init-1 Exited
Container devops-intro-quicknotes-1 Starting
Container devops-intro-quicknotes-1 Started
durable absent
```

The note survived `docker compose down` and `docker compose up -d`, but it disappeared after `docker compose down -v`, which proves the named volume worked as expected.

### Design Answers

#### e) Distroless healthcheck strategy

Distroless has no shell and no `curl` or `wget`, so a normal shell-based healthcheck does not work. I solved this by compiling a small Go helper binary called `/healthcheck` into the image and using the exec-form healthcheck:

```yaml
healthcheck:
  test: ["CMD", "/healthcheck"]
```

This is cheap, has no side effects, and works inside a distroless container.

#### f) Why named volumes survive `docker compose down`

`docker compose down` removes containers and the default network, but it does not remove named volumes unless I ask for that explicitly. The volume stays on the Docker host, so the next container can mount the same data again.

The volume is destroyed by `docker compose down -v` or by removing it directly with Docker volume commands.

#### g) `depends_on` without `service_healthy`

Plain `depends_on` waits only until the dependency container starts. It does not wait until the dependency is ready to serve traffic.

That can cause race conditions. For example, one service can try to connect to another service before the second one has finished startup, and the first request fails with `connection refused` or another temporary error.

## Bonus Task

### Hardened Compose Snippet

```yaml
quicknotes:
  build:
    context: ./app
  image: quicknotes:lab6
  depends_on:
    volume-init:
      condition: service_completed_successfully
  ports:
    - "8080:8080"
  environment:
    ADDR: ":8080"
    DATA_PATH: /data/notes.json
    SEED_PATH: /seed.json
  volumes:
    - quicknotes-data:/data
  healthcheck:
    test: ["CMD", "/healthcheck"]
    interval: 10s
    timeout: 3s
    retries: 3
    start_period: 5s
  restart: unless-stopped
  cap_drop:
    - ALL
  read_only: true
  tmpfs:
    - /tmp
  security_opt:
    - no-new-privileges:true
```

### Verification Outputs

```text
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
65532:65532

$ docker compose exec -T quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH

$ cid=$(docker compose ps -q quicknotes)
$ docker inspect "$cid" --format '{{ json .HostConfig.CapDrop }}'
["ALL"]

$ docker inspect "$cid" --format '{{ .HostConfig.ReadonlyRootfs }}'
true

$ docker inspect "$cid" --format '{{ json .HostConfig.SecurityOpt }}'
["no-new-privileges:true"]

$ docker run --rm --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges:true --entrypoint /busybox/sh quicknotes:lab6-debug -c 'touch /etc/test'
touch: /etc/test: Read-only file system
```

For the read-only root test I used a temporary `:debug` variant of the same image. The normal distroless image has no shell, so I needed the debug tag only to attempt the write and prove it failed.

### Trivy Summary

```text
Report Summary

Target                          Type      Vulnerabilities
quicknotes:lab6 (debian 12.14)  debian    0
healthcheck                     gobinary  16
quicknotes                      gobinary  16

healthcheck (gobinary) Total: 16 (HIGH: 15, CRITICAL: 1)
quicknotes  (gobinary) Total: 16 (HIGH: 15, CRITICAL: 1)

Critical example:
CVE-2025-68121 in Go stdlib, fixed in 1.24.13 / 1.25.7 / 1.26.0-rc.3
```

The distroless base worked well for OS packages: Trivy found zero HIGH or CRITICAL issues in the Debian runtime layer. The remaining findings came from the statically linked Go binaries because the builder used Go `1.24.5`, which is older than the fixed patch versions in the 2026 vulnerability database.

### Which default gives the most security per line

The best value per line is dropping all capabilities with `cap_drop: [ALL]`. It removes a large class of kernel-level privileges and QuickNotes does not need any of them, so the security gain is high and the configuration cost is very small.

The second strongest default here is the distroless non-root runtime. It reduces both attack surface and privilege level at the same time. Read-only root is also very useful because it blocks many persistence and tampering attempts even after a compromise.
