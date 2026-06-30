# syntax=docker/dockerfile:1

# Builder: official Go, pinned to the latest 1.24 patch (not :latest). Staying
# current within 1.24 clears the standard-library CVEs that have a 1.24 fix.
FROM golang:1.24.13 AS builder
WORKDIR /src

# Dependency manifest first so the module layer caches apart from the source.
# QuickNotes has no third-party deps, so there is no go.sum.
COPY go.mod ./
RUN go mod download

# Then the source. Editing code does not bust the layer above.
COPY . .

# Static, stripped, reproducible build. CGO off so the binary needs no libc,
# which is what lets distroless-static run it.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

# Distroless has no shell, curl, or wget, so ship a tiny probe the healthcheck
# can exec. It does a GET /health and exits 0 or 1.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./cmd/healthcheck

# Pre-create the data dir. A fresh named volume copies this dir's ownership, so
# the nonroot user (65532) can write notes.json into the volume.
RUN mkdir -p /out/data

# Runtime: distroless static + nonroot. No shell, no package manager, UID 65532.
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY --from=builder /src/seed.json /seed.json

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

USER nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
