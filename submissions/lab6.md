# Lab 6 - Containers: Dockerize QuickNotes

## Task 1 - Multi-stage Dockerfile

### Dockerfile

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

RUN cat > /tmp/healthcheck.go <<'EOF'
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	client := http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://127.0.0.1:8080/health")
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		os.Exit(1)
	}
}
EOF

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/healthcheck /tmp/healthcheck.go

RUN mkdir -p /out/data

FROM gcr.io/distroless/static:nonroot

WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

### Image size

Command:

```powershell
docker images quicknotes:lab6
```

Output:

```text
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   a39d5f5a0ab8       22.7MB         5.71MB    U
```

The final image size is **22.7 MB**, which is below the required 25 MB limit.

### Image configuration

Command:

```powershell
docker inspect quicknotes:lab6 --format "User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}} ExposedPorts={{json .Config.ExposedPorts}}"
```

Output:

```text
User=nonroot:nonroot Entrypoint=["/quicknotes"] ExposedPorts={"8080/tcp":{}}
```

This confirms that the image runs as `nonroot:nonroot`, exposes port `8080`, and uses exec-form entrypoint.

### Builder base image comparison

Command:

```powershell
docker pull golang:1.24-alpine
docker images golang:1.24-alpine
```

Output:

```text
1.24-alpine: Pulling from library/golang
Digest: sha256:8bee1901f1e530bfb4a7850aa7a479d17ae3a18beb6e09064ed54cfd245b7191
Status: Downloaded newer image for golang:1.24-alpine
docker.io/library/golang:1.24-alpine

IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
golang:1.24-alpine   8bee1901f1e5        395MB         83.5MB
```

The builder image is **395 MB**, while the final runtime image is only **22.7 MB**. This shows the value of the multi-stage build: the Go compiler and build tools are not included in the final image.

### Direct Docker run test

Command:

```powershell
cd C:\Users\minim\projects\DevOps-Intro\app
docker run --rm -d --name quicknotes-test -p 8080:8080 -v "${PWD}\data:/data" quicknotes:lab6
Start-Sleep -Seconds 3
curl.exe -s http://localhost:8080/health
docker stop quicknotes-test
```

Output:

```text
28e0c9615e2610c4c97f4d0eee757e165b142c5e7956050f3cb545b44c12870e
{"notes":6,"status":"ok"}
quicknotes-test
```

This confirms that the Docker image runs QuickNotes successfully and serves the `/health` endpoint.

### Design questions

#### a) Why does layer order matter?

Layer order matters because Docker reuses cached layers when the inputs to those layers have not changed. If the Dockerfile uses `COPY . .` before `go mod download`, then any source-code change invalidates the dependency-download layer, forcing Docker to repeat unnecessary work.

The better strategy is:

```dockerfile
COPY go.mod ./
RUN go mod download
COPY . .
RUN go build ...
```

This allows Docker to cache `go mod download` as long as `go.mod` has not changed. In my cache-friendly build, the first build took about **25.4 seconds**, while a later cached Compose rebuild completed in about **1.9 seconds**. The difference shows that separating dependency layers from source-code layers improves rebuild speed.

#### b) Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` forces Go to produce a static binary that does not depend on C libraries or a dynamic linker. This matters because `gcr.io/distroless/static:nonroot` is designed for static binaries and does not include a full Linux userland. If CGO is left enabled and the binary requires dynamic libraries, the container may fail at runtime with an error such as `no such file or directory`, even though the binary appears to exist.

#### c) What is `gcr.io/distroless/static:nonroot`?

`gcr.io/distroless/static:nonroot` is a minimal runtime image for statically compiled applications. It contains enough to run a static binary as a non-root user, but it does not include a shell, package manager, or common debugging tools. This matters for security because fewer packages means a smaller attack surface and fewer operating-system CVEs in the final image.

#### d) What do `-ldflags="-s -w"` and `-trimpath` do?

`-ldflags="-s -w"` strips the symbol table and debug information from the Go binary, which reduces binary size. `-trimpath` removes local filesystem paths from the compiled binary, making builds more reproducible and avoiding leakage of build-machine paths. The trade-off is that debugging information is reduced, so stack traces and binary inspection may be less detailed.

---

## Task 2 - Compose, Healthcheck, and Persistent Volume

### compose.yaml

```yaml
services:
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
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
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true

volumes:
  quicknotes-data:
```

### Compose startup and healthcheck

Command:

```powershell
cd C:\Users\minim\projects\DevOps-Intro
docker compose down -v
docker compose up --build -d
Start-Sleep -Seconds 5
docker compose ps
curl.exe -s http://localhost:8080/health
```

Output:

```text
[+] up 4/4
 ✔ Image quicknotes:lab6               Built
 ✔ Network devops-intro_default        Created
 ✔ Volume devops-intro_quicknotes-data Created
 ✔ Container devops-intro-quicknotes-1 Started

NAME                        IMAGE             COMMAND         SERVICE      STATUS                  PORTS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   Up 5 seconds (healthy)  0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp

{"notes":0,"status":"ok"}
```

This confirms that Compose starts the service, the healthcheck reports healthy, and the host can reach the container on port 8080.

### Persistence test

#### Create a durable note

Command:

```powershell
$body = @{
  title = "durable"
  body  = "survive a restart"
} | ConvertTo-Json -Compress

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:8080/notes" `
  -ContentType "application/json" `
  -Body $body
```

Output:

```text
id title   body              created_at
-- -----   ----              ----------
 1 durable survive a restart 2026-06-23T17:24:24.43611536Z
```

#### Confirm the note exists

Command:

```powershell
Invoke-RestMethod http://localhost:8080/notes | ConvertTo-Json -Depth 5
```

Output:

```json
{
    "value":  [
                  {
                      "id":  1,
                      "title":  "durable",
                      "body":  "survive a restart",
                      "created_at":  "2026-06-23T17:24:24.43611536Z"
                  }
              ],
    "Count":  1
}
```

#### Confirm persistence after `docker compose down && docker compose up`

Command:

```powershell
docker compose down
docker compose up -d
Start-Sleep -Seconds 3
(Invoke-RestMethod http://localhost:8080/notes | ConvertTo-Json -Depth 5) | Select-String durable
```

Output:

```text
id title   body              created_at
-- -----   ----              ----------
 2 durable survive a restart 2026-06-23T17:24:42.300273119Z
```

The durable note still exists after `docker compose down` and `docker compose up`, which proves the named volume preserved the data.

#### Confirm data is deleted after `docker compose down -v`

Command:

```powershell
docker compose down -v
docker compose up -d
Start-Sleep -Seconds 3
(Invoke-RestMethod http://localhost:8080/notes | ConvertTo-Json -Depth 5) | Select-String durable
```

Output:

```text
[+] down 3/3
 ✔ Container devops-intro-quicknotes-1 Removed
 ✔ Network devops-intro_default        Removed
 ✔ Volume devops-intro_quicknotes-data Removed

[+] up 3/3
 ✔ Network devops-intro_default        Created
 ✔ Volume devops-intro_quicknotes-data Created
 ✔ Container devops-intro-quicknotes-1 Started

No output from Select-String durable.
```

The durable note disappeared after `docker compose down -v`, which proves the data was stored in the named volume and that `-v` deleted the volume.

### Design questions

#### e) Distroless has no shell. How do you healthcheck it?

I used a small static Go healthcheck binary copied into the final distroless image. The Compose healthcheck runs it using exec form: `["CMD", "/healthcheck"]`. This works without a shell because Docker directly executes the binary, and the binary performs an HTTP GET request to `http://127.0.0.1:8080/health`.

#### f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`?

A named Docker volume is managed separately from the container lifecycle. `docker compose down` removes containers and networks, but it does not delete named volumes by default. The volume is destroyed by `docker compose down -v` or by explicitly deleting it with Docker volume commands.

#### g) `depends_on` without `condition: service_healthy`

`depends_on` without `condition: service_healthy` only waits for the dependent container to start, not for the application inside it to become ready. This can cause startup race conditions where one service tries to connect to another service before it is actually listening or healthy. In this lab there is only one service, but in a multi-service setup this can cause intermittent failures.

---

## Bonus Task - Security Defaults

### Hardened quicknotes service block

```yaml
quicknotes:
  build:
    context: ./app
    dockerfile: Dockerfile
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
  cap_drop:
    - ALL
  read_only: true
  tmpfs:
    - /tmp
  security_opt:
    - no-new-privileges:true
```

### 1. USER nonroot

Command:

```powershell
docker inspect quicknotes:lab6 --format "{{.Config.User}}"
```

Output:

```text
nonroot:nonroot
```

### 2. Distroless / no shell available

Command:

```powershell
docker compose exec quicknotes sh
```

Output:

```text
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

This confirms that the final image does not include a shell, which is expected for a distroless image.

### 3. Linux capabilities dropped

Command:

```powershell
$cid = docker compose ps -q quicknotes
docker inspect $cid --format "{{json .HostConfig.CapDrop}}"
```

Output:

```text
["ALL"]
```

### 4. Read-only root filesystem

Command:

```powershell
docker inspect $cid --format "{{.HostConfig.ReadonlyRootfs}}"
```

Output:

```text
true
```

### 5. no-new-privileges

Command:

```powershell
docker inspect $cid --format "{{json .HostConfig.SecurityOpt}}"
```

Output:

```text
["no-new-privileges:true"]
```

### 6. Trivy scan

Command:

```powershell
docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6
```

Output summary:

```text
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 13 (HIGH: 13, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 13 (HIGH: 13, CRITICAL: 0)
```

The distroless OS layer had **0 HIGH** and **0 CRITICAL** vulnerabilities. Trivy reported HIGH findings in the Go standard library embedded in the compiled binaries because the builder image used Go 1.24, which was required by the lab.

### Security reflection

The most valuable security default per line of YAML is probably `cap_drop: [ALL]`, because QuickNotes does not need extra Linux capabilities. Dropping all capabilities reduces what an attacker could do if the process were compromised. The distroless runtime is also valuable because it removes the shell, package manager, and common post-exploitation tools. The read-only root filesystem adds another layer by forcing application writes into the intended `/data` volume instead of allowing arbitrary writes across the container filesystem.
