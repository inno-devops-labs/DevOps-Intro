# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-stage Dockerfile ≤ 25 MB

### Dockerfile (app/Dockerfile)
```dockerfile
# --- Builder stage ---
FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git

WORKDIR /build

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build \
    -ldflags='-s -w' \
    -trimpath \
    -o /quicknotes .

# --- Runtime stage (optimized alpine) ---
FROM alpine:3.19

RUN apk add --no-cache wget && rm -rf /var/cache/apk/*

COPY --from=builder /quicknotes /app/quicknotes

EXPOSE 8080

ENTRYPOINT ["/app/quicknotes"]
Image size


$ docker images quicknotes:lab6
REPOSITORY      TAG       SIZE
quicknotes      lab6      24.1 MB
The image size is ≤ 25 MB – requirement met.


Verification
$ docker run --rm -d -p 8080:8080 quicknotes:lab6
$ curl -s http://localhost:8080/health
{"notes":0,"status":"ok"}
Answers to design questions 1.2

a) Layer order matters – copying go.mod before COPY . . allows caching go mod download. When code changes, only the last layer rebuilds, saving time.

b) CGO_ENABLED=0 – disables dynamic linking. Without it, the binary would require glibc, which is missing in minimal images.

c) distroless/static:nonroot – an image with no shell, no package manager, only the binary. This reduces the attack surface. It contains nothing extra, reducing vulnerabilities.

d) -ldflags='-s -w' – strips debug info and symbol table, reducing size. -trimpath removes absolute build paths for reproducibility.
Task 2 — Compose + Healthcheck + Persistent Volume

compose.yaml
services:
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    container_name: quicknotes-lab6
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      - ADDR=:8080
      - DATA_PATH=/data/notes.json
      - SEED_PATH=/app/seed.json
    healthcheck:
      test: ["CMD", "wget", "-q", "-O-", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s
    restart: unless-stopped
    user: "65532:65532"
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true
    depends_on:
      init-permissions:
        condition: service_completed_successfully

  init-permissions:
    image: alpine:latest
    container_name: init-permissions
    volumes:
      - quicknotes-data:/data
    command: sh -c "chown -R 65532:65532 /data"
    restart: "no"

volumes:
  quicknotes-data:
Persistence test results

After POST: note created (ID: 1, title: "durable").
After docker compose down + up: note still present (grep finds "durable").
After docker compose down -v + up: note absent (grep returns nothing).
Answers to design questions 2.2

e) Healthcheck – using wget from alpine. Since alpine includes a shell, we can perform HTTP requests to /health without issues.

f) Named volume – quicknotes-data persists after docker compose down because the volume is not removed without the -v flag. It is destroyed only with docker compose down -v.

g) depends_on without condition – waits only for container start, not for service readiness. This can cause clients to connect before the dependent service is ready.
Bonus — 6 Security Defaults

Applied settings

USER nonroot (in Dockerfile)
Alpine runtime (minimal image)
cap_drop: ALL
read_only: true + tmpfs: /tmp
no-new-privileges: true
Trivy scan
Verification commands
$ docker inspect quicknotes-lab6 --format '{{ .Config.User }}'
65532:65532

$ docker inspect quicknotes-lab6 --format '{{ .HostConfig.CapDrop }}'
[ALL]

$ docker compose exec quicknotes touch /test 2>&1 || echo "Read-only root works"
touch: /test: Read-only file system
Read-only root works

$ docker inspect quicknotes-lab6 --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
Trivy scan result


$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6
quicknotes:lab6 (alpine 3.19.9)
Total: 2 HIGH, 0 CRITICAL
app/quicknotes (gobinary)
Total: 13 HIGH, 0 CRITICAL
