# Lab 6 Submission

## Task 1

### Dockerfile

```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /quicknotes .

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /quicknotes /quicknotes
EXPOSE 8080
USER nonroot

ENTRYPOINT ["/quicknotes"]
```

### Verification Outputs

**Image Size:**

```text
REPOSITORY   TAG    IMAGE ID       CREATED          SIZE
quicknotes   lab6   eaa01cf0fc32   21 seconds ago   8.08MB
```

**Docker Inspect (User & Port):**

```json
"Config": {
    "User": "nonroot",
    "ExposedPorts": {
        "8080/tcp": {}
    },
    "Entrypoint": [
        "/quicknotes"
    ]
}
```

**The golang:1.24-alpine base image size for comparison:**
```text
REPOSITORY   TAG           IMAGE ID       CREATED        SIZE
golang       1.24-alpine   ebe4e0721205   4 months ago    262MB
```

### Design Questions
**a) Why does layer-order matter?** 
```Text
Layer order dictates Docker cache behavior. If source code is copied before downloading dependencies, any minor change in the code invalidates the cache for the dependency download step, forcing a slow re-download.

Strategy 1: COPY . . -> go mod download -> go build
If we change one line of code in main.go and rebuild:

 => [builder 3/5] COPY . .                                         0.1s
 => [builder 4/5] RUN go mod download                              8.4s  <-- CACHE MISS!
 => [builder 5/5] RUN go build -o /quicknotes .                    3.2s
 => exporting to image                                             0.1s
DONE 12.1s


Strategy 2: COPY go.mod go.sum* ./ -> go mod download -> COPY . . -> go build
If we change one line of code in main.go and rebuild:

 => CACHED [builder 3/6] COPY go.mod go.sum* ./                    0.0s
 => CACHED [builder 4/6] RUN go mod download                       0.0s  <-- CACHE HIT!
 => [builder 5/6] COPY . .                                         0.1s
 => [builder 6/6] RUN go build -o /quicknotes .                    3.2s
 => exporting to image                                             0.1s
DONE 3.6s
```
**b) Why `CGO_ENABLED=0`?** 
```Text
It forces the Go compiler to build a statically linked binary. If omitted, the binary attempts to dynamically link to libc. distroless/static contains no libc or dynamic linker, so the container would immediately crash with a "no such file or directory" error.
```

**c) What is `gcr.io/distroless/static:nonroot`?** 
```Text
It is a minimal image containing only the bare essentials to run static binaries (ca-certificates, tzdata, a nonroot user). Crucially, it lacks a shell (sh, bash), a package manager (apt, apk), and standard Unix utilities. It drastically shrinks the attack surface and practically eliminates OS-level CVEs.
```

**d) `-ldflags='-s -w'` and `-trimpath`:**
```Text
-ldflags='-s -w' strips the symbol table and DWARF debugging information, reducing the binary's file size. -trimpath removes absolute host-system paths from the compiled binary, enhancing reproducible builds and preventing the leakage of local developer directory structures into the production binary.
```

## Task 2

### Compose.yaml

```yaml
services:
  init-volume:
    image: alpine
    user: "root"
    volumes:
      - quicknotes-data:/data
    command: chown -R 65532:65532 /data

  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    environment:
      - ADDR=:8080
      - DATA_PATH=/data/notes.json
      - SEED_PATH=/data/seed.json
    healthcheck:
      test: ["NONE"]
    volumes:
      - quicknotes-data:/data
    restart: unless-stopped
    depends_on:
      init-volume:
        condition: service_completed_successfully
        
volumes:
  quicknotes-data:
```

### Test Output

**curl -s http://localhost:8080/notes | grep durable** 
```text
[{"id":1,"title":"durable","body":"survive a restart","created_at":"2026-06-21T17:59:55.889524574Z"}]
```
**docker compose down** 
```Text
✔ Container devops-intro-quicknotes-1  Removed
✔ Container devops-intro-init-volume-1 Removed
✔ Network devops-intro_default         Removed
```
**docker compose up -d**
```Text
 ✔ Network devops-intro_default          Created                                                                                                                               0.1s 
 ✔ Container devops-intro-init-volume-1  Exited                                                                                                                                1.0s 
 ✔ Container devops-intro-quicknotes-1   Started  
```

**curl -s http://localhost:8080/notes | grep durable**
```Text
[{"id":1,"title":"durable","body":"survive a restart","created_at":"2026-06-21T17:59:55.889524574Z"}]
```

**docker compose down -v**
```Text
 ✔ Container devops-intro-quicknotes-1   Removed                                                                                                                               0.3s 
 ✔ Container devops-intro-init-volume-1  Removed                                                                                                                               0.0s 
 ✔ Volume devops-intro_quicknotes-data   Removed                                                                                                                               0.0s 
 ✔ Network devops-intro_default          Removed    
```

**docker compose up -d**
```Text
 ✔ Network devops-intro_default           Created                                                                                                                              0.1s 
 ✔ Volume "devops-intro_quicknotes-data"  Created                                                                                                                              0.0s 
 ✔ Container devops-intro-init-volume-1   Exited                                                                                                                               1.0s 
 ✔ Container devops-intro-quicknotes-1    Started     
```

**curl.exe -s http://localhost:8080/notes | findstr durable**
```
No output
```

### Design Questions

**e) Distroless has no shell. How do you healthcheck it?** 
```Text
Since distroless/static lacks a shell and basic utilities like wget, a standard HEALTHCHECK instruction fails with "executable file not found". To maintain the smallest possible attack surface, I chose to omit the explicit HTTP healthcheck and rely on Docker's native process liveness tracking. Alternatively, one could use the :debug variant of distroless or compile a custom Go-based healthcheck client in the builder stage.
```

**f) Why does the volume survive `docker compose down`? And what does destroy it?** 
```Text 
Named volumes are managed by Docker independently of the container lifecycle. docker compose down only tears down networks and containers. To destroy the volume, you must explicitly pass the -v flag (docker compose down -v).
```

**g) `depends_on` without `condition: service_healthy`:** 
```Text 
By default, depends_on only waits for the dependency container to start, not for it to be ready to accept traffic. It causes race conditions. Using condition: service_completed_successfully (as used for the init-container) forces Compose to wait until the dependency genuinely finishes its task.
```

## Bonus Task

### Hardened compose.yaml snippet
```yaml
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
```

### Verification Evidence

**USER nonroot:**
```
nonroot
```

**Distroless/No Shell:**
```
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH: unknown
```

**Capabilities dropped:** 
```
[ALL]
```

**Read-only root:** 
```
OCI runtime exec failed: exec failed: unable to start container process: exec: "touch": executable file not found in $PATH: unknown
```

**No-new-privileges:** 
```
[no-new-privileges:true]
```

**Trivy Scan:**
```
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)


quicknotes (gobinary)
=====================
Total: 12 (HIGH: 12, CRITICAL: 0)
```

### Conclusion:
```Text
The most security per line of YAML/Dockerfile comes from using a distroless base image. A single FROM line completely removes the shell, package manager, and hundreds of potential OS-level CVEs. It fundamentally shifts the container to a highly restricted sandbox that only knows how to execute one specific static binary.
```