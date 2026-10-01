# Lab 6 — Containers: Dockerize QuickNotes

**Student:** SophiiaSultanova  
**GitHub:** [@fsstilerr](https://github.com/fsstilerr)  
**Docker:** 29.2.1

---

## Task 1 — Multi-Stage Dockerfile, ≤ 25 MB

The final Dockerfile is stored at [`app/Dockerfile`](../app/Dockerfile).

It uses a `golang:1.24.5-alpine` builder and a `gcr.io/distroless/static-debian12:nonroot` runtime, builds with `CGO_ENABLED=0`, `-trimpath`, and `-ldflags="-s -w"`, runs as UID/GID `65532:65532`, exposes port 8080, and uses exec-form `ENTRYPOINT`.

A small static `/healthcheck` binary is also built so Compose can perform an HTTP health check even though the distroless runtime has no shell, curl, or wget.

### Image size

```text
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   1cdfd16c939d   21.4MB       5.21MB
```

The final image is below the required 25 MB limit.

Builder base comparison:

```text
IMAGE                  ID             DISK USAGE   CONTENT SIZE
golang:1.24.5-alpine   daae04ebad0c   387MB        79.9MB
```

### Image configuration

```json
{
  "User": "65532:65532",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/quicknotes"
  ]
}
```

### Runtime verification

```text
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 26

{"notes":4,"status":"ok"}
```

`GET /notes` also returned the four seeded notes successfully.

### Design questions

#### a) Why does layer order matter?

I compared two strategies after changing application source code.

Cache-friendly:

```dockerfile
COPY go.mod ./
RUN go mod download
COPY *.go ./
```

Poor-cache:

```dockerfile
COPY . .
RUN go mod download
```

Measured rebuild times:

```text
GOOD CACHE REBUILD
7.091 s total

BAD CACHE REBUILD
5.951 s total
```

The cache-friendly build was not faster in this single wall-clock sample. QuickNotes currently has no external module dependencies, so `go mod download` is effectively trivial and the total time is dominated by compilation plus normal Docker timing noise.

The cache behavior is still different: in the cache-friendly Dockerfile, changing a `.go` file does not invalidate the earlier dependency-download layer. With `COPY . .` first, any source change invalidates everything after that copy. The advantage becomes much larger on projects with non-trivial dependency graphs.

#### b) Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` produces a static Go binary without a dependency on a system C library or dynamic linker.

That matters for `distroless/static`, because it intentionally does not contain the normal dynamic-linker environment. A dynamically linked binary may otherwise fail to start even though the binary itself exists.

#### c) What is `gcr.io/distroless/static:nonroot`?

It is a minimal runtime image intended for static executables. It does not contain a shell, package manager, compiler, or the normal interactive Linux userland.

The `nonroot` variant also uses an unprivileged identity. Fewer packages and tools mean a smaller attack surface and fewer OS-level CVEs.

#### d) What do `-ldflags='-s -w'` and `-trimpath` do?

`-ldflags="-s -w"` strips the symbol table and DWARF debug information, reducing binary size.

`-trimpath` removes local filesystem paths from the compiled output, improving reproducibility and avoiding leakage of developer-specific paths.

The cost is reduced low-level debugging information.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

The final Compose configuration is stored at [`compose.yaml`](../compose.yaml).

The `quicknotes` service builds from `./app`, tags the image as `quicknotes:lab6`, publishes port 8080, mounts the named volume `quicknotes-data` at `/data`, passes `ADDR`, `DATA_PATH`, and `SEED_PATH`, defines a healthcheck, and uses `restart: unless-stopped`.

Observed health status:

```text
Health=healthy
```

### Persistence test

A durable note was created:

```text
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-22T13:55:42.804208838Z"}
```

It was present before shutdown and still present after:

```bash
docker compose down
docker compose up -d
```

After:

```bash
docker compose down -v
docker compose up -d
```

the result was:

```text
durable note is gone as expected
```

This proves that the application state is stored in the named volume rather than the container's writable layer.

### Design questions

#### e) Distroless has no shell. How do you healthcheck it?

I built a small static Go healthcheck binary and copied it into the final image as `/healthcheck`.

Compose runs it in exec form:

```yaml
healthcheck:
  test: ["CMD", "/healthcheck"]
```

The binary sends an HTTP request to `http://127.0.0.1:8080/health` and exits non-zero if the request fails or the response is not HTTP 200.

#### f) Why does the named volume survive `docker compose down`?

A named volume has a lifecycle separate from the container. `docker compose down` removes the containers and network but preserves named volumes by default.

`docker compose down -v` explicitly removes the volumes, which is why the durable note disappeared after that command.

#### g) What does `depends_on` without `condition: service_healthy` wait for?

Plain `depends_on` controls startup ordering. It waits for the dependency container to be started, not for the application inside it to become ready.

This can create a race where a dependent service tries to connect before the upstream service is actually healthy.

---

## Bonus — Six Security Defaults

### 1. Non-root user

```text
User=65532:65532
```

### 2. Distroless runtime / no shell

```text
OCI runtime exec failed: exec failed: unable to start container process:
exec: "sh": executable file not found in $PATH
```

### 3. Capabilities dropped

```text
CapDrop=["ALL"]
```

### 4. Read-only root filesystem

```text
ReadonlyRootfs=true
```

The writable application data is isolated to `/data`, and `/tmp` is a tmpfs.

### 5. No new privileges

```text
SecurityOpt=["no-new-privileges:true"]
```

### 6. Trivy scan

Trivy 0.59.1 reported zero HIGH/CRITICAL findings for the distroless Debian runtime layer:

```text
quicknotes:lab6 (debian 12.15)
==============================
Total: 0 (HIGH: 0, CRITICAL: 0)
```

The Go binaries themselves were also scanned:

```text
healthcheck (gobinary)
======================
Total: 22 (HIGH: 21, CRITICAL: 1)

quicknotes (gobinary)
=====================
Total: 22 (HIGH: 21, CRITICAL: 1)
```

These findings came from the Go 1.24.5 standard library embedded in the static binaries. This shows that a minimal base image can remove OS-package vulnerabilities while statically linked language-runtime vulnerabilities can still remain and require toolchain updates.

### Which defaults give the most security per line?

`cap_drop: [ALL]` gives especially high security value for one small Compose setting because it removes kernel privileges the application does not need. `read_only: true` is similarly valuable because it limits filesystem modification after compromise. Running as non-root and enabling `no-new-privileges` further reduce privilege-escalation paths. Distroless reduces attack surface and OS-package CVEs, although the Trivy output shows that the embedded Go standard library must still be kept patched.

---

## Result

- Task 1: completed
- Task 2: completed
- Bonus: completed with verification and Trivy output
