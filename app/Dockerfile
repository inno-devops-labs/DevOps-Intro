# ─── Stage 1: builder ───────────────────────────────────────────────────────
# Use official Go image on Alpine for a small build environment.
# Bumped 1.24 -> 1.25 in Lab 9: Go stdlib 1.24.13 carried 11 HIGH CVEs
# (net/url, crypto/x509, crypto/tls, net, http2, net/mail — all DoS-class),
# all fixed in >= 1.25.11. Rebuilding on 1.25 clears every image finding.
FROM golang:1.25-alpine AS builder

WORKDIR /src

# Copy dependency files first to maximize layer cache reuse.
# go.mod and go.sum change less frequently than source code — 
# so if only source changes, the go mod download layer is reused.
COPY go.mod ./
RUN go mod download

# Copy source code after dependencies are cached
COPY . .

# Build a static binary:
# CGO_ENABLED=0 — disables C bindings, produces a fully static binary
# -trimpath     — removes local file paths from the binary (reproducibility)
# -ldflags='-s -w' — strips debug symbols and DWARF info (smaller binary)
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /quicknotes .

# Build a minimal HTTP healthcheck binary inline.
# This single-file Go program does GET /health and exits 0 on 200, 1 otherwise.
# We build it here rather than copying wget from busybox to avoid relying on
# external image tags and to guarantee a fully static binary compatible with
# distroless/static (which has no libc or dynamic linker).
RUN printf 'package main\nimport ("net/http";"os")\nfunc main(){r,e:=http.Get("http://localhost:8080/health");if e!=nil{os.Exit(1)};if r.StatusCode!=200{os.Exit(1)}}\n' \
    > /tmp/healthcheck.go && \
    CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /healthcheck /tmp/healthcheck.go

# Pre-create the /data directory owned by nonroot (uid 65532).
# When Docker mounts a fresh named volume here, it copies the image's /data
# into the volume — preserving ownership — so the nonroot process can write to it.
RUN mkdir -p /data

# ─── Stage 2: runtime ───────────────────────────────────────────────────────
# Distroless static image: no shell, no apt, no package manager, minimal CVEs.
# The :nonroot tag sets the default user to uid 65532 (nonroot).
FROM gcr.io/distroless/static:nonroot

# Copy only the compiled binary from the builder stage
COPY --from=builder /quicknotes /quicknotes

# Copy the compiled healthcheck binary (distroless has no shell, curl, or wget)
COPY --from=builder /healthcheck /healthcheck

# Copy the pre-created /data directory with nonroot ownership so a fresh
# named volume inherits the correct permissions without a separate init container.
COPY --from=builder --chown=65532:65532 /data /data

# Copy the seed data file needed by QuickNotes on startup
COPY seed.json /seed.json

# Document that the container listens on port 8080
EXPOSE 8080

# Run as nonroot user (uid 65532) — never as root
USER nonroot

# Use exec form (not shell form) so the process gets PID 1 directly
ENTRYPOINT ["/quicknotes"]