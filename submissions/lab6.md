# Lab 6 — Containers: Dockerize QuickNotes

- Student: Arina Nikolaeva (Nik-ari-ai)
- Fork: https://github.com/Nik-ari-ai/DevOps-Intro
- Branch: feature/lab6

## Task 1 — Multi-Stage Dockerfile

### `app/Dockerfile`

```dockerfile
# ---------- builder ----------
FROM golang:1.24 AS builder
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
      -trimpath -ldflags='-s -w' -o /out/quicknotes .
RUN mkdir -p /hc && cd /hc && \
    printf 'package main\nimport("net/http";"os")\nfunc main(){r,e:=http.Get("http://127.0.0.1:8080/health");if e!=nil||r.StatusCode!=200{os.Exit(1)};os.Exit(0)}\n' > main.go && \
    go mod init hc >/dev/null 2>&1 && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck .
RUN mkdir -p /data && chown 65532:65532 /data

# ---------- runtime ----------
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /data /data
COPY --from=builder /src/seed.json /seed.json
USER 65532:65532
ENV ADDR=:8080 DATA_PATH=/data/notes.json SEED_PATH=/seed.json
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
```

A tiny second binary (`/healthcheck`) is compiled in the builder so a shell-less distroless image can still run a real HTTP healthcheck. `/data` is created and chowned to `65532` so a fresh named volume inherits nonroot-writable ownership.

### Image size

```
REPOSITORY:TAG    SIZE
quicknotes:lab6   21.7MB
```

21.7 MB ≤ 25 MB. For comparison, the `golang:1.24` builder base pulled ~316 MB of compressed layers during the build (98 + 75 + 68 + 25 + 50 MB) — multi-stage keeps all of that out of the runtime image.

### `docker inspect` config

```json
{
  "User": "65532:65532",
  "ExposedPorts": { "8080/tcp": {} },
  "Entrypoint": ["/quicknotes"],
  "Env": [
    "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt",
    "ADDR=:8080",
    "DATA_PATH=/data/notes.json",
    "SEED_PATH=/seed.json"
  ]
}
```

### Run + curl

```
$ docker run -d --rm -p 8080:8080 --name qn-lab6 quicknotes:lab6
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
$ curl -s http://localhost:8080/notes | jq 'length'
4
```

### 1.2 Design questions

**a) Why does layer-order matter? (`COPY . .` first vs `COPY go.mod` first)**
Docker caches each layer by the inputs to that step. If you `COPY . .` before `go mod download`, any source edit invalidates the copy layer and forces `go mod download` to re-run on every rebuild. Copying `go.mod`/`go.sum` first and running `go mod download` before `COPY . .` means the dependency layer is cached and only re-runs when dependencies actually change; a source-only edit reuses it. In this project the effect is small because QuickNotes has zero third-party dependencies (`go.mod` has no `require`, no `go.sum`), so `go mod download` is a no-op either way — but the ordering is the pattern that saves minutes on any real dependency tree. The cold build here was dominated (~9 min) by pulling the `golang:1.24` base, not by dependency work.

**b) Why `CGO_ENABLED=0`?**
It produces a statically linked binary with no dependency on the system C library / dynamic linker. `distroless/static` contains no libc and no `ld.so`, so a dynamically linked binary (the default, `CGO_ENABLED=1`) would fail at start with `no such file or directory` — the kernel can't find the interpreter. The local build confirmed the binary is "statically linked … not a dynamic executable".

**c) What is `gcr.io/distroless/static:nonroot`?**
It is a minimal runtime image with only CA certificates, `/etc/passwd`, timezone data and a nonroot user (UID 65532) — no shell, no package manager, no busybox, no libc. That matters for CVEs because most image vulnerabilities come from the OS packages and shells that normal base images carry; with none of them present, the attack surface and the CVE count of the base collapse to (here) zero. It also means there is no shell for an attacker to pivot into.

**d) `-ldflags='-s -w'` and `-trimpath`**
`-s` strips the symbol table, `-w` strips DWARF debug info — together they shrink the binary (smaller image, less to ship). `-trimpath` removes absolute local filesystem paths from the compiled binary, so the build is reproducible across machines and doesn't leak build-host paths. The cost: `-s -w` makes symbolic debugging / stack symbolization harder (you'd rebuild with symbols to debug), and `-trimpath` makes local path-based tooling less convenient — both acceptable for a shipped artifact.

## Task 2 — Compose + Healthcheck + Persistent Volume

### `compose.yaml`

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
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
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

### Healthcheck working

```
NAME                        IMAGE             STATUS
devops-intro-quicknotes-1   quicknotes:lab6   Up 15 seconds (healthy)
health=healthy
```

### Persistence test

```
# POST a note
$ curl -s -X POST -d '{"title":"durable","body":"survive a restart"}' .../notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-11T16:45:59Z"}

# present before restart
{"id":5,"title":"durable",...}

# docker compose down   (keep volume)  ->  docker compose up -d
# STILL present:
{"id":5,"title":"durable",...}          # persistence PASS

# docker compose down -v (destroy volume)  ->  docker compose up -d
# gone:
(empty)                                  # volume destroyed, note gone
```

### 2.2 Design questions

**e) Distroless has no shell — how do you healthcheck it?**
I compiled a tiny static Go binary (`/healthcheck`) into the image in the builder stage and point Docker's healthcheck at it with exec form: `test: ["CMD", "/healthcheck"]`. It does one `http.Get("http://127.0.0.1:8080/health")` and exits 0 on 200, non-zero otherwise. This needs no shell, no `curl`/`wget`, and is cheap and side-effect free. (The other options — a wget-only debug image, a sidecar, or relying on process-alive — are all weaker or heavier; a purpose-built binary is the clean distroless answer.) The run showed `Up 15 seconds (healthy)`.

**f) Why does the named volume survive `docker compose down`? What destroys it?**
`docker compose down` removes the containers and the default network but leaves named volumes untouched — the data in `quicknotes-data` lives independently of any container, so the note survived a `down` + `up`. It is destroyed by `docker compose down -v` (or `docker volume rm quicknotes-data`), which is exactly what the test showed: after `down -v` the note was gone.

**g) `depends_on` without `condition: service_healthy` — what does it wait for?**
Plain `depends_on` only waits for the dependency container to be *created/started*, not for it to be *ready*. So a dependent service can start talking to a database (or QuickNotes) while it is still booting and not yet accepting connections — a race that shows up as flaky "connection refused" at startup. `depends_on: { <svc>: { condition: service_healthy } }` makes Compose wait for the dependency's healthcheck to pass first, closing that race.

## Bonus — The 6 Security Defaults

All six applied to the `quicknotes` service and verified:

| # | Default | Evidence |
|---|---------|----------|
| 1 | `USER nonroot` | `docker inspect … .Config.User` → `65532:65532` |
| 2 | distroless / no shell | `docker compose exec quicknotes sh` → fails, no shell in the image |
| 3 | drop all capabilities | `.HostConfig.CapDrop` → `[ALL]` |
| 4 | read-only root fs (+ tmpfs) | `.HostConfig.ReadonlyRootfs` → `true`, `Tmpfs` → `map[/tmp:]` |
| 5 | `no-new-privileges` | `.HostConfig.SecurityOpt` → `[no-new-privileges:true]` |
| 6 | Trivy scan | see below |

Under all five runtime constraints the service still served `{"notes":4,"status":"ok"}`.

### Trivy scan (HIGH/CRITICAL)

```
Target                          Type       Vulnerabilities
quicknotes:lab6 (debian 13.6)   debian     0
healthcheck                     gobinary   19  (HIGH: 19, CRITICAL: 0)
quicknotes                      gobinary   19  (HIGH: 19, CRITICAL: 0)
```

The distroless base itself is **clean (0)** — the value of a minimal base. The 19 HIGH findings are all Go **stdlib** CVEs (built on `go1.24.13`; each is fixed in a later Go patch such as `1.25.x` / `1.26.x`), with **0 CRITICAL**. They are closed by rebuilding on a newer Go toolchain rather than by anything in the image layout.

### B.4 — Which default gives the most security per line of YAML?

`cap_drop: [ALL]` — a single line removes every Linux capability from the container. Capabilities are the main lever for in-container privilege escalation (raw sockets, mounting, changing ownership, loading modules), and QuickNotes needs none of them (it binds a high port, no privileged syscalls). One line therefore closes the entire capability-based escalation surface at zero functional cost. `read_only: true` and `no-new-privileges` are close behind, but capability dropping removes the broadest class of abuse for the least YAML.
