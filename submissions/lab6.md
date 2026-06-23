# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-Stage Dockerfile (≤ 25 MB)

### Dockerfile (`app/Dockerfile`)

```dockerfile
# ─── builder stage ───
FROM golang:1.24-alpine AS builder
WORKDIR /src

# Dependency manifest first → cached unless go.mod changes.
# (QuickNotes is stdlib-only, so there is no go.sum.)
COPY go.mod ./
RUN go mod download

# Then the source.
COPY . .

# Static (CGO off), stripped (-s -w), reproducible (-trimpath) binary.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /quicknotes .

# Pre-create /data owned by nonroot (65532) so the named volume inherits it.
RUN mkdir -p /data && chown 65532:65532 /data

# ─── runtime stage ───
FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder --chown=65532:65532 /data /data
COPY --chown=65532:65532 seed.json /seed.json

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

USER nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
```

> The distroless image has no shell or curl, so the healthcheck is a subcommand
> of the app binary itself (`/quicknotes healthcheck`) — added in `main.go`. It
> does an HTTP GET to `/health` on loopback and exits 0 (healthy) or 1.

### Image size

```
$ docker images quicknotes:lab6
REPOSITORY   TAG    IMAGE ID       CREATED         SIZE
quicknotes   lab6   8f49caa3db13   3 minutes ago   14.9MB

$ docker image ls | grep golang
golang       1.24   d2d2bc1c84f7   4 months ago    1.33GB
```

The final image is **14.9 MB** vs the **1.33 GB** full Go toolchain image. Multi-stage cut ~99% by keeping only the static binary in a distroless runtime.

### `docker inspect` — User / ExposedPorts / Entrypoint

```
$ docker inspect quicknotes:lab6 | jq '.[0].Config | {User, ExposedPorts, Entrypoint, Env}'
{
  "User": "nonroot",
  "ExposedPorts": { "8080/tcp": {} },
  "Entrypoint": [ "/quicknotes" ],
  "Env": [
    "ADDR=:8080",
    "DATA_PATH=/data/notes.json",
    "SEED_PATH=/seed.json"
  ]
}
```

### Functional test

```
$ docker run -d --name qn-test -p 8080:8080 quicknotes:lab6
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
$ curl -s http://localhost:8080/notes | head -c 120
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, ...
```

### Design Questions

**a) Why does layer order matter?**

Docker caches each instruction as a layer and reuses it until one of its inputs changes; once a layer is invalidated, every layer after it is rebuilt too. If I write `COPY . . && go mod download && go build`, then **any** change to a source file invalidates the `COPY` layer, so `go mod download` is forced to run again on every rebuild. If instead I write `COPY go.mod ./ && go mod download && COPY . . && go build`, the dependency layer only depends on `go.mod`, so editing source code keeps the cached dependencies and skips the download. QuickNotes is stdlib-only, so the download is almost instant here, but on a real project with many modules this is the difference between a fast rebuild and re-fetching every dependency each time. The rule from the lab — manifest before source — maximizes cache reuse.

**b) Why `CGO_ENABLED=0`? What happens in distroless-static if you forget it?**

`CGO_ENABLED=0` tells Go to build a fully **static** binary with no dependency on the system C library (libc) and to use the pure-Go DNS resolver instead of the C one. The `distroless/static` base is intentionally empty — it has no libc and no dynamic linker. If I forget the flag, Go may produce a **dynamically linked** binary, and when the container starts the kernel cannot find the linker/libc, so it fails with a confusing `no such file or directory` even though the binary is right there. Building static makes the binary self-contained, which is exactly what a `static` base expects.

**c) What is `gcr.io/distroless/static:nonroot`?**

It is a minimal base image that contains almost nothing: CA certificates, `/etc/passwd` with a `nonroot` user (UID 65532), timezone data, and a writable `/tmp` — and that is basically it. What it does **not** have is a shell, a package manager, libc, or any of the usual OS utilities. This matters for CVEs because vulnerability scanners report issues in installed packages, and there are almost no packages here, so the attack surface is tiny — Trivy typically reports **zero** HIGH/CRITICAL findings. There is also no shell for an attacker to use if they do get in, which removes a whole class of exploitation.

**d) `-ldflags='-s -w'` and `-trimpath` — what does each do, and the cost?**

`-ldflags='-s -w'` strips two things from the binary: `-s` removes the symbol table and `-w` removes the DWARF debug information. The benefit is a noticeably smaller binary; the cost is that debugging is harder — tools like `gdb`/`delve` lose symbol and debug data (Go panic stack traces still work). `-trimpath` removes the absolute build-machine paths (like `/Users/me/...`) from the binary and replaces them with clean module paths. The benefit is **reproducibility** — the same source builds byte-for-byte the same regardless of where it is built — and it avoids leaking local filesystem paths into the binary; the cost is again slightly less convenient debugging because the original paths are gone.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

### compose.yaml (repo root)

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
      test: ["CMD", "/quicknotes", "healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped

    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true

volumes:
  quicknotes-data:
```

The healthcheck works (`docker compose ps` reports the container as `healthy`):

```
NAME                        IMAGE             COMMAND         SERVICE      STATUS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   Up 9 seconds (healthy)
```

### Persistence test

```
# 1) create a note, confirm it is there
$ curl -X POST -H 'Content-Type: application/json' \
    -d '{"title":"durable","body":"survive a restart"}' http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T12:51:40Z"}
$ curl -s http://localhost:8080/notes | grep durable
...,"id":5,"title":"durable",...          # present ✅

# 2) down WITHOUT -v, then up again → note survives
$ docker compose down
$ docker compose up -d
$ curl -s http://localhost:8080/notes | grep durable
...,"id":5,"title":"durable",...          # STILL present ✅

# 3) down -v (removes the volume), then up → note is gone
$ docker compose down -v
 ✔ Volume devops-intro_quicknotes-data Removed
$ docker compose up -d
$ curl -s http://localhost:8080/notes | grep durable || echo "GONE (empty)"
GONE (empty)                              # destroyed ✅
```

### Design Questions

**e) Distroless has no shell. How do you healthcheck it?**

I used the option **"a binary that's already in the image"** — the app binary itself. I added a tiny `healthcheck` subcommand to `main.go`, so `/quicknotes healthcheck` does an HTTP GET to `/health` on loopback and exits `0` (healthy) or `1`. The compose healthcheck is then `test: ["CMD", "/quicknotes", "healthcheck"]` in exec form (no shell needed). I rejected the alternatives: a **sidecar** container adds a whole extra service and does not even set the health *status* of `quicknotes` itself; a **`:debug` image with wget** pulls busybox back in and breaks the minimal/no-shell property that is the whole point; and **relying on process-liveness only** does not prove the HTTP server actually answers. Reusing the binary keeps the image minimal and gives a real HTTP check.

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`? What destroys it?**

A **named volume** is a Docker object with its own lifecycle, separate from any container. The notes are written into that volume, not into the container's writable layer. `docker compose down` removes the containers and the network but **leaves named volumes alone**, so when I bring the stack back up the same volume is re-attached and the note is still there — which the test confirms. What destroys it is asking for it explicitly: `docker compose down -v` (or `docker volume rm devops-intro_quicknotes-data`). The test shows exactly this — after `down -v` the note is gone.

**g) `depends_on` without `condition: service_healthy` — what does it wait for, and the bug?**

Plain `depends_on: [quicknotes]` only waits for the container to be **started** (created and running), not for the application inside to be **ready**. The bug is a startup race: a dependent service can begin sending requests while QuickNotes is still booting/seeding and not yet listening, so it gets connection-refused or flaky failures that only happen on cold start. Adding `condition: service_healthy` makes Docker wait until the healthcheck passes before starting the dependent service, which removes the race.

---

## Bonus — The 6 Security Defaults

### Hardened `services.quicknotes` block

```yaml
    read_only: true
    tmpfs:
      - /tmp                     #     writable scratch outside the /data volume
    cap_drop:
      - ALL                      # (3) drop every Linux capability (app needs none)
    security_opt:
      - no-new-privileges:true   # (5) block setuid privilege escalation
    # (1) USER nonroot + (2) distroless base come from the Dockerfile
```

### Verification of each default

```
1. USER nonroot
   $ docker inspect quicknotes:lab6 --format '{{.Config.User}}'
   nonroot

2. No shell (distroless) — exec must FAIL
   $ docker compose exec quicknotes sh
   OCI runtime exec failed: exec: "sh": executable file not found in $PATH
   exit=127

3. Capabilities dropped
   $ docker inspect $CID --format '{{.HostConfig.CapDrop}}'
   [ALL]

4. Read-only root filesystem
   $ docker inspect $CID --format '{{.HostConfig.ReadonlyRootfs}}'
   true

5. no-new-privileges
   $ docker inspect $CID --format '{{.HostConfig.SecurityOpt}}'
   [no-new-privileges:true]
```

### Trivy scan (default 6)

```
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6

quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)          ← distroless OS layer is clean

quicknotes (gobinary)
=====================
Total: 13 (HIGH: 13, CRITICAL: 0)        ← Go stdlib CVEs (net/url, crypto/x509, net/http …)
```

**Reading the result honestly:** the distroless **OS layer has 0 HIGH/CRITICAL**, which is exactly the value of a minimal base — there are no OS packages to be vulnerable. The 13 HIGH findings are all in `stdlib` (the Go runtime compiled into the binary, v1.24.13); their fixed versions are 1.25.x/1.26.x, so the only real remediation is bumping the Go toolchain — but Lab 6 pins the builder to Go **1.24**, so within that constraint they remain. The lesson: distroless removes the *operating system* attack surface entirely, but the application binary still carries the *language runtime's* CVEs, so a minimal base is necessary but not sufficient — you also have to keep the compiler patched.

### Which default gives the most security per line of YAML?

The **distroless base** (defaults 1+2, effectively one `FROM` line plus `USER nonroot`) gives the most: it removed the entire OS CVE surface (Trivy shows 0 OS findings) and removed the shell, so even a successful RCE has no `sh`, no package manager, and no tools to pivot with — that kills several exploitation classes at once. In the compose file, `cap_drop: ALL` is the best single line: one line strips every Linux capability, so the process cannot do privileged kernel operations even if compromised. `read_only: true` and `no-new-privileges:true` are each one cheap line that closes off tampering and setuid escalation respectively. Together they layer cleanly, but distroless is the highest-leverage choice.

