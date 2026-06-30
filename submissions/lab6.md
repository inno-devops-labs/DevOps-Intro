# Lab 6: Containers - Dockerize QuickNotes

Built and verified on Apple Silicon (M4, arm64, macOS 26.5) with Docker Engine
29.2.1 (Docker Desktop 4.64.0). The lab lists Docker 28.x; 29.2.1 is newer and
ships Compose v2 the same way. The image is built for the host architecture, and
the Dockerfile hardcodes no GOARCH and uses multi-arch base images, so an amd64
grader rebuilds an equivalent amd64 image from the same file.

## Objective

Write a multi-stage Dockerfile that produces a distroless QuickNotes image at or
under 25 MB, a compose.yaml that runs it with a healthcheck and a persistent
named volume, and (bonus) apply and verify the six container-security defaults.

## Environment

| Component     | Version / value                    |
|---------------|------------------------------------|
| Host          | Apple Silicon M4, macOS 26.5, arm64 |
| Docker Engine | 29.2.1 (Docker Desktop 4.64.0)     |
| Builder image | golang:1.24.13 (latest 1.24 patch) |
| Runtime base  | gcr.io/distroless/static:nonroot   |
| Scanner       | aquasec/trivy:0.59.1               |

## Deliverables

- app/Dockerfile - multi-stage build, distroless static runtime
- app/cmd/healthcheck/main.go - small HTTP probe baked into the image
- app/.dockerignore - keeps the build context small and the cache stable
- compose.yaml - service, named volume, healthcheck, hardening
- submissions/lab6.md - this report

About the extra app file: distroless has no shell, curl, or wget, so the
healthcheck cannot be a shell command. The usual way to health-check a
distroless HTTP service is to ship a small probe binary and exec it. QuickNotes
has no such command of its own (main.go ignores its arguments), so I added a
minimal cmd/healthcheck. It has no third-party imports and passes the same vet
and lint the CI runs.

---

## Task 1: Multi-stage Dockerfile

### Dockerfile

```dockerfile
# syntax=docker/dockerfile:1

# Builder: official Go, pinned to the latest 1.24 patch (not :latest). Staying
# current within 1.24 clears the standard-library CVEs that have a 1.24 fix.
FROM golang:1.24.13 AS builder
WORKDIR /src

# Dependency manifest first so the module layer caches apart from the source.
# QuickNotes has no third-party deps, so there is no go.sum.
COPY go.mod ./
RUN go mod download

# Then the source. Editing code does not bust the layer above.
COPY . .

# Static, stripped, reproducible build. CGO off so the binary needs no libc,
# which is what lets distroless-static run it.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

# Distroless has no shell, curl, or wget, so ship a tiny probe the healthcheck
# can exec. It does a GET /health and exits 0 or 1.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./cmd/healthcheck

# Pre-create the data dir. A fresh named volume copies this dir's ownership, so
# the nonroot user (65532) can write notes.json into the volume.
RUN mkdir -p /out/data

# Runtime: distroless static + nonroot. No shell, no package manager, UID 65532.
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY --from=builder /src/seed.json /seed.json

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

USER nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
```

### Image size

```
docker images quicknotes:lab6
IMAGE             DISK USAGE   CONTENT SIZE
quicknotes:lab6   21.6MB       5.31MB
```

Both are under the 25 MB limit. CONTENT SIZE (5.31 MB) is what a registry stores
and transfers; DISK USAGE (21.6 MB) is the unpacked footprint containerd
accounts for locally. Size comparison:

```
golang:1.24.13 (builder base)    : 1.33 GB
gcr.io/distroless/static:nonroot : 6.37 MB on disk (818 kB content)
quicknotes:lab6 (final)          : 21.6 MB on disk (5.31 MB content)
```

The final image is about 60 times smaller than the toolchain it was built with.
Most of it is the two static Go binaries (on arm64, quicknotes is about 5.6 MB
and healthcheck about 5.4 MB); the distroless base adds only a few MB.

### Config excerpt

```
docker inspect quicknotes:lab6 | jq '.[0].Config'
User        : nonroot
ExposedPorts: 8080/tcp
Entrypoint  : ["/quicknotes"]
Env         : ADDR=:8080
              DATA_PATH=/data/notes.json
              SEED_PATH=/seed.json
              SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt   (from the base)
```

### Build and run

```
docker build -t quicknotes:lab6 ./app
docker run -d -p 8080:8080 -v qn-data:/data quicknotes:lab6

# container log
quicknotes listening on :8080 (notes loaded: 4)

curl -s localhost:8080/health
{"notes":4,"status":"ok"}
```

The container runs as nonroot and seeds the four starter notes into the volume
on first start. GET /notes returns those four notes.

About the volume: the lab example uses a host bind mount (-v "$PWD/data:/data").
On Docker Desktop for Mac that works, because the file sharing layer maps the
container's writes back to the host user. On native Linux the same bind mount
would be owned by the host uid and the nonroot container (uid 65532) could not
write to it. The portable answer is the named volume, which is why compose uses
one: a fresh named volume inherits the ownership of the image's /data directory
(pre-created as 65532 in the build), so nonroot can always write.

### Design answers

a) Why layer order matters. Each Dockerfile instruction is a cached layer, and a
layer is invalidated when its inputs change, which also invalidates every layer
after it. If you COPY the whole source before downloading dependencies, any code
edit changes the COPY layer and forces the dependency download to run again. If
you COPY only go.mod first and download dependencies before the source, a code
edit leaves the download layer cached. Measured demo below.

b) Why CGO_ENABLED=0. It produces a fully static binary with no dependency on
libc or a dynamic linker. distroless-static contains no libc and no loader, so a
dynamically linked binary cannot start there. If you forget and build with CGO
on (the default when a C toolchain is present), the container fails to start,
usually with "no such file or directory", which is the loader the binary expects
being absent rather than the binary itself missing.

c) What gcr.io/distroless/static:nonroot is. A minimal base that contains only
what a static binary needs at runtime: CA certificates, /etc/passwd with a
nonroot user (uid 65532), timezone data, and a few base files. It has no shell,
no package manager, and no libc. That matters for CVEs because almost all image
CVEs come from OS packages; with no packages there is almost no OS attack
surface. The Trivy scan below confirms zero findings on this layer.

d) -ldflags='-s -w' and -trimpath. -s drops the symbol table and -w drops the
DWARF debug info, which makes the binary smaller; the cost is that stack traces
lose symbol and line detail, so debugging is harder. -trimpath removes local
filesystem paths (like /Users/.../src) from the binary, which makes builds
reproducible across machines; the cost is that paths in any panic output no
longer point at real source locations.

### Layer-cache demo (question a, measured)

Two builder strategies, each warmed and then rebuilt after a source-only edit:

```
GOOD (COPY go.mod -> go mod download -> COPY . . -> go build)
  COPY go.mod ./        CACHED
  RUN go mod download   CACHED      reused after the source change
  COPY . .              re-run
  RUN go build          re-run
  rebuild time: 4.18s

BAD (COPY . . -> go mod download -> go build)
  COPY . .              re-run      busted by the source change
  RUN go mod download   re-run      invalidated by the COPY above it
  RUN go build          re-run
  rebuild time: 4.08s
```

The times are nearly equal only because QuickNotes has no third-party
dependencies, so go mod download does no real work. The cache markers are the
point: in GOOD the download layer survives a code change; in BAD every code
change re-downloads. On a project with real modules, the BAD path pays the full
download time on every source edit.

---

## Task 2: Compose, healthcheck, persistent volume

### compose.yaml

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
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped
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

### Healthcheck

```
docker compose ps
NAME                        IMAGE             STATUS
devops-intro-quicknotes-1   quicknotes:lab6   Up (healthy)
```

The healthcheck execs the probe binary baked into the image
(test: ["CMD", "/healthcheck"]). The probe does a GET /health against
127.0.0.1:8080 and exits 0 on a 200, 1 otherwise. It works even under the
hardened settings (read-only root, all capabilities dropped, no-new-privileges).

### Persistence test

```
docker compose up --build -d
POST {"title":"durable",...}   -> {"id":5,"title":"durable","body":"survive a restart",...}
GET  /notes contains durable   -> PRESENT

docker compose down            (no -v)
docker compose up -d
GET  /notes contains durable   -> PRESENT  (survived restart)

docker compose down -v         (volume destroyed)
docker compose up -d
GET  /notes contains durable   -> GONE
```

The note survives down and up because the data lives in the named volume, not in
the container. down -v deletes the volume, so the data is gone.

### Design answers

e) Distroless has no shell, so how do you healthcheck it? I ship a small probe
binary in the image and exec it. The other options are weaker: a process-only
check (Docker's default with no HEALTHCHECK) confirms the process is alive but
never tests the HTTP path; a sidecar adds a whole service and still does not set
the main service's health state; a debug image with wget reintroduces a shell
and defeats the hardening. The probe binary is small, has no side effects, and
tests the real endpoint.

f) Why does volumes: [quicknotes-data:/data] survive docker compose down, and
what destroys it? down removes the containers and the network but leaves named
volumes in place, because a named volume is a separate object
(devops-intro_quicknotes-data) with its own lifecycle. It is destroyed by
docker compose down -v, or by docker volume rm. This is the difference from a
bind mount, which lives in a host directory that Docker never deletes at all.

g) depends_on without condition: service_healthy. Plain depends_on only waits
for the dependency's container to start, meaning created and running, not ready.
The bug it causes: a dependent service can come up and immediately try to talk
to a dependency that is still initializing, and get connection refused or
similar. condition: service_healthy makes it wait until the dependency's
healthcheck passes.

---

## Bonus: the six security defaults

All six are applied to the quicknotes service. The first two come from the
Dockerfile (USER nonroot, distroless base); the rest are in compose.yaml:

```yaml
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
```

### Verification

```
1) USER nonroot
   docker inspect quicknotes:lab6 --format '{{.Config.User}}'
   nonroot

2) No shell in the image
   docker exec <c> /bin/sh -c 'echo hi'
   OCI runtime exec failed: exec: "/bin/sh": stat /bin/sh: no such file or directory
   docker compose exec quicknotes sh
   OCI runtime exec failed: exec: "sh": executable file not found in $PATH

3) All capabilities dropped
   docker inspect <c> --format '{{.HostConfig.CapDrop}}'
   [ALL]

4) Read-only root filesystem
   docker inspect <c> --format '{{.HostConfig.ReadonlyRootfs}}'
   true        (Tmpfs: /tmp)
   Active proof, point DATA_PATH at the read-only root and the app cannot write:
   docker run --rm --read-only --tmpfs /tmp -e DATA_PATH=/etc/notes.json quicknotes:lab6
   seed: open /etc/notes.json: read-only file system
   (A touch test is not possible because the image has no shell or coreutils,
   which is itself part of the hardening.)

5) no-new-privileges
   docker inspect <c> --format '{{.HostConfig.SecurityOpt}}'
   [no-new-privileges:true]
```

### Trivy scan

```
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6
```

Trivy reports three targets, the OS layer and the two Go binaries:

```
Target                                  HIGH  CRITICAL
quicknotes:lab6 (debian 13.5, OS layer)   0      0
quicknotes (gobinary)                    11      0
healthcheck (gobinary)                   11      0
```

The distroless OS layer has zero findings, which is the point of a minimal base:
no OS packages means almost no OS CVE surface.

The remaining findings are in the Go standard library the binaries are compiled
with, not in the image's OS. My first build used go1.24.5 and Trivy flagged 14
(13 HIGH, 1 CRITICAL), the CRITICAL being CVE-2025-68121, a crypto/tls
certificate-validation bug. I bumped the builder to the latest 1.24 patch,
go1.24.13, which clears every stdlib CVE that has a 1.24 fix:

```
go1.24.5   -> 14 findings (HIGH 13, CRITICAL 1)
go1.24.13  -> 11 findings (HIGH 11, CRITICAL 0)
```

The 11 that remain are all CVE-2026 standard-library denial-of-service issues
whose only fixes are in Go 1.25 and 1.26. The lab pins the builder to Go 1.24,
so they cannot be cleared without leaving 1.24. They are DoS-class rather than
remote code execution, and QuickNotes is a small internal service, so the
residual risk is low. In a real project the fix is to move to Go 1.25 or 1.26.

### Most security per line of YAML

cap_drop: ALL is the best value for two lines. It removes every Linux capability
the container could otherwise use against the host (raw sockets, mount, ptrace,
changing file ownership, and so on), and QuickNotes needs none of them.
read_only: true is a close second: it makes the whole root filesystem
immutable, so even a code-execution bug cannot drop a binary or rewrite config,
at a cost of one line plus a one-line tmpfs for /tmp. USER nonroot and the
distroless base matter just as much, but they live in the Dockerfile; among the
compose-level options, cap_drop ALL gives the largest reduction in blast radius
per line.

---

## How to run

```
# from the repo root
docker compose up --build -d
curl -s localhost:8080/health
docker compose down       # keeps the volume, data persists
docker compose down -v    # removes the volume, data gone

# build and inspect the image directly
docker build -t quicknotes:lab6 ./app
docker images quicknotes:lab6
```
