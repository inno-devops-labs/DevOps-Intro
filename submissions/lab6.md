# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-Stage Dockerfile, ≤ 25 MB (6 pts)

### Dockerfile (`app/Dockerfile`)

```dockerfile
FROM golang:1.24 AS builder

WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags='-s -w' -trimpath -o /quicknotes
RUN mkdir -p /data && chown 65532:65532 /data

RUN mkdir -p /healthcheck-src && cat > /healthcheck-src/main.go <<'GOEOF'
package main
import (
	"io"
	"net/http"
	"os"
)
func main() {
	resp, err := http.Get("http://localhost:8080/health")
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()
	io.Copy(io.Discard, resp.Body)
	if resp.StatusCode != 200 {
		os.Exit(1)
	}
}
GOEOF
RUN CGO_ENABLED=0 go build -ldflags='-s -w' -o /healthcheck /healthcheck-src/main.go

FROM gcr.io/distroless/static:nonroot

COPY --from=builder --chown=65532:65532 /data /data
COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY --from=builder /src/seed.json /seed.json

EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
```

### Build + verify

```bash
❯ docker build -t quicknotes:lab6 ./app/
# ... build output ...

❯ docker images quicknotes:lab6 --format '{{.Size}}'
13MB

❯ docker inspect quicknotes:lab6 --format 'User={{.Config.User}} Entrypoint={{.Config.Entrypoint}} ExposedPorts={{.Config.ExposedPorts}}'
User=65532 Entrypoint=[/quicknotes] ExposedPorts=map[8080/tcp:{}]

❯ docker images golang:1.24 --format '{{.Size}}'
911MB
```

After multi-stage distroless: **13 MB** (vs 911 MB for the full golang toolchain).

### Design questions (1.2)

**a) Why does layer-order matter?**

With the wrong order (`COPY . . && go mod download && go build`), any source file change invalidates the `go mod download` cache layer, forcing a full re-download on every rebuild. With the correct order (`COPY go.mod ./ && go mod download` then later `COPY . . && go build`), changing source code only invalidates the build layer — the module cache is reused. For a project with many dependencies, this saves 30-60 seconds per rebuild; for QuickNotes (stdlib only) the difference is small, but the pattern is essential for any real project.

**b) Why `CGO_ENABLED=0`?**

Go defaults to `CGO_ENABLED=1`, which produces a binary linked against glibc (or the host C library). In a distroless-static image, there is no glibc — the dynamic linker is missing entirely. Without `CGO_ENABLED=0`, the binary would fail with a misleading "file not found" error when executed, because the system can't find the ELF interpreter. Setting it to 0 produces a fully static binary that has no runtime dependencies on any shared library.

**c) What is `gcr.io/distroless/static:nonroot`?**

It's a minimal container image from Google containing only the essentials: glibc, libssl, and a CA certificate bundle — no shell, no package manager, no utilities. It runs as UID 65532 (nonroot). Because there is no shell or package manager, the attack surface is drastically reduced: there is no `apt` to exploit, no shell to break into, no Python or Perl to pivot with. For CVE counts, this means the system package count is ~5 (vs 100+ in ubuntu:latest), so critical vulnerabilities are rare to non-existent.

**d) `-ldflags='-s -w'` and `-trimpath` — what do they do?**

`-ldflags='-s -w'` strips the symbol table (`-s`) and DWARF debug info (`-w`) from the binary, reducing its size by about 30-40%. The cost is that stack traces no longer contain function names or file locations — you lose post-mortem debugging capability. `-trimpath` removes the absolute build paths from the binary (e.g., `/home/user/go/src/...` becomes just the package path), improving reproducibility: two builds from different directories produce identical binaries.

---

## Task 2 — Compose + Healthcheck + Persistent Volume (4 pts)

### `compose.yaml` (repo root)

```yaml
services:
  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      - ADDR=:8080
      - DATA_PATH=/data/notes.json
      - SEED_PATH=/seed.json
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp

volumes:
  quicknotes-data:
```

### Persistence test (3 steps)

```bash
# Step 1: Create note, verify it exists
❯ docker compose up --build -d
❯ sleep 3
❯ curl -X POST -H 'Content-Type: application/json' \
    -d '{"title":"durable","body":"survive a restart"}' \
    http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T15:41:15.835790452Z"}
❯ curl -s http://localhost:8080/notes | grep durable
"title":"durable","body":"survive a restart"

# Step 2: docker compose down (NOT -v) → up → data survives
❯ docker compose down
❯ docker compose up -d
❯ sleep 3
❯ curl -s http://localhost:8080/notes | grep durable
"title":"durable","body":"survive a restart"   # ✅ Still present

# Step 3: docker compose down -v → up → data gone
❯ docker compose down -v
❯ docker compose up -d
❯ sleep 3
❯ curl -s http://localhost:8080/notes | grep durable
# ⚠️ (exit code 1 — data gone, as expected)
```

### Design questions (2.2)

**e) Distroless has no shell. How do you healthcheck it?**

I compiled a tiny Go HTTP healthcheck binary in the builder stage and copied it into the runtime image. The binary does a simple `http.Get("http://localhost:8080/health")` and exits 0 on 200, 1 otherwise. This keeps the runtime image distroless with no shell or package manager, while giving us a real HTTP healthcheck. The alternative approaches (sidecar container, wget-only debug image) add complexity or image size; the custom Go binary adds < 2 MB and has zero dependencies.

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`?**

`docker compose down` removes containers and networks but **preserves named volumes** by default. Named volumes are managed Docker resources with their own lifecycle — they persist until explicitly removed with `docker compose down -v` or `docker volume rm`. The data inside the volume (the notes.json file) is stored in Docker's storage area on the host, not in the container's writable layer.

**g) `depends_on` without `condition: service_healthy` — what does it actually wait for?**

`depends_on` without a condition only waits for the container to be **started** (i.e., `docker create` + `docker start`), not for the service inside to be ready. This means a database container might be "started" but still initializing, and the app container will likely fail its first connection attempt. The bug manifests as intermittent failures on startup, especially after a cold start or restart. The fix is `condition: service_healthy` combined with a proper healthcheck.

---

## Bonus Task — The 6 Security Defaults (2 pts)

### Hardened `compose.yaml` snippet

```yaml
services:
  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      - ADDR=:8080
      - DATA_PATH=/data/notes.json
      - SEED_PATH=/seed.json
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
```

### Verification outputs

**1. USER nonroot** — binary runs as UID 65532, never as root:
```
❯ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
65532
```

**2. No shell available** — distroless has no sh, no bash, no busybox:
```
❯ docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process:
exec: "sh": executable file not found in $PATH
```

**3. All capabilities dropped** — zero Linux capabilities granted:
```
❯ docker inspect devops-intro-quicknotes-1 --format '{{ .HostConfig.CapDrop }}'
[ALL]
```

**4. Read-only root filesystem** — only /data (volume) and /tmp (tmpfs) are writable:
```
❯ docker inspect devops-intro-quicknotes-1 --format 'ReadOnly={{ .HostConfig.ReadonlyRootfs }}, Tmpfs={{ .HostConfig.Tmpfs }}'
ReadOnly=true, Tmpfs=map[/tmp:]
```

**5. no-new-privileges** — the container can never escalate privileges:
```
❯ docker inspect devops-intro-quicknotes-1 --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
```

### Trivy scan

```bash
❯ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
    quicknotes:lab6
```

**OS packages (debian 13.5):** 0 HIGH, 0 CRITICAL
**Go stdlib (quicknotes binary):** 13 HIGH (stdlib CVEs), 0 CRITICAL
**Go stdlib (healthcheck binary):** 13 HIGH (stdlib CVEs), 0 CRITICAL

The distroless base image itself contains no HIGH or CRITICAL vulnerabilities across all 5 system packages. The 13 HIGH findings are all in Go's standard library (CVE-2026-25679, CVE-2026-27145, etc.) and affect the stdlib at Go 1.24.13 — these would be resolved by rebuilding with a patched Go version.

### Which of the 6 defaults gives the most security per line of YAML?

**`cap_drop: [ALL]`** — one line of YAML eliminates every Linux capability, which means the container cannot perform any privileged operation: no raw sockets, no `ptrace`, no `mount`, no `setuid`, no `net_raw`. Combined with distroless (no shell to `capsh` from), this makes container escape via kernel exploit substantially harder. Dropping capabilities costs nothing in functionality for an HTTP microservice, yet it removes entire classes of kernel-based privilege escalation attacks.
