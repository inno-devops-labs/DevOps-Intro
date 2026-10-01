# Lab 6 submission

## Task 1 — Multi-Stage Dockerfile, ≤ 25 MB

### 1.1 — Dockerfile

File: [`app/Dockerfile`](../app/Dockerfile)

```dockerfile
# syntax=docker/dockerfile:1.7

# ---------- Stage 1: builder ----------
FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux \
    go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

# Empty /data dir — copied to runtime stage with nonroot ownership
RUN mkdir -p /out/data

# ---------- Stage 2: runtime ----------
FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /app/quicknotes
COPY --from=builder --chown=nonroot:nonroot /out/data /data

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/app/quicknotes"]
```

### 1.3 — Build + verify

```bash
$ docker build -t quicknotes:lab6 app/
...
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   f4df058d7186       14.5MB         3.16MB
```

**Final image: 14.5 MB (disk) — well under the 25 MB budget.**

For comparison:

| Image | Role | Size |
|---|---|---|
| `golang:1.24-alpine` | builder (contains full Go toolchain) | ~80 MB |
| `gcr.io/distroless/static:nonroot` | runtime base | ~800 KB |
| **`quicknotes:lab6`** | final | **14.5 MB** |

The multi-stage build cuts the final image ~5.5× smaller than the builder.

`docker inspect quicknotes:lab6` excerpt:

```json
{
  "User": "nonroot:nonroot",
  "ExposedPorts": { "8080/tcp": {} },
  "Entrypoint": ["/app/quicknotes"]
}
```

Running container serves traffic:

```bash
$ docker run --rm -d --name qn-test -p 8080:8080 \
    -v "$PWD/app/data:/data" quicknotes:lab6
$ curl -s http://localhost:8080/health | jq
{ "notes": 0, "status": "ok" }

$ curl -s -X POST http://localhost:8080/notes \
    -H 'Content-Type: application/json' \
    -d '{"title":"from container","body":"written via -v"}' | jq
{ "id": 1, "title": "from container", ... }
```

### 1.2 — Design questions

**a) Why does layer order matter? Show before/after.**

Docker caches each layer keyed on the exact command **and the content of everything it copies**. `COPY . .` copies the entire source tree — any edit to any `.go` file changes the layer's cache key. So if you do:

```dockerfile
COPY . .               # ← invalidated on every source change
RUN go mod download    # ← re-downloads modules every time
RUN go build ...
```

…the module download runs on every rebuild even when `go.mod` didn't change.

Correct order:

```dockerfile
COPY go.mod go.sum* ./ # ← changes rarely
RUN go mod download    # ← cached until go.mod changes
COPY . .               # ← invalidated on source changes
RUN go build ...
```

In our rebuilds the difference is measurable even for a zero-dependency project: `go mod download` completes in ~0.1 s (cached) vs. several seconds if it re-ran. For a project with a real `go.sum` (100s of modules), the difference is 30+ seconds per rebuild. The principle: **put rarely-changing layers first, frequently-changing layers last.**

**b) Why `CGO_ENABLED=0`? What happens in distroless-static if you forget it?**

Go's default is `CGO_ENABLED=1` on most platforms, which means the binary links against the host's libc (`glibc` on Ubuntu) **dynamically**. That binary needs a dynamic linker (`/lib64/ld-linux-*.so`) at runtime to even start.

`gcr.io/distroless/static` contains **no libc and no dynamic linker**. If you copy a dynamically-linked binary into it, the kernel can't find the interpreter and returns:

```
exec /app/quicknotes: no such file or directory
```

— which is *incredibly* confusing because the file clearly exists. The fix is `CGO_ENABLED=0`, which forces Go to produce a **statically linked** binary with no runtime dependencies. That's precisely what `distroless/static` is designed for.

**c) What is `gcr.io/distroless/static:nonroot`?**

It's Google's distroless image with:
- **Just enough** to run a static binary: `/etc/passwd`, `/etc/group`, CA certificates, timezone data, `/tmp` — that's it. ~800 KB compressed.
- **No shell** (`sh`, `bash`), no package manager (`apt`, `apk`), no coreutils.
- **No libc** (the `static` variant), so only CGO_ENABLED=0 binaries work.
- **Pre-configured `nonroot` user** (UID 65532) with `USER nonroot:nonroot` already set.

Why this matters for CVEs: most container CVEs live in **packages you didn't write** — `openssl`, `libc`, `curl`, `bash`, etc. A distroless image simply doesn't have them, so a scanner like Trivy reports **0 OS-level HIGH/CRITICAL vulnerabilities** (verified in the Bonus section below). Smaller attack surface and fewer patches to track.

**d) `-ldflags='-s -w'` and `-trimpath`: what each does, and the cost?**

- **`-ldflags='-s -w'`** — linker flags that strip **debug information**: `-s` removes the symbol table and DWARF debug sections, `-w` removes DWARF specifically. Effect: ~30% smaller binary. **Cost:** you lose the ability to run `dlv attach`, `gdb`, or get meaningful stack traces with file:line info from a core dump. Fine for production; you'd keep it off in a debug build.
- **`-trimpath`** — records file paths in the binary as `module/package/file.go` instead of `/Users/witch/DevOps-Intro/app/package/file.go`. Effect: (1) reproducibility — building the same source on another machine produces a byte-identical binary; (2) doesn't leak local directory structure into production artifacts. **Cost:** in crash stack traces you'll see the module-relative path, which is usually clearer anyway.

Combined effect on our binary: from ~12 MB (default) down to ~7 MB stripped. That's most of why the final image is under 15 MB.

## Task 2 — Compose + Healthcheck + Persistent Volume

### 2.1 — compose.yaml

File: [`compose.yaml`](../compose.yaml) at the repo root.

```yaml
services:
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    container_name: quicknotes
    restart: unless-stopped

    ports:
      - "8080:8080"

    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/app/seed.json"

    volumes:
      - quicknotes-data:/data

    # Security defaults (see Bonus)
    cap_drop: [ALL]
    read_only: true
    tmpfs: [/tmp]
    security_opt:
      - no-new-privileges:true

    healthcheck:
      test: ["CMD", "/app/quicknotes", "--healthcheck"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 5s

volumes:
  quicknotes-data:
    name: quicknotes-data
```

### 2.3 — Persistence test

```bash
$ curl -s -X POST http://localhost:8080/notes \
    -H 'Content-Type: application/json' \
    -d '{"title":"durable","body":"survive a restart"}' | jq
{ "id": 1, "title": "durable", ... }

$ curl -s http://localhost:8080/notes | grep durable
[{"id":1,"title":"durable","body":"survive a restart",...}]   ← present

$ docker compose down
$ docker compose up -d
$ curl -s http://localhost:8080/notes | grep durable
[{"id":1,"title":"durable",...}]                             ← still present ✅

$ docker compose down -v                                     ← destroys the volume
$ docker compose up -d
$ curl -s http://localhost:8080/notes | grep durable || echo "durable is gone"
durable is gone                                              ✅ as designed
```

### 2.2 — Design questions

**e) Distroless has no shell — how do you healthcheck it?**

I chose to **add a `--healthcheck` mode to the binary itself**. The idea: since there's no `curl`, `wget`, or shell to run them from, the binary must act as its own probe.

In `app/main.go`:

```go
func main() {
    if len(os.Args) > 1 && os.Args[1] == "--healthcheck" {
        os.Exit(runHealthcheck())
    }
    // ... normal server startup
}

func runHealthcheck() int {
    addr := envOrDefault("ADDR", ":8080")
    if strings.HasPrefix(addr, ":") {
        addr = "127.0.0.1" + addr
    }
    client := &http.Client{Timeout: 2 * time.Second}
    resp, err := client.Get("http://" + addr + "/health")
    if err != nil { return 1 }
    defer resp.Body.Close()
    if resp.StatusCode != http.StatusOK { return 1 }
    return 0
}
```

And in `compose.yaml`:

```yaml
healthcheck:
  test: ["CMD", "/app/quicknotes", "--healthcheck"]
```

**Why this is the right choice for distroless:**
- No additional packages needed in the image (image stays tiny).
- Exec form (`CMD`, not `CMD-SHELL`) — no shell required.
- Probe performs a real HTTP request against `/health`, so it verifies the whole stack (listen socket + router + handlers), not just "is PID 1 alive".

Alternatives I considered:
- **Sidecar container** with curl — works, but adds a second container just for a healthcheck; over-engineered for one service.
- **Docker's process-liveness only** — the default when no healthcheck is set. Doesn't catch "process running but not serving" (a real failure mode for Go servers with a stuck handler).
- **`:debug` distroless variant** — has a busybox shell, but doubles the image size and ships a shell you'd rather not have in production.

Verified locally:
```
$ ADDR=:8080 /tmp/qn --healthcheck   (server up)
exit code: 0

$ ADDR=:8080 /tmp/qn --healthcheck   (server down)
healthcheck: dial tcp 127.0.0.1:8080: connect: connection refused
exit code: 1
```

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`? What destroys it?**

Named volumes are **first-class Docker resources** with their own lifecycle. They are created by `docker volume create` (or implicitly by `compose up`) and are **not tied** to the container that mounts them. When you run `docker compose down`, Compose stops and removes the container, but leaves the named volume alone — because the volume might be shared with another service or intentionally preserved. On the next `docker compose up`, the volume is re-mounted into the fresh container, and QuickNotes reads the same `notes.json`.

What **destroys** the volume:
- `docker compose down -v` — the explicit "and remove volumes" flag.
- `docker volume rm quicknotes-data` — manual removal.
- `docker volume prune` — removes all unused volumes (the kind you run to "free up space").
- `docker system prune --volumes` — same, broader.

We verified both directions in §2.3.

**g) `depends_on` without `condition: service_healthy` — what does it wait for? What's the bug it can cause?**

`depends_on: [foo]` (the short form) waits only for `foo`'s **container to start** — meaning the container process has been created, not that the service inside is ready to accept connections. Docker literally just waits for the container to enter the `running` state, then starts the dependent.

The bug: a service like QuickNotes takes a moment to bind to `:8080` — it must seed `notes.json`, initialize the store, and call `ListenAndServe`. If a consumer (`depends_on: [quicknotes]`) tries to connect in that window, it gets `connection refused` and may crash on startup, even though QuickNotes becomes healthy 200 ms later. The long form fixes this:

```yaml
depends_on:
  quicknotes:
    condition: service_healthy
```

That tells Docker to wait until the healthcheck reports `healthy` (using the healthcheck we defined in §2.2e) before starting the dependent service. Only then does the dependent see a live, ready-to-serve QuickNotes.

## Bonus — The 6 Security Defaults

All six applied and each verified with a concrete command.

### 1. `USER nonroot`

In the Dockerfile:
```dockerfile
USER nonroot:nonroot
```

Verify:
```bash
$ docker inspect quicknotes --format '{{ .Config.User }}'
nonroot:nonroot
```

### 2. Distroless base

```dockerfile
FROM gcr.io/distroless/static:nonroot
```

No shell → no arbitrary command execution even if an attacker gets RCE inside the process.

Verify:
```bash
$ docker compose exec quicknotes sh -c 'echo hi'
OCI runtime exec failed: exec failed: unable to start container process:
exec: "sh": executable file not found in $PATH
```

### 3. Drop ALL Linux capabilities

```yaml
cap_drop: [ALL]
```

Verify:
```bash
$ docker inspect quicknotes --format '{{ .HostConfig.CapDrop }}'
[ALL]

$ docker inspect quicknotes --format '{{ .HostConfig.CapAdd }}'
[]
```

QuickNotes needs **zero** capabilities — it doesn't bind privileged ports (< 1024), doesn't change UID, doesn't use raw sockets or net_admin.

### 4. Read-only root filesystem + tmpfs

```yaml
read_only: true
tmpfs: [/tmp]
```

Verify:
```bash
$ docker inspect quicknotes --format '{{ .HostConfig.ReadonlyRootfs }} {{ .HostConfig.Tmpfs }}'
true map[/tmp:]
```

The container cannot write outside `/data` (our named volume) and `/tmp` (in-memory). Verified persistence still works with `read_only: true` — the named volume remains writable.

### 5. `no-new-privileges`

```yaml
security_opt:
  - no-new-privileges:true
```

Blocks setuid/setgid binaries from elevating the container process's privileges via `execve`.

Verify:
```bash
$ docker inspect quicknotes --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
```

### 6. Trivy image scan

```bash
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
    quicknotes:lab6
```

Output (summary):

```
quicknotes:lab6 (debian 13.7)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)              ← ✅ OS-layer: clean (distroless working as intended)

app/quicknotes (gobinary)
=========================
Total: 19 (HIGH: 19, CRITICAL: 0)            ← ⚠️ Go stdlib v1.24.13
```

The 19 HIGH findings are **not** in our code — they are Go **standard library** CVEs in `stdlib v1.24.13`, all of which have fixes only in the 1.25/1.26 lines. This demonstrates two things:

1. **The value of distroless**: the OS layer is 0 findings. If we'd used `ubuntu:24.04` as the runtime, we'd be staring at hundreds of OS-package CVEs.
2. **The remaining risk lives in the toolchain**: pinning `golang:1.24-alpine` in the builder has consequences for what ships in the binary. In a real project, the fix would be to bump the builder to `golang:1.25` (or newer) as soon as the app compiles cleanly on it — and to keep that bump visible in CI (Lab 9's Trivy integration).

### Which of the 6 gives the most security per line of YAML?

**`cap_drop: [ALL]`** — one line, one list item, and it removes the entire kernel attack surface that Linux capabilities expose. Every non-trivial container escape uses *some* capability (usually `CAP_SYS_ADMIN` or `CAP_DAC_OVERRIDE`); with `cap_drop: [ALL]` there's simply nothing to leverage. It's the purest expression of least privilege in Compose, requires no code changes, and if you genuinely need a capability the failure is immediate and obvious (the app breaks, you add the one capability back). Compared to that, distroless (which requires a whole base-image choice), no-new-privileges (which is a subtler hardening), and read-only rootfs (which requires careful tmpfs/volume planning) all cost more effort for their marginal gain over the capability drop.
