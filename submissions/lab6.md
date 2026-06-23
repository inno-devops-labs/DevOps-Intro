# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-Stage Dockerfile

### Dockerfile

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags='-s -w' \
    -o /quicknotes .

FROM busybox:1.36-musl AS busybox

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json
COPY --from=busybox /bin/busybox /busybox
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
```

### Image size

```
$ docker images quicknotes:lab6
REPOSITORY   TAG    SIZE
quicknotes   lab6   16MB
```

Builder base for comparison:

```
$ docker images golang:1.24-alpine
golang:1.24-alpine   388MB
```

Full output: [`attachments/lab6/docker-images.txt`](attachments/lab6/docker-images.txt)

### `docker inspect` excerpt

```json
{
    "User": "65532",
    "ExposedPorts": { "8080/tcp": {} },
    "Entrypoint": ["/quicknotes"],
    "WorkingDir": "/home/nonroot"
}
```

Full output: [`attachments/lab6/docker-inspect-config.json`](attachments/lab6/docker-inspect-config.json)

### Health endpoint (standalone `docker run`)

```
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

Evidence: [`attachments/lab6/curl-health.txt`](attachments/lab6/curl-health.txt)

### Design questions (a–d)

**a) Why does layer-order matter?**

Docker caches each layer. If `COPY . .` comes before `go mod download`, any source change invalidates the layer that also contains dependency download, so `go mod download` and `go build` run again.

Measured rebuild after touching `handlers.go` only:

| Strategy | `real` time |
|----------|------------|
| Good: `COPY go.mod` → `go mod download` → `COPY . .` → build | **1.70 s** |
| Bad: `COPY . .` → `go mod download` → build | **3.72 s** |

Evidence: [`attachments/lab6/cache-good-rebuild.txt`](attachments/lab6/cache-good-rebuild.txt), [`attachments/lab6/cache-bad-rebuild.txt`](attachments/lab6/cache-bad-rebuild.txt)

**b) Why `CGO_ENABLED=0`?**

With CGO enabled, Go may link against libc and produce a dynamically linked binary. Distroless `static` has no dynamic linker (`/lib/ld-linux.so`), so the binary fails at startup with `no such file or directory` or similar. `CGO_ENABLED=0` forces a fully static binary that runs on distroless-static.

**c) What is `gcr.io/distroless/static-debian12:nonroot`?**

It is a minimal runtime image: CA certs, timezone data, `/etc/passwd` entry for UID 65532 (`nonroot`), and nothing else — no shell, package manager, or libc beyond what a static binary needs. Fewer packages mean a smaller attack surface and fewer OS-level CVEs (Trivy reported **0 HIGH/CRITICAL** on the Debian layer).

**d) `-ldflags='-s -w'` and `-trimpath`**

- `-s -w`: strip the symbol table and DWARF debug info → smaller binary, faster pulls.
- `-trimpath`: remove local filesystem paths from the binary → reproducible builds and no host paths leaked into artifacts.

Cost: harder to debug crashes inside the container (no symbols); stack traces are less informative without separate debug symbols.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

### `compose.yaml`

```yaml
services:
  volume-init:
    image: busybox:1.36-musl
    volumes:
      - quicknotes-data:/data
    command: ["sh", "-c", "chown 65532:65532 /data"]
    restart: "no"

  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    depends_on:
      volume-init:
        condition: service_completed_successfully
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    volumes:
      - quicknotes-data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/busybox", "wget", "-qO-", "http://127.0.0.1:8080/health"]
      interval: 5s
      timeout: 3s
      retries: 3
      start_period: 10s
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp

volumes:
  quicknotes-data:
```

**Note on `volume-init`:** A fresh Docker named volume is owned by `root`. The distroless image runs as UID `65532` and cannot create `/data/notes.json` without fixing ownership first. The one-shot `volume-init` service runs `chown 65532:65532 /data` before `quicknotes` starts.

### Compose status

```
$ docker compose ps
NAME                        IMAGE             STATUS
devops-intro-quicknotes-1   quicknotes:lab6   Up (healthy)
```

Evidence: [`attachments/lab6/compose-ps.txt`](attachments/lab6/compose-ps.txt), [`attachments/lab6/compose-up.txt`](attachments/lab6/compose-up.txt)

### Persistence test (3 steps)

1. POST note `durable` → present in `GET /notes`
2. `docker compose down` (no `-v`) → `docker compose up -d` → note **still present**
3. `docker compose down -v` → `docker compose up -d` → note **gone** (seed data only)

Evidence: [`attachments/lab6/persistence-test.txt`](attachments/lab6/persistence-test.txt)

### Design questions (e–g)

**e) Distroless has no shell — how do you healthcheck it?**

Strategy: copy a static `busybox` binary from a separate build stage into the runtime image and use exec-form healthcheck: `["CMD", "/busybox", "wget", "-qO-", "http://127.0.0.1:8080/health"]`. This performs a real HTTP probe without a shell. Alternatives (sidecar, process-alive only) are weaker or heavier; `wget` via minimal busybox is cheap and side-effect free.

**f) Why does the named volume survive `docker compose down`?**

`docker compose down` stops and removes containers and networks but **not** named volumes declared in the top-level `volumes:` block. Data in `quicknotes-data` persists on the Docker host. **`docker compose down -v`** (or `docker volume rm`) destroys the volume and all notes stored there.

**g) `depends_on` without `condition: service_healthy`**

Plain `depends_on` only waits until the dependency **container has started**, not until it is ready to serve traffic. A dependent service can connect before migrations, volume permissions, or HTTP listeners are ready → flaky startups. Here we use `condition: service_completed_successfully` for `volume-init` so `chown` finishes before `quicknotes` writes to `/data`.

---

## Bonus — Six Security Defaults

### Hardened `quicknotes` service block

```yaml
  quicknotes:
    # ... build, ports, env, volumes ...
    healthcheck:
      test: ["CMD", "/busybox", "wget", "-qO-", "http://127.0.0.1:8080/health"]
      interval: 5s
      timeout: 3s
      retries: 3
      start_period: 10s
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
```

Defaults 1–2 (nonroot user, distroless base) are enforced in the Dockerfile (`static-debian12:nonroot`, `User: 65532`).

### Verification

| Default | Command / check | Result |
|---------|-----------------|--------|
| USER nonroot | `docker inspect quicknotes:lab6 --format '{{ .Config.User }}'` | `65532` |
| No shell | `docker compose exec quicknotes sh` | `executable file not found` |
| CapDrop ALL | `docker inspect … --format '{{ .HostConfig.CapDrop }}'` | `[ALL]` |
| Read-only root | `docker compose exec quicknotes /busybox touch /etc/test` | `Read-only file system` |
| no-new-privileges | `docker inspect … --format '{{ .HostConfig.SecurityOpt }}'` | `[no-new-privileges:true]` |

Full output: [`attachments/lab6/bonus-security.txt`](attachments/lab6/bonus-security.txt)

### Trivy scan

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
  quicknotes:lab6
```

Summary:

| Target | HIGH | CRITICAL |
|--------|-----:|---------:|
| `quicknotes:lab6` (debian 12.14 OS layer) | 0 | 0 |
| `quicknotes` (embedded Go binary) | 13 | 0 |

The OS layer is clean thanks to distroless. The 13 HIGH findings are **stdlib CVEs in the compiled Go binary** (toolchain 1.24.x); fixing them requires rebuilding with a patched Go release, not switching the base image.

Full output: [`attachments/lab6/trivy.txt`](attachments/lab6/trivy.txt)

### Security per line of YAML

**`cap_drop: [ALL]`** gives the most security per line: it removes the entire Linux capability set, so even if the Go process is compromised it cannot perform privileged operations (e.g. `CAP_NET_RAW`, `CAP_SYS_ADMIN`) without a separate kernel bug. Read-only root and `no-new-privileges` are close runners-up; distroless/nonroot are foundational but mostly set once in the Dockerfile rather than compose.

---

## Artifacts

| File | Description |
|------|-------------|
| `app/Dockerfile` | Multi-stage build |
| `compose.yaml` | Compose stack with volume + hardening |
| `attachments/lab6/*.txt` | Command outputs and test evidence |
