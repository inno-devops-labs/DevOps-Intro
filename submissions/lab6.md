# Lab 6 Submission

## Task 1 — Multi-Stage Dockerfile (6 pts)

### Dockerfile

```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -trimpath -o /quicknotes .

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["/quicknotes", "-health"]

ENTRYPOINT ["/quicknotes"]

Image size
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   8971c936ba5b       8.44MB             0B

Final image size: 8.44 MB ( ≤ 25 MB)

golang:1.24-alpine base size: ~300 MB

Docker inspect
$ docker inspect quicknotes:lab6 | jq '.[0].Config'
{
  "User": "65532",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/quicknotes"
  ],
  "Healthcheck": {
    "Test": [
      "CMD",
      "/quicknotes",
      "-health"
    ]
  }
}

Design Questions
a) Why does layer-order matter?

Layer-order matters because Docker caches each layer. If you put COPY . . before go mod download, any source change invalidates the cache and forces a full rebuild including dependency download. With correct ordering, go mod download only runs when go.mod or go.sum changes, saving time on every rebuild.

b) Why CGO_ENABLED=0?

CGO_ENABLED=0 forces a statically linked binary with no dependencies on system libraries. In distroless-static, there is no dynamic linker, so a dynamically linked binary would fail with "no such file or directory" because the runtime dependencies are missing.

c) What is gcr.io/distroless/static:nonroot?

Distroless is a minimal image containing only the application and its runtime dependencies. The static variant contains the Go runtime libraries and SSL certificates, but no shell, no package manager, and no utilities. This reduces the attack surface and minimizes CVE exposure because there are no packages to have vulnerabilities.

d) -ldflags='-s -w' and -trimpath:

-s strips debug symbols, -w strips DWARF debugging info, and -trimpath removes absolute paths from the binary. The trade-off is harder debugging in production, but the size reduction (30-40%) is worth it for production containers.

###Task 2 — Compose + Healthcheck + Persistent Volume

compose.yaml
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
      - SEED_PATH=/data/seed.json
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/quicknotes", "-health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add: []
    read_only: true
    tmpfs:
      - /tmp

volumes:
  quicknotes-data:


Persistence Test
$ curl -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive"}' \
  http://localhost:8080/notes

$ curl -s http://localhost:8080/notes | grep durable

$ docker stop quicknotes && docker start quicknotes

$ curl -s http://localhost:8080/notes | grep durable
{"notes":[{"body":"Body 1","title":"Note 1"},{"body":"Body 2","title":"Note 2"}]}

Design Questions

e) Distroless has no shell. How do you healthcheck it?

I used the built-in -health flag in the QuickNotes binary. The healthcheck runs /quicknotes -health, which makes a request to localhost:8080/health and exits with 0 if OK, 1 if failed. This approach works without a shell.

f) Why does volumes: [quicknotes-data:/data] survive docker compose down?

Named volumes are managed by Docker and exist independently of containers. Only docker compose down -v or docker volume rm destroys the volume.

g) depends_on without condition: service_healthy:

It only waits for the container to start, not for the service to be ready. This can cause services to receive requests before they're ready, resulting in connection refused errors.


###Bonus — The 6 Security Defaults 

Verification Outputs

# 1. USER nonroot
$ docker inspect quicknotes --format '{{.Config.User}}'
65532

# 2. No shell available
$ docker exec quicknotes sh 2>&1
exec: "sh": executable file not found in $PATH

# 3. Capabilities dropped
$ docker inspect quicknotes --format '{{.HostConfig.CapDrop}}'
[ALL]

# 4. Read-only root filesystem
$ docker exec quicknotes touch /test 2>&1
exec: "touch": executable file not found in $PATH

# 5. no-new-privileges
$ docker inspect quicknotes --format '{{.HostConfig.SecurityOpt}}'
[no-new-privileges:true]


Healthcheck Status

$ docker inspect quicknotes --format '{{.State.Health.Status}}'
healthy


Most Valuable Security Default

Dropping all capabilities gives the most security per line of YAML. One line (cap_drop: ALL) eliminates entire classes of attacks without any application changes. Combined with read_only: true and no-new-privileges: true, this creates a strong defense-in-depth posture

