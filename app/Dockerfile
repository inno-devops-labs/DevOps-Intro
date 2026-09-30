# ---- Builder stage ----
FROM golang:1.24-alpine AS builder

WORKDIR /src

# Copy dependency metadata first to maximize layer-cache reuse.
COPY go.mod ./
RUN go mod download

# Copy application source only after dependencies are cached.
COPY . .

# Build QuickNotes as a small, fully static binary.
RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags='-s -w' \
    -o /quicknotes \
    .

# Build a tiny static HTTP healthcheck binary.
RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags='-s -w' \
    -o /healthcheck \
    ./cmd/healthcheck

# Prepare the persistent-data directory.
RUN mkdir -p /runtime-data && touch /runtime-data/.keep


# ---- Runtime stage ----
FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY seed.json /seed.json

# Initialize /data with ownership matching distroless nonroot (UID/GID 65532).
COPY --from=builder --chown=65532:65532 /runtime-data/ /data/

USER nonroot

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
