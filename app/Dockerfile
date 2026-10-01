# syntax=docker/dockerfile:1

# ---- Builder stage ----
FROM golang:1.24-alpine AS builder

WORKDIR /src

# Copy dependency files first to maximize layer cache reuse.
COPY go.mod ./
RUN go mod download

# Copy application source.
COPY . .

# Build a static, stripped, reproducible binary.
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/quicknotes . && \
    mkdir -p /out/data && \
    chown 65532:65532 /out/data

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/healthcheck ./cmd/healthcheck

# ---- Runtime stage ----
FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /app/quicknotes
COPY --from=builder /out/healthcheck /app/healthcheck
COPY --from=builder /src/seed.json /app/seed.json
COPY --from=builder --chown=65532:65532 /out/data /data

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/app/quicknotes"]
