# Lab 6 Submission

## Task 1: Multi-Stage Dockerfile

### Dockerfile

See at [`Dockerfile`](/app/Dockerfile) and pasted here for reference:

```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /build

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes . && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./healthcheck/ && \
    mkdir -p /out/data

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder /build/seed.json /seed.json
COPY --chown=65532:65532 --from=builder /out/data /data

USER nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
```

### Build & Verify

```
docker build -t quicknotes:lab6 .
```

```
#1 [internal] load build definition from Dockerfile
...
#17 naming to docker.io/library/quicknotes:lab6 done
```

---

```
docker images quicknotes:lab6
```

```
REPOSITORY   TAG     IMAGE ID       CREATED         SIZE
quicknotes   lab6    239cf76e4b95   2 minutes ago   13.7MB
```

---

```
docker run --rm -p 8080:8080 -v quicknotes-verify:/data \
  -e DATA_PATH=/data/notes.json -e SEED_PATH=/seed.json quicknotes:lab6 &
sleep 2
curl -s http://localhost:8080/health
```

```
{"notes":0,"status":"ok"}
```

> The endpoint returns `200 OK`. The count is `0` here because a freshly-created
> named volume is empty and **root-owned**, so the `nonroot` (UID 65532) process
> cannot write the seed file into it on Docker Desktop (Windows). Task 2 fixes this
> with a one-shot `volume-init` sidecar that `chown`s the volume before startup —
> there the count is the expected `4`.

### `docker inspect` Config excerpt

```
docker inspect quicknotes:lab6 | jq '.[0].Config'
```

```json
{
  "User": "nonroot",
  "ExposedPorts": { "8080/tcp": {} },
  "WorkingDir": "/home/nonroot",
  "Entrypoint": ["/quicknotes"]
}
```

### Inspecting User, ExposedPorts, EntryPoint

```bash
docker inspect quicknotes:lab6 --format "{{.Config.User}}"
nonroot
```
```bash
docker inspect quicknotes:lab6 --format "{{json .Config.ExposedPorts}}"
{"8080/tcp":{}}
```
```bash
docker inspect quicknotes:lab6 --format "{{json .Config.Entrypoint}}"
["/quicknotes"]
```

### Builder vs runtime image size

| Image                          | Size    |
| ------------------------------ | ------- |
| `golang:1.24-alpine` (builder) | ~300 MB |
| `quicknotes:lab6` (runtime)    | 13.7 MB |

### Design Questions

**a) Why does layer-order matter?**

Docker caches each layer; a cache miss invalidates all layers below it. Copying `go.mod` first and running `go mod download` before `COPY . .` means source-only changes skip the dependency download step entirely, cutting cold-rebuild time from ~30 s to ~5 s.

**b) Why `CGO_ENABLED=0`?**

The default (`CGO_ENABLED=1`) produces a binary dynamically linked against libc, which distroless-static does not ship. Without the flag the container fails at start with `no such file or directory` because the dynamic linker (`ld-linux`) is missing.

**c) What is `gcr.io/distroless/static:nonroot`?**

It contains only ca-certificates and timezone data (no shell, no package manager, no libc). The minimal attack surface means the image typically has zero HIGH/CRITICAL CVEs, compared to hundreds in a full Debian or Alpine base.

**d) `-ldflags='-s -w'` and `-trimpath`**

`-s` strips the symbol table and `-w` drops DWARF debug info, together shrinking the binary by ~30%. `-trimpath` removes local filesystem paths from the binary for reproducible builds. The cost is harder debugging: stack traces lose file paths and symbol names.

---

## Task 2: Compose + Healthcheck + Persistent Volume

### compose.yaml

See at [`compose.yaml`](/compose.yaml) and pasted here for reference:

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
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped

volumes:
  quicknotes-data:
```

**Healthcheck strategy.** Distroless has no shell, `curl`, or `wget`, so the
`HEALTHCHECK` runs a tiny static Go binary ([`app/healthcheck/main.go`](/app/healthcheck/main.go))
that we build alongside the app and copy into the image. It does an HTTP `GET /health`
and exits `0`/`1` — exec-form, side-effect free.

**`volume-init` sidecar.** A fresh named volume is empty and **root-owned**. The
`nonroot` (UID 65532) app can't create `notes.json` in it, so the one-shot
`volume-init` service runs `chown 65532:65532 /data` first. `quicknotes` waits for it
via `depends_on: condition: service_completed_successfully`.

### Stack up + health

```
docker compose up --build -d
docker compose ps
```

```
NAME                        IMAGE             COMMAND         SERVICE      STATUS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   Up (healthy)
```

---

```
docker inspect devops-intro-quicknotes-1 --format "{{.State.Health.Status}}"
```

```
healthy
```

### Persistence test

**Step 1 — POST a note, confirm present:**

```
curl -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' http://localhost:8080/notes
```

```json
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T20:37:18.101090202Z"}
```

```
curl -s http://localhost:8080/notes | grep durable
```

```
... {"id":5,"title":"durable","body":"survive a restart", ...}
```
Present
---

**Step 2 — `docker compose down` (no `-v`) then `up`, note STILL present:**

```
docker compose down
docker compose up -d
curl -s http://localhost:8080/notes | grep durable
```

```
... {"id":5,"title":"durable","body":"survive a restart", ...}  
```
Still present
---

**Step 3 — `docker compose down -v` then `up`, note GONE:**

```
docker compose down -v
docker compose up -d
curl -s http://localhost:8080/notes | grep durable
curl -s http://localhost:8080/health
```
```
{"notes":4,"status":"ok"}
```

The volume `quicknotes-data` was destroyed by `down -v`; `volume-init` re-seeds a
fresh volume, so only the 4 seed notes remain.

### Design Questions

**e) Distroless has no shell. How do you healthcheck it?**

I copy a purpose-built static Go binary (`/healthcheck`) into the image and use exec-form `test: ["CMD", "/healthcheck"]`. It does a real `GET /health`, so the probe verifies the HTTP server actually serves — cheaper and more honest than a sidecar, and the only practical option since there's no `curl`/`wget`/shell to invoke.

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`? What destroys it?**

Named volumes are managed independently of containers; `docker compose down` removes containers and networks but leaves named volumes intact, so `/data/notes.json` persists. Only `docker compose down -v` (or `docker volume rm`) deletes the volume and its data.

**g) `depends_on` without `condition: service_healthy` — what does it wait for, and the bug?**

Plain `depends_on` only waits for the dependency's container to *start*, not to be *ready*, so a dependent can race ahead and hit a not-yet-listening service. Here I use `condition: service_completed_successfully` so the `chown` actually finishes before `quicknotes` tries to write to `/data`.

---

## Bonus Task: The 6 Security Defaults

### Hardened `quicknotes` service block

```yaml
  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    # ... depends_on, ports, environment, volumes, healthcheck ...
    restart: unless-stopped
    read_only: true                 # 4. read-only root filesystem
    tmpfs:
      - /tmp:size=16m,mode=1777     # 4. writable scratch (app needs none, but defensive)
    cap_drop:
      - ALL                         # 3. drop every Linux capability
    security_opt:
      - no-new-privileges:true      # 5. block setuid privilege escalation
```

Defaults **1** (`USER nonroot`) and **2** (distroless base) are enforced in the Dockerfile from Task 1.

### Verification

**1. `USER nonroot`**

```
docker inspect quicknotes:lab6 --format "{{.Config.User}}"
```

```
nonroot
```

---

**2. No shell available (distroless base)**

```
docker compose exec quicknotes sh
```

```
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH: unknown
```

---

**3. Capabilities dropped**

```
docker inspect devops-intro-quicknotes-1 --format "{{.HostConfig.CapDrop}}"
```

```
[ALL]
```

---

**4. Read-only root filesystem**

```
docker inspect devops-intro-quicknotes-1 --format "{{.HostConfig.ReadonlyRootfs}}"
```

```
true
```

Only `/data` (named volume) and `/tmp` (tmpfs) are writable. There's no shell to run
`touch /etc/test`, so the `ReadonlyRootfs: true` config flag is the enforced proof; the
container still boots healthy because the app's only writes go to `/data`.

---

**5. `no-new-privileges`**

```
docker inspect devops-intro-quicknotes-1 --format "{{.HostConfig.SecurityOpt}}"
```

```
[no-new-privileges:true]
```

### Trivy scan

```
docker run --rm -v //var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6
```

_No output captured — the Trivy vulnerability-DB download failed due to connection
slowness/issues in my environment. Expected result with a distroless-static base is
**0 HIGH/CRITICAL** on the OS layer (no shell, no package manager, no OS packages to be
vulnerable); any findings would be stdlib CVEs inside the compiled Go binaries, fixable
by rebuilding with a patched Go toolchain rather than changing the base image._

### Which default gives the most security per line of YAML?

`cap_drop: [ALL]` is the highest-leverage line in the compose file: two lines strip the
entire Linux capability set, so even a fully compromised process can't bind low ports,
load kernel modules, or use raw sockets without a separate kernel exploit. `read_only`
and `no-new-privileges` are close behind, while `USER nonroot` and the distroless base are
foundational but set once in the Dockerfile. Applied together they form independent,
overlapping layers rather than a single point of failure.
