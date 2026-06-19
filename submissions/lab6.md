# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-stage Dockerfile

### Dockerfile

The implementation is in [`app/Dockerfile`](../app/Dockerfile).

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.24.13-alpine AS builder

WORKDIR /src

# Cache module downloads independently from source-code changes.
COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

# Distroless contains no shell, curl, or wget, so provide a dedicated probe.
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
CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/healthcheck /tmp/healthcheck.go
mkdir /out/data
EOF

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder /src/seed.json /seed.json
# An empty named volume inherits this mount-point ownership on first use.
COPY --chown=65532:65532 --from=builder /out/data /data

USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
```

This repository has no `go.sum` because it has no third-party modules, so the dependency layer copies only `go.mod`.

### Build, tests, and image size

```console
$ docker compose build
Image quicknotes:lab6 Built

$ docker run --rm -v "$PWD/app:/src:ro" -w /src golang:1.24.13-alpine go test ./...
ok      quicknotes      0.005s

$ docker image inspect quicknotes:lab6 --format '{{.Size}}'
5313617
```

The final image is 5,313,617 bytes (approximately 5.31 MB), well below the 25 MB limit.

### Runtime configuration

```console
$ docker image inspect quicknotes:lab6 --format \
  'user={{.Config.User}} entrypoint={{json .Config.Entrypoint}} exposed={{json .Config.ExposedPorts}}'
user=nonroot:nonroot entrypoint=["/quicknotes"] exposed={"8080/tcp":{}}
```

### Builder image comparison

```console
$ docker image inspect golang:1.24.13-alpine --format '{{.Size}}'
79878487
```

The local builder image is 79,878,487 bytes, roughly 15 times the size of the final runtime image. The Go toolchain remains only in the builder stage.

### Design questions

#### a) Why does layer order matter?

Docker reuses a layer only while that instruction and every preceding layer remain unchanged. With `COPY . .` first, any source edit invalidates the copy layer and forces both `go mod download` and `go build` to run again. Copying `go.mod` first isolates dependency resolution: normal source edits invalidate only the later source and build layers, while a dependency change correctly invalidates the module-download layer.

I built equivalent temporary Dockerfiles, changed a file in their build context, and timed the rebuilds:

```console
$ /usr/bin/time -p docker build -q -f Dockerfile.cache-test .
real 5.38

$ /usr/bin/time -p docker build -q -f Dockerfile.cache-good .
real 5.08
```

The project currently has no external modules, so the measured difference is small. The important observable cache behavior is that the good-order `go mod download` layer remains cached; in a project with dependencies this avoids network downloads and produces a much larger saving.

#### b) Why `CGO_ENABLED=0`?

It tells Go to build without C bindings and produces a binary that does not depend on a system C library or dynamic linker. `distroless/static` is intended for such self-contained binaries. If a dynamically linked binary is copied into this image, startup commonly fails with `no such file or directory`: the binary exists, but its requested dynamic loader does not.

#### c) What is `gcr.io/distroless/static:nonroot`?

It is a minimal runtime image for statically linked applications, with basic runtime data such as CA certificates, time-zone data, and nonroot user metadata. It deliberately omits a shell, package manager, compiler, and normal Unix utilities. The `nonroot` variant supplies UID/GID 65532 and selects that identity by default. Fewer installed components mean a smaller attack surface and fewer OS packages that can carry CVEs; application and Go standard-library vulnerabilities still remain possible.

#### d) What do `-ldflags="-s -w"` and `-trimpath` do?

`-s` removes the executable symbol table and debug symbols, while `-w` removes DWARF debugging information. This reduces binary size at the cost of less useful low-level debugging. `-trimpath` removes local filesystem paths from the compiled output, improving reproducibility and avoiding disclosure of build-machine paths; the trade-off is less precise source-path information in debugging output.

## Task 2 — Compose, healthcheck, and persistent volume

### Compose configuration

The implementation is in [`compose.yaml`](../compose.yaml).

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

`/seed.json` is read-only application data copied into the image. `/data/notes.json` is the mutable data file on the named volume. The image creates `/data` as UID/GID 65532 so that an initially empty named volume is writable by the nonroot process.

### Healthcheck and persistence evidence

```console
$ docker compose up -d
$ docker compose ps
NAME                        IMAGE             COMMAND         SERVICE      STATUS                   PORTS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   Up 6 seconds (healthy)   0.0.0.0:8080->8080/tcp

$ curl -fsS -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-19T14:20:08.345032045Z"}

$ curl -fsS http://localhost:8080/notes | grep -o '"title":"durable"'
"title":"durable"

$ docker compose down
$ docker compose up -d
$ curl -fsS http://localhost:8080/notes | grep -o '"title":"durable"'
"title":"durable"

$ docker compose down -v
$ docker compose up -d
$ curl -fsS http://localhost:8080/notes | grep -o '"title":"durable"' || echo 'durable note is gone'
durable note is gone
```

#### e) How is a distroless container healthchecked?

The builder compiles a second small, static Go binary named `/healthcheck`. Docker invokes it directly with Compose's exec-form `test: ["CMD", "/healthcheck"]`, so no shell, `curl`, or `wget` is required. The probe requests `http://127.0.0.1:8080/health`, enforces a two-second timeout, and exits nonzero on a connection error or non-200 response. This checks the HTTP service rather than merely checking that the process exists.

#### f) Why does the named volume survive `docker compose down`?

The volume is a separate Docker-managed object, not part of the container's writable layer. Plain `docker compose down` removes the project's containers and network but intentionally retains named volumes, so the next `up` attaches the same data. `docker compose down -v` or an explicit `docker volume rm devops-intro_quicknotes-data` destroys it.

#### g) What does `depends_on` without `condition: service_healthy` wait for?

It controls creation and startup order only. It does not wait until the dependency can serve requests. A dependent process can therefore start while its dependency is still initializing, fail its first connection, and crash or enter a bad state unless it retries. A healthcheck plus `condition: service_healthy` can gate readiness where that dependency relationship is needed.

## Bonus — Six security defaults

The hardened Compose block is shown above. The following checks were run against the live service.

### 1. Nonroot user

```console
$ docker inspect quicknotes:lab6 --format '{{.Config.User}}'
nonroot:nonroot
```

### 2. Distroless image with no shell

```console
$ docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

### 3. All Linux capabilities dropped

```console
$ docker inspect "$(docker compose ps -q quicknotes)" --format '{{json .HostConfig.CapDrop}}'
["ALL"]
```

QuickNotes binds to unprivileged port 8080 and needs no added capability.

### 4. Read-only root filesystem and writable temporary storage

```console
$ docker inspect "$(docker compose ps -q quicknotes)" \
  --format 'readonly={{.HostConfig.ReadonlyRootfs}} tmpfs={{json .HostConfig.Tmpfs}}'
readonly=true tmpfs={"/tmp":""}
```

The separate `/data` named volume remains writable while the image root is read-only.

### 5. No new privileges

```console
$ docker inspect "$(docker compose ps -q quicknotes)" --format '{{json .HostConfig.SecurityOpt}}'
["no-new-privileges:true"]
```

### 6. Trivy scan

The default Trivy database mirror twice returned `unexpected EOF`, so the same Trivy version was rerun with its official GHCR database repository:

```console
$ docker run --rm \
  -e TRIVY_DB_REPOSITORY=ghcr.io/aquasecurity/trivy-db:2 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
  quicknotes:lab6

quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 12 (HIGH: 12, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 12 (HIGH: 12, CRITICAL: 0)
```

The distroless OS layer has zero HIGH/CRITICAL findings. Trivy reports the same 12 HIGH findings in each binary's Go standard library because the lab requires Go 1.24 and the pinned builder contains Go 1.24.13; the current fixes require newer Go release lines. Hiding these findings or silently changing the compiler would make the evidence misleading or violate the assignment's explicit version constraint.

### Most security per line

`cap_drop: [ALL]` provides the most security per line for this service because QuickNotes needs no Linux capabilities. It removes a broad class of kernel-facing privileges with one narrowly scoped declaration and no application change. `read_only: true` is similarly valuable, but it requires identifying and explicitly mounting every legitimate writable path. These controls complement rather than replace the nonroot identity and minimal runtime image.
