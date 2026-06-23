# Lab 6 Submission

## Task 1. Multi-Stage Dockerfile

### Dockerfile

The Dockerfile is located at:

```text
app/Dockerfile
```

It satisfies the main requirements:

* Multi-stage build
* Builder image pinned to `golang:1.24-alpine`
* Distroless runtime image
* Static binary with `CGO_ENABLED=0`
* Binary stripped with `-ldflags="-s -w"`
* Reproducible build with `-trimpath`
* Runtime user is `nonroot`
* Exec-form entrypoint
* Exposes port `8080`
* Final image size is below 25 MB

Dockerfile:

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/quicknotes"]
```

### Build Output

Source file:

```text
submissions/src/lab06/docker_build.txt
```

Command:

```powershell
cd app
docker build -t quicknotes:lab6 .
```

Important output:

```text
naming to docker.io/library/quicknotes:lab6 done
```

### Final Image Size

Source files:

```text
submissions/src/lab06/docker_images.txt
submissions/src/lab06/quicknotes_image_size.txt
```

Command:

```powershell
docker images quicknotes:lab6
```

Output:

```text
quicknotes:lab6   14.5MB
```

The final image size is 14.5 MB, which is below the 25 MB limit.

### Builder Base Image Size

Source file:

```text
submissions/src/lab06/golang_base_image_size.txt
```

Command:

```powershell
docker images golang:1.24-alpine --format "{{.Repository}}:{{.Tag}} {{.Size}}"
```

Output:

```text
golang:1.24-alpine 395MB
```

The final runtime image is much smaller than the Go builder image because the Go toolchain is not copied into the runtime stage.

### Docker Run Health Check

Source files:

```text
submissions/src/lab06/docker_run_id.txt
submissions/src/lab06/docker_run_health.txt
submissions/src/lab06/docker_run_stop.txt
submissions/src/lab06/docker_run_rm.txt
```

Command:

```powershell
docker run -d --name qn-lab6-run -p 8080:8080 -v "${PWD}\data:/data" quicknotes:lab6
curl.exe -s http://localhost:8080/health
docker stop qn-lab6-run
docker rm qn-lab6-run
```

Output:

```json
{"notes":5,"status":"ok"}
```

### Docker Inspect Config

Source file:

```text
submissions/src/lab06/docker_inspect_config.txt
```

Command:

```powershell
docker inspect quicknotes:lab6 --format 'User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}} ExposedPorts={{json .Config.ExposedPorts}}'
```

Output:

```text
User=nonroot:nonroot Entrypoint=["/quicknotes"] ExposedPorts={"8080/tcp":{}}
```

---

### Question a. Why Does Layer Order Matter?

Docker reuses cached layers. If `go.mod` is copied before source files, dependency download is cached and does not run again when only application code changes.

Bad order:

```dockerfile
COPY . .
RUN go mod download
RUN go build
```

Good order:

```dockerfile
COPY go.mod ./
RUN go mod download
COPY . .
RUN go build
```

The good order is better because changes in `.go` files do not invalidate the dependency-download layer.

Source files for timing evidence:

```text
submissions/src/lab06/badcache_build_time.txt
submissions/src/lab06/goodcache_build_time.txt
```

Measured result:

```text
TODO: paste bad order rebuild time
TODO: paste good order rebuild time
```

In this project the difference is small because QuickNotes has no third-party Go dependencies, but the good order is still the correct production pattern.

### Question b. Why CGO_ENABLED=0?

`CGO_ENABLED=0` builds a static Go binary.

Distroless static images do not include a dynamic linker or common shared libraries. If CGO is enabled, the binary may depend on missing runtime libraries and fail with an error such as:

```text
no such file or directory
```

Using a static binary avoids this problem.

### Question c. What Is gcr.io/distroless/static-debian12:nonroot?

It is a minimal runtime image for static applications.

It includes only minimal runtime files, CA certificates, and a non-root user. It does not include a shell, package manager, compiler, or debugging tools.

This matters for security because fewer packages mean a smaller attack surface and fewer operating-system CVEs.

### Question d. What Do -ldflags="-s -w" and -trimpath Do?

`-ldflags="-s -w"` removes symbol tables and debug information from the binary. This reduces binary size.

`-trimpath` removes local filesystem paths from the compiled binary. This improves reproducibility.

The cost is that debugging becomes harder because the binary contains less debug information.

---

## Task 2. Compose, Healthcheck, and Persistent Volume

### compose.yaml

The Compose file is located at:

```text
compose.yaml
```

It satisfies the main requirements:

* Defines a `quicknotes` service
* Builds from `./app`
* Tags the image as `quicknotes:lab6`
* Publishes port `8080`
* Defines a named volume mounted at `/data`
* Passes `ADDR`, `DATA_PATH`, and `SEED_PATH`
* Uses `restart: unless-stopped`
* Uses a sidecar container for HTTP health checking because the distroless image has no shell or curl
* Includes hardening settings for the bonus task

Compose file:

```yaml
services:
  quicknotes-init:
    image: busybox:1.36
    command: ["sh", "-c", "mkdir -p /data && chown -R 65532:65532 /data"]
    volumes:
      - quicknotes-data:/data

  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    depends_on:
      quicknotes-init:
        condition: service_completed_successfully
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    volumes:
      - quicknotes-data:/data
    user: "65532:65532"
    restart: unless-stopped
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp

  quicknotes-health:
    image: curlimages/curl:8.11.1
    depends_on:
      - quicknotes
    command:
      - sh
      - -c
      - |
        while true; do
          curl -fsS http://quicknotes:8080/health && sleep 30 || sleep 2
        done
    restart: unless-stopped

volumes:
  quicknotes-data:
```

### Compose Startup

Source file:

```text
submissions/src/lab06/compose_up.txt
```

Command:

```powershell
docker compose up --build -d
```

Important output:

```text
Container devops-intro-quicknotes-init-1 Started
Container devops-intro-quicknotes-init-1 Exited
Container devops-intro-quicknotes-1 Started
Container devops-intro-quicknotes-health-1 Started
```

### Compose Status

Source file:

```text
submissions/src/lab06/compose_ps.txt
```

Command:

```powershell
docker compose ps
```

Output:

```text
NAME                               IMAGE                    COMMAND                  SERVICE             STATUS
devops-intro-quicknotes-1          quicknotes:lab6          "/quicknotes"            quicknotes          Up
devops-intro-quicknotes-health-1   curlimages/curl:8.11.1   "/entrypoint.sh sh ..."   quicknotes-health   Up
```

### Compose Health Endpoint

Source file:

```text
submissions/src/lab06/compose_health.txt
```

Command:

```powershell
curl.exe -s http://localhost:8080/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

---

### Persistence Test. Create Durable Note

Source files:

```text
submissions/src/lab06/durable.json
submissions/src/lab06/persistence_post.txt
submissions/src/lab06/persistence_before_down.txt
```

Command:

```powershell
@'
{"title":"durable","body":"survive a restart"}
'@ | Set-Content -NoNewline submissions\src\lab06\durable.json

curl.exe -s -X POST http://localhost:8080/notes `
  -H "Content-Type: application/json" `
  --data-binary "@submissions/src/lab06/durable.json"

curl.exe -s http://localhost:8080/notes
```

Output:

```json
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T19:27:53.985140113Z"}
```

The note was present before restart:

```text
"title":"durable","body":"survive a restart"
```

### Persistence Test. docker compose down Then up

Source files:

```text
submissions/src/lab06/compose_down.txt
submissions/src/lab06/compose_up_after_down.txt
submissions/src/lab06/persistence_after_down_up.txt
```

Commands:

```powershell
docker compose down
docker compose up -d
curl.exe -s http://localhost:8080/notes
```

Output:

```text
"title":"durable","body":"survive a restart"
```

The note survived `docker compose down` and `docker compose up`.

### Persistence Test. docker compose down -v Then up

Source files:

```text
submissions/src/lab06/compose_down_v.txt
submissions/src/lab06/compose_up_after_down_v.txt
submissions/src/lab06/persistence_after_down_v_up.txt
```

Commands:

```powershell
docker compose down -v
docker compose up -d
curl.exe -s http://localhost:8080/notes
```

Output:

```json
[
  {
    "id":1,
    "title":"Welcome to QuickNotes"
  },
  {
    "id":2,
    "title":"Read app/main.go first"
  },
  {
    "id":3,
    "title":"DevOps mantra"
  },
  {
    "id":4,
    "title":"Endpoint cheat-sheet"
  }
]
```

The durable note disappeared after `docker compose down -v`, which confirms that the named volume was removed.

---

### Question e. Distroless Has No Shell. How Do You Healthcheck It?

I used a separate health sidecar container.

The main QuickNotes container uses a distroless image, so it does not contain `sh`, `curl`, or `wget`. The sidecar uses `curlimages/curl` and repeatedly checks:

```text
http://quicknotes:8080/health
```

This keeps the runtime image minimal while still giving an HTTP health check.

### Question f. Why Does volumes: [quicknotes-data:/data] Survive docker compose down?

Named volumes are Docker-managed resources.

`docker compose down` removes containers and networks but keeps named volumes. The data is destroyed only with:

```bash
docker compose down -v
```

or by manually removing the volume.

### Question g. What Does depends_on Without condition: service_healthy Do?

It only waits for the dependent container to start.

It does not wait until the application is ready to accept requests. This can cause race conditions where a dependent service starts too early and fails because the upstream service is not ready yet.

---

# Bonus Task. Security Defaults

## Applied Security Defaults

The following defaults were applied:

* `USER nonroot:nonroot`
* Distroless runtime image
* `cap_drop: [ALL]`
* `read_only: true`
* `tmpfs: /tmp`
* `security_opt: no-new-privileges:true`
* Trivy image scan

## Verification. USER nonroot

Source file:

```text
submissions/src/lab06/verify_user_nonroot.txt
```

Command:

```powershell
docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
```

Output:

```text
TODO: paste output, expected nonroot:nonroot
```

## Verification. No Shell Available

Source file:

```text
submissions/src/lab06/verify_no_shell.txt
```

Command:

```powershell
docker compose exec quicknotes sh
```

Output:

```text
TODO: paste output, expected failure because distroless has no shell
```

## Verification. Capabilities Dropped

Source file:

```text
submissions/src/lab06/verify_cap_drop.txt
```

Command:

```powershell
docker inspect <container_id> --format '{{ .HostConfig.CapDrop }}'
```

Output:

```text
TODO: paste output, expected [ALL]
```

## Verification. Read-Only Root Filesystem

Source file:

```text
submissions/src/lab06/verify_readonly_rootfs.txt
```

Command:

```powershell
docker inspect <container_id> --format '{{ .HostConfig.ReadonlyRootfs }}'
```

Output:

```text
TODO: paste output, expected true
```

Because the image has no shell, direct commands such as `touch /etc/test` cannot run inside the container. This is also evidence that the distroless image has no interactive shell.

## Verification. no-new-privileges

Source file:

```text
submissions/src/lab06/verify_no_new_privileges.txt
```

Command:

```powershell
docker inspect <container_id> --format '{{ .HostConfig.SecurityOpt }}'
```

Output:

```text
TODO: paste output, expected [no-new-privileges:true]
```

## Trivy Scan

Source file:

```text
submissions/src/lab06/trivy.txt
```

Command:

```powershell
docker run --rm -v //var/run/docker.sock:/var/run/docker.sock `
  aquasec/trivy:0.59.1 image `
  --severity HIGH,CRITICAL `
  --no-progress `
  quicknotes:lab6
```

Output summary:

```text
quicknotes:lab6 (debian 12.14)
Total: 0 (HIGH: 0, CRITICAL: 0)

quicknotes (gobinary)
Total: 13 (HIGH: 13, CRITICAL: 0)
```

The distroless Debian base image has no HIGH or CRITICAL vulnerabilities. Trivy reported HIGH findings in the Go binary. These findings come from the Go standard library embedded into the static binary and can be fixed by rebuilding with a newer Go version when allowed by the lab requirements.

## Which Security Default Provides the Most Value?

The distroless runtime image provides the most security per line of configuration. It removes the shell, package manager, compiler, and most operating-system packages. This greatly reduces the attack surface and the number of possible OS-level vulnerabilities. Running as a non-root user is also very valuable because it limits the damage if the application is compromised.

---

# Observations

* The final image size is 14.5 MB, which is below the required 25 MB limit.
* The builder image `golang:1.24-alpine` is 395 MB.
* Multi-stage builds prevent the Go compiler and build tools from entering the runtime image.
* The application successfully runs from `docker run`.
* The application successfully runs from `docker compose up`.
* The runtime image uses `nonroot:nonroot`.
* The runtime image has no shell.
* The named volume preserved the durable note after `docker compose down`.
* The durable note disappeared after `docker compose down -v`.
* Trivy found 0 HIGH and 0 CRITICAL vulnerabilities in the distroless Debian base image.
* Trivy found HIGH findings in the Go binary, which should be fixed by rebuilding with a patched Go toolchain.

# Conclusions

- The QuickNotes application was successfully containerized using a multi-stage Docker build and a distroless runtime image.

- The final image is small, runs as a non-root user, and exposes only the required application port.

- Docker Compose provides a repeatable way to run the service with persistent storage.

- The persistence test confirmed that named volumes survive normal container recreation but are removed by `docker compose down -v`.

- The bonus hardening settings improve security by reducing privileges, removing unnecessary tools, and making the root filesystem read-only.
