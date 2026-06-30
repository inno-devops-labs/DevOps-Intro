# syntax=docker/dockerfile:1

# ─── builder stage ───
# Official Go image, pinned to a 1.24 patch (not :latest).
FROM golang:1.24.5 AS builder
WORKDIR /src

# Copy dependency manifest first so the module layer is cached independently
# of the source. QuickNotes has no third-party deps, so there is no go.sum.
COPY go.mod ./
RUN go mod download

# Now copy the source — changes here don't invalidate the layer above.
COPY . .

# Build a static, stripped, reproducible binary. CGO off so distroless-static
# (which has no libc / dynamic linker) can run it.
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /quicknotes .

# A tiny healthcheck helper — distroless has no shell/wget/curl, so we ship a
# minimal static binary that hits /health and exits 0/1.
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /healthcheck ./cmd/healthcheck

# Pre-create the data dir. A fresh named volume inherits this dir's ownership,
# so the nonroot user (65532) can write notes.json.
RUN mkdir -p /data

# ─── runtime stage ───
# Distroless static + nonroot: no shell, no package manager, runs as UID 65532.
FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /data /data
COPY seed.json /seed.json

# Sensible defaults so `docker run` works without extra env (compose overrides).
ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

EXPOSE 8080
USER nonroot
ENTRYPOINT ["/quicknotes"]
