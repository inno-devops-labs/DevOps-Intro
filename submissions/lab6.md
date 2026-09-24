# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-Stage Dockerfile (≤ 25 MB)

### 1.1 Dockerfile

`app/Dockerfile`:

```dockerfile
# syntax=docker/dockerfile:1.7

# ---------- Stage 1: builder ----------
FROM golang:1.24-alpine AS builder

WORKDIR /src

# Cache dependencies first (layer-order matters — see Q1.2a)
COPY go.mod ./
RUN go mod download

# Copy source and build a fully static binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w" \
    -trimpath \
    -o /out/quicknotes .

# ---------- Stage 2: runtime ----------
FROM gcr.io/distroless/static:nonroot

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json

USER 65532:65532

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

### 1.2 Build + verify

#### `docker images quicknotes:lab6`

```
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   89d941c8c290         15MB         3.37MB    U
```

✅ **3.37 MB content size** — well under the 25 MB limit.

#### `docker inspect` excerpt

```
User:         65532:65532
ExposedPorts: map[8080/tcp:{}]
Entrypoint:   [/quicknotes]
```

#### Base image size comparison

| Image | Size |
|---|---|
| `golang:1.24-alpine` (builder base) | **83.3 MB** (83,301,112 bytes) |
| `gcr.io/distroless/static:nonroot` | ~2 MB |
| **`quicknotes:lab6` (final)** | **3.37 MB** |

The final image is **~25× smaller** than the builder base — the Go toolchain, Alpine OS, and all build artifacts stay behind in the discarded builder stage.

#### Smoke test — serves `/health` and `/notes`

Ran with a pre-chowned named volume (Windows bind mounts can't preserve UID 65532):

```
$ curl.exe -s http://localhost:8080/health
{"notes":4,"status":"ok"}

$ curl.exe -s http://localhost:8080/notes
[{"id":1,"title":"Welcome to QuickNotes",...},{"id":2,...},{"id":3,...},{"id":4,...}]
```

#### No shell (as designed)

```
$ docker exec qn sh
OCI runtime exec failed: exec failed: unable to start container process:
exec: "sh": executable file not found in $PATH
```

### 1.3 Design Questions

#### a) Why does layer-order matter?

Docker caches each instruction as a layer. A cache miss invalidates that layer **and every layer after it**.

**Bad order** — `COPY . . && go mod download && go build`:
Any source edit (even a comment) changes the `COPY . .` layer → `go mod download` re-runs → `go build` re-runs. Every rebuild downloads all dependencies again.

**Good order** — `COPY go.mod go.sum ./ && go mod download && COPY . . && go build`:
- `COPY go.mod go.sum ./` — only invalidated when dependency files change
- `go mod download` — cached across every code edit
- `COPY . .` — only this layer and the build re-run on source changes

**Measured (this project — zero external deps):**

| Build | Time |
|---|---|
| First (cold cache) | ~18.5 s |
| Rebuild after `main.go` edit | ~5 s (only last 2 layers re-run) |
| Rebuild with no changes | <1 s (all cached) |

In a project with dozens of dependencies, the difference is 30+ seconds versus 1–2 seconds per rebuild.

#### b) Why `CGO_ENABLED=0`?

Go's default `CGO_ENABLED=1` links the binary against the host's C library (`glibc` on Debian, `musl` on Alpine). `gcr.io/distroless/static` contains **no libc at all** — it's built from scratch. A CGO-enabled binary fails at startup with a misleading error:

```
exec /quicknotes: no such file or directory
```

That's the kernel complaining it can't find the **dynamic linker** referenced by the ELF header — not the binary itself. Setting `CGO_ENABLED=0` makes Go use pure-Go implementations of syscalls/networking, producing a **fully static binary** that runs on any Linux kernel with no libc.

#### c) What is `gcr.io/distroless/static:nonroot`?

Google's minimal base image. Contains only what a static Go binary needs at runtime.

**Included:**
- CA certificates (`/etc/ssl/certs/`) — for outbound TLS
- `/etc/passwd`, `/etc/group` — including `nonroot` UID 65532
- `/etc/nsswitch.conf`
- Timezone data
- `/home/nonroot`

**Not included:**
- No shell (`sh`, `bash`)
- No package manager (`apt`, `apk`)
- No coreutils (`ls`, `cp`, `cat`)
- No libc
- No Python, Perl, curl, wget

**Why it matters for CVEs:** Almost every container CVE lives in the shell, package manager, or system libraries. Since distroless-static ships none of them, the attack surface is minimal and Trivy typically reports **0 HIGH/CRITICAL** vulnerabilities. Trade-offs: no shell for debugging (`docker exec sh` fails — by design), no `curl`/`wget` for healthchecks, and you must build statically.

#### d) `-ldflags='-s -w'` and `-trimpath`

| Flag | What it does | Cost |
|---|---|---|
| `-s` | Omits the **symbol table** (used by `nm`, `objdump`) | Cannot resolve function names in `pprof` or core dumps |
| `-w` | Omits **DWARF debug info** (used by `gdb`, `delve`) | Cannot single-step in a debugger |
| `-s -w` combined | Shrinks the binary by ~25–30% | Same as above — production binary is opaque to debuggers |
| `-trimpath` | Replaces absolute source paths (`C:\Users\vorid\...`) with module-relative paths (`quicknotes/main.go`) | Panic traces show package-relative paths, which is fine |

**Combined benefit:** smaller image (fewer bytes to push/pull), reproducible builds (binary is byte-identical regardless of build machine), and no leakage of your local filesystem layout into a public image.
# Task 2 — Compose + Healthcheck + Persistent Volume

## 2.1 compose.yaml

```yaml
services:
  quicknotes-init:
    image: alpine:3.20
    user: "0:0"
    volumes:
      - quicknotes-data:/data
    command: ["sh", "-c", "chown -R 65532:65532 /data"]
    restart: "no"

  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    container_name: quicknotes
    depends_on:
      quicknotes-init:
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
      test: ["CMD", "/quicknotes", "-health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 5s
    restart: unless-stopped

volumes:
  quicknotes-data:
```

**Why the `quicknotes-init` service?** Docker creates named volumes owned by `root:root`. The `quicknotes` container runs as UID 65532 and cannot write to `/data` — the app exits immediately with `seed: open /data/notes.json: permission denied`. The init service runs as root, chowns the volume to 65532, and exits. `depends_on: condition: service_completed_successfully` makes Compose wait for the chown to finish before starting `quicknotes`.

**Why the `-health` flag?** Distroless has no shell, so `wget`/`curl`-based healthchecks are impossible. The binary itself implements the probe. Added at the top of `func main()` in `app/main.go`:

```go
if len(os.Args) > 1 && os.Args[1] == "-health" {
    resp, err := http.Get("http://127.0.0.1:8080/health")
    if err != nil || resp.StatusCode != http.StatusOK {
        os.Exit(1)
    }
    os.Exit(0)
}
```

## 2.2 Persistence test output

### Step 1 — POST a note and confirm it exists

```
$ curl.exe -s -i -X POST -H "Content-Type: application/json" --data-binary "@body.json" http://localhost:8080/notes
HTTP/1.1 201 Created
Content-Type: application/json
Content-Length: 100

{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T21:40:40.825169637Z"}

$ curl.exe -s http://localhost:8080/notes | Select-String durable
[...,{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T21:40:40.825169637Z"},...]
```

✅ Note present.

### Step 2 — `docker compose down` (no `-v`), then `up`

```
$ docker compose down
 ✔ Container quicknotes                     Removed
 ✔ Container devops-intro-quicknotes-init-1 Removed
 ✔ Network devops-intro_default             Removed

$ docker compose up -d
 ✔ Container devops-intro-quicknotes-init-1 Exited
 ✔ Container quicknotes                     Started

$ curl.exe -s http://localhost:8080/notes | Select-String durable
[...,{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T21:40:40.825169637Z"}]
```

✅ Note **still present** — the named volume survived `down`.

### Step 3 — `docker compose down -v`, then `up`

```
$ docker compose down -v
 ✔ Container quicknotes                     Removed
 ✔ Container devops-intro-quicknotes-init-1 Removed
 ✔ Network devops-intro_default             Removed
 ✔ Volume devops-intro_quicknotes-data      Removed

$ docker compose up -d
 ✔ Network devops-intro_default             Created
 ✔ Volume devops-intro_quicknotes-data      Created
 ✔ Container devops-intro-quicknotes-init-1 Exited
 ✔ Container quicknotes                     Started

$ curl.exe -s http://localhost:8080/notes | Select-String durable
(no output)
```

✅ Note **absent** — the volume was destroyed.

**Summary:** note present → `down` + `up` → present → `down -v` + `up` → absent. Named volume survives container lifecycle; only `down -v` (or `docker volume rm` / `docker volume prune`) destroys it.

## 2.3 Design Questions

### e) Distroless has no shell. How do you healthcheck it?

I added a `-health` flag to the binary itself and use it as the healthcheck command: `["CMD", "/quicknotes", "-health"]`. This is exec form, so Docker invokes the binary directly without a shell. The binary performs an HTTP GET to `http://127.0.0.1:8080/health`, exits 0 on HTTP 200, and exits 1 otherwise.

**Why this strategy over the alternatives:**

- **HTTP via a separate sidecar** — adds a second container and image, more moving parts, more failure modes, and the sidecar must also be distroless or you reintroduce CVEs.
- **`wget`-only debug image** — the `:debug` distroless tag adds a shell and busybox, which defeats the entire point of using distroless (attack surface, CVE count).
- **Rely on Docker's default "process is alive" behavior** — Docker cannot distinguish "running but hung" from "healthy." A deadlocked process still shows as running.
- **Use a binary already in the image** — this is what I did. The app binary is already there, requires zero new dependencies, adds zero new attack surface, and is side-effect free (a single local HTTP request every 30s).

The check is cheap and safe: it uses `start_period: 5s` so the container has time to bind its port before the first probe.

### f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`? What destroys it?

Docker **named volumes** are managed by the daemon and live independently of containers. They are first-class objects with their own lifecycle — `docker volume ls` shows them even when no container is running.

`docker compose down` performs three operations: stops and removes containers, removes the default network, and **leaves named volumes intact**. This is deliberate: an accidental `down` should not destroy user data.

What **does** destroy a named volume:

- `docker compose down -v` — the explicit `--volumes` flag tells Compose to also remove named volumes declared in the compose file.
- `docker volume rm quicknotes-data` — direct removal by name.
- `docker volume prune` — removes all volumes not currently used by any container.

Bind mounts (`./data:/data`) behave differently: they point at a host directory, so Compose never "removes" them. Deleting the host folder is what loses data.

In the persistence test above, Step 2 (`down` without `-v`) kept the volume and the note; Step 3 (`down -v`) removed the volume and the note was gone after `up`.

### g) `depends_on` without `condition: service_healthy` — what does it wait for? What's the bug?

Without a `condition`, `depends_on: [other]` waits only for the other container's **process to start** — i.e., the entrypoint has been launched. It does **not** wait for the service to be listening on its port, to have run migrations, or to be ready to serve traffic.

**The bug:** a classic race condition. The dependent service starts, immediately tries to connect to the dependency, and gets `connection refused` because the dependency's app hasn't bound its port yet. Compose reports success ("container started"), but the app crashes or errors on first request. On slower machines or under load, this is intermittent — the worst kind of bug.

**Fix:** use a `condition`:

- `condition: service_healthy` — waits until the dependency's healthcheck passes. Requires the dependency to define a `healthcheck:` block.
- `condition: service_completed_successfully` — waits until the dependency exits with code 0. Used for init/migration containers.

In this compose file, `quicknotes` uses `condition: service_completed_successfully` for `quicknotes-init` because the init container's job is to run to completion (chown the volume), not to stay healthy. Using plain `depends_on: [quicknotes-init]` without the condition would start `quicknotes` while `chown` was still running — and the app would then hit `permission denied` on the volume again.

## Bonus Task — The 6 Security Defaults

### Hardened compose.yaml snippet

```yaml
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    container_name: quicknotes
    depends_on:
      quicknotes-init:
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
      test: ["CMD", "/quicknotes", "-health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 5s
    restart: unless-stopped
    user: "65532:65532"
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
```

Defaults 1 (`USER nonroot`) and 2 (distroless base) are enforced in the Dockerfile (Task 1) and confirmed by the inspect output below.

### Verification outputs

**1. `USER nonroot` (from the Dockerfile):**

```
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
65532:65532
```

**2. No shell (distroless base):**

```
$ docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

**3. Capabilities dropped:**

```
$ docker inspect quicknotes --format '{{ .HostConfig.CapDrop }}'
[ALL]
```

**4. Read-only root filesystem:**

```
$ docker inspect quicknotes --format '{{ .HostConfig.ReadonlyRootfs }}'
true
```

Note: `docker compose exec quicknotes touch /etc/test` cannot be used as proof, because there is no shell in the image to invoke `touch`. The `ReadonlyRootfs: true` inspect field is the enforcement proof.

**5. `no-new-privileges`:**

```
$ docker inspect quicknotes --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
```

### Trivy summary

```
$ docker run --rm -v //var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
    quicknotes:lab6

quicknotes:lab6 (debian 13.7)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 19 (HIGH: 19, CRITICAL: 0)
```

The OS layer — the only layer controlled by the base image choice — has **0 HIGH, 0 CRITICAL**, which is the value of using `gcr.io/distroless/static:nonroot`. The 19 HIGH findings are all in the Go standard library (`stdlib v1.24.13`), not in the application code or the OS. They are upstream Go CVEs fixed in Go 1.25.8+ / 1.26.x. The lab pins the builder to `golang:1.24`, so they cannot be resolved without violating the constraint; the correct mitigation is to bump the Go minor version once the lab allows it.

### Reflection — which default gives the most security per line of YAML?

The single highest-leverage default is `cap_drop: [ALL]`. It's one line of YAML that removes every privileged kernel operation a process could request — `CAP_SYS_ADMIN`, `CAP_NET_RAW`, `CAP_SYS_PTRACE`, `CAP_DAC_OVERRIDE`, and the rest. Most container escapes rely on at least one of these capabilities, so dropping all of them removes the majority of the practical attack surface in one shot. Paired with `security_opt: [no-new-privileges:true]` — also one line — a compromised process cannot regain privilege through setuid binaries or file capabilities. The distroless base is arguably the more valuable decision overall for CVE reduction, but that lives in the Dockerfile, not in YAML. Inside `compose.yaml`, `cap_drop: [ALL]` gives the most security per line.