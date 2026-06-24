# Lab 6 Submission - Containers: Dockerize QuickNotes

---

## Task 1 - Multi-Stage Dockerfile

### 1.1 Dockerfile

```dockerfile
# --- Stage 1: builder ----------------------------------------------------
FROM golang:1.24-alpine AS builder

WORKDIR /src

# Copy dependency files first to maximize layer cache reuse.
# go.mod changes less frequently than source code —
# so if only source changes, the go mod download layer is reused.
COPY go.mod ./
RUN go mod download

# Copy source code after dependencies are cached
COPY . .

# Build a static binary:
# CGO_ENABLED=0 - disables C bindings, produces a fully static binary
# -trimpath     - removes local file paths from the binary
# -ldflags='-s -w' - strips debug symbols and DWARF info
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /quicknotes .

# --- Stage 2: runtime ----------------------------------------------------
# Distroless static image: no shell, no apt, no package manager, minimal CVEs.
# The :nonroot tag sets the default user to uid 65532 (nonroot).
FROM gcr.io/distroless/static:nonroot

# Copy only the compiled binary from the builder stage
COPY --from=builder /quicknotes /quicknotes

# Copy the seed data file needed by QuickNotes on startup
COPY seed.json /seed.json

# Document that the container listens on port 8080
EXPOSE 8080

# Run as nonroot user (uid 65532) — never as root
USER nonroot

# Use exec form (not shell form) so the process gets PID 1 directly.
# Shell form would require sh which doesn't exist in distroless.
ENTRYPOINT ["/quicknotes"]
```

### 1.2 Image size

```text
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   862b131225de       15.4MB         3.32MB 
```

Final image: **15.4 MB**

Base image size for comparison:
```text
$ docker images golang:1.24-alpine
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
golang:1.24-alpine   8bee1901f1e5        390MB         83.5MB 
```

### 1.3 docker inspect Config excerpt

```text
User:         nonroot
ExposedPorts: {"8080/tcp": {}}
Entrypoint:   ["/quicknotes"]
```

### 1.4 Design Questions

**a) Why does layer order matter?**
Dockerfile layers are cached by content. If `COPY . .` comes before `go mod download`, every source code change invalidates the dependency download layer, forcing a full re-download on every build. By copying `go.mod` first, running `go mod download`, then copying the source, the dependency layer is only invalidated when `go.mod` changes, not when source changes. Result: rebuilds go from ~30s to ~5s.

**b) Why `CGO_ENABLED=0`?**
By default, Go uses CGO to link against the host's C standard library (`libc`) for certain operations. A dynamically-linked binary requires `libc` to be present at runtime. `distroless/static` contains no C library. If you forget `CGO_ENABLED=0`, the container will fail with `no such file or directory` when trying to load the missing dynamic linker (`/lib/ld-linux-x86-64.so.2`). Setting `CGO_ENABLED=0` produces a fully static binary that carries everything it needs.

**c) What is `gcr.io/distroless/static:nonroot`?**
It is a Google-maintained base image containing only the absolute minimum needed to run a static binary: CA certificates, timezone data, and a minimal `/etc/passwd`. It has no shell (`sh`, `bash`), no package manager (`apt`, `apk`), no `libc`, no utilities. The `:nonroot` tag additionally sets the default user to `uid 65532` (named `nonroot`). This matters for CVEs because every package in a container is a potential vulnerability surface. With distroless, there are typically zero HIGH/CRITICAL CVEs in the base image because there is almost nothing to scan.

**d) `-ldflags='-s -w'` and `-trimpath`**
- `-ldflags='-s -w'`: `-s` strips the symbol table; `-w` strips DWARF debug info. Together they shrink the binary by ~30%. The cost: you cannot attach a debugger (`gdb`, `dlv`) to the binary or get useful stack traces with source line numbers. For a production release binary, this trade-off is acceptable.
- `-trimpath`: removes the local build path from the binary (e.g. `/home/mackay/DevOps-Intro/app/main.go` becomes `app/main.go`). This makes builds reproducible, the same source produces bit-for-bit identical binaries regardless of where on disk it was built. The cost: none in practice.

---
