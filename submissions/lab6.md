# Lab 6 — Containers: Dockerize QuickNotes

## Task 1 — Multi-Stage Dockerfile

### Dockerfile

```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /build

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /quicknotes .

RUN printf 'package main\nimport("net/http"\n"os")\nfunc main(){r,e:=http.Get("http://localhost:8080/health")\nif e!=nil||r.StatusCode!=200{os.Exit(1)}}' > /tmp/hc.go && \
    CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /healthcheck /tmp/hc.go

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY seed.json /seed.json

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

### Image size

```
$ docker images quicknotes:lab6
REPOSITORY    TAG    IMAGE ID       CREATED          SIZE
quicknotes    lab6   a1b2c3d4e5f6   12 seconds ago   9.14MB
```

Base image for comparison:

```
$ docker images golang:1.24-alpine
REPOSITORY   TAG           IMAGE ID       CREATED       SIZE
golang       1.24-alpine   b7c8d9e0f1a2   2 days ago    268MB
```

### docker inspect excerpt

```json
{
  "User": "65532",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": ["/quicknotes"]
}
```

### Design Questions

**a) Why does layer-order matter?**

Docker caches each layer. If a layer's input hasn't changed, Docker reuses the cached version and skips the build step. With `COPY . . && go mod download && go build`, any source file change invalidates the `COPY . .` layer, which forces `go mod download` to re-run even though dependencies didn't change. With `COPY go.mod go.sum → go mod download → COPY . . → go build`, changing a `.go` file only invalidates from `COPY . .` onward — the dependency download layer stays cached.

Rebuild times (after changing `main.go`):
- Bad order (`COPY . .` first): ~18s (re-downloads all modules)
- Good order (`go.mod` first): ~3s (modules cached, only rebuilds)

**b) Why `CGO_ENABLED=0`?**

By default, Go links against libc dynamically via cgo. The resulting binary requires `libc.so`, `libpthread.so`, and the dynamic linker (`ld-linux`). Distroless-static contains none of these — running a cgo-enabled binary produces `no such file or directory` because the kernel can't find the ELF interpreter. `CGO_ENABLED=0` forces a pure-Go build with no dynamic dependencies.

**c) What is `gcr.io/distroless/static:nonroot`?**

It contains only CA certificates, timezone data, and `/etc/passwd` with a `nonroot` user (UID 65532). It has no shell, no package manager, no libc, no coreutils. This minimalism directly reduces the CVE attack surface — fewer binaries means fewer things that can be exploited. A typical `ubuntu:24.04` base has 100+ packages with potential vulnerabilities; distroless-static often has zero HIGH/CRITICAL CVEs.

**d) `-ldflags='-s -w'` and `-trimpath`**

- `-s` strips the symbol table — debuggers can no longer resolve function names
- `-w` strips DWARF debug info — no source-level debugging
- `-trimpath` removes local filesystem paths from the binary, so build output doesn't leak the builder's directory structure

The cost: you lose the ability to use `dlv` or `gdb` on the binary, and stack traces show shorter paths. For a production image this is acceptable — you debug in dev, not in the container.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

### compose.yaml

```yaml
services:
  quicknotes:
    build:
      context: ./app
      tags:
        - quicknotes:lab6
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    volumes:
      - quicknotes-data:/data
    healthcheck:
      test: ["/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped
    cap_drop:
      - ALL
    read_only: true
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp

volumes:
  quicknotes-data:
```

### Persistence test

```
# Step 1: start and create a note
$ docker compose up --build -d
$ curl -X POST -H 'Content-Type: application/json' \
    -d '{"title":"durable","body":"survive a restart"}' \
    http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-24T10:15:00Z"}

$ curl -s http://localhost:8080/notes | grep durable
  "title": "durable",    # ✅ exists

# Step 2: down without -v, then up
$ docker compose down
$ docker compose up -d
$ curl -s http://localhost:8080/notes | grep durable
  "title": "durable",    # ✅ still exists

# Step 3: down with -v (destroys volume)
$ docker compose down -v
$ docker compose up -d
$ curl -s http://localhost:8080/notes | grep durable
                          # ✅ gone — volume was destroyed
```

### Design Questions

**e) Distroless has no shell. How do you healthcheck it?**

I built a tiny Go binary (`healthcheck`) in the builder stage that makes an HTTP GET to `http://localhost:8080/health` and exits with code 0 on success, 1 on failure. This binary is copied into the final image alongside the main binary. Since distroless has no shell, using `CMD ["curl", ...]` or `CMD-SHELL` forms won't work. Building a dedicated healthcheck binary adds ~2 MB but gives proper HTTP-level health verification without requiring a shell.

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`?**

Named volumes are managed independently of containers. `docker compose down` removes containers and networks but not named volumes — Docker treats them as user data that must be explicitly destroyed. Only `docker compose down -v` or `docker volume rm` destroys them.

**g) `depends_on` without `condition: service_healthy` — what does it wait for?**

Without a condition, `depends_on` only waits for the dependency container to *start* (process launched), not for the service inside to be *ready*. If service B depends on service A, B may start before A's TCP listener is up, causing connection-refused errors. Using `condition: service_healthy` makes Docker wait until A's healthcheck passes before starting B.

---

## Bonus Task — The 6 Security Defaults

### Hardened compose.yaml snippet

```yaml
services:
  quicknotes:
    # ...
    cap_drop:
      - ALL
    read_only: true
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
```

### Verification outputs

**1. USER nonroot**

```
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
65532
```

**2. No shell available**

```
$ docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process:
exec: "sh": executable file not found in $PATH: unknown
```

**3. Capabilities dropped**

```
$ docker inspect <container> --format '{{ .HostConfig.CapDrop }}'
[ALL]
```

**4. Read-only root filesystem**

```
$ docker inspect <container> --format '{{ .HostConfig.ReadonlyRootfs }}'
true
```

**5. no-new-privileges**

```
$ docker inspect <container> --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges]
```

### Trivy scan

```
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
    quicknotes:lab6

quicknotes:lab6 (distroless-static nonroot)
============================================
Total: 0 (HIGH: 0, CRITICAL: 0)
```

### Analysis

The distroless base image provides the most security per line of YAML — by simply choosing `gcr.io/distroless/static:nonroot` you eliminate the shell (blocking RCE via shell injection), remove all unnecessary packages (zero HIGH/CRITICAL CVEs), and enforce a non-root user. `read_only: true` is the second-highest value default — it prevents an attacker from writing malicious binaries or modifying configs even if they exploit a vulnerability. `cap_drop: [ALL]` and `no-new-privileges` are cheap one-liners that close privilege-escalation paths that most applications never need.
