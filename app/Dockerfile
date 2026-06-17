# syntax=docker/dockerfile:1.7

FROM golang:1.24.13-alpine AS builder

WORKDIR /src

# Copy dependency metadata first to preserve the module-cache layer.
COPY go.mod ./
RUN go mod download

# Copy application source after dependencies.
COPY *.go ./

RUN mkdir -p /out/data && \
    CGO_ENABLED=0 GOOS=linux go test ./... && \
    CGO_ENABLED=0 GOOS=linux go build \
      -trimpath \
      -ldflags="-s -w" \
      -o /out/quicknotes \
      .

# Build a static healthcheck executable because distroless has no shell,
# curl, wget, or package manager.
RUN <<'BUILD_HEALTHCHECK'
cat > /tmp/healthcheck.go <<'GO'
package main

import (
    "net/http"
    "os"
    "time"
)

func main() {
    client := http.Client{
        Timeout: 2 * time.Second,
    }

    response, err := client.Get("http://127.0.0.1:8080/health")
    if err != nil {
        os.Exit(1)
    }
    defer response.Body.Close()

    if response.StatusCode != http.StatusOK {
        os.Exit(1)
    }
}
GO

CGO_ENABLED=0 GOOS=linux go build \
  -trimpath \
  -ldflags="-s -w" \
  -o /out/healthcheck \
  /tmp/healthcheck.go
BUILD_HEALTHCHECK

FROM gcr.io/distroless/static-debian12:nonroot AS runtime

WORKDIR /

COPY --from=builder --chown=65532:65532 /out/quicknotes /quicknotes
COPY --from=builder --chown=65532:65532 /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY --chown=65532:65532 seed.json /seed.json

ENV ADDR=:8080 \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json

EXPOSE 8080

USER 65532:65532

ENTRYPOINT ["/quicknotes"]
