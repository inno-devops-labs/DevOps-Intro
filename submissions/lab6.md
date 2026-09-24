# Lab 6 — Containers: Dockerize QuickNotes

## Environment

- Docker: 29.8.1 (Docker Engine; cache benchmark was measured earlier on snap Docker 29.6.1)
- Docker Compose: v5.5.1 (cache benchmark and initial persistence test used v5.3.1)
- Builder: `golang:1.24-alpine`
- Runtime: `gcr.io/distroless/static:nonroot`

## Task 1 — Multi-stage Dockerfile

### Build and image size

The [Dockerfile](../app/Dockerfile) copies `go.mod` before source because this project has no `go.sum` or external modules. The `.dockerignore` excludes local `data/` and `quicknotes` from the build context. It builds both the application and its healthcheck with `CGO_ENABLED=0`, `-trimpath`, and `-ldflags="-s -w"`.

```text
$ docker build -t quicknotes:lab6 .
... naming to docker.io/library/quicknotes:lab6 ...
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   476637abcf99         23MB         5.76MB   U
$ docker image inspect quicknotes:lab6 --format '{{.Size}}'
23019915
```

On the current Engine, the builder base `golang:1.24-alpine` is 394,365,627 bytes (`docker images`: 395 MB); the final image is 23,019,915 bytes (23 MB), below the 25 MB limit. The earlier snap daemon reported 262,329,113 and 13,821,082 bytes for these images, respectively; The two daemons reported different image sizes; this report uses the current Engine values for the acceptance limit.

### Runtime and image configuration

With `ADDR=:8080`, `DATA_PATH=/data/notes.json`, `SEED_PATH=/app/seed.json`, and a named volume at `/data`, direct `docker run` testing returned:

```text
GET /health -> HTTP/1.1 200 OK
{"notes":4,"status":"ok"}
GET /notes -> HTTP/1.1 200 OK
```

```text
$ docker image inspect quicknotes:lab6 --format 'user={{.Config.User}} ports={{json .Config.ExposedPorts}} entrypoint={{json .Config.Entrypoint}}'
user=nonroot:nonroot ports={"8080/tcp":{}} entrypoint=["/quicknotes"]
```

The image includes `/app/seed.json`. Its `/data` directory belongs to UID/GID 65532 so a fresh named volume accepts both `notes.json` and the temporary file used for atomic updates.

### Layer-cache benchmark

Each strategy was built once, then `main.go` was changed only in a separate temporary context. The contexts used the same Go builder, runtime, build flags, and application sources. Wall time came from `/usr/bin/time -f 'wall_seconds=%e' docker build`.

| Layer order | Initial build | Source-only rebuild | Dependency step on rebuild |
| --- | ---: | ---: | --- |
| `COPY . .` then `RUN go mod download` | 6.19 s | 5.64 s | Re-executed (0.2 s) |
| `COPY go.mod` then download, then source | 5.37 s | 5.42 s | `CACHED` |

The measured difference is small because this application has no external modules and binary compilation dominates both rebuilds. Source changes invalidate layers after `COPY . .`; keeping `go.mod` in an earlier layer preserves the dependency-download layer until the module manifest changes.

### Design questions

**a) Layer ordering.** Docker reuses a layer only when its inputs match. Copying all source before dependency download invalidates that download step for every source edit. Copying `go.mod` first kept it cached in the 5.42 s rebuild above, while the 5.64 s alternative ran it again; the benefit grows when dependencies are more costly to download.

**b) `CGO_ENABLED=0`.** The two binaries are built without C linkage, so they do not require glibc, musl, or a dynamic loader in the distroless static image. A dynamically linked executable could fail to start there if its loader or shared libraries were absent.

**c) Distroless static nonroot.** This runtime supplies the minimal files needed for static applications and runtime metadata such as certificates, without a normal Linux user space, shell, package manager, compiler, or debug tools. Fewer installed packages generally reduce attack surface and package-level findings; the vulnerability scan result is recorded below.

**d) Build flags.** `-ldflags="-s -w"` strips symbol and debug metadata to reduce binary size, at the cost of less convenient binary debugging. `-trimpath` omits local build paths from metadata, improving build path privacy and reproducibility.


## Task 2 — Compose, healthcheck, and persistence

The [Compose file](../compose.yaml) builds `./app` as `quicknotes:lab6`, publishes port 8080, sets `ADDR`, `DATA_PATH`, and `SEED_PATH`, mounts the named `quicknotes-data` volume at `/data`, and uses `restart: unless-stopped`.

### Healthcheck

The statically built `/healthcheck` performs a GET of `http://127.0.0.1:8080/health` with a two-second client timeout. Compose executes it directly using `test: ["CMD", "/healthcheck"]`, every ten seconds with a three-second Docker timeout and three retries. `docker compose config` accepted the configuration. The first container inspection reported `"Status":"healthy","FailingStreak":0` and a healthcheck `"ExitCode":0`; `docker compose ps` showed `Up 8 seconds (healthy)`.

### Persistence test

The test was repeated on Docker Engine 29.8.1 with all security options enabled. Commands were run against the actual Compose service:

```text
$ curl -X POST -H 'Content-Type: application/json' -d '{"title":"durable","body":"survive a restart"}' http://127.0.0.1:8080/notes
{"id":6,"title":"durable","body":"survive a restart","created_at":"2026-09-24T20:23:18.736780082Z"}
Before down: "title":"durable"
$ docker compose down && docker compose up -d
After down/up health: healthy
After down/up: "title":"durable"
$ docker compose down -v && docker compose up -d
After down -v/up health: healthy
After down -v/up: durable note absent
```

The last absence was checked with `grep`; its expected nonzero result was treated as success. Only the Lab 6 Compose volume was deleted.

### Design questions

**e) Distroless healthcheck.** Distroless has no shell, curl, or wget. The image contains a small static healthcheck binary; Docker executes it directly, and its exit code follows the result of `/health`. This keeps a working healthcheck without adding a general-purpose user space.

**f) Named volume lifetime.** `docker compose down` removes the containers and network while preserving named volumes by default, so the note remained. `docker compose down -v` explicitly removed the named volume, so the next start restored only seed notes. A direct `docker volume rm` could also destroy that data.

**g) `depends_on` readiness.** Plain `depends_on` orders container startup but does not wait for the application to accept requests. A dependent service requiring readiness should use `condition: service_healthy` with a working healthcheck.


## Bonus — Security defaults

### Hardened configuration

The image runs as `nonroot:nonroot` on `gcr.io/distroless/static:nonroot`. The Compose file sets `cap_drop: [ALL]`, `read_only: true`, and `security_opt: [no-new-privileges:true]`. The named volume mounted at `/data` remains writable. The sixth default is the Trivy scan below.

### Runtime verification

After moving from the Canonical Docker snap to Docker Engine 29.8.1, the full Compose configuration started successfully. The earlier snap daemon had rejected every container launched with `no-new-privileges:true`, including a Go Alpine `/bin/true` test; this is a [documented snap limitation](https://github.com/canonical/docker-snap#usage). The following evidence comes from the working Engine and its actual Compose container:

```text
$ docker image inspect quicknotes:lab6 --format 'image_user={{.Config.User}}'
image_user=nonroot:nonroot
$ docker inspect "$(docker compose ps -q quicknotes)" --format 'container_user={{.Config.User}} cap_drop={{.HostConfig.CapDrop}} readonly={{.HostConfig.ReadonlyRootfs}} security_opt={{.HostConfig.SecurityOpt}} status={{.State.Health.Status}}'
container_user=nonroot:nonroot cap_drop=[ALL] readonly=true security_opt=[no-new-privileges:true] status=healthy
$ docker compose exec -T quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

The failed `sh` invocation proves the production image does not contain a shell. A controlled one-off container used the same image with all three Compose runtime flags and `DATA_PATH=/etc/lab6-write-test`; startup failed with:

```text
2026/09/24 20:19:51 seed: open /etc/lab6-write-test: read-only file system
root write blocked as expected
```

The actual hardened Compose service also wrote successfully to its named volume:

```text
POST /notes -> {"id":5,"title":"hardened","body":"writable volume","created_at":"2026-09-24T20:19:51.197125556Z"}
GET /health -> 200
GET /notes -> 200
Health status -> healthy; FailingStreak -> 0; healthcheck ExitCode -> 0
```

The image inspection establishes the nonroot default. The Compose container inspection establishes capability drop, read-only root, and no-new-privileges on the running service. The write attempts and API responses demonstrate enforcement and continued function.

### Trivy scan

The required command completed with Trivy 0.59.1, scanning `quicknotes:lab6` with the `HIGH,CRITICAL` filter. The local image contains Debian 13.7 runtime packages and two Go binaries. A JSON-format scan counted results by target. The required text scan was repeated on the current Engine and returned the same counts:

```text
quicknotes:lab6 (debian 13.7)  HIGH 0   CRITICAL 0
healthcheck                     HIGH 19  CRITICAL 0
quicknotes                      HIGH 19  CRITICAL 0
Total                           HIGH 38  CRITICAL 0
```

The findings shown by Trivy are in Go `stdlib` version `v1.24.13`; for example, `CVE-2026-25679` was reported HIGH for both binaries. The chosen builder meets the required Go 1.24 version, and no zero-vulnerability claim is made.

### Security analysis

For this service, `read_only: true` gives the most useful restriction per line of Compose configuration because it blocks writes across the image filesystem. The named `/data` volume keeps the note store writable, while the controlled `/etc` write failed. This control needs intentional writable mounts for any application state or scratch files, so it is not suitable unchanged for every service. Dropping all capabilities and preventing privilege gain add further protection without breaking QuickNotes on the current Engine.
