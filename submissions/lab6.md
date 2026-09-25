# Lab 6 Submission

Environment note: Docker Desktop could not start WSL2 on this Windows host
(`Wsl/Service/RegisterDistro/CreateVm/HCS/ERROR_NOT_SUPPORTED`), so I ran
Docker Engine inside the Lab 5 VirtualBox VM and forwarded host
`127.0.0.1:8080` to the VM. The image and compose behavior were still verified
through `localhost:8080`.

## Task 1: Multi-stage Dockerfile

Docker version used in the VM:

```text
Docker version 29.8.1, build 4a63305
Docker Compose version v5.5.1
```

`app/Dockerfile`:

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /out/quicknotes .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /out/healthcheck ./cmd/healthcheck
RUN mkdir -p /out/data

FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY --chown=65532:65532 seed.json /seed.json

USER 65532:65532
EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

Build and image size:

```text
docker build -t quicknotes:lab6 app/

REPOSITORY   TAG       SIZE
quicknotes   lab6      22.6MB
```

Builder base image size:

```text
REPOSITORY   TAG           SIZE
golang       1.24-alpine   395MB
```

Config excerpt:

```text
User=65532:65532 ExposedPorts={"8080/tcp":{}} Entrypoint=["/quicknotes"]
User=65532:65532 Entrypoint=["/quicknotes"] Shell=null Size=22550294
```

Standalone run check, using a Docker named volume because a root-owned host bind
mount is not writable by UID 65532:

```text
docker run --rm -d --name qn-standalone -p 8082:8080 -v qn-standalone-data:/data quicknotes:lab6
curl -fsS http://127.0.0.1:8082/health

{"notes":4,"status":"ok"}
```

Layer history excerpt:

```text
COPY /out/healthcheck /healthcheck       5.59MB
COPY /out/quicknotes /quicknotes         5.87MB
USER 65532:65532                         0B
ENTRYPOINT ["/quicknotes"]               0B
```

## Dockerfile Design Answers

a) Layer order matters because Docker reuses cached layers only until the first
changed instruction. If `COPY . .` appears before `go mod download`, every
source-only edit invalidates the module download layer. With the submitted
order, `go.mod` is copied first, so the dependency layer stays cached unless the
module file changes.

Measured in the VM after editing only `handlers.go`:

```text
naive_source_change_rebuild_seconds=58.93
optimized_source_change_rebuild_seconds=63.88

naive_rebuild_cache_lines:
#12 [builder 4/7] RUN go mod download
#13 [builder 5/7] RUN CGO_ENABLED=0 ... go build ...

optimized_rebuild_cache_lines:
#12 [builder 4/8] RUN go mod download
#12 CACHED
#14 [builder 6/8] RUN CGO_ENABLED=0 ... go build ...
```

QuickNotes has no third-party module dependencies, so the optimized timing did
not win on this small VM run. The important evidence is that the optimized
Dockerfile kept `go mod download` cached while the naive order reran it. A
no-change warm rebuild of the submitted Dockerfile completed in `3.17s`.

b) `CGO_ENABLED=0` makes the binaries static. If CGO is left enabled, a binary
may require libc and the dynamic linker. In a distroless static image those
runtime files are not present, so startup commonly fails with a misleading
`no such file or directory` error.

c) `gcr.io/distroless/static-debian12:nonroot` is a minimal Debian-derived
runtime with enough filesystem metadata and certificates for static workloads,
plus the nonroot user. It does not include a shell, package manager, compiler,
or normal debugging tools. That reduces both image size and the number of OS
packages that can appear in vulnerability scans.

d) `-ldflags="-s -w"` strips the symbol table and DWARF debug data, reducing
binary size at the cost of easier debugging. `-trimpath` removes local build
paths from the binary, improving reproducibility and avoiding host path leaks.

## Task 2: Compose, Healthcheck, Volume

`compose.yaml`:

```yaml
services:
  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    volumes:
      - quicknotes-data:/data
    healthcheck:
      test: [ "CMD", "/healthcheck" ]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true

volumes:
  quicknotes-data:
```

Compose status and health:

```text
NAME                IMAGE             COMMAND         SERVICE      STATUS
lab6-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   Up (healthy)

curl http://127.0.0.1:8080/health
{"notes":4,"status":"ok"}
```

Persistence test:

```text
POST /notes
{"id":5,"title":"lab6-persist","body":"durable through compose restart",...}

curl /notes | grep lab6-persist
"title":"lab6-persist"

docker compose down
docker compose up -d
curl /notes | grep lab6-persist
"title":"lab6-persist"

docker compose down -v
docker compose up -d
curl /notes | grep lab6-persist
OK: lab6-persist absent after docker compose down -v
```

## Compose Design Answers

e) Distroless has no shell, so the healthcheck uses a small static Go binary
compiled in the builder stage and copied to `/healthcheck`. Compose runs it in
exec form, so it does not need `/bin/sh` or curl in the runtime image.

f) A named volume is a Docker-managed object with its own lifecycle. `docker
compose down` removes containers and the network but leaves named volumes in
place. `docker compose down -v` or `docker volume rm` destroys it.

g) `depends_on` without `condition: service_healthy` only waits for dependency
containers to be started, not ready. The common bug is that an app tries to
connect to a database or service while it is still booting and fails at startup.

## Bonus: Six Security Defaults

Runtime hardening evidence:

```text
docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
65532:65532

docker compose exec -T quicknotes sh
OCI runtime exec failed: exec: "sh": executable file not found in $PATH
OK_no_shell_available

docker inspect <container>
ReadOnly=true CapDrop=["ALL"] SecurityOpt=["no-new-privileges:true"] Tmpfs={"/tmp":""} Restart=unless-stopped
```

Read-only root filesystem: the running container has
`HostConfig.ReadonlyRootfs=true`. Because the final image intentionally has no
shell or `touch`, the enforcement evidence is the Docker host config plus the
successful app write to the `/data` named volume only.

Trivy command:

```text
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache/ \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
  quicknotes:lab6
```

Trivy summary:

```text
quicknotes:lab6 (debian 12.15)
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)

quicknotes (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)
```

The OS layer is clean. The Go binary findings are current 2026 Go stdlib CVEs
reported against Go `1.24.13`; Trivy listed fixed versions in Go 1.25 and Go
1.26. I kept the builder pinned to Go 1.24 because Lab 6 explicitly requires an
official Go image pinned to `1.24`. These findings should be triaged or fixed
when Lab 9 allows changing the toolchain policy.

`cap_drop: [ALL]` gives the most security per line for this service. QuickNotes
does not need privileged kernel operations, so dropping every capability removes
a broad escalation surface without app changes. `no-new-privileges:true` is a
close second, but capabilities are the larger default ambient power reduction.
