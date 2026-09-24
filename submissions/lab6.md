# Lab 6 — Dockerize QuickNotes

**Setup:** MacBook Air (Apple Silicon), Docker Desktop 29.2.1.

## Task 1 — Multi-stage Dockerfile

**Dockerfile:** [`app/Dockerfile`](../app/Dockerfile)

- Builder: `golang:1.24-alpine`. `go.mod` is copied and `go mod download` runs before `COPY . .`.
- Build: `CGO_ENABLED=0 go build -trimpath -ldflags='-s -w'` (static, stripped binary)
- Runtime: `gcr.io/distroless/static-debian12:nonroot`, with `USER nonroot`, `EXPOSE 8080` and exec-form `ENTRYPOINT ["/app/quicknotes"]`
- A tiny second binary, `/app/healthcheck` ([`app/cmd/healthcheck`](../app/cmd/healthcheck/main.go)), is used for the healthcheck because distroless has no shell or curl (see question e)
- `/data` is created owned by UID 65532, so the named volume is writable for nonroot

**Image size:**

```console
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   e94c505841c8       21.5MB         5.22MB

$ docker images golang:1.24-alpine
IMAGE                ID             DISK USAGE   CONTENT SIZE
golang:1.24-alpine   8bee1901f1e5        388MB         80.1MB
```

**21.5 MB** (limit 25 MB), which is about 18× smaller than the builder image.

**Config:**

```console
$ docker inspect quicknotes:lab6 --format 'User={{.Config.User}} Ports={{json .Config.ExposedPorts}} Entrypoint={{json .Config.Entrypoint}}'
User=nonroot:nonroot  Ports={"8080/tcp":{}}  Entrypoint=["/app/quicknotes"]
```

**Run test:**

```console
$ docker run -d --name qn-test -p 8080:8080 quicknotes:lab6
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
$ curl -s http://localhost:8080/notes
[{"id":2,"title":"Read app/main.go first", ...
$ docker ps --filter name=qn-test --format '{{.Names}}  {{.Status}}'
qn-test  Up 27 seconds (healthy)
```

### Design questions

**a) Layer order.** Docker reuses a cached layer only if that layer and all layers before it are unchanged. I edited one file in `app/` and rebuilt with both orders:

| Order | What re-ran after the edit | Rebuild time |
|---|---|---:|
| `COPY . .` → `go mod download` → `go build` | `COPY`, **`go mod download`**, `go build` | 4.38 s |
| `COPY go.mod` → `go mod download` → `COPY . .` → `go build` | `COPY . .`, `go build` (`go mod download` = **CACHED**) | 4.51 s |

The times are almost the same because QuickNotes has **no dependencies** (no `go.sum`), so `go mod download` has nothing to download. The cache log still shows the difference: with the bad order, every code edit re-runs the dependency download. In a real project with dependencies, that means re-downloading all of them on every commit. The good order only re-downloads when `go.mod`/`go.sum` change.

**b) `CGO_ENABLED=0`.** It makes Go build a fully static binary that doesn't need the C library (libc). `distroless/static` has no libc and no dynamic linker. With CGO on, the binary would be linked against libc and fail to start with a confusing `no such file or directory`: the file that's missing is the linker, not the binary.

**c) `distroless/static:nonroot`.** A minimal base image from Google that has only CA certificates, timezone data, `/etc/passwd` with a `nonroot` user (UID 65532), and a `/tmp`. It has no shell, no package manager and no libc. Fewer packages means fewer CVEs: Trivy found **0** vulnerabilities in the base layer (see Bonus). An attacker who gets in also has no shell or tools to use.

**d) `-ldflags='-s -w'` and `-trimpath`.** `-s -w` removes the symbol table and debug info, so the binary is smaller. The cost is that you can't debug it with a debugger like `delve`, though panics still show stack traces. `-trimpath` removes my local file paths (like `/Users/ilmira/...`) from the binary. This makes builds reproducible on any machine and doesn't leak paths. The cost is that stack traces show module paths instead of full local paths.

## Task 2 — Compose + healthcheck + volume

**compose.yaml** (repo root):

```yaml
services:
  quicknotes:
    build: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: /data/notes.json
      SEED_PATH: /app/seed.json
    volumes:
      - quicknotes-data:/data
    healthcheck:
      test: ["CMD", "/app/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped

    # --- Bonus: security defaults ---
    user: "65532:65532"
    cap_drop: [ALL]
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true

volumes:
  quicknotes-data:
```

**Persistence test:**

```console
=== 1. add note
$ curl -X POST ... -d '{"title":"durable","body":"survive a restart"}' http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T19:50:01.736697629Z"}
$ curl -s http://localhost:8080/notes | grep -o '"title":"durable"'
"title":"durable"

=== 2. docker compose down -> up
 ✔ Container devops-intro-quicknotes-1 Removed
 ✔ Network devops-intro_default        Removed
"title":"durable"                     ← still there

=== 3. docker compose down -v -> up
 ✔ Volume devops-intro_quicknotes-data Removed
NOT FOUND                             ← gone with the volume

$ docker compose ps
NAME                        IMAGE             STATUS
devops-intro-quicknotes-1   quicknotes:lab6   Up 5 seconds (healthy)
```

### Design questions

**e) Healthcheck without a shell.** I used **a binary that's in the image**. I wrote a ~20-line Go program (`cmd/healthcheck`) that requests `http://127.0.0.1:8080/health` and exits 0 on HTTP 200 and 1 otherwise. It's built static in the same builder stage and called in exec form (`["CMD", "/app/healthcheck"]`), so no shell is needed. This checks that the app actually answers, not just that the process is alive. It adds about 5 MB and no shell, curl or wget, and the status shows `(healthy)`.

**f) Why the volume survives `down`.** A named volume is managed by Docker separately from containers. `docker compose down` removes containers and networks but keeps named volumes, so the new container mounts the same data. It's destroyed by `docker compose down -v`, `docker volume rm`, or `docker volume prune` (shown in step 3 above).

**g) `depends_on` without `condition: service_healthy`.** It only waits until the other container has **started**, not until the app inside is ready. The bug: e.g. an app starts before its database is accepting connections, fails on the first request and crashes or retries. With `condition: service_healthy`, Compose waits for the healthcheck to pass.

## Bonus — 6 security defaults

All six are applied in the `compose.yaml` above and the Dockerfile.

| # | Default | Proof |
|---|---|---|
| 1 | `USER nonroot` | `docker inspect quicknotes:lab6 --format '{{ .Config.User }}'` → `nonroot:nonroot` |
| 2 | Distroless, no shell | `docker compose exec quicknotes sh` → `exec: "sh": executable file not found in $PATH` (exit 127) |
| 3 | All capabilities dropped | `CapDrop=[ALL]` |
| 4 | Read-only root + tmpfs | `ReadonlyRootfs=true  Tmpfs={"/tmp":""}` + write test below |
| 5 | `no-new-privileges` | `SecurityOpt=[no-new-privileges:true]` |
| 6 | Trivy scan | below |

```console
$ docker inspect devops-intro-quicknotes-1 --format 'CapDrop={{.HostConfig.CapDrop}}  ReadonlyRootfs={{.HostConfig.ReadonlyRootfs}}  SecurityOpt={{.HostConfig.SecurityOpt}}  Tmpfs={{json .HostConfig.Tmpfs}}'
CapDrop=[ALL]  ReadonlyRootfs=true  SecurityOpt=[no-new-privileges:true]  Tmpfs={"/tmp":""}
```

**Read-only test.** With no shell there's no `touch`, so I used the QuickNotes binary itself. I started a second copy inside the container and pointed its data file at `/home/nonroot`, a folder the nonroot user owns. Without `read_only` this write would succeed:

```console
$ docker compose exec -e ADDR=:9999 -e DATA_PATH=/home/nonroot/notes.json quicknotes /app/quicknotes
2026/09/24 19:51:50 seed: open /home/nonroot/notes.json: read-only file system
```

**Trivy** (`aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL quicknotes:lab6`):

```text
quicknotes:lab6 (debian 12.15)
Total: 0 (HIGH: 0, CRITICAL: 0)

app/healthcheck (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)

app/quicknotes (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)
```

The distroless base has **0** HIGH/CRITICAL. All 19 findings are in the **Go standard library 1.24.13** compiled into my two binaries, mostly DoS bugs in `net/http`, `crypto/tls` and `crypto/x509`. They are only fixed in Go **1.25.x / 1.26.x**. Go 1.24 no longer gets security updates, so 1.24.13 is its last release. The lab requires Go 1.24, so I kept it. The real fix is to raise the builder to a supported Go version (e.g. `golang:1.26-alpine`) and rebuild. This shows why the scan must run in CI (Lab 9): the image was "clean" when Go 1.24 was current and became vulnerable without any change to my code.

**Most security per line of YAML:** I think `read_only: true` and `cap_drop: [ALL]`. Each is one line, and together they stop most of what an attacker does after breaking in: dropping tools or malware into the filesystem, changing configs, or using root-like powers (network tricks, changing file owners). They also didn't break anything, because QuickNotes only writes to `/data`. Distroless + nonroot matter just as much but are set in the Dockerfile, not the YAML.
