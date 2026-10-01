# syntax=docker/dockerfile:1

##############################################################################
# Stage 1 - builder: full Go toolchain, compiles a static binary
##############################################################################
FROM golang:1.24-alpine AS builder

WORKDIR /src

# --- Layer-cache-friendly order (requirement 1.1.9) -------------------------
# Copy ONLY the dependency manifest first, so `go mod download` becomes a
# cached layer that never re-runs when source files change.
# This module is stdlib-only (go.mod has no require lines), so there is no
# go.sum file - COPY go.mod alone is the complete dependency manifest here.
# `go mod download` stays anyway: the day the first dependency appears,
# this layer starts doing real work and remains cacheable.
COPY go.mod ./
RUN go mod download

# Only now copy the source - edits to .go files do NOT invalidate the
# dependency layer above.
COPY . .

# --- Static, stripped, reproducible build ------------------------------------
#   CGO_ENABLED=0    -> pure-Go static binary, no libc, runs on distroless
#   -trimpath        -> no absolute build-machine paths inside the binary
#   -ldflags='-s -w' -> strip symbol table (-s) and DWARF debug info (-w)
# mkdir /out/data    -> the runtime stage cannot mkdir (no shell), so we
#                       ship a /data directory into the final image.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes . \
    && mkdir /out/data

##############################################################################
# Stage 2 - runtime: distroless static, nonroot, no shell, no package manager
##############################################################################
FROM gcr.io/distroless/static-debian12:nonroot

# Binary + an empty /data directory owned by UID 65532 (nonroot).
# When the named volume from compose.yaml is first mounted, Docker copies
# this directory's contents AND ownership into the volume - that is what
# lets the nonroot process create /data/notes.json (the classic
# "root-owned volume" pitfall from the lab).
COPY --from=builder --chown=65532:65532 /out/quicknotes /quicknotes
COPY --from=builder --chown=65532:65532 /out/data /data

# Seed file (4 starter notes); the app only ever reads it.
COPY --from=builder /src/seed.json /seed.json

# Sensible defaults so even a plain `docker run quicknotes:lab6` works;
# compose.yaml passes the same values explicitly (requirement 2.1.5).
ENV ADDR=":8080" \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json

EXPOSE 8080

# Distroless nonroot = UID 65532. Never root (requirement 1.1.6).
USER nonroot

# Exec form (requirement 1.1.7). Bonus healthcheck strategy: distroless has
# no shell/curl/wget, so the app binary itself carries a `healthcheck`
# subcommand (see main.go) that dials ADDR/health and exits 0/1 - that is
# what compose.yaml's healthcheck invokes.
ENTRYPOINT ["/quicknotes"]
