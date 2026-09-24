# syntax=docker/dockerfile:1

# ---------- Stage 1: build ----------
FROM golang:1.24-alpine AS builder
WORKDIR /src

# Dependencies first: this layer is reused until go.mod/go.sum change
COPY go.mod go.sum* ./
RUN go mod download

# Source second: editing code only invalidates the layers below
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/quicknotes . \
 && CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./cmd/healthcheck \
 && mkdir -p /out/data

# ---------- Stage 2: runtime ----------
FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /app

COPY --from=builder /out/quicknotes /out/healthcheck /app/
COPY --from=builder /src/seed.json /app/seed.json
# /data owned by nonroot so a fresh named volume inherits writable ownership
COPY --from=builder --chown=65532:65532 /out/data /data

ENV ADDR=:8080 \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/app/seed.json

USER nonroot:nonroot
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/app/healthcheck"]
ENTRYPOINT ["/app/quicknotes"]
