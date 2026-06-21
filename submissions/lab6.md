# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-Stage Dockerfile, ≤ 25 MB

### Dockerfile

`app/Dockerfile`:

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

RUN cat > /tmp/healthcheck.go <<'GOEOF'
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	client := http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://127.0.0.1:8080/health")
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		os.Exit(1)
	}
}
GOEOF

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/healthcheck /tmp/healthcheck.go

RUN mkdir -p /out/data

FROM gcr.io/distroless/static:nonroot

WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY --from=builder /src/seed.json /seed.json

USER 65532:65532

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

### Build command

```bash
cd app
docker build -t quicknotes:lab6 .
```

### Image size

Command:

```bash
docker images quicknotes:lab6
```

Output:

```text
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   c0c9f4994508       22.8MB         5.71MB        
```

### Image configuration

Commands:

```bash
docker inspect quicknotes:lab6 --format "User={{.Config.User}}"
docker inspect quicknotes:lab6 --format "ExposedPorts={{json .Config.ExposedPorts}}"
docker inspect quicknotes:lab6 --format "Entrypoint={{json .Config.Entrypoint}}"
```

Output:

```text
User=65532:65532
ExposedPorts={"8080/tcp":{}}
Entrypoint=["/quicknotes"]
```

### Base image size

Command:

```bash
docker pull golang:1.24-alpine
docker images golang:1.24-alpine
```

Output:

```text
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
golang:1.24-alpine   8bee1901f1e5        395MB         83.5MB        
```

Comparison:

The builder image `golang:1.24-alpine` is `395MB`, while the final runtime image is only `22.8MB`. This shows why the multi-stage build is useful: the final image does not include the Go compiler, source cache, or build tools.

### Run verification

Command:

```bash
docker rm -f quicknotes-lab6 2>/dev/null || true

MSYS_NO_PATHCONV=1 docker run -d \
  --name quicknotes-lab6 \
  -p 8080:8080 \
  -v "$(pwd -W)/data:/data" \
  -e ADDR=:8080 \
  -e DATA_PATH=/data/notes.json \
  -e SEED_PATH=/seed.json \
  quicknotes:lab6
```

Output:

```text
quicknotes-lab6
3b20463be7c939eb85ebbd308ab951307185a920737fcd97b05824c9504bb804
```

Health check:

```bash
curl -s http://localhost:8080/health
```

Output:

```json
{"notes":7,"status":"ok"}
```

Notes check:

```bash
curl -s http://localhost:8080/notes
```

Output excerpt:

```json
[{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-16T17:06:20.062663863Z"},{"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-16T17:14:38.598761313Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"hello","body":"first POST","created_at":"2026-06-08T08:49:23.6080851Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"}]

```

### Design questions

#### a) Why does layer order matter?

Docker reuses cached layers only when the previous layers have not changed. If the Dockerfile uses `COPY . .` before `go mod download`, then any source-code change invalidates the dependency layer and forces Docker to download modules again. The better strategy is to copy `go.mod` first, run `go mod download`, and only then copy the rest of the source code. This keeps the dependency layer cached when only application source files change.

Measured rebuild times:

```text
Naive order: COPY . . && go mod download && go build
Rebuild time after source-only change: TODO seconds

Optimized order: COPY go.mod ./ && go mod download && COPY . . && go build
Rebuild time after source-only change: TODO seconds
```

The optimized order is better because dependency download is separated from source-code changes. In this project, the final Dockerfile uses the optimized order. The repository does not contain `go.sum`, so only `go.mod` is copied before `go mod download`.

#### b) Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` forces Go to build a static binary that does not depend on C libraries or a dynamic linker. This matters because `gcr.io/distroless/static:nonroot` is designed for static binaries and does not include a normal Linux userland. If I forget `CGO_ENABLED=0`, the binary may require dynamic libraries such as libc, and the container can fail at runtime because the required linker or shared libraries are not present.

#### c) What is `gcr.io/distroless/static:nonroot`?

`gcr.io/distroless/static:nonroot` is a minimal runtime image for static binaries. It does not include a shell, package manager, compiler, or normal debugging tools. It also runs with a predefined non-root user. This reduces the attack surface because there are fewer packages and tools inside the final image. Fewer packages usually means fewer CVEs compared to a full Linux distribution image.

#### d) What do `-ldflags="-s -w"` and `-trimpath` do?

`-ldflags="-s -w"` strips symbol table and debug information from the Go binary, which makes the binary smaller. The cost is that debugging and stack-symbol inspection become less convenient. `-trimpath` removes local filesystem paths from the compiled binary, which improves reproducibility and avoids leaking local build paths. The cost is that some debug output may contain less detailed local path information.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

### compose.yaml

`compose.yaml` at the repository root:

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
      SEED_PATH: "/seed.json"
    volumes:
      - quicknotes-data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    user: "65532:65532"
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true

volumes:
  quicknotes-data:
```

### Compose run verification

Command:

```bash
docker compose up --build -d
sleep 10
docker compose ps
curl -s http://localhost:8080/health
curl -s http://localhost:8080/notes
```

Output excerpt:

```text
Image quicknotes:lab6                           Built
Network devops-intro_default                   Created
Volume devops-intro_quicknotes-data            Created
Container devops-intro-quicknotes-1            Started
```

`docker compose ps` output excerpt:

```text
NAME                        IMAGE             COMMAND         SERVICE      CREATED          STATUS                    PORTS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   12 seconds ago   Up 11 seconds (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

Health output:

```json
{"notes":4,"status":"ok"}
```

Notes output excerpt:

```json
[{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"}]
```

### Persistence test

#### Step 1 — create a durable note

Command:

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes
```

Output:

```json
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-21T09:17:23.967580238Z"}
```

Check:

```bash
curl -s http://localhost:8080/notes | grep durable
```

Output excerpt:

```text
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-21T09:17:23.967580238Z"}
```

#### Step 2 — `docker compose down` without deleting the volume

Command:

```bash
docker compose down
docker compose up -d
sleep 5
docker compose ps
curl -s http://localhost:8080/notes | grep durable
```

Output excerpt:

```text
✔ Container devops-intro-quicknotes-1 Removed                                                     0.3s
✔ Network devops-intro_default        Removed                                                     0.3s

✔ Network devops-intro_default        Created                                                     0.0s
✔ Container devops-intro-quicknotes-1 Started                                                     0.5s

devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   7 seconds ago   Up 6 seconds (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

The durable note was still present after restart:

```text
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-21T09:17:23.967580238Z"}
```

#### Step 3 — `docker compose down -v` deletes the volume

Command:

```bash
docker compose down -v
docker compose up -d
sleep 5
docker compose ps
curl -s http://localhost:8080/notes | grep durable || echo "durable note is gone"
```

Output excerpt:

```text
✔ Container devops-intro-quicknotes-1 Removed                                                     0.3s
✔ Volume devops-intro_quicknotes-data Removed                                                     0.0s
✔ Network devops-intro_default        Removed                                                     0.3s

✔ Network devops-intro_default        Created                                                     0.1s
✔ Volume devops-intro_quicknotes-data Created                                                     0.0s
✔ Container devops-intro-quicknotes-1 Started                                                     0.4s

devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   7 seconds ago   Up 6 seconds (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp

durable note is gone
```

### Design questions

#### e) Distroless has no shell. How do you healthcheck it?

Distroless images do not include `sh`, `curl`, `wget`, or a package manager, so a shell-based healthcheck is not possible. I solved this by adding a small static Go healthcheck binary to the image. The binary sends an HTTP request to `http://127.0.0.1:8080/health` and exits with code `0` for success or `1` for failure. In `compose.yaml`, the healthcheck uses exec form:

```yaml
healthcheck:
  test: ["CMD", "/healthcheck"]
```

This works with distroless because Docker runs the binary directly and does not need a shell.

#### f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`? What destroys it?

A named volume is managed separately from the container lifecycle. `docker compose down` removes the container and network, but it does not remove named volumes by default. That is why the note survived after `docker compose down && docker compose up -d`. The volume is destroyed when I explicitly run `docker compose down -v`, because the `-v` flag tells Compose to remove named volumes declared by the project.

#### g) What does `depends_on` without `condition: service_healthy` actually wait for?

`depends_on` without `condition: service_healthy` only waits until the dependency container has been started. It does not wait until the application inside the container is actually ready to accept requests. This can cause a bug where one service starts, immediately tries to connect to another service, and fails because the dependency process is still booting or initializing data. For readiness-sensitive services, a healthcheck plus `condition: service_healthy` is safer than relying on start order alone.

## Bonus Task — Container Hardening and Vulnerability Scan

### Hardening configuration

The Compose service includes several hardening options:

```yaml
user: "65532:65532"
read_only: true
tmpfs:
  - /tmp
cap_drop:
  - ALL
security_opt:
  - no-new-privileges:true
```

These options make the container run as a non-root user, prevent writes to the root filesystem, remove Linux capabilities, and prevent privilege escalation.

### Hardening verification

```bash
docker inspect quicknotes:lab6 --format "User={{.Config.User}}"
docker compose exec quicknotes sh
CID=$(docker compose ps -q quicknotes)
docker inspect "$CID" --format "CapDrop={{.HostConfig.CapDrop}}"
docker inspect "$CID" --format "ReadonlyRootfs={{.HostConfig.ReadonlyRootfs}}"
docker inspect "$CID" --format "SecurityOpt={{json .HostConfig.SecurityOpt}}"
```

Output:

```text
User=65532:65532
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
CapDrop=[ALL]
ReadonlyRootfs=true
SecurityOpt=["no-new-privileges:true"]
```

### Trivy scan

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image \
  --severity HIGH,CRITICAL \
  --no-progress \
  quicknotes:lab6
```

Output summary:

```text
quicknotes:lab6 (debian 13.5)
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
Total: 12 (HIGH: 12, CRITICAL: 0)

quicknotes (gobinary)
Total: 12 (HIGH: 12, CRITICAL: 0)
```

### Security per line of YAML

The best security per line of YAML is `cap_drop: [ALL]` because it removes many Linux capabilities with one small configuration block. This reduces the container’s ability to perform privileged operations even if the application is compromised. `no-new-privileges:true` is also very strong because it prevents privilege escalation during runtime, but `cap_drop: ALL` removes a wider set of powers at once. In my setup, the combination of non-root user, dropped capabilities, read-only root filesystem, and no-new-privileges gives the best practical hardening.
