# Lab 6 - Containers: Dockerize QuickNotes

## Task 1 - Multi-Stage Dockerfile

### Dockerfile

```dockerfile
# syntax=docker/dockerfile:1.7

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/quicknotes .

RUN cat <<'EOF' >/tmp/healthcheck.go
package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	if len(os.Args) == 3 && os.Args[1] == "--write-test" {
		if err := os.WriteFile(os.Args[2], []byte("write-test"), 0o644); err != nil {
			fmt.Fprintf(os.Stderr, "write failed: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("write succeeded")
		return
	}

	url := "http://127.0.0.1:8080/health"
	if override := os.Getenv("HEALTHCHECK_URL"); override != "" {
		url = override
	}

	client := http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		fmt.Fprintf(os.Stderr, "healthcheck failed: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		fmt.Fprintf(os.Stderr, "unexpected status: %s\n", resp.Status)
		os.Exit(1)
	}
}
EOF

RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/healthcheck /tmp/healthcheck.go

RUN mkdir -p /out/data /out/root-write-test

FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=nonroot:nonroot /out/data /data
COPY --from=builder --chown=nonroot:nonroot /out/root-write-test /root-write-test
COPY --chown=nonroot:nonroot seed.json /app/seed.json

ENV ADDR=:8080
ENV DATA_PATH=/data/notes.json
ENV SEED_PATH=/app/seed.json

USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

I also added `app/.dockerignore` so local binaries and local `app/data/` do not enter the build context:

```text
data/
quicknotes
quicknotes.exe
*.test
coverage.out
```

### Build and image size

```text
$ docker build -t quicknotes:lab6 app/
...
naming to docker.io/library/quicknotes:lab6 done

$ docker images quicknotes:lab6
REPOSITORY   TAG       SIZE
quicknotes   lab6      22.8MB
```

The final image is below the 25 MB limit.

Builder image size for comparison:

```text
$ docker images golang:1.24-alpine
REPOSITORY   TAG           SIZE
golang       1.24-alpine   395MB
```

### Image config

```text
$ docker inspect quicknotes:lab6 --format 'User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}} ExposedPorts={{json .Config.ExposedPorts}}'
User=nonroot:nonroot Entrypoint=["/quicknotes"] ExposedPorts={"8080/tcp":{}}
```

### Direct run verification

```text
$ docker run -d --name quicknotes-lab6-run-final -p 18081:8080 -v "$PWD/app/data:/data" quicknotes:lab6
CONTAINER_ID=392fcab4b8f51968f41eb1ec9fd38c42cbe6f7b9646f50ea44632dc56191d8e8

$ curl -s http://localhost:18081/health
{"notes":6,"status":"ok"}
```

### Design questions

a) Layer order matters because Docker cache invalidation is sequential. If `COPY . .` happens before `go mod download`, every source change invalidates the dependency-download layer. With the optimized order, `go.mod` is copied first, so source-only changes reuse the module-download layer.

Measured rebuild after a harmless build-context change:

```text
Naive:     COPY . . -> go mod download -> go build
Optimized: COPY go.mod ./ -> go mod download -> COPY . . -> go build

NAIVE_REBUILD_SECONDS=8.082
OPTIMIZED_REBUILD_SECONDS=7.803
```

The difference is small here because QuickNotes has no external module dependencies, but the optimized build reused the `go mod download` layer. On a real dependency-heavy service, avoiding repeated module downloads is a large rebuild-time win.

b) `CGO_ENABLED=0` forces a fully static Go binary. Distroless static images do not include a dynamic linker, glibc, musl, or package-manager-provided shared libraries. If the binary needs a dynamic linker, the container often fails at startup with a misleading `no such file or directory` error even though the binary path exists.

c) `gcr.io/distroless/static:nonroot` is a minimal runtime image with CA certificates, user metadata, and enough filesystem structure to run a static binary as a nonroot user. It does not include a shell, package manager, compiler, curl, apt, or debugging tools. That matters for CVEs because there are far fewer OS packages to scan, patch, or exploit.

d) `-ldflags="-s -w"` strips the symbol table and DWARF debug information, reducing binary size. `-trimpath` removes local filesystem paths from the compiled binary, improving reproducibility and avoiding host-path leakage. The cost is weaker postmortem debugging because stack traces and binary inspection have less symbolic/debug context.

## Task 2 - Compose, Healthcheck, Persistent Volume

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
      SEED_PATH: "/app/seed.json"
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
    tmpfs:
      - /tmp:rw,noexec,nosuid,size=16m
    security_opt:
      - no-new-privileges:true

volumes:
  quicknotes-data:
```

### Compose health

```text
$ docker compose -p lab6 up --build -d
$ docker compose -p lab6 ps
Name                  Image             Command       Service      Status
lab6-quicknotes-1     quicknotes:lab6   "/quicknotes" quicknotes   Up 8 seconds (healthy)

$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

### Persistence test

PowerShell was used on Windows to avoid `curl.exe` JSON quoting issues; the request body is the same JSON as in the lab statement.

```text
$body = '{"title":"durable","body":"survive a restart"}'
Invoke-RestMethod -Method Post -Uri http://localhost:8080/notes -ContentType 'application/json' -Body $body
POST_RESULT={"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-21T07:48:47.497253517Z"}

Invoke-RestMethod -Uri http://localhost:8080/notes
DURABLE_PRESENT_BEFORE_DOWN=True

docker compose -p lab6 down
docker compose -p lab6 up -d
Invoke-RestMethod -Uri http://localhost:8080/notes
DURABLE_PRESENT_AFTER_DOWN_UP=True

docker compose -p lab6 down -v
docker compose -p lab6 up -d
Invoke-RestMethod -Uri http://localhost:8080/notes
DURABLE_PRESENT_AFTER_DOWN_V_UP=False

Invoke-RestMethod -Uri http://localhost:8080/health
FINAL_HEALTH={"notes":4,"status":"ok"}
```

### Compose design questions

e) Distroless has no shell and no curl, so I used a tiny static Go helper copied into the final image as `/healthcheck`. Compose runs it with exec-form `["CMD", "/healthcheck"]`. The helper performs an HTTP GET to `127.0.0.1:8080/health`, so the healthcheck validates the actual API instead of only checking whether PID 1 exists.

f) `volumes: [quicknotes-data:/data]` survives `docker compose down` because named volumes are separate Docker objects, not anonymous container filesystems. `down` removes containers and the project network, but keeps named volumes by default. `docker compose down -v` destroys the named volume, which is why the durable note disappeared after that step.

g) `depends_on` without `condition: service_healthy` only waits for dependency containers to be started, not for their applications to be ready. The bug is a race: a dependent service can begin connecting while the dependency is still booting or failing healthchecks. That causes flaky startup failures unless the app retries or Compose uses a health-based dependency condition.

## Bonus Task - Six Security Defaults

### Hardened service block

The `quicknotes` service applies all runtime hardening defaults:

```yaml
quicknotes:
  image: quicknotes:lab6
  cap_drop:
    - ALL
  read_only: true
  tmpfs:
    - /tmp:rw,noexec,nosuid,size=16m
  security_opt:
    - no-new-privileges:true
```

`USER nonroot` and the distroless base are enforced in the Dockerfile.

### Verification outputs

1. Nonroot user:

```text
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
nonroot:nonroot
```

2. Distroless / no shell available:

```text
$ docker compose -p lab6 exec -T quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
SHELL_TEST_EXIT=127
```

3. Capabilities dropped:

```text
$ docker inspect lab6-quicknotes-1 --format '{{ .HostConfig.CapDrop }}'
[ALL]
```

4. Read-only root filesystem with writable `/tmp` tmpfs:

```text
$ docker inspect lab6-quicknotes-1 --format '{{ .HostConfig.ReadonlyRootfs }}'
true

$ docker compose -p lab6 exec -T quicknotes /healthcheck --write-test /root-write-test/test
write failed: open /root-write-test/test: read-only file system
ROOT_WRITE_TEST_EXIT=1

$ docker compose -p lab6 exec -T quicknotes /healthcheck --write-test /tmp/test
write succeeded
TMPFS_WRITE_TEST_EXIT=0
```

5. `no-new-privileges`:

```text
$ docker inspect lab6-quicknotes-1 --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
```

6. Trivy scan:

The sandbox rejected mounting `/var/run/docker.sock` into the Trivy container because that grants broad Docker-daemon control. I used a safer equivalent scan path: save the local image to a tarball and mount that tarball read-only into Trivy.

```text
$ docker save quicknotes:lab6 -o .lab6-trivy/quicknotes-lab6.tar
$ docker run --rm -v "$PWD/.lab6-trivy:/scan:ro" aquasec/trivy:0.59.1 image --input /scan/quicknotes-lab6.tar --severity HIGH,CRITICAL --no-progress

/scan/quicknotes-lab6.tar (debian 13.5)
=======================================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 12 (HIGH: 12, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 12 (HIGH: 12, CRITICAL: 0)
```

The OS/base-image result is clean for HIGH/CRITICAL findings, which is the main value of distroless. Trivy still reports Go standard-library findings in the two static Go binaries because the `golang:1.24-alpine` builder currently resolves to Go `1.24.13`, and the database lists fixes in newer Go release lines. I kept the lab-required Go `1.24` base and documented the scan result instead of hiding it.

### Security reflection

The best security per line is `cap_drop: [ALL]` because QuickNotes does not need Linux capabilities at all, so the setting removes an entire privilege class with almost no operational cost. `read_only: true` is also high value because it turns many post-exploitation writes into immediate failures, while the named `/data` volume preserves the one path the app legitimately needs. Distroless is the best image-level default because it removes shells and package-manager tools that attackers often use after initial compromise. `no-new-privileges` is cheap defense-in-depth: it prevents privilege escalation through setuid or similar mechanisms even if such a binary appears later.
