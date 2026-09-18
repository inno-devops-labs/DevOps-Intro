# Lab 6 — Containers: Dockerize QuickNotes

## Environment

```text
Docker version 28.5.2, build ecc6942
Docker Compose version v5.0.2
Free disk space before the lab: 19G
```

---

# Task 1 — Multi-Stage Dockerfile, ≤ 25 MB

## Final `app/Dockerfile`

```dockerfile
# ---- Builder stage ----
FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags='-s -w' \
    -o /quicknotes \
    .

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags='-s -w' \
    -o /healthcheck \
    ./cmd/healthcheck

RUN mkdir -p /runtime-data && touch /runtime-data/.keep

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY seed.json /seed.json
COPY --from=builder --chown=65532:65532 /runtime-data/ /data/

USER nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
```

The builder uses Go 1.24. The final runtime is distroless and non-root. Both Go binaries are built statically with `CGO_ENABLED=0`, stripped with `-ldflags='-s -w'`, and built with `-trimpath`.

## Image size

```bash
docker images quicknotes:lab6
```

```text
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
quicknotes   lab6      dfe385138836   47 seconds ago   13.8MB
```

The final image is **13.8 MB**, below the required 25 MB limit.

Builder image for comparison:

```bash
docker images golang:1.24-alpine
```

```text
REPOSITORY   TAG           IMAGE ID       CREATED        SIZE
golang       1.24-alpine   ebe4e0721205   7 months ago   262MB
```

## Runtime verification

```bash
curl -s http://localhost:8080/health
```

```json
{"notes":0,"status":"ok"}
```

```bash
curl -s http://localhost:8080/notes
```

```json
[]
```

Image configuration:

```bash
docker inspect quicknotes:lab6 | jq '.[0].Config | {User, ExposedPorts, Entrypoint}'
```

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

## Design questions

### a) Why does layer order matter?

Docker can reuse a cached layer only while its inputs and previous layers remain unchanged. With `COPY . .` before `go mod download`, any source change invalidates the copy layer and forces the dependency step to run again. With `go.mod` copied first, the dependency layer stays cached until the dependency metadata itself changes.

Measured results:

| Strategy | Initial build | Rebuild after changing `handlers.go` |
|---|---:|---:|
| Bad: `COPY . .` before dependency download | 19.75 s | 18.97 s |
| Good: copy `go.mod` first | 19.61 s | 17.98 s |

The good rebuild showed:

```text
CACHED [builder 3/6] COPY go.mod ./
CACHED [builder 4/6] RUN go mod download
```

The bad rebuild executed `RUN go mod download` again. The project has almost no external dependencies, so the measured time difference is small, but the cache behavior is visible.

### b) Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` produces a Go binary without dependencies on C libraries or a system dynamic linker. This is required for a `distroless/static` runtime, which does not provide a normal libc-based userspace. Without a static binary, the program can fail to start because its dynamic loader or shared libraries are missing.

### c) What is `gcr.io/distroless/static:nonroot`?

It is a minimal runtime image for statically linked applications, configured to run as a non-root user. It does not contain a shell, package manager, compiler, or the normal utilities of a general-purpose Linux distribution. This reduces image size, attack surface, and package-level CVE exposure.

### d) What do `-ldflags='-s -w'` and `-trimpath` do?

`-s` removes the symbol table and `-w` removes DWARF debugging information, reducing binary size at the cost of less debugging information. `-trimpath` removes local build-system paths from compiled output, improving reproducibility and avoiding embedding developer-specific filesystem paths.

---

# Task 2 — Compose + Healthcheck + Persistent Volume

## Final `compose.yaml`

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
      test: ["CMD", "/healthcheck"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 2s

    restart: unless-stopped

    cap_drop:
      - ALL

    read_only: true

    tmpfs:
      - /tmp:size=16m,mode=1777

    security_opt:
      - no-new-privileges:true

volumes:
  quicknotes-data:
```

QuickNotes receives:

```text
ADDR=:8080
DATA_PATH=/data/notes.json
SEED_PATH=/seed.json
```

The healthcheck is a small static Go program copied into the distroless image as `/healthcheck`, because the runtime contains no shell, `curl`, or `wget`.

## Compose verification

```text
NAME                        IMAGE             COMMAND         SERVICE      STATUS
 devops-intro-quicknotes-1  quicknotes:lab6   "/quicknotes"  quicknotes   Up (healthy)
```

Logs showed:

```text
quicknotes listening on :8080 (notes loaded: 4)
```

Health endpoint:

```json
{"notes":4,"status":"ok"}
```

The first attempt failed with:

```text
seed: open /data/notes.json: permission denied
```

The Dockerfile was then updated so `/data` is initialized with ownership `65532:65532`, matching the distroless non-root user.

## Persistence test

A test note was created:

```json
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-18T19:28:44.434652448Z"}
```

Before restart, `grep durable` found the note.

After:

```bash
docker compose down
docker compose up -d
```

`grep durable` still found:

```text
"id":5,"title":"durable","body":"survive a restart"
```

Then the named volume was removed:

```bash
docker compose down -v
docker compose up -d
```

Final check:

```bash
curl -s http://localhost:8080/notes | grep durable
echo $?
```

```text
1
```

The note therefore survived normal `down && up` but disappeared after `down -v` removed the named volume.

## Design questions

### e) How do you healthcheck a distroless image?

I used a dedicated static Go healthcheck binary. It performs an HTTP GET to `http://127.0.0.1:8080/health` and exits non-zero when the request fails or returns a non-2xx status. Compose executes it directly with `test: ["CMD", "/healthcheck"]`, so no shell, `curl`, or `wget` is required.

### f) Why does `quicknotes-data:/data` survive `docker compose down`?

A named volume has a lifecycle independent from the container using it. `docker compose down` removes the containers and network but leaves named volumes intact. `docker compose down -v` or an explicit `docker volume rm` deletes the volume and its data.

### g) What does `depends_on` without `condition: service_healthy` wait for?

It controls startup order but does not guarantee that the dependency is actually ready to serve requests. A dependent service can therefore start while another service is still initializing, causing a startup race and temporary connection failures.

---

# Bonus — Six Security Defaults

## Applied defaults

1. `USER nonroot`.
2. Distroless runtime.
3. All Linux capabilities dropped.
4. Read-only root filesystem plus `/tmp` tmpfs.
5. `no-new-privileges`.
6. Trivy scan completed with version 0.59.1.

## Verification

### Non-root user

```bash
docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
```

```text
nonroot
```

### No shell

```bash
docker compose exec quicknotes sh
```

```text
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

### Capabilities dropped

```bash
docker inspect "$CID" --format '{{json .HostConfig.CapDrop}}'
```

```text
["ALL"]
```

### Read-only root filesystem

```bash
docker inspect "$CID" --format 'ReadonlyRootfs={{.HostConfig.ReadonlyRootfs}} Tmpfs={{json .HostConfig.Tmpfs}}'
```

```text
ReadonlyRootfs=true Tmpfs={"/tmp":"size=16m,mode=1777"}
```

Attempting to run `touch` also failed because distroless contains no `touch` utility:

```text
OCI runtime exec failed: exec failed: unable to start container process: exec: "touch": executable file not found in $PATH
```

The direct proof of the root filesystem setting is `ReadonlyRootfs=true`.

### `no-new-privileges`

```bash
docker inspect "$CID" --format '{{json .HostConfig.SecurityOpt}}'
```

```text
["no-new-privileges:true"]
```

The hardened container remained healthy:

```json
{"notes":4,"status":"ok"}
```

## Trivy scan

Command:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
  quicknotes:lab6
```

Relevant summary:

```text
quicknotes:lab6 (debian 13.7)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 19 (HIGH: 19, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 19 (HIGH: 19, CRITICAL: 0)
```

The distroless OS packages had **0 HIGH and 0 CRITICAL** findings. Trivy found **19 HIGH and 0 CRITICAL** findings in each Go binary because both contain Go standard library version `v1.24.13`; the same stdlib CVEs therefore appear for both binaries. The scan output reports fixes in newer Go release lines, while the lab requires the builder to remain on Go 1.24, so these results are documented rather than hidden.

### Which default gives the most security per line of YAML?

For QuickNotes, `cap_drop: [ALL]` gives a large security benefit for very little configuration because the application does not need Linux capabilities. Removing them reduces the privileged kernel functionality available to a compromised process. `no-new-privileges` is similarly cheap and prevents the process from gaining additional privileges. These controls are strongest when combined with the non-root user and read-only root filesystem.

---

# Acceptance summary

- Multi-stage Dockerfile: yes
- Go 1.24 builder: yes
- Distroless/non-root runtime: yes
- Static build with `CGO_ENABLED=0`: yes
- `-trimpath` and `-ldflags='-s -w'`: yes
- `EXPOSE 8080` and exec-form `ENTRYPOINT`: yes
- Final image ≤ 25 MB: **13.8 MB**
- `/health` and `/notes`: working
- Layer-cache experiment: documented
- Compose named volume: working
- Healthcheck: healthy
- Required environment variables: set
- `restart: unless-stopped`: set
- Persistence across `down && up`: verified
- Deletion after `down -v`: verified
- Six security defaults: applied and verified
- Trivy scan: completed and documented
