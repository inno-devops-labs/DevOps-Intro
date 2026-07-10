# syntax=docker/dockerfile:1

# ---- Stage 1: builder ----
# Pinned Go 1.24 (not :latest) on Alpine for a small builder.
FROM golang:1.26.4-alpine AS builder

WORKDIR /src

# Copy go.mod (and go.sum if present) FIRST and download deps, so this layer
# is cached and only re-runs when dependencies change ??? not on every source
# edit. This is the layer-cache-friendly ordering.
COPY go.mod ./
RUN go mod download

# Now copy the rest of the source. Edits here don't bust the deps layer above.
COPY . .

# Build a fully static binary:
#   CGO_ENABLED=0  -> no libc dependency, runs on distroless-static / scratch
#   -trimpath      -> strip local filesystem paths for reproducible builds
#   -ldflags=-s -w -> drop symbol table and DWARF debug info to shrink the binary
RUN CGO_ENABLED=0 GOOS=linux go build \
        -trimpath \
        -ldflags='-s -w' \
        -o /out/quicknotes .

# ---- Stage 2: runtime ----
# distroless static: no shell, no package manager, no libc ??? just CA certs,
# tzdata, /etc/passwd with a nonroot user, and nothing else.
FROM gcr.io/distroless/static:nonroot

# Copy only the compiled binary and the seed file from the builder.
COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json

# Run as the built-in nonroot user (UID 65532), never root.
USER nonroot:nonroot

EXPOSE 8080

# Exec form (not shell form) ??? distroless has no shell to interpret a string.
ENTRYPOINT ["/quicknotes"]

