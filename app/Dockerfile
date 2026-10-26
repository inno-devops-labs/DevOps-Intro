# syntax=docker/dockerfile:1

# ------------------------------------------------------------
# Stage 1: build
# ------------------------------------------------------------
FROM golang:1.27.3-alpine AS builder

WORKDIR /src

# Keep dependency download in its own cacheable layer.
COPY go.mod ./
RUN go mod download

COPY . .

# Build the application.
RUN CGO_ENABLED=0 GOOS=linux \
    go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/quicknotes \
    .

# Build a tiny HTTP healthcheck binary for the distroless image.
RUN CGO_ENABLED=0 GOOS=linux \
    go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/healthcheck \
    ./cmd/healthcheck

# Prepare an empty writable data directory.
RUN mkdir -p /out/data

# ------------------------------------------------------------
# Stage 2: runtime
# ------------------------------------------------------------
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY seed.json /seed.json

# UID/GID 65532 is the distroless nonroot identity.
COPY --from=builder --chown=65532:65532 /out/data /data

USER nonroot:nonroot

EXPOSE 8080

HEALTHCHECK --interval=5s --timeout=3s --start-period=2s --retries=5 CMD ["/healthcheck"]

ENTRYPOINT ["/quicknotes"]
