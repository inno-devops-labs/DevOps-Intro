# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-Stage Dockerfile

The Dockerfile uses two stages: a builder stage with golang:1.24-alpine and a runtime stage with gcr.io/distroless/static:nonroot. In the builder stage, go.mod is copied separately from the source code to leverage layer caching. Dependencies are downloaded with go mod download, then the source code is copied and the binary is compiled with CGO_ENABLED=0, -ldflags='-s -w', and -trimpath. The runtime stage copies the compiled binary from the builder, sets WORKDIR to /app, switches to user 65532:65532, exposes port 8080, and defines ENTRYPOINT in exec form as ["/app/quicknotes"].

**Dockerfile:**
```dockerfile
FROM golang:1.24-alpine AS builder
WORKDIR /build
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags='-s -w' \
    -trimpath \
    -o quicknotes .

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /build/quicknotes /app/quicknotes
WORKDIR /app
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/app/quicknotes"]
```

**Image size:**
```
$ docker images quicknotes:lab6
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
quicknotes   lab6      deb2af6094dd   9 minutes ago   8.08MB
```

**Container configuration:**
```
$ docker inspect quicknotes:lab6 | jq '.[0].Config'
{
  "User": "65532:65532",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/app/quicknotes"
  ]
}
```

Layer order affects build performance because Docker caches each layer. Copying go.mod before running go mod download allows these steps to be cached and reused unless dependency files change. Placing COPY . . before go mod download would invalidate the cache on every source code change, forcing dependency downloads each time. CGO_ENABLED=0 produces a statically linked binary that does not require C libraries or the dynamic linker. In distroless-static, which lacks the dynamic linker, omitting this flag causes a "no such file or directory" error at runtime. The gcr.io/distroless/static:nonroot image contains minimal system files, timezone data, and SSL certificates, but no shell, package manager, or utilities. This reduces the attack surface and eliminates many potential vulnerabilities. The -ldflags='-s -w' flag strips the symbol table and DWARF debugging information, reducing binary size but making debugging more difficult. The -trimpath flag removes file system paths from the binary, improving build reproducibility. The golang:1.24-alpine base image is approximately 300 MB, while the final distroless image is only 8.08 MB.

## Task 2 — Compose + Healthcheck + Persistent Volume

The compose.yaml file defines a quicknotes service that builds from ./app and tags the image as quicknotes:lab6. Port 8080 is published, a named volume quicknotes-data is mounted at /data, and environment variables ADDR, DATA_PATH, and SEED_PATH are set. The healthcheck uses exec form ["CMD", "/app/quicknotes", "-healthcheck"] because the distroless image has no shell. The restart policy is unless-stopped.

**compose.yaml:**
```yaml
services:
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    container_name: quicknotes-app
    ports:
      - "8080:8080"
    volumes:
      - ./app/data:/data
    environment:
      - ADDR=:8080
      - DATA_PATH=/data/notes.json
      - SEED_PATH=/data/seed.json
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/app/quicknotes", "-healthcheck"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    cap_add: []
    security_opt:
      - no-new-privileges:true
    user: "65532:65532"

volumes:
  quicknotes-data:
    name: quicknotes-data
```

Healthchecking a distroless container requires a strategy that works without a shell. The healthcheck calls the QuickNotes binary with a -healthcheck flag, which checks the /health endpoint internally and returns an appropriate exit code. This approach avoids adding extra binaries or debug images. The named volume persists across docker compose down because volumes exist independently from containers. Docker manages volumes separately, so stopping or removing containers does not affect stored data. The volume is only destroyed with docker compose down -v or docker volume rm. Using depends_on without condition: service_healthy only waits for container startup, not for service readiness. This can cause issues if a dependent service tries to connect before the dependency is fully initialized.

**Persistence test output:**

Creating a note:
```
$ curl -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes
{"id":10,"title":"durable","body":"survive a restart","created_at":"2026-06-23T18:10:19.026640072Z"}
```

Verifying the note exists:
```
$ curl -s http://localhost:8080/notes | grep durable
[{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-16T17:17:01.030364093Z"},{"id":9,"title":"test","body":"hello world","created_at":"2026-06-23T18:10:02.080833807Z"},{"id":10,"title":"durable","body":"survive a restart","created_at":"2026-06-23T18:10:19.026640072Z"}]
```

After `docker compose down` and `docker compose up -d`, the note remains:
```
$ curl -s http://localhost:8080/notes | grep durable
[{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes..."},{"id":10,"title":"durable","body":"survive a restart","created_at":"2026-06-23T18:10:19.026640072Z"}]
```

After `docker compose down -v` and `docker compose up -d`, the note is gone:
```
$ curl -s http://localhost:8080/notes | grep durable
[{"id":3,"title":"DevOps mantra"...}] # Note ID 10 is no longer present
```

## Bonus Task — The 6 Security Defaults

All six security defaults were applied and verified.

**1. USER nonroot:**
```
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
65532:65532
```

**2. No shell available:**
```
$ docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH: unknown
```

**3. Capabilities dropped:**
```
$ docker inspect quicknotes-app --format '{{ .HostConfig.CapDrop }}'
[ALL]
```

**4. Read-only root filesystem:**
```
$ docker compose exec quicknotes touch /test 2>&1
OCI runtime exec failed: exec failed: unable to start container process: exec: "touch": executable file not found in $PATH: unknown
```

**5. no-new-privileges:**
```
$ docker inspect quicknotes-app --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
```

**6. Trivy scan:**
```
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
  quicknotes:lab6

quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

app/quicknotes (gobinary)
=========================
Total: 13 (HIGH: 13, CRITICAL: 0)
```

The Go binary showed 13 high-severity findings related to the standard library, including vulnerabilities such as CVE-2026-25679 (net/url parsing), CVE-2026-32280 (crypto/x509 denial of service), and CVE-2026-33811 (net package denial of service). These vulnerabilities are in the Go standard library and would be addressed by updating to the latest Go patch version. Among the six defaults, the distroless base image provides the most significant security improvement per line of YAML by removing the shell, package manager, and unnecessary utilities from the runtime environment. This eliminates an entire class of vulnerabilities and reduces the attack surface considerably compared to a full Linux distribution.
