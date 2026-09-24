# Lab 6 — Containers: Dockerize QuickNotes

## Task 1

### Dockerfile

```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/quicknotes .

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/healthcheck ./cmd/healthcheck

RUN mkdir -p /out/data && touch /out/data/.keep

FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY --chown=65532:65532 seed.json /app/seed.json

USER nonroot

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

### Image size

```text
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   bf4d78f346fe         23MB         5.76MB
```

The final image is 23 MB, which is below the 25 MB limit.

### Image configuration

```json
{
  "User": "nonroot",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/quicknotes"
  ]
}
```

### Builder image comparison

```text
IMAGE                ID             DISK USAGE   CONTENT SIZE
golang:1.24-alpine   8bee1901f1e5        395MB         83.5MB
```

The final distroless image is 23 MB instead of the 395 MB builder image.

### Design answers

#### a) Why does layer order matter?

Docker reuses a layer only while that layer and all preceding layers have unchanged inputs. With `COPY . .` before `go mod download`, every source change invalidates the dependency-download layer. With `COPY go.mod ./` followed by `go mod download`, a source-only change keeps the dependency layer cached.

I tested both equivalent multi-stage Dockerfiles after changing a file in the build context:

```text
Bad order:       COPY . . -> go mod download -> go build
Rebuild time:    21.773 s

Good order:      COPY go.mod -> go mod download -> COPY . . -> go build
Rebuild time:    20.941 s
```

The bad-order build executed `go mod download` again, while the good-order build showed that layer as `CACHED`. The difference is small because this project has almost no external Go dependencies; it becomes much larger in projects with a large `go.sum`.

#### b) Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` builds a static Go binary without depending on a C runtime or dynamic linker. A binary that depends on dynamic libraries cannot start in `distroless/static`, because that image does not contain the dynamic linker and shared libraries. The typical startup error is `no such file or directory` even when the binary file itself exists.

#### c) What is `gcr.io/distroless/static:nonroot`?

It is a minimal runtime image intended for statically linked executables and configured with the unprivileged `nonroot` user. It contains only the minimal runtime files needed by such applications, rather than a shell, package manager, compiler, or general-purpose utilities. Fewer installed packages and no interactive shell reduce the attack surface and the number of OS-package CVEs.

#### d) What do `-ldflags="-s -w"` and `-trimpath` do?

`-ldflags="-s -w"` removes the symbol table and DWARF debug information, reducing binary size. `-trimpath` removes local filesystem paths from the compiled binary, making builds more reproducible across machines. The trade-off is less detailed debugging information and less convenient stack-trace/source-path analysis.

## Task 2

### compose.yaml

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
      DATA_PATH: /data/notes.json
      SEED_PATH: /app/seed.json
    volumes:
      - quicknotes-data:/data
    healthcheck:
      test: ["CMD", "/healthcheck"]
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

The healthcheck uses `/healthcheck`, a small static Go binary included in the image. It sends an HTTP request to `http://127.0.0.1:8080/health` and exits with status 0 only for HTTP 200.

### Persistence test

```text
POST /notes:
{"id":5,"title":"durable","body":"survive a restart"}

Before docker compose down:
... "title":"durable","body":"survive a restart" ...

After docker compose down and docker compose up -d:
... "title":"durable","body":"survive a restart" ...

After docker compose down -v and docker compose up -d:
durable is absent (expected)
```

### Design answers

#### e) Distroless has no shell. How do you healthcheck it?

A shell-form healthcheck cannot work because distroless has no shell, `curl`, or `wget`. I added a small static Go HTTP client at `app/cmd/healthcheck/main.go` and use exec-form Compose healthcheck syntax: `["CMD", "/healthcheck"]`. Docker executes that binary directly inside the container.

#### f) Why does the named volume survive `docker compose down`?

A named volume is Docker-managed storage separate from the container writable layer. `docker compose down` removes containers and networks but keeps named volumes by default, so `quicknotes-data` remains available to the next container. `docker compose down -v`, `docker volume rm`, or volume pruning removes it.

#### g) What does `depends_on` without `condition: service_healthy` wait for?

It only ensures that Docker starts the dependency container before the dependent container. It does not wait until the application inside that container is ready to accept requests. A dependent service can therefore start too early and fail with connection errors or an incomplete initialization race.

## Bonus — Security Defaults

### Hardened service configuration

The `quicknotes` service uses `USER nonroot` in the Dockerfile, a distroless runtime image, `cap_drop: [ALL]`, `read_only: true`, `no-new-privileges:true`, and a `tmpfs` mount at `/tmp`.

### Verification

```text
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
nonroot
```

```text
$ docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

```text
$ docker inspect <container-id> --format '{{ .HostConfig.CapDrop }}'
[ALL]
```

```text
$ docker inspect <container-id> --format 'ReadonlyRootfs={{ .HostConfig.ReadonlyRootfs }}'
ReadonlyRootfs=true
```

```text
$ docker compose exec -u 0 -e DATA_PATH=/etc/lab6-readonly-test -e SEED_PATH=/missing quicknotes /quicknotes
2026/09/24 19:47:06 seed: open /etc/lab6-readonly-test: read-only file system
```

```text
$ docker inspect <container-id> --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
```

### Trivy scan

Command:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image \
  --severity HIGH,CRITICAL \
  --no-progress \
  quicknotes:lab6
```

Summary:

```text
quicknotes:lab6 (debian 13.7)
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)

quicknotes (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)
```

The OS layer has no HIGH or CRITICAL findings. Trivy found the same Go standard-library findings in both static Go binaries; the installed Go version was `1.24.13`, while the reported fixes require newer Go releases. The lab requires Go 1.24, so I documented the findings rather than hiding them.

### Most security per line of YAML

For this service, `cap_drop: [ALL]` provides the most security per line because QuickNotes listens on unprivileged port 8080 and needs no Linux capabilities. It removes many privileged kernel operations without changing application code. `read_only: true` is a close second because it limits a compromise to the explicit writable mounts, especially `/data` and `/tmp`.
