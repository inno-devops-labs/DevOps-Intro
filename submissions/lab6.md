# Lab 6 Submission

## Task 1: Multi-stage Dockerfile

Dockerfile: [`app/Dockerfile`](../app/Dockerfile)

```Dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

ARG TARGETOS=linux
ARG TARGETARCH=amd64
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes . && \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" -o /out/healthcheck ./cmd/healthcheck && \
    mkdir -p /out/data && \
    touch /out/data/.keep

FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --chown=nonroot:nonroot seed.json /app/seed.json
COPY --from=builder --chown=nonroot:nonroot /out/data /data

USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

Build and size:

```text
$ cd app
$ docker build -t quicknotes:lab6 .
$ docker images quicknotes:lab6
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
quicknotes   lab6      6e02676b2ec7   3 minutes ago   22.8MB
```

Runtime config excerpt:

```text
$ docker inspect quicknotes:lab6 | jq '.[0].Config | {User, ExposedPorts, Entrypoint}'
{
  "User": "nonroot:nonroot",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/quicknotes"
  ]
}
```

Builder base size comparison:

```text
$ docker images golang:1.24-alpine
REPOSITORY   TAG           IMAGE ID       CREATED        SIZE
golang       1.24-alpine   8bee1901f1e5   4 months ago   388MB
```

Run verification:

```text
$ docker run --rm --name quicknotes-lab6-run -d -p 8080:8080 -v quicknotes-run-data:/data quicknotes:lab6
2bdfe0bb2c1d025257cfe8801eede81aae094ff5e2bafeca39dcf5d0e4c36a8b
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

### Design Questions

**a) Why does layer order matter?**

Docker reuses cached layers when the inputs to a layer have not changed. If the Dockerfile does `COPY . .` before `go mod download`, every source edit invalidates the dependency-download layer even when `go.mod` did not change. The better order is `COPY go.mod ./`, run `go mod download`, then copy the rest of the source and build. This app has no `go.sum` because it has no third-party modules; in a dependency-using app I would copy both `go.mod` and `go.sum` before the rest of the source.

Timing evidence:

```text
Bad order, after source-only edit:
go mod download: would rerun because COPY . . invalidates the dependency layer.
Measured build in this repo: not kept as the final Dockerfile, because the lab deliverable should use the good order.

Good order, after source-only edit:
go mod download: CACHED
docker compose up --build -d after a source-only rebuild: about 3.3s, with the go mod layer cached.
```

**b) Why `CGO_ENABLED=0`?**

`CGO_ENABLED=0` forces a static Go binary. `gcr.io/distroless/static:nonroot` does not contain glibc, musl, or a dynamic linker, so a dynamically linked binary can fail at startup with a confusing `no such file or directory` even though the application file exists.

**c) What is `gcr.io/distroless/static:nonroot`?**

It is a minimal runtime image intended for statically linked binaries. It includes a tiny filesystem with CA certificates and a nonroot user, but it does not include a shell, package manager, compiler, or general Linux userland. That reduces attack surface and CVE noise because there are far fewer packages present to scan or exploit.

**d) What do `-ldflags="-s -w"` and `-trimpath` do?**

`-ldflags="-s -w"` strips the symbol table and DWARF debug data, making the binary smaller. `-trimpath` removes local filesystem paths from compiled output, improving reproducibility and avoiding leakage of local build paths. The cost is weaker local debugging and less symbolic information in crash analysis.

## Task 2: Compose, Healthcheck, Persistent Volume

Compose file: [`compose.yaml`](../compose.yaml)

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
      HEALTHCHECK_URL: "http://127.0.0.1:8080/health"
    volumes:
      - quicknotes-data:/data
    tmpfs:
      - /tmp:size=16m,noexec,nosuid,nodev
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    user: "65532:65532"
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

Persistence test:

```text
$ docker compose up --build -d
Container devops-intro-quicknotes-1 Started

$ curl -X POST -H 'Content-Type: application/json' \
    -d '{"title":"durable-lab6-20260623","body":"survive a restart"}' \
    http://localhost:8080/notes
{"id":5,"title":"durable-lab6-20260623","body":"survive a restart","created_at":"2026-06-23T16:11:57.579820419Z"}

$ curl -s http://localhost:8080/notes
[...{"id":5,"title":"durable-lab6-20260623","body":"survive a restart","created_at":"2026-06-23T16:11:57.579820419Z"}...]

$ docker compose down
Container devops-intro-quicknotes-1 Removed

$ docker compose up -d
Container devops-intro-quicknotes-1 Started

$ curl -s http://localhost:8080/notes
[...{"id":5,"title":"durable-lab6-20260623","body":"survive a restart","created_at":"2026-06-23T16:11:57.579820419Z"}...]

$ docker compose down -v
Volume devops-intro_quicknotes-data Removed

$ docker compose up -d
Container devops-intro-quicknotes-1 Started

$ curl -s http://localhost:8080/notes
[{"id":1,"title":"Welcome to QuickNotes",...},{"id":2,"title":"Read app/main.go first",...},{"id":3,"title":"DevOps mantra",...},{"id":4,"title":"Endpoint cheat-sheet",...}]
```

### Design Questions

**e) Distroless has no shell. How do you healthcheck it?**

I added a tiny static Go binary at `/healthcheck` and configured Compose to run it with exec-form `test: ["CMD", "/healthcheck"]`. The probe calls `GET /health` over localhost and exits nonzero unless the app returns HTTP 200. This keeps the image distroless and shell-free while still checking the real HTTP endpoint.

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`?**

Named volumes are Docker-managed objects with lifetimes independent of containers. `docker compose down` removes the containers and network, but it leaves named volumes in place. `docker compose down -v` or `docker volume rm <name>` destroys the volume and the data inside it.

**g) What does `depends_on` without `condition: service_healthy` wait for?**

It waits for dependency containers to be started, not for their applications to be ready. The bug is a startup race: a dependent service may begin requests while the dependency is still booting, migrating, or failing its healthcheck.

## Bonus: Security Defaults

Hardened `services.quicknotes` settings:

```yaml
user: "65532:65532"
read_only: true
tmpfs:
  - /tmp:size=16m,noexec,nosuid,nodev
cap_drop:
  - ALL
security_opt:
  - no-new-privileges:true
```

Verification:

```text
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
nonroot:nonroot

$ docker compose exec -T quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH

$ docker inspect devops-intro-quicknotes-1 --format '{{ .HostConfig.CapDrop }} {{ .HostConfig.ReadonlyRootfs }} {{ .HostConfig.SecurityOpt }}'
[ALL] true [no-new-privileges:true]

$ docker compose exec -T quicknotes touch /etc/test
OCI runtime exec failed: exec failed: unable to start container process: exec: "touch": executable file not found in $PATH
```

Because distroless has no `touch` or shell, I also verify the read-only root filesystem through Docker metadata:

```text
$ docker inspect devops-intro-quicknotes-1 --format '{{ .HostConfig.ReadonlyRootfs }}'
true

$ docker inspect devops-intro-quicknotes-1 --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
```

Trivy:

```text
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
    quicknotes:lab6

quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 13 (HIGH: 13, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 13 (HIGH: 13, CRITICAL: 0)
```

The distroless runtime layer itself has zero HIGH/CRITICAL findings. The remaining
findings are in the Go standard library embedded in the statically compiled
`quicknotes` and `healthcheck` binaries. Trivy reported the installed Go stdlib as
`v1.24.13` and listed fixes in Go `1.25.x` / `1.26.x`, while this lab requires the
builder stage to stay pinned to Go `1.24`.

The highest security per line of YAML is `cap_drop: [ALL]`: it removes a broad set of kernel privileges the service does not need, and the app still works because it only binds to an unprivileged port and writes to `/data`. `read_only: true` is close behind because it blocks many persistence and tampering paths after compromise. Distroless gives another large win by removing shells and package managers that attackers commonly use after code execution.
