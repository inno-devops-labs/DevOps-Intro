# Lab 6 Submission

## Task 1 — Multi-Stage Dockerfile

### Dockerfile (`app/Dockerfile`)

```dockerfile
# builder stage
FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes

# runtime stage
FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /quicknotes

COPY --from=builder /src/seed.json ./seed.json


EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/quicknotes"]
```


### Image Size Verification

```bash
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   f2ca1d6c0dc6       15.5MB         3.55MB
```

**Result: 15.5 MB <= 25 MB**

### Docker Inspect Output

```bash
$ docker inspect quicknotes:lab6 --format '{{json .Config}}'
{"User":"nonroot:nonroot","ExposedPorts":{"8080/tcp":{}},"Env":["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin","SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"],"Entrypoint":["/quicknotes"],"WorkingDir":"/app"}
```

### Base Image Comparison

- `golang:1.24-alpine`: **395 MB**
- `quicknotes:lab6` (distroless/static:nonroot): **15.5 MB**

**Reduction: 96%**

### Design Questions

**a) Why does layer-order matter?**

Layer order determines cache reuse efficiency. Dependencies change rarely; source code changes often.

**Strategy 1 (BAD):**
```dockerfile
COPY . .
RUN go mod download
RUN go build
```
Any source code change invalidates the `go mod download` layer -> full re-download of all dependencies (rebuild takes more time).

**Strategy 2 (GOOD):**
```dockerfile
COPY go.mod ./
RUN go mod download
COPY . .
RUN go build
```
Source code change only invalidates the last two layers; dependencies stay cached (much faster rebuild).



**b) Why `CGO_ENABLED=0`? What happens in distroless-static if you forget it?**

`CGO_ENABLED=0` produces a statically-linked binary with no external dependencies. Distroless-static contains no libc and no dynamic linker (`/lib/ld-linux.so`).

If you forget `CGO_ENABLED=0`:
- Go builds a dynamically-linked binary that expects `/lib/ld-linux.so` to exist
- Distroless-static doesn't have it
- Container fails at startup with: `exec: no such file or directory`
- The binary exists but the dynamic linker it needs is missing

**c) What is `gcr.io/distroless/static:nonroot`?**

A minimal base image from Google containing only the runtime artifacts needed to run a static binary:
- Static binary runtime (nothing else)
- No shell (`sh`, `bash`)
- No package manager (`apt`, `apk`)
- No utilities (`curl`, `wget`, `ls`)
- No dynamic linker (`/lib/ld-linux.so`)

The `nonroot` tag sets UID/GID to 65532 (non-root user).

**Why it matters for CVEs:** With almost no software present, the attack surface shrinks to near zero. There's no shell for shell injection, no package manager to exploit, no utilities for reconnaissance. Even if an attacker compromises the application, they can't escalate privileges or move laterally because there's nothing else in the container to exploit.

**d) `-ldflags='-s -w'` and `-trimpath`: what does each flag do, and what's the cost?**

- `-s`: strips the symbol table (removes function names from binary)
- `-w`: strips DWARF debugging information (removes debug symbols)
- `-trimpath`: removes local filesystem paths from the compiled binary, improving reproducibility

**Cost:** Loss of debuggability. Stack traces lose file paths and line numbers, making post-mortem debugging harder. Binary size drops ~20-30%.

For production containers, this trade-off is acceptable — you debug with logs and metrics, not by attaching a debugger to the binary.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

### `compose.yaml`

```yaml
services:
  # One-shot init: fixes ownership of the named volume so the nonroot app
  # (UID 65532) can write to /data. Runs to completion before quicknotes starts.
  init-data:
    image: busybox:1.36
    command: ["sh", "-c", "chown -R 65532:65532 /data"]
    volumes:
      - quicknotes-data:/data
    restart: "no"

  quicknotes:
    build: ./app
    image: quicknotes:lab6
    depends_on:
      init-data:
        condition: service_completed_successfully
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/app/seed.json"
    volumes:
      - quicknotes-data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/quicknotes", "-healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s

volumes:
  quicknotes-data:
```

### Persistence Test Output

**Step 1: Check health (seed loaded)**
```bash
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

**Step 2: Create note**
```bash
$ curl -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T12:35:15.272673189Z"}
```

**Step 3: Verify note exists**
```bash
$ curl -s http://localhost:8080/notes | grep durable
[{"id":1,"title":"Welcome to QuickNotes",...},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T12:35:15.272673189Z"}]
```

**Step 4: `docker compose down` (no `-v`)**
```bash
$ docker compose down
[+] down 3/3
 ✔ Container devops-intro-quicknotes-1 Removed
 ✔ Container devops-intro-init-data-1  Removed
 ✔ Network devops-intro_default        Removed
```

**Step 5: `docker compose up -d`**
```bash
$ docker compose up -d
[+] up 3/3
 ✔ Network devops-intro_default        Created
 ✔ Container devops-intro-init-data-1  Exited
 ✔ Container devops-intro-quicknotes-1 Started
```

**Step 6: Note STILL exists**
```bash
$ curl -s http://localhost:8080/notes | grep durable
[{"id":4,"title":"Endpoint cheat-sheet",...},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T12:35:15.272673189Z"},...]
```

**Step 7: `docker compose down -v` (volume destroyed)**
```bash
$ docker compose down -v
[+] down 4/4
 ✔ Container devops-intro-quicknotes-1 Removed
 ✔ Container devops-intro-init-data-1  Removed
 ✔ Volume devops-intro_quicknotes-data Removed
 ✔ Network devops-intro_default        Removed
```

**Step 8: `docker compose up -d`**
```bash
$ docker compose up -d
[+] up 4/4
 ✔ Network devops-intro_default        Created
 ✔ Volume devops-intro_quicknotes-data Created
 ✔ Container devops-intro-init-data-1  Exited
 ✔ Container devops-intro-quicknotes-1 Started
```

**Step 9: Note is GONE**
```bash
$ curl -s http://localhost:8080/notes | grep durable
# (no output - only seed notes remain)
```

### Design Questions

**e) Distroless has no shell. How do you healthcheck it?**

Strategy: modification of `main.go` (added `-healthcheck` flag to enable self-probing) - use a binary already present in the image.

Since QuickNotes is the only binary in the distroless image, the healthcheck invokes it directly with a healthcheck flag (`["CMD", "/quicknotes", "-healthcheck"]`). The binary performs an HTTP request to its own `/health` endpoint and exits 0/1.


Alternative strategies:
- **Sidecar container**: Run a separate container with `curl`/`wget` to check health — adds complexity
- **Debug image variant**: Use `gcr.io/distroless/static:debug-nonroot` which includes a shell and busybox tools — breaks the security model
- **Process check only**: Rely on Docker's default behavior of checking if the process is alive — doesn't verify the service is actually healthy

The chosen strategy (invoke the binary itself) is the cleanest: no extra containers, no shell, no additional attack surface.



**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`?**

Named volumes are Docker-managed resources, independent of containers. `docker compose down` removes containers and networks but intentionally preserves volumes — data is assumed valuable and should persist by default.

Only `docker compose down -v` explicitly destroys volumes. This design prevents accidental data loss. If you want to destroy the data, you must explicitly opt-in with `-v`.

**g) `depends_on` without `condition: service_healthy` — what does it actually wait for?**

Without `condition: service_healthy`, `depends_on` only waits for the container to **start**, not for the service inside to be **ready**.

**Bug scenario:** If `quicknotes` depends on `redis`, quicknotes may start before redis accepts connections, causing `connection refused` errors on startup. The container is "up" (process running) but the service isn't healthy (not accepting connections yet).

Using `condition: service_healthy` makes Compose wait for the healthcheck to pass before starting dependent services, ensuring the service is actually ready to accept connections.

In our case, we use `depends_on` with `condition: service_completed_successfully` for the init-data container, ensuring the volume has correct permissions before quicknotes starts.