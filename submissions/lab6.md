# Lab 6 submission

## Task 1: Multi-Stage Dockerfile

See [`app/Dockerfile`](../app/Dockerfile).

```text
$ docker images quicknotes:lab6
REPOSITORY:TAG    SIZE
quicknotes:lab6   15.2MB          # builder base golang:1.24-alpine = 395 MB

$ docker inspect quicknotes:lab6 --format 'User={{.Config.User}} Exposed={{.Config.ExposedPorts}} Entrypoint={{.Config.Entrypoint}}'
User=nonroot Exposed=map[8080/tcp:{}] Entrypoint=[/quicknotes]

$ docker run -d -p 8080:8080 quicknotes:lab6
$ curl -s localhost:8080/health
{"notes":4,"status":"ok"}

$ curl -s -X POST -d '{"title":"hello","body":"from docker"}' localhost:8080/notes
{"id":5,"title":"hello","body":"from docker",...}
```

* **a) Layer order.** Docker rebuilds a layer when its inputs change. By copying `go.mod` and running `go mod download` *before* `COPY . .`, the dependency layer is reused when only source code changes. If `COPY . .` is placed first, dependencies are downloaded again on every build. After a one-line code change, rebuild time was **9.81 s** with the bad order versus **8.48 s** with the good order. The difference is small because QuickNotes has no dependencies; in larger projects, the penalty would be much greater

* **b) `CGO_ENABLED=0`.** A fully static Go binary is produced, eliminating dependencies on libc and a dynamic linker. This is required for `distroless/static`, which does not include `ld-linux`. A dynamically linked binary (`CGO_ENABLED=1`) fails to start because the linker is absent

* **c) `distroless/static:nonroot`.** A minimal runtime image is used, containing only essentials such as CA certificates, timezone data, `/tmp`, and a non-root user (UID 65532). No shell, package manager, or libc is included. Because very few packages are present, the base image typically contributes **0 HIGH/CRITICAL CVEs** and presents a smaller attack surface

* **d) `-ldflags="-s -w"` and `-trimpath`.** The symbol table (`-s`) and debug information (`-w`) are removed, reducing binary size. Local filesystem paths are stripped by `-trimpath`, improving build reproducibility and preventing path leakage. The tradeoff is reduced debugging information, although panic stack traces remain available. No runtime cost is introduced by `-trimpath`

## Task 2: Compose + Healthcheck + Persistent Volume

See [`compose.yaml`](../compose.yaml)

```text
# 1. POST a note, confirm present
$ curl -s -X POST -d '{"title":"durable","body":"survive a restart"}' localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T18:47:20.118042755Z"}
$ curl -s localhost:8080/notes | grep -o durable
durable

# 2. down (NO -v) then up -> note survives the named volume
$ docker compose down && docker compose up -d
$ curl -s localhost:8080/notes | grep -o durable
durable

# 3. down -v then up -> volume destroyed, note gone (grep exits 1, no output)
$ docker compose down -v && docker compose up -d
$ curl -s localhost:8080/notes | grep -o durable ; echo "grep_exit=$?"
grep_exit=1

$ docker compose ps
NAME                        IMAGE             COMMAND         SERVICE      STATUS                    PORTS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   Up 18 seconds (healthy)   0.0.0.0:8080->8080/tcp
$ docker compose exec quicknotes /quicknotes healthcheck ; echo $?
0
```

### Design questions (Task 2)

* **e) Healthcheck without a shell.** A binary already present in the image is used: the application itself. `quicknotes healthcheck` (in `app/main.go`) performs an HTTP GET to `/health` (2 s timeout) and exits with status 0 or 1; Compose invokes it in exec form: `["CMD", "/quicknotes", "healthcheck"]`. This avoids adding tools such as `wget` (which increases package surface), avoids a sidecar container for a single request, and is more reliable than Docker's default process-alive check, which cannot distinguish between a running process and a functioning service. The cost is effectively zero because no additional image content is required

* **f) Volume survives `down`.** Named volumes are managed as separate Docker resources with their own lifecycle and are not owned by containers. As a result, `docker compose down` removes containers and networks but leaves volumes intact, allowing them to be reattached by a later `up`. Removal requires either `docker compose down -v` or `docker volume rm devops-intro_quicknotes-data`

* **g) `depends_on` without `condition: service_healthy`.** Standard `depends_on` waits only for a dependency container to start, not for the service inside it to become ready. A dependent service can therefore start while, for example, a database is still initializing and fail its initial requests. Adding `condition: service_healthy` delays startup until the dependency's healthcheck passes, eliminating this race condition

## Bonus: 6 Security Defaults

All six applied in [`app/Dockerfile`](../app/Dockerfile) (1–2) and [`compose.yaml`](../compose.yaml) (3–5); verified:

```text
1. nonroot       $ docker inspect quicknotes:lab6 --format '{{.Config.User}}'
                 nonroot
2. distroless    $ docker compose exec quicknotes sh
                 OCI runtime exec failed: exec: "sh": executable file not found in $PATH
3. drop caps     $ docker inspect <c> --format '{{.HostConfig.CapDrop}} {{.HostConfig.CapAdd}}'
                 [ALL] []
4. read-only fs  $ docker inspect <c> --format '{{.HostConfig.ReadonlyRootfs}} {{.HostConfig.Tmpfs}}'
                 true map[/tmp:]
                 # no shell/touch in-image, so mechanism shown with busybox + same flag:
                 $ docker run --rm --read-only busybox touch /etc/test
                 touch: /etc/test: Read-only file system        # blocked
5. no-new-privs  $ docker inspect <c> --format '{{.HostConfig.SecurityOpt}}'
                 [no-new-privileges:true]
6. trivy         see below
```

### Trivy

```text
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6

quicknotes:lab6 (debian 12.14)   Total: 0  (HIGH: 0, CRITICAL: 0)    <- distroless base is clean
quicknotes (gobinary)            Total: 13 (HIGH: 13, CRITICAL: 0)   <- Go stdlib CVEs
```

The base image is clean. The 13 HIGH vulnerabilities come from the Go standard library included in the binary by the pinned Go 1.24 toolchain, not from the OS layer. They are fixed in Go 1.25.11 and 1.26.4, but cannot be fixed while Task 1 requires Go 1.24

**Most security per line of YAML:** `read_only: true` (+ a one-line `tmpfs`). It makes the whole rootfs immutable, no dropped web-shells, overwritten binaries, or `/etc` tampering, while the app keeps working since it only writes to the `/data` volume. `cap_drop: [ALL]` and `no-new-privileges` are cheap and worth keeping, but a non-root capability-less process can't use most of what they remove anyway
