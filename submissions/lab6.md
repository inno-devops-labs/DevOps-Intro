# Lab 6 — Containers

## Task 1 — Multi-stage Docker image

The QuickNotes application is built using a multi-stage Dockerfile.

Builder:
- `golang:1.24`
- `CGO_ENABLED=0`
- `-trimpath`
- `-ldflags="-s -w"`

Runtime:
- `gcr.io/distroless/static-debian12:nonroot`
- non-root user `65532:65532`
- exec-form entrypoint `/quicknotes`
- port `8080` exposed

A separate static Go binary `/healthcheck` is included for the container health check.

### Image size

The final image size is approximately 21.5 MB, which is below the 25 MB requirement.

The Go builder image is approximately 1.33 GB on disk, while only the small distroless runtime image and compiled binaries are used in the final image.

### Image configuration

```text
User=65532:65532
Entrypoint=["/quicknotes"]
ExposedPorts={"8080/tcp":{}}
```

### a) Docker layer ordering and cache efficiency

A cache-unfriendly Dockerfile using:

```dockerfile
COPY . .
RUN go mod download
RUN go build ...
```

was compared with the dependency-first Dockerfile:

```dockerfile
COPY go.mod ./
RUN go mod download
COPY . .
RUN go build ...
```

After changing application source code, measured wall-clock rebuild times were:

```text
Bad ordering:  29.406 s
Good ordering: 19.076 s
```

The optimized build was about 35% faster in this test. In the optimized version, the `go mod download` layer remained cached because `go.mod` had not changed. With `COPY . .` first, a source-code change invalidated that layer and caused the dependency step to run again.

QuickNotes currently has no external Go modules, so the project has `go.mod` but no generated `go.sum`.

### b) Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` produces a statically linked Go binary without a dependency on a system C runtime. This is important for the `distroless/static` runtime because it does not provide the normal dynamic runtime environment expected by a CGO-linked executable.

Without this, a dynamically linked binary may fail to start because the required dynamic loader or libraries are absent.

### c) Distroless static nonroot image

`distroless/static-debian12:nonroot` contains only the minimal runtime files required for running a static application. It does not include a shell, package manager, compiler, or normal debugging utilities.

This reduces image size and attack surface because fewer packages and utilities are installed. The `nonroot` variant also runs the application without root privileges.

### d) Build flags

`-ldflags="-s -w"` removes the symbol table and DWARF debugging information from the Go binary, reducing its size. The trade-off is that low-level debugging information is reduced.

`-trimpath` removes local filesystem paths from the compiled binary, improving reproducibility and avoiding embedding local build paths.

---

## Task 2 — Docker Compose

The Compose service:
- builds from `./app`
- uses the tag `quicknotes:lab6`
- publishes port `8080`
- stores data in the named volume `quicknotes-data`
- uses the required environment variables
- has a health check
- uses `restart: unless-stopped`

The running service reported:

```text
NAME                        IMAGE             COMMAND         SERVICE      STATUS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   Up (healthy)
```

### e) Healthcheck strategy

The runtime image is distroless and therefore does not contain `curl`, `wget`, or a shell.

I created a small static Go healthcheck binary that sends an HTTP GET request to:

```text
http://127.0.0.1:8080/health
```

It exits successfully only when the endpoint returns HTTP 200.

Compose executes it directly:

```yaml
healthcheck:
  test: ["CMD", "/healthcheck"]
```

This keeps the healthcheck compatible with the distroless image without installing shell utilities.

### f) Named-volume persistence

A note was created:

```text
{"id":5,"title":"durable","body":"survive a restart",...}
```

After:

```bash
docker compose down
docker compose up -d
```

the `durable` note was still present.

This happens because a named Docker volume has a lifecycle separate from the container. `docker compose down` removes the containers and network but preserves named volumes by default.

After:

```bash
docker compose down -v
docker compose up -d
```

the `durable` note was no longer present because `-v` removed the named volume.

### g) `depends_on` without `service_healthy`

Normal `depends_on` controls container startup order, but it does not guarantee that the dependency is ready to serve requests.

Without a `service_healthy` condition, a dependent application may start while its dependency is still initializing, causing startup race conditions or failed connection attempts.

---

## Bonus — Container security

The following security defaults were applied:

```yaml
cap_drop:
  - ALL

read_only: true

security_opt:
  - no-new-privileges:true
```

The runtime image also uses the distroless non-root user.

### Security verification

Non-root user:

```text
65532:65532
```

Attempting to execute a shell:

```text
OCI runtime exec failed: exec failed: unable to start container process:
exec: "sh": executable file not found in $PATH
```

Dropped Linux capabilities:

```text
[ALL]
```

Read-only root filesystem:

```text
true
```

No-new-privileges:

```text
[no-new-privileges:true]
```

The application remained healthy with these restrictions enabled.

### Trivy scan

The image was scanned with Trivy 0.59.1 for HIGH and CRITICAL vulnerabilities.

Base distroless/Debian runtime:

```text
quicknotes:lab6 (debian 12.15)
Total: 0 (HIGH: 0, CRITICAL: 0)
```

The two Go binaries were built using Go stdlib v1.24.13. Trivy reported:

```text
healthcheck (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)

quicknotes (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)
```

The reported findings are Go standard-library vulnerabilities for which Trivy lists fixes in newer Go releases. The base runtime itself had zero HIGH or CRITICAL findings.

### Security per line

Dropping all Linux capabilities provides strong security value for very little configuration because QuickNotes does not require additional Linux capabilities. It reduces the privileges available to the application if the process is compromised.

The read-only root filesystem and `no-new-privileges` setting provide additional defense-in-depth.