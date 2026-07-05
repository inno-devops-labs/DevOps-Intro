# Lab 6 Submission - Task 1

## Dockerfile

File: `app/Dockerfile`

```dockerfile
# syntax=docker/dockerfile:1

# ---- builder stage ----
FROM golang:1.24.13-alpine AS builder

WORKDIR /src

# copy go.mod/go.sum first so dependency download is cached
# across rebuilds that only change source code
COPY go.mod go.sum* ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags='-s -w' -trimpath \
    -o /out/quicknotes .

# distroless has no shell, curl or wget, so build a tiny static binary
# that just GETs /health and exits 0/1 - used as the HEALTHCHECK command
RUN <<'EOF'
cat > /tmp/healthcheck.go <<'GO'
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
	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
GO
CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck /tmp/healthcheck.go
EOF

# empty dir owned by nonroot, baked in so a fresh named volume
# mounted at /data inherits this ownership instead of root's
RUN mkdir /out/data && chown 65532:65532 /out/data

# ---- runtime stage ----
FROM gcr.io/distroless/static:nonroot AS runtime

WORKDIR /app

COPY --from=builder /out/quicknotes /app/quicknotes
COPY --from=builder /out/healthcheck /app/healthcheck
COPY --from=builder /src/seed.json /app/seed.json
COPY --from=builder --chown=65532:65532 /out/data /data

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/app/quicknotes"]
```

## Build and size check

Command:

```bash
docker build -t quicknotes:lab6 .
docker images quicknotes:lab6
```

Output:

```
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   f5e54933369e   22.8MB       5.71MB
```

The final image is 22.8 MB, under the 25 MB limit. It includes both the `quicknotes` binary and a small `healthcheck` binary used in Task 2.

For comparison, the builder base image `golang:1.24.13-alpine`:

```
IMAGE                   ID             DISK USAGE   CONTENT SIZE
golang:1.24.13-alpine   8bee1901f1e5   395MB        83.5MB
```

The builder image alone is about 27 times bigger than the final image. Multi-stage build throws away the whole Go toolchain and only keeps the compiled binary.

## docker inspect output

Command:

```bash
docker inspect quicknotes:lab6 | jq '.[0].Config'
```

Output:

```json
{
  "User": "nonroot:nonroot",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Env": [
    "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
  ],
  "Entrypoint": [
    "/app/quicknotes"
  ],
  "WorkingDir": "/app"
}
```

User is `nonroot:nonroot`, port 8080 is exposed, and entrypoint is set in exec form.

## Run test

Command:

```bash
docker run -d --rm -p 8080:8080 -v "$PWD/data:/data" -e DATA_PATH=/data/notes.json quicknotes:lab6
curl -s http://localhost:8080/health
curl -s http://localhost:8080/notes
```

Output:

```
{"notes":4,"status":"ok"}

[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point, env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]
```

The container starts, the seed data loads, and both `/health` and `/notes` respond correctly.

## Design questions

### a) Why does layer order matter?

Docker caches each layer. `COPY . .` before `go mod download` invalidates the download cache on every source change. Copying `go.mod`/`go.sum` first keeps it cached.

Proof, changed one line in `handlers.go`, rebuilt both orders:
```
good order: #12 RUN go mod download / #12 CACHED
bad order:  #10 RUN go mod download (no CACHED mark, reran)
```

### b) Why CGO_ENABLED=0? What happens in distroless-static if you forget it?

It forces a static binary with no dependency on the system C library. Distroless-static has no dynamic linker, so only static binaries run.

Proof, built without it on `golang:1.24` (has gcc), result was dynamically linked:
```
ELF 64-bit LSB executable, x86-64, dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2
```
Running it in distroless-static failed with:
```
exec /app/quicknotes: no such file or directory
```
The binary exists, but there is no linker to load it.

### c) What is gcr.io/distroless/static:nonroot? What's in it, what isn't, and why does that matter for CVEs?

Contains only CA certificates, timezone data, and a `nonroot` user entry (UID 65532). No shell, no package manager, no libc, no coreutils.

Scanners find CVEs in installed packages. With almost nothing installed, there is almost nothing to scan, and no shell for an attacker after a compromise.

### d) -ldflags='-s -w' and -trimpath: what does each flag do, and what's the cost?

- `-s` strips the symbol table.
- `-w` strips debug info (DWARF).
- `-trimpath` removes local file paths from the binary, for reproducible builds.

Measured on the QuickNotes binary:
```
without flags:    8662952 bytes
-s -w -trimpath:  5865656 bytes
```
About 32% smaller. Cost: no debugger and no file/line info in panic stack traces.

---

# Task 2

## compose.yaml

File: `compose.yaml` (repo root)

```yaml
services:
  quicknotes:
    build: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/app/seed.json"
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

Note: a fresh named volume at `/data` is owned by root by default, so the `nonroot` container could not write to it. Fixed by baking an empty `/data` directory owned by UID 65532 into the image (see `app/Dockerfile` in Task 1), so Docker copies that ownership into the volume on first creation.

## Persistence test

Commands and output:

```
docker compose up --build -d

curl -X POST -H 'Content-Type: application/json' -d '{"title":"durable","body":"survive a restart"}' http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-20T16:37:08.290893044Z"}

curl -s http://localhost:8080/notes | grep durable
"title":"durable"        # present

docker compose down
docker compose up -d

curl -s http://localhost:8080/notes | grep durable
"title":"durable"        # still present after down and up

docker compose down -v
docker compose up -d

curl -s http://localhost:8080/notes | grep durable
                          # no output, note is gone after down -v
```

## Design questions

### e) Distroless has no shell. How do you healthcheck it?

The image has only `/app/quicknotes`, no shell, no wget, no curl, so an exec-form check using an OS tool is not possible.

Strategy used: a binary already in the image, built for this purpose. The builder stage compiles a second tiny static Go binary (`/app/healthcheck`) that does an HTTP GET to `http://127.0.0.1:8080/health` and exits 0 or 1. Compose runs `["CMD", "/app/healthcheck"]`.

Verified with:
```
docker inspect <container> --format '{{.State.Health.Status}}'
healthy
```

### f) Why does volumes: [quicknotes-data:/data] survive docker compose down? What destroys it?

Named volumes are managed by Docker separately from containers. `docker compose down` removes containers and the network, not volumes. `docker compose down -v`, `docker volume rm`, or `docker system prune --volumes` destroy them.

### g) depends_on without condition: service_healthy, what does it actually wait for?

It only waits for the dependency container to start, not for the app inside to be ready. This can cause connection errors if the dependency needs time to initialize. Our compose.yaml has one service, so depends_on is not used, but it matters once a second service is added.

---

# Bonus Task

## Hardened compose.yaml snippet

```yaml
services:
  quicknotes:
    build: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/app/seed.json"
    healthcheck:
      test: ["CMD", "/app/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,nodev,size=16m
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
```

## Verification

1. USER nonroot
```
docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
nonroot:nonroot
```

2. No shell available
```
docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

3. Capabilities dropped
```
docker inspect <container> --format '{{ .HostConfig.CapDrop }}'
[ALL]
```

4. Read-only root filesystem

No write tool exists in the image, so the write attempt was made by pointing the app itself at a path outside the volume:
```
docker run --rm --read-only --tmpfs /tmp:rw,noexec,nosuid,nodev,size=16m -e DATA_PATH=/etc/notes.json quicknotes:lab6
2026/06/20 16:59:14 seed: open /etc/notes.json: read-only file system
```
Also checked directly:
```
docker inspect <container> --format '{{ .HostConfig.ReadonlyRootfs }}'
true
```

5. no-new-privileges
```
docker inspect <container> --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
```

## Trivy scan

Command:
```
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
  quicknotes:lab6
```

Summary:
```
quicknotes:lab6 (debian 13.5)
Total: 0 (HIGH: 0, CRITICAL: 0)

app/healthcheck (gobinary)
Total: 12 (HIGH: 12, CRITICAL: 0)

app/quicknotes (gobinary)
Total: 12 (HIGH: 12, CRITICAL: 0)
```

The OS layer (distroless base) has 0 HIGH/CRITICAL findings. The 12 HIGH findings on each binary come from the Go standard library version used to compile them, fixed only in Go 1.25 and 1.26. Since the lab requires pinning the builder to Go 1.24, these cannot be fixed without breaking that requirement.

## Most valuable default

Dropping all capabilities (`cap_drop: [ALL]`) gives the most security per line of YAML. Two lines remove an entire category of kernel-level attacks regardless of what the application code does. A distroless base and nonroot user already limit an attacker, but capabilities control what the process can do to the kernel itself, for almost no extra YAML.
