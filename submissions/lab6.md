# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-Stage Dockerfile

Dockerfile: [`app/Dockerfile`](../app/Dockerfile)

I created a multi-stage Docker image for QuickNotes.

The build stage uses the pinned Go 1.24 image:

```dockerfile
FROM golang:1.24 AS builder
```

The runtime stage uses a minimal distroless image:

```dockerfile
FROM gcr.io/distroless/static-debian12:nonroot
```

The Go compiler and other build tools are therefore available only during the build and are not included in the final runtime image.

The application is compiled as a static binary using:

```dockerfile
RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /quicknotes \
    .
```

The final image exposes port 8080, runs as a non-root user, and uses an exec-form entrypoint:

```dockerfile
EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/app/quicknotes"]
```

### Final image size

Command:

```bash
docker images quicknotes:lab6
```

Output:

```text
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   4d170c451220       21.5MB         5.22MB
```

The final image is **21.5 MB**, which is below the required **25 MB** limit.

### Builder image size

Command:

```bash
docker images golang:1.24
```

Output:

```text
IMAGE         ID             DISK USAGE   CONTENT SIZE
golang:1.24   d2d2bc1c84f7       1.33GB          327MB
```

The builder image is much larger than the final runtime image. Multi-stage builds allow the compiler and build tools to stay in the builder stage instead of being included in production.

### Image configuration

Command:

```bash
docker inspect quicknotes:lab6 | jq '.[0].Config | {
  User,
  ExposedPorts,
  Entrypoint
}'
```

Output:

```json
{
  "User": "nonroot:nonroot",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/app/quicknotes"
  ]
}
```

This confirms that the final image:

- runs as a non-root user;
- exposes TCP port 8080;
- uses an exec-form entrypoint.

### Runtime verification

The container successfully served the health endpoint:

```bash
curl -s http://127.0.0.1:18081/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

---

### a. Why does Dockerfile layer ordering matter?

Docker caches image layers. If a layer changes, that layer and all layers after it have to be rebuilt.

I compared two strategies.

#### Bad ordering

```dockerfile
COPY . .
RUN go mod download
RUN go build ...
```

In this version, every source-code change invalidates the `COPY . .` layer. Because `go mod download` comes after it, the dependency step also has to run again even when `go.mod` did not change.

#### Good ordering

```dockerfile
COPY go.mod ./
RUN go mod download

COPY *.go ./
RUN go build ...
```

The project currently has no external Go dependencies, so there is no `go.sum` file. Therefore only `go.mod` is copied before `go mod download`.

With this ordering, changing an application source file does not invalidate the dependency layer.

#### Cache experiment

I first warmed the Docker cache and then changed only `main.go`.

With the good ordering, Docker reported:

```text
CACHED [builder 3/6] COPY go.mod ./
CACHED [builder 4/6] RUN go mod download
[builder 5/6] COPY *.go ./
[builder 6/6] RUN CGO_ENABLED=0 go build ...
```

The dependency layer remained cached.

Measured rebuild time:

```text
docker build -t quicknotes:cache-good ./app
0.11s user 0.09s system 4% cpu 4.768 total
```

I then tested the bad ordering:

```dockerfile
COPY . .
RUN go mod download
```

After changing `main.go`, Docker reported:

```text
[builder 3/5] COPY . .
[builder 4/5] RUN go mod download
[builder 5/5] RUN CGO_ENABLED=0 go build ...
```

The `go mod download` step was executed again because `COPY . .` had changed.

Measured rebuild time:

```text
docker build -t quicknotes:cache-bad ./app
0.11s user 0.09s system 4% cpu 4.306 total
```

The bad version happened to be slightly faster in this small experiment. This is because QuickNotes currently has no external Go dependencies, and `go mod download` took only about 0.1 seconds. Therefore wall-clock time is dominated by compilation and Docker overhead.

The important result is the **cache behavior**: with the good ordering, the dependency layer stayed cached. In a larger project with many dependencies, this avoids repeatedly downloading dependencies after normal source-code changes.

---

### b. Why is `CGO_ENABLED=0` used?

`CGO_ENABLED=0` tells Go to build without dependencies on C libraries.

This produces a statically linked Go binary that can run in a very small runtime image without requiring system libraries such as glibc.

This is especially important when using a distroless static image.

If CGO were enabled and the binary required dynamically linked C libraries, the application could fail to start in `distroless/static` because the required libraries are not available there.

---

### c. What is `gcr.io/distroless/static-debian12:nonroot`?

The runtime image used in this lab is:

```text
gcr.io/distroless/static-debian12:nonroot
```

A distroless image contains only the minimal runtime files required to execute the application.

It does **not** contain normal development and administration tools such as:

- a shell;
- `apt`;
- a compiler;
- `curl`;
- `wget`;
- other unnecessary command-line utilities.

The `nonroot` variant is also designed to run applications without root privileges.

This reduces both the final image size and the attack surface. There are fewer packages and tools that can contain vulnerabilities or be useful to an attacker if the application is compromised.

The Trivy scan also showed that the Debian runtime layer itself had:

```text
Total: 0 (HIGH: 0, CRITICAL: 0)
```

---

### d. What do `-ldflags="-s -w"` and `-trimpath` do?

The application is built with:

```text
-ldflags="-s -w"
```

The `-s` option removes the symbol table and the `-w` option removes DWARF debugging information.

This reduces the size of the final Go binary.

The application is also compiled with:

```text
-trimpath
```

This removes local filesystem paths from the compiled output. It avoids embedding build-machine-specific paths and helps make builds cleaner and more reproducible.

The main trade-off is that stripping symbols and debugging information makes low-level debugging of the compiled binary more difficult.

---

# Task 2 — Compose, Healthcheck and Persistent Volume

Compose file: [`compose.yaml`](../compose.yaml)

The Compose configuration defines the `quicknotes` service and:

- builds the image from `./app`;
- tags it as `quicknotes:lab6`;
- publishes port 8080;
- defines the required environment variables;
- mounts a named volume at `/data`;
- configures a healthcheck;
- uses `restart: unless-stopped`.

The required environment variables are:

```yaml
environment:
  ADDR: ":8080"
  DATA_PATH: "/data/notes.json"
  SEED_PATH: "/app/seed.json"
```

The named volume is mounted as:

```yaml
volumes:
  - quicknotes-data:/data
```

The application stores its persistent `notes.json` file inside this volume.

## Healthcheck

Because the final runtime is distroless, it does not contain a shell, `curl`, or `wget`.

I therefore created a small Go healthcheck program in:

```text
app/cmd/healthcheck/main.go
```

It performs an HTTP GET request to:

```text
http://127.0.0.1:8080/health
```

and exits with code `1` if the request fails or the response status is not HTTP 200.

The healthcheck is compiled as a static binary in the builder stage:

```dockerfile
RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /healthcheck \
    ./cmd/healthcheck
```

It is then copied into the distroless runtime image:

```dockerfile
COPY --from=builder /healthcheck /app/healthcheck
```

Compose executes the binary directly:

```yaml
healthcheck:
  test: ["CMD", "/app/healthcheck"]
  interval: 5s
  timeout: 3s
  retries: 5
  start_period: 3s
```

This avoids adding a shell or HTTP command-line utility to the production image.

### Healthcheck verification

Command:

```bash
docker compose ps
```

Output:

```text
NAME                        IMAGE             COMMAND             SERVICE      STATUS                   PORTS
devops-intro-quicknotes-1   quicknotes:lab6   "/app/quicknotes"   quicknotes   Up (healthy)             0.0.0.0:8080->8080/tcp
```

Health endpoint:

```bash
curl -s http://localhost:8080/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

---

## Persistent volume test

I tested whether application data survives container recreation.

### 1. Create a note

Command:

```bash
curl -X POST \
  -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes
```

Output:

```json
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-15T18:11:49.156273591Z"}
```

I verified that the note existed:

```bash
curl -s http://localhost:8080/notes | grep durable
```

The response contained:

```text
"id":5,"title":"durable","body":"survive a restart"
```

### 2. Recreate the container without deleting the volume

I stopped the Compose stack:

```bash
docker compose down
```

Docker removed the container and network:

```text
Container devops-intro-quicknotes-1 Removed
Network devops-intro_default Removed
```

I then started it again:

```bash
docker compose up -d
```

After the new container started, I checked for the note again:

```bash
curl -s http://localhost:8080/notes | grep durable
```

The response still contained:

```text
"id":5,"title":"durable","body":"survive a restart"
```

This confirms that the note survived container recreation because it was stored in the named volume.

### 3. Delete the volume

I then removed the Compose stack together with its named volume:

```bash
docker compose down -v
```

Output:

```text
Container devops-intro-quicknotes-1 Removed
Network devops-intro_default Removed
Volume devops-intro_quicknotes-data Removed
```

I started the service again:

```bash
docker compose up -d
```

Searching for the `durable` note now returned no output:

```bash
curl -s http://localhost:8080/notes | grep durable
```

The health endpoint returned:

```json
{"notes":4,"status":"ok"}
```

The application therefore returned to the four initial notes from `seed.json`.

This proves that the data survived `docker compose down`, but was destroyed by `docker compose down -v`.

---

### e. What healthcheck strategy is used with distroless?

A normal shell-based healthcheck such as:

```text
curl http://localhost:8080/health
```

cannot be used inside this image because distroless does not provide a shell, `curl`, or `wget`.

I used a small statically compiled Go healthcheck binary instead.

The binary is included directly in the final image and Docker runs it using exec form:

```yaml
test: ["CMD", "/app/healthcheck"]
```

This keeps the runtime distroless while still performing a real HTTP readiness/health check against the application.

---

### f. Why does the named volume survive `docker compose down`?

Named volumes have a lifecycle separate from containers.

Running:

```bash
docker compose down
```

removes the Compose containers and network, but named volumes are preserved by default.

Therefore the `notes.json` file stored under `/data` survives when the QuickNotes container is deleted and recreated.

Running:

```bash
docker compose down -v
```

explicitly removes the named volumes as well. This destroys the persisted QuickNotes data.

The persistence experiment confirmed both behaviors.

---

### g. What does `depends_on` wait for without `service_healthy`?

Without a health condition, `depends_on` primarily controls service startup ordering. It does not by itself mean that the dependency's application is fully ready to accept requests.

For example, a container may already be running while its application is still initializing.

A dependent service can therefore start too early and attempt to connect before the dependency is ready. This can cause startup-time connection failures.

Using a healthcheck together with a `service_healthy` condition allows a dependent service to wait for the dependency to become healthy instead of only waiting for the container startup sequence.

---

# Bonus — Security Defaults

I applied all six security-related bonus requirements.

## 1. Run as a non-root user

The Dockerfile uses:

```dockerfile
USER nonroot:nonroot
```

Verification:

```bash
docker inspect quicknotes:lab6 --format 'User={{.Config.User}}'
```

Output:

```text
User=nonroot:nonroot
```

The application therefore does not run with root privileges.

---

## 2. Distroless runtime

The final runtime image is:

```dockerfile
FROM gcr.io/distroless/static-debian12:nonroot
```

It contains no shell or package manager.

Verification:

```bash
docker compose exec quicknotes sh
```

Output:

```text
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

The failure is expected and confirms that a shell is not present in the production image.

---

## 3. Drop all Linux capabilities

Compose configuration:

```yaml
cap_drop:
  - ALL
```

Verification:

```bash
docker inspect devops-intro-quicknotes-1 \
  --format 'CapDrop={{.HostConfig.CapDrop}}'
```

Output:

```text
CapDrop=[ALL]
```

The application receives no additional Linux capabilities.

---

## 4. Read-only root filesystem

Compose configuration:

```yaml
read_only: true

tmpfs:
  - /tmp
```

The application data is stored separately in the writable named volume:

```yaml
volumes:
  - quicknotes-data:/data
```

Verification:

```bash
docker inspect devops-intro-quicknotes-1 \
  --format 'ReadonlyRootfs={{.HostConfig.ReadonlyRootfs}}'
```

Output:

```text
ReadonlyRootfs=true
```

A shell-based `touch /etc/test` test cannot be executed in the production container because the distroless image intentionally has no shell or `touch` utility. The Docker runtime configuration confirms that the root filesystem is mounted read-only.

The only persistent writable application location is `/data`, while `/tmp` is provided as a temporary in-memory filesystem.

---

## 5. Prevent privilege escalation

Compose configuration:

```yaml
security_opt:
  - no-new-privileges:true
```

Verification:

```bash
docker inspect devops-intro-quicknotes-1 \
  --format 'SecurityOpt={{.HostConfig.SecurityOpt}}'
```

Output:

```text
SecurityOpt=[no-new-privileges:true]
```

This prevents processes inside the container from gaining additional privileges.

After enabling all security options, QuickNotes remained healthy:

```text
devops-intro-quicknotes-1   quicknotes:lab6   Up (healthy)
```

and:

```json
{"notes":4,"status":"ok"}
```

---

## 6. Trivy vulnerability scan

I scanned the final image with Trivy 0.59.1:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image \
  --severity HIGH,CRITICAL \
  --no-progress \
  quicknotes:lab6
```

Trivy detected Debian 12.15 in the runtime image:

```text
Detected OS     family="debian" version="12.15"
```

### Runtime OS result

```text
quicknotes:lab6 (debian 12.15)
==============================
Total: 0 (HIGH: 0, CRITICAL: 0)
```

The distroless Debian runtime layer contained no HIGH or CRITICAL vulnerabilities.

### Healthcheck binary

```text
app/healthcheck (gobinary)
==========================
Total: 19 (HIGH: 19, CRITICAL: 0)
```

### QuickNotes binary

```text
app/quicknotes (gobinary)
=========================
Total: 19 (HIGH: 19, CRITICAL: 0)
```

The HIGH findings were reported in the Go standard library embedded in the two compiled binaries.

Trivy reported the installed Go standard library version as:

```text
v1.24.13
```

and showed fixed versions in newer Go releases for the detected CVEs.

The scan was performed as required and documents the current vulnerability state of the image.

---

## Security summary

The security default that provides the most protection is the combination of a **minimal distroless runtime and non-root execution**. Distroless removes unnecessary tools such as shells and package managers, reducing both the attack surface and the tools available after a compromise. Running as non-root, dropping all Linux capabilities, and enabling `no-new-privileges` significantly restrict what a compromised application process can do. Finally, the read-only root filesystem prevents modification of the container filesystem, while the application keeps only its required persistent data in the dedicated `/data` volume.

---

## Final verification

The final QuickNotes image:

```text
quicknotes:lab6
Size: 21.5 MB
```

The final configuration provides:

- multi-stage build;
- pinned `golang:1.24` builder;
- distroless runtime;
- static `CGO_ENABLED=0` binary;
- stripped build with `-s -w` and `-trimpath`;
- non-root execution;
- exec-form entrypoint;
- port 8080;
- cache-friendly dependency ordering;
- Docker Compose service;
- HTTP healthcheck;
- persistent named volume;
- required environment variables;
- `restart: unless-stopped`;
- all Linux capabilities dropped;
- read-only root filesystem;
- tmpfs for `/tmp`;
- `no-new-privileges`;
- Trivy HIGH/CRITICAL vulnerability scan.

The service remained operational and healthy after applying the container and security configuration.