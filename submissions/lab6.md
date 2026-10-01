# Lab 6 — Dockerizing QuickNotes

## Goal

Dockerize the QuickNotes application using a multi-stage Docker build and Docker Compose.

The solution uses a minimal distroless runtime image, a non-root user, a named volume for persistent data, a shell-free healthcheck, and additional container security defaults.

---

## Task 1 — Multi-stage Dockerfile

### Dockerfile

The application is built using the official `golang:1.24-alpine` builder image and runs in `gcr.io/distroless/static:nonroot`.

The Dockerfile uses the following cache-friendly order:

1. Copy `go.mod` and `go.sum`
2. Download dependencies
3. Copy application source
4. Build the static binary
5. Build a small static HTTP healthcheck binary
6. Copy only the required runtime files into the distroless image

The application binary is built with:

* `CGO_ENABLED=0`
* `GOOS=linux`
* `GOARCH=$TARGETARCH`
* `-trimpath`
* `-ldflags="-s -w"`

The final container runs as `nonroot:nonroot` (UID 65532).

### Image size

Builder image:

```text
golang:1.24-alpine
DISK USAGE:    388 MB
CONTENT SIZE:  80.1 MB
```

Final image:

```text
quicknotes:lab6
DISK USAGE:    21.9 MB
CONTENT SIZE:  5.36 MB
```

The final image is below the required 25 MB limit.

### Container configuration

The resulting image configuration includes:

```text
User:        nonroot:nonroot
WorkingDir:  /app
Entrypoint:  ["/app/quicknotes"]
ExposedPort: 8080/tcp
```

The runtime image does not contain a shell or package manager.

### Cache experiment

Two Dockerfile layer orders were compared.

#### Before — inefficient order

```text
COPY . .
RUN go mod download
```

After changing a file in the build context, the following layers were rebuilt:

```text
COPY . .
RUN go mod download
RUN go build
```

Measured build time:

```text
real 5.42
user 0.11
sys  0.11
```

#### After — cache-friendly order

The final Dockerfile uses:

```text
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
```

After changing a file in the build context, the dependency layer remained cached:

```text
CACHED COPY go.mod go.sum* ./
CACHED RUN go mod download
```

Measured build time:

```text
real 5.65
user 0.12
sys  0.11
```

The absolute build times are similar because QuickNotes has almost no external dependencies. However, the BuildKit output confirms that the optimized Dockerfile reuses the dependency layer when source files change. With a larger dependency graph, this would significantly reduce rebuild time.

### Design question A — Why does layer order matter?

Docker caches individual build layers. If `go.mod` and `go.sum` are copied and dependencies are downloaded before the application source is copied, changing source files does not invalidate the dependency layer.

With the inefficient order, `COPY . .` happens first, so any source change invalidates the following `go mod download` layer.

The optimized order therefore improves rebuild performance and makes better use of Docker's layer cache.

### Design question B — Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` produces a statically linked Go binary without dependencies on the system C library or other dynamically linked libraries.

This is important because the final runtime uses a minimal distroless static image. A statically linked binary can run without a normal Linux userspace or installed runtime libraries.

### Design question C — What is distroless static and what are the CVE implications?

A distroless image contains only the minimal runtime components required to run the application. The `static:nonroot` image does not provide a shell, package manager, or normal collection of operating-system utilities.

This reduces the number of components in the final image and therefore reduces the potential attack surface and number of packages that may contain vulnerabilities.

However, distroless does not mean that the image can never contain vulnerabilities. The base image and application dependencies still need to be maintained and scanned.

### Design question D — What do `-s -w` and `-trimpath` do?

`-ldflags="-s -w"` removes symbol and DWARF debugging information from the compiled binary. This reduces the binary size, which is useful for a minimal container image.

The trade-off is that debugging and post-mortem analysis become more difficult because debugging information is removed.

`-trimpath` removes local filesystem paths from the compiled binary. This makes builds more reproducible and avoids exposing local source paths.

---

## Task 2 — Docker Compose

The root `compose.yaml` defines a `quicknotes` service with:

* build context `./app`
* image tag `quicknotes:lab6`
* port `8080:8080`
* named volume `quicknotes-data:/data`
* `ADDR=:8080`
* `DATA_PATH=/data/notes.json`
* `SEED_PATH=/app/seed.json`
* `restart: unless-stopped`
* healthcheck using a compiled Go helper
* `cap_drop: ALL`
* `read_only: true`
* `/tmp` tmpfs
* `no-new-privileges:true`

### Healthcheck

The runtime image is distroless and therefore does not contain a shell, `curl`, or `wget`.

For this reason, a small static Go program was compiled as `/app/healthcheck`.

It performs:

```text
GET http://127.0.0.1:8080/health
```

and exits with status 0 only when the HTTP status is `200 OK`.

The Compose healthcheck is:

```yaml
healthcheck:
  test: ["CMD", "/app/healthcheck"]
  interval: 10s
  timeout: 3s
  retries: 3
  start_period: 5s
```

The container successfully reached the `healthy` state.

### Functional test

The application was started with Docker Compose and tested through the published port:

```text
curl http://localhost:8080/health
```

Result:

```json
{"notes":4,"status":"ok"}
```

The `/notes` endpoint also returned the four seed notes.

### Persistence test

A new note was created:

```json
{
  "title": "Lab 6 persistence",
  "body": "This note must survive docker compose down/up"
}
```

The application returned note ID `5`.

After:

```text
docker compose down
docker compose up -d
```

the health endpoint reported:

```json
{"notes":5,"status":"ok"}
```

The created note was still present.

This confirms that the named volume preserves application data across normal container recreation.

After:

```text
docker compose down -v
docker compose up -d
```

the application returned:

```json
{"notes":4,"status":"ok"}
```

and only the original seed notes were present.

This confirms that `docker compose down -v` removes the named volume and destroys the persisted application data.

### Design question E — Why use a healthcheck compatible with distroless?

A distroless image does not provide common shell utilities such as `sh`, `curl`, or `wget`.

Therefore, the healthcheck uses a compiled static Go executable. It communicates directly with the application's `/health` endpoint and works without requiring a shell or additional runtime packages.

### Design question F — How does volume persistence work?

The application data is stored in the named volume:

```text
quicknotes-data:/data
```

`docker compose down` removes the container but does not remove named volumes by default, so the data survives.

`docker compose down -v` explicitly removes the named volume, so the stored notes are deleted.

### Design question G — What does `depends_on` do?

`depends_on` controls service startup order, but basic `depends_on` does not mean that the dependency is ready to accept traffic.

If another service depended on QuickNotes, a health-aware condition such as:

```yaml
depends_on:
  quicknotes:
    condition: service_healthy
```

could be used when appropriate.

In this lab there is only one application service, so `depends_on` is not required.

---

# Bonus — Container Security

The Compose configuration implements the requested security defaults.

## 1. Non-root user

The Dockerfile contains:

```dockerfile
USER nonroot:nonroot
```

Verification:

```text
User=nonroot:nonroot
```

The application therefore does not run as root.

## 2. Distroless runtime

The final stage uses:

```dockerfile
FROM gcr.io/distroless/static:nonroot
```

The following command was also tested:

```text
docker compose exec quicknotes sh
```

It failed with:

```text
exec: "sh": executable file not found in $PATH
```

This confirms that the runtime image does not contain a shell.

## 3. Drop all Linux capabilities

Compose contains:

```yaml
cap_drop:
  - ALL
```

Verification:

```text
CapDrop=[ALL]
```

## 4. Read-only root filesystem

Compose contains:

```yaml
read_only: true
tmpfs:
  - /tmp
```

The persistent `/data` directory is provided through a named writable volume.

Verification:

```text
ReadonlyRootfs=true
Tmpfs={"/tmp":""}
```

A POST request successfully created a new note while the root filesystem was read-only, confirming that the `/data` volume remains writable.

## 5. No new privileges

Compose contains:

```yaml
security_opt:
  - no-new-privileges:true
```

Verification:

```text
SecurityOpt=[no-new-privileges:true]
```

This prevents processes in the container from gaining additional privileges.

## 6. Trivy vulnerability scan

Trivy version `0.59.1` was used with the required HIGH and CRITICAL severity filter:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 \
  image \
  --severity HIGH,CRITICAL \
  --no-progress \
  quicknotes:lab6
```

The scan could not complete because Trivy was unable to download its vulnerability database.

Two official database repositories were tested.

First:

```text
mirror.gcr.io/aquasec/trivy-db:2
```

Result:

```text
unexpected EOF
```

Second:

```text
ghcr.io/aquasecurity/trivy-db:2
```

Result:

```text
stream error: stream ID 1; PROTOCOL_ERROR; received from peer
```

The second attempt used a 30-minute timeout.

Therefore, no vulnerability count is claimed. The failure occurred while downloading the vulnerability database, before the `quicknotes:lab6` image could be scanned.

---

## Final verification

The final Compose container was healthy and the application remained functional with the security defaults enabled.

The main security controls were verified through `docker inspect`:

```text
User=nonroot:nonroot
ReadonlyRootfs=true
CapDrop=[ALL]
SecurityOpt=[no-new-privileges:true]
Tmpfs={"/tmp":""}
```

The final image size was approximately:

```text
21.9 MB disk usage
5.36 MB content size
```

which satisfies the required maximum final image size of 25 MB.

## Conclusion

QuickNotes was successfully containerized using a multi-stage Docker build and Docker Compose.

The final solution uses a minimal distroless runtime, a static non-root binary, cache-friendly Docker layers, a shell-free healthcheck, persistent named storage, and multiple container security hardening options.

Functional, persistence, image-size, caching, and security configuration tests were completed successfully. The Trivy scan was attempted with version 0.59.1, but the vulnerability database could not be downloaded because of network/registry transfer errors.
