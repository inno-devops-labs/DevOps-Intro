# Lab 6 — Containers: Dockerize QuickNotes

## Environment

The lab was completed on macOS running on Apple Silicon.

```text
Docker version 29.8.2
Docker Compose version v5.6.0

Client:
OS/Arch: darwin/arm64

Server:
Docker Desktop 4.95.0
OS/Arch: linux/arm64
Architecture: aarch64
```

Docker functionality was verified with:

```bash
docker run --rm hello-world
```

Result:

```text
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

---

# Task 1 — Multi-Stage Dockerfile

## 1. Dockerfile

File: `app/Dockerfile`

```dockerfile
# syntax=docker/dockerfile:1

# ------------------------------------------------------------
# Stage 1: build
# ------------------------------------------------------------
FROM golang:1.24-alpine AS builder

WORKDIR /src

# Keep dependency download in its own cacheable layer.
COPY go.mod ./
RUN go mod download

COPY . .

# Build the application.
RUN CGO_ENABLED=0 GOOS=linux \
    go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/quicknotes \
    .

# Build a small HTTP healthcheck binary for the distroless image.
RUN CGO_ENABLED=0 GOOS=linux \
    go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/healthcheck \
    ./cmd/healthcheck

# Prepare a writable data directory.
RUN mkdir -p /out/data

# ------------------------------------------------------------
# Stage 2: runtime
# ------------------------------------------------------------
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY seed.json /seed.json

# UID/GID 65532 is the distroless nonroot identity.
COPY --from=builder --chown=65532:65532 /out/data /data

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

The project currently has no external Go module dependencies and therefore has no `go.sum`. For this reason, only `go.mod` is copied into the dependency layer:

```dockerfile
COPY go.mod ./
RUN go mod download
```

In a project with external dependencies, both `go.mod` and `go.sum` should normally be copied before the source code.

---

## 2. Healthcheck helper

Because the runtime image is distroless and does not contain `sh`, `curl`, or `wget`, a small static Go binary is included specifically for Docker healthchecks.

File: `app/cmd/healthcheck/main.go`

```go
package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	client := http.Client{
		Timeout: 2 * time.Second,
	}

	resp, err := client.Get("http://127.0.0.1:8080/health")
	if err != nil {
		fmt.Fprintln(os.Stderr, "healthcheck request failed:", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		fmt.Fprintln(os.Stderr, "unhealthy HTTP status:", resp.StatusCode)
		os.Exit(1)
	}

	os.Exit(0)
}
```

The program performs an HTTP request to the real application health endpoint.

Its exit status has the following meaning:

```text
HTTP /health returns 2xx
        ↓
exit code 0
        ↓
container is healthy

request fails or returns non-2xx
        ↓
exit code 1
        ↓
container is unhealthy
```

---

## 3. Build

The image was built with:

```bash
cd app
docker build -t quicknotes:lab6 .
```

First build timing:

```text
docker build -t quicknotes:lab6 .  0.20s user 0.27s system 2% cpu 20.769 total
```

The longer first build included pulling the Go builder image, the distroless runtime image, and Dockerfile frontend layers.

---

## 4. Final image size

```bash
docker images quicknotes:lab6
```

Output:

```text
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   d0963edefb65       21.5MB         5.22MB
```

Exact image size:

```bash
docker image inspect quicknotes:lab6 \
  --format 'Size={{.Size}} bytes'
```

Output:

```text
Size=21453206 bytes
```

The required maximum size is 25 MB, therefore the image satisfies the size requirement.

### Builder image size

```bash
docker images golang:1.24-alpine
```

Output:

```text
IMAGE                ID             DISK USAGE   CONTENT SIZE
golang:1.24-alpine   8bee1901f1e5        388MB         80.1MB
```

Exact size:

```bash
docker image inspect golang:1.24-alpine \
  --format 'Size={{.Size}} bytes'
```

Output:

```text
Size=387739930 bytes
```

Comparison:

```text
golang:1.24-alpine   ~388 MB
quicknotes:lab6      ~21.5 MB
```

The Go compiler, linker, source tree, and build environment remain in the builder stage and are not copied into the final runtime image.

---

## 5. Image configuration

Command:

```bash
docker inspect quicknotes:lab6 |
jq '.[0].Config | {
  User,
  ExposedPorts,
  Entrypoint,
  WorkingDir
}'
```

Output:

```json
{
  "User": "nonroot:nonroot",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/quicknotes"
  ],
  "WorkingDir": "/"
}
```

This confirms:

- the application does not run as root;
- TCP port 8080 is declared;
- the executable is started using exec-form `ENTRYPOINT`;
- the runtime working directory is `/`.

A shell was intentionally not present:

```bash
docker exec quicknotes-lab6 sh
```

Output:

```text
OCI runtime exec failed: exec failed: unable to start container process:
exec: "sh": executable file not found in $PATH
```

This is expected for a distroless image.

---

## 6. Runtime verification

The container was started with:

```bash
docker run \
  --rm \
  -d \
  --name quicknotes-lab6 \
  -p 8080:8080 \
  -v "$PWD/data:/data" \
  quicknotes:lab6
```

Running container:

```text
CONTAINER ID   IMAGE             COMMAND         STATUS
bdd7468e4f90   quicknotes:lab6   "/quicknotes"   Up
```

Application log:

```text
quicknotes listening on :8080 (notes loaded: 6)
```

Health endpoint:

```bash
curl -s http://localhost:8080/health
```

Output:

```json
{"notes":6,"status":"ok"}
```

The `/notes` endpoint also returned the stored QuickNotes records successfully.

---

# Task 1 Design Questions

## a) Why does Dockerfile layer order matter?

Docker images are constructed from layers. Docker can reuse a previous layer when the instruction and all of its inputs are unchanged.

A naive Dockerfile can use:

```dockerfile
COPY . .
RUN go mod download
RUN go build ...
```

The problem is that `COPY . .` depends on the entire build context.

If only one source file such as `handlers.go` changes:

```text
handlers.go changes
        ↓
COPY . . changes
        ↓
all following layers become invalid
        ↓
go mod download runs again
        ↓
go build runs again
```

The optimized version separates dependency metadata from source code:

```dockerfile
COPY go.mod ./
RUN go mod download

COPY . .
RUN go build ...
```

Now source changes do not invalidate the dependency download layer:

```text
handlers.go changes
        ↓
go.mod unchanged
        ↓
COPY go.mod      → cached
go mod download → cached
        ↓
COPY . .         → rebuilt
go build         → rebuilt
```

### Cache experiment

Two Dockerfiles were tested.

The naive version used:

```dockerfile
COPY . .
RUN go mod download
RUN go build ...
```

The optimized version used:

```dockerfile
COPY go.mod ./
RUN go mod download
COPY . .
RUN go build ...
```

Both caches were first populated. Then only application source code was modified by appending a harmless comment to `handlers.go`.

### Naive rebuild

Relevant output:

```text
[builder 3/5] COPY . .
DONE

[builder 4/5] RUN go mod download
go: no module dependencies to download
DONE

[builder 5/5] RUN CGO_ENABLED=0 GOOS=linux go build ...
DONE
```

Timing:

```text
3.721 seconds total
```

`go mod download` executed again even though dependency metadata did not change.

### Optimized rebuild

Relevant output:

```text
[builder 3/6] COPY go.mod ./
CACHED

[builder 4/6] RUN go mod download
CACHED

[builder 5/6] COPY . .
DONE

[builder 6/6] RUN CGO_ENABLED=0 GOOS=linux go build ...
DONE
```

Timing:

```text
3.366 seconds total
```

The absolute timing difference was small because QuickNotes currently has no external Go module dependencies:

```text
go: no module dependencies to download
```

However, the cache behavior demonstrates the important difference: source changes in the optimized Dockerfile do not cause the dependency-download layer to run again.

In a larger project with many dependencies and network downloads, this can save substantially more time.

---

## b) Why use `CGO_ENABLED=0`?

CGO allows Go programs to interact with C libraries.

When CGO is enabled, a produced executable may depend on external shared libraries and a dynamic linker provided by the operating system.

A normal Linux image may contain components such as:

```text
/lib/...
libc
dynamic linker
other shared libraries
```

A `distroless/static` image intentionally contains a very small userspace and does not provide a normal Linux runtime environment.

Therefore QuickNotes is built with:

```bash
CGO_ENABLED=0
```

This produces a self-contained Go executable for this application without the normal C runtime dependency.

If the application were built as a dynamically linked executable and then copied into `distroless/static`, the executable could fail to start even though the file itself existed.

A typical confusing error would be:

```text
no such file or directory
```

The missing object can actually be the dynamic linker required to load the executable rather than `/quicknotes` itself.

---

## c) What is a distroless static nonroot image?

A distroless image is a minimal runtime image designed to contain only the files required to run an application rather than a full Linux distribution.

This lab uses:

```text
gcr.io/distroless/static-debian12:nonroot
```

It provides the minimal runtime environment and a predefined non-root identity.

It intentionally does not provide normal administrative and debugging utilities such as:

```text
/bin/sh
bash
apt
apk
curl
wget
```

This was verified by attempting:

```bash
docker exec quicknotes-lab6 sh
```

which failed because `sh` does not exist.

This matters for security because software that is not installed cannot contain package-specific vulnerabilities and cannot be abused by an attacker.

A smaller runtime therefore reduces the attack surface and the number of components that must be patched and scanned.

There is also a trade-off: interactive debugging inside the production container is more difficult because normal troubleshooting tools are intentionally absent.

---

## d) What do `-ldflags="-s -w"` and `-trimpath` do?

The binary is built using:

```bash
go build \
  -trimpath \
  -ldflags="-s -w"
```

### `-s`

The linker flag `-s` removes symbol table and debugging-related symbol information from the produced executable.

This reduces executable size.

### `-w`

The linker flag `-w` removes DWARF debugging information.

This also makes the binary smaller.

The trade-off is reduced debugging information. Debugging production crashes using low-level symbols becomes more difficult.

### `-trimpath`

`-trimpath` removes filesystem paths from the build environment that would otherwise be recorded in the compiled binary.

This helps avoid embedding machine-specific paths and improves reproducibility.

For example, the resulting artifact should not depend on a developer-specific path such as:

```text
/Users/<user>/project/...
```

The trade-off is that some path information that could be useful during debugging is no longer available.

---

# Task 2 — Docker Compose, Healthcheck and Persistent Volume

## 1. compose.yaml

File: `compose.yaml`

```yaml
services:
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile

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
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 2s

    restart: unless-stopped

volumes:
  quicknotes-data:
```

The configuration was validated with:

```bash
docker compose config
```

---

## 2. Compose architecture

The service separates immutable application files from persistent application state.

```text
                     host
                      │
                      │ TCP 8080
                      ▼
              Docker container
             quicknotes:lab6
              │           │
              │           ├── /quicknotes
              │           ├── /healthcheck
              │           └── /seed.json
              │
              ▼
             /data
              │
              │ mounted volume
              ▼
    devops-intro_quicknotes-data
              │
              └── notes.json
```

The image contains the application and initial seed data.

The mutable `notes.json` file is stored outside the container's writable layer in a named Docker volume.

---

## 3. Environment variables

The application is configured with:

```yaml
environment:
  ADDR: ":8080"
  DATA_PATH: "/data/notes.json"
  SEED_PATH: "/seed.json"
```

Their purposes are:

```text
ADDR
└── address used by the HTTP server

DATA_PATH
└── persistent notes database
    /data/notes.json

SEED_PATH
└── initial data
    /seed.json
```

Keeping runtime configuration in environment variables means that the same image can be reused with different runtime settings.

---

## 4. Healthcheck

The Compose healthcheck is:

```yaml
healthcheck:
  test: ["CMD", "/healthcheck"]
  interval: 5s
  timeout: 3s
  retries: 5
  start_period: 2s
```

After startup:

```bash
docker compose ps
```

Output:

```text
NAME                        IMAGE             COMMAND         SERVICE      STATUS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   Up (healthy)
```

Detailed health state:

```bash
docker inspect \
  $(docker compose ps -q quicknotes) \
  --format '{{json .State.Health}}' | jq .
```

Output excerpt:

```json
{
  "Status": "healthy",
  "FailingStreak": 0,
  "Log": [
    {
      "ExitCode": 0,
      "Output": ""
    }
  ]
}
```

Repeated healthcheck executions returned exit code `0`.

Application health endpoint:

```bash
curl -s http://localhost:8080/health | jq .
```

Output:

```json
{
  "notes": 4,
  "status": "ok"
}
```

---

# Persistence Test

## Step 1 — Create persistent data

The Compose stack created the named volume:

```bash
docker volume ls
```

Output:

```text
DRIVER    VOLUME NAME
local     devops-intro_quicknotes-data
```

A new note was created:

```bash
curl -s \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes | jq .
```

Output:

```json
{
  "id": 5,
  "title": "durable",
  "body": "survive a restart",
  "created_at": "2026-10-20T18:05:16.176489084Z"
}
```

Verification:

```bash
curl -s http://localhost:8080/notes |
jq '.[] | select(.title == "durable")'
```

Output:

```json
{
  "id": 5,
  "title": "durable",
  "body": "survive a restart",
  "created_at": "2026-10-20T18:05:16.176489084Z"
}
```

---

## Step 2 — Recreate the container without deleting the volume

The stack was stopped:

```bash
docker compose down
```

Output:

```text
Container devops-intro-quicknotes-1 Removed
Network devops-intro_default Removed
```

The volume still existed:

```bash
docker volume ls | grep quicknotes
```

Output:

```text
local     devops-intro_quicknotes-data
```

The application was then recreated:

```bash
docker compose up -d
```

The note was checked again:

```bash
curl -s http://localhost:8080/notes |
jq '.[] | select(.title == "durable")'
```

Output:

```json
{
  "id": 5,
  "title": "durable",
  "body": "survive a restart",
  "created_at": "2026-10-20T18:05:16.176489084Z"
}
```

Therefore container recreation did not destroy the stored note.

---

## Step 3 — Delete the named volume

The stack was stopped with volume removal enabled:

```bash
docker compose down -v
```

Output:

```text
Container devops-intro-quicknotes-1 Removed
Volume devops-intro_quicknotes-data Removed
Network devops-intro_default Removed
```

Verification:

```bash
docker volume ls | grep quicknotes || echo "quicknotes volume removed"
```

Output:

```text
quicknotes volume removed
```

The application was then started again:

```bash
docker compose up -d
```

Docker created a new volume:

```text
Volume devops-intro_quicknotes-data Created
```

The deleted note was searched for:

```bash
curl -s http://localhost:8080/notes |
jq '[.[] | select(.title == "durable")]'
```

Output:

```json
[]
```

The health endpoint showed that QuickNotes had returned to its four initial seeded records:

```bash
curl -s http://localhost:8080/health | jq .
```

Output:

```json
{
  "notes": 4,
  "status": "ok"
}
```

This demonstrates that application data is stored in the Docker named volume rather than in the disposable container filesystem.

---

# Task 2 Design Questions

## e) Distroless has no shell. How do you healthcheck it?

A shell-based healthcheck such as:

```yaml
test: ["CMD-SHELL", "curl -f http://localhost:8080/health"]
```

cannot be used because the selected distroless runtime contains neither a shell nor `curl`.

For this lab I chose to include a small separate static Go binary:

```text
/healthcheck
```

The binary sends:

```text
GET http://127.0.0.1:8080/health
```

and returns:

```text
exit 0 → healthy
exit 1 → unhealthy
```

Compose invokes it directly:

```yaml
healthcheck:
  test: ["CMD", "/healthcheck"]
```

This uses exec form, so Docker does not need `/bin/sh`.

This strategy has several advantages:

- it performs a real application-level HTTP health test;
- it works with a shell-less distroless image;
- it does not require installing `curl` or `wget`;
- it keeps the production runtime minimal;
- it is inexpensive and has no side effects.

The cost is one additional small executable in the image.

---

## f) Why does a named volume survive `docker compose down`, and what destroys it?

Container lifecycle and volume lifecycle are separate.

The Compose declaration:

```yaml
volumes:
  - quicknotes-data:/data
```

creates a Docker-managed named volume.

When:

```bash
docker compose down
```

is executed, Compose removes objects such as the service container and default network, but named volumes are retained by default.

Therefore:

```text
container deleted
        ↓
volume remains
        ↓
new container mounts same volume
        ↓
notes.json is still present
```

This was demonstrated by the `durable` note surviving `docker compose down` followed by `docker compose up`.

The volume was explicitly destroyed with:

```bash
docker compose down -v
```

After that command:

```text
devops-intro_quicknotes-data
```

no longer existed.

The next `docker compose up` created a fresh empty volume, and QuickNotes initialized it from `/seed.json`.

Consequently the `durable` note disappeared.

---

## g) What does `depends_on` wait for without `condition: service_healthy`?

A basic Compose dependency such as:

```yaml
depends_on:
  - database
```

controls service startup ordering, but startup and readiness are not the same thing.

A process can have been created and started while still being unable to serve requests.

For example:

```text
database process starts
        ↓
container is running
        ↓
database is still initializing
        ↓
application starts
        ↓
application immediately connects
        ↓
connection fails
```

This produces a startup race.

A container being in the `running` state therefore does not automatically mean that the service inside it is ready.

When a real readiness dependency exists, Compose can use a healthcheck on the dependency together with:

```yaml
depends_on:
  database:
    condition: service_healthy
```

Then the dependent service can wait for the dependency's healthcheck to report healthy rather than merely relying on process startup.

QuickNotes in this lab has no second application service dependency, so `depends_on` is not required in the current `compose.yaml`.

---

# Results

| Requirement | Result |
|---|---|
| Multi-stage Dockerfile | ✅ |
| Official Go 1.24 builder | ✅ |
| Distroless runtime | ✅ |
| Static Go build with `CGO_ENABLED=0` | ✅ |
| `-trimpath` | ✅ |
| `-ldflags="-s -w"` | ✅ |
| Non-root runtime | ✅ |
| Exec-form `ENTRYPOINT` | ✅ |
| `EXPOSE 8080` | ✅ |
| Final image ≤25 MB | ✅ 21.5 MB |
| `/health` works | ✅ |
| `/notes` works | ✅ |
| Cache strategy compared | ✅ |
| Naive rebuild | 3.721 s |
| Optimized rebuild | 3.366 s |
| Compose service | ✅ |
| Named volume at `/data` | ✅ |
| Runtime environment variables | ✅ |
| Distroless-compatible healthcheck | ✅ |
| Compose reports `healthy` | ✅ |
| `restart: unless-stopped` | ✅ |
| Note survives `down && up` | ✅ |
| Note disappears after `down -v` | ✅ |

## Conclusion

QuickNotes was successfully containerized using a multi-stage Docker build.

The Go build environment is isolated in the builder stage, while the runtime image contains only the compiled application, the healthcheck executable, seed data, and the minimal distroless runtime.

The final image size is approximately 21.5 MB compared with approximately 388 MB for the Go builder image.

The application runs as a non-root user and does not contain a shell or package manager.

Docker Compose provides one-command application startup, runtime configuration, a real HTTP healthcheck, port publishing, restart policy, and persistent state through a named volume.

The persistence experiment demonstrated that containers are disposable while application state can have an independent lifecycle through Docker volumes.