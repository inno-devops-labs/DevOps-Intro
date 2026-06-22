# Lab 6 Submission

## Task 1 — Multi-Stage Dockerfile

### Dockerfile

```dockerfile
# syntax=docker/dockerfile:1

# ---- builder stage ----
FROM golang:1.24 AS build

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /qn .

# Create healthcheck.go inside the container
RUN echo 'package main\n\nimport (\n\t"net/http"\n\t"os"\n)\n\nfunc main() {\n\tresp, err := http.Get("http://127.0.0.1:8080/health")\n\tif err != nil || resp.StatusCode != http.StatusOK {\n\t\tos.Exit(1)\n\t}\n}' > /tmp/healthcheck.go

# Build healthcheck binary
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /healthcheck /tmp/healthcheck.go

# Create /data directory with nonroot permissions
RUN mkdir -p /data && chown 65532:65532 /data

# ---- runtime stage ----
FROM gcr.io/distroless/static:nonroot

WORKDIR /app

# Copy binaries and seed.json
COPY --from=build /qn /app/quicknotes
COPY --from=build /healthcheck /app/healthcheck
COPY --from=build /src/seed.json /app/seed.json
COPY --from=build --chown=65532:65532 /data /data

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/app/seed.json"

EXPOSE 8080

USER nonroot:nonroot

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/app/healthcheck"]

ENTRYPOINT ["/app/quicknotes"]
```
### Build and size
```bash
$ docker build -t quicknotes:lab6 .
Successfully built ce71cd9cfbb1
Successfully tagged quicknotes:lab6

$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   ce71cd9cfbb1   22.8MB       5.71MB
```
Image size: 22.8 MB ≤ 25 MB

### Image config
```bash
$ docker inspect quicknotes:lab6 --format '{{.Config.User}}'
nonroot:nonroot

$ docker inspect quicknotes:lab6 --format '{{.Config.ExposedPorts}}'
map[8080/tcp:{}]

$ docker inspect quicknotes:lab6 --format '{{.Config.Entrypoint}}'
[/app/quicknotes]

$ docker inspect quicknotes:lab6 --format '{{.Config.Healthcheck}}'
{[CMD /app/healthcheck] 10s 3s 5s 0s 3}
```

### Verification
```bash
$ docker run --rm -p 8080:8080 -v "$PWD/data:/data" quicknotes:lab6
$ curl -s http://localhost:8080/health
{"notes":7,"status":"ok"}
```

### Design Questions
a) Why does layer-order matter?

Layers are cached. If go.mod changes, dependencies are re-downloaded. If source code changes but go.mod doesn't, only the COPY . . and go build layers are rebuilt, saving time.

b) Why CGO_ENABLED=0?

It produces a fully static binary. Without it, distroless/static would fail with no such file or directory because the dynamic linker is missing.

c) What is gcr.io/distroless/static:nonroot?

A minimal image containing only the binary and its dependencies. No shell, no package manager, no OS tools. This drastically reduces the attack surface and CVEs.

d) -ldflags='-s -w' and -trimpath:

- -s: strips debug symbol table

- -w: strips DWARF debug info

- -trimpath: removes absolute paths from the binary for reproducibility

## Task 2 — Compose + Healthcheck + Persistent Volume
### compose.yaml
```yaml
services:
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    container_name: quicknotes
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      - ADDR=:8080
      - DATA_PATH=/data/notes.json
      - SEED_PATH=/app/seed.json
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/app/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp

volumes:
  quicknotes-data:
    name: quicknotes-data
```
### Container status
```bash
$ docker ps
CONTAINER ID   IMAGE             COMMAND             CREATED          STATUS                    PORTS                                         NAMES
9ec111a598b7   quicknotes:lab6   "/app/quicknotes"   59 seconds ago   Up 58 seconds (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp   quicknotes
```
Container is healthy

### Healthcheck verification

```bash
$ docker inspect quicknotes --format '{{.State.Health.Status}}'
healthy
```

### Persistence test
#### Step 1: Create a note
```bash
$ body = @{title="durable"; body="survive a restart"} | ConvertTo-Json
$ Invoke-RestMethod -Uri http://localhost:8080/notes -Method POST -ContentType "application/json" -Body $body

id title   body              created_at                    
-- -----   ----              ----------                    
 5 durable survive a restart 2026-06-22T12:04:07.160955147Z
```
#### Step 2: Verify note exists
```bash
$ curl -s http://localhost:8080/notes | findstr durable
[{"id":5,"title":"durable","body":"survive a restart",...}]
```
Note is present.

#### Step 3: Stop container (without removing volume)
```bash
$ docker compose down
[+] Running 2/2
 ✔ Container quicknotes          Removed
 ✔ Network devops-intro_default  Removed
```

#### Step 4: Start again
```bash
$ docker compose up -d
[+] Running 2/2
 ✔ Container quicknotes          Started
```

#### Step 5: Verify note still exists
```bash
$ curl -s http://localhost:8080/notes | findstr durable
[{"id":5,"title":"durable","body":"survive a restart",...}]
```
Note survived down + up — volume persistence works.

####  Step 6: Remove volume (everything is lost)
```bash
$ docker compose down -v
[+] Running 3/3
 ✔ Container quicknotes          Removed
 ✔ Volume quicknotes-data        Removed
 ✔ Network devops-intro_default  Removed
```

####  Step 7: Start again
```bash
$ docker compose up -d
[+] Running 3/3
 ✔ Container quicknotes          Started
```

####  Step 8: Verify note is gone
```bash
$ curl -s http://localhost:8080/notes | findstr durable
(no output)
```
Note is gone after down -v — volume was removed.

### Design Questions
e) How to healthcheck distroless?

I built a separate static binary /app/healthcheck that makes an HTTP GET request to http://127.0.0.1:8080/health and exits with code 0 (healthy) or 1 (unhealthy). This works because distroless has no shell, and the binary is self-contained.

f) Why does volume survive docker compose down?

Named volumes are managed by Docker and persist even when containers are removed. Only docker compose down -v explicitly deletes them.

g) depends_on without condition: service_healthy:

It waits only for the container to start, not for the service to be ready. This can cause race conditions where dependent services try to connect before the app is fully initialized.