# syntax=docker/dockerfile:1

FROM golang:1.24.5-alpine AS builder

WORKDIR /src

# Dependency layer first for better cache reuse.
COPY go.mod ./
RUN go mod download

# Application source.
COPY *.go ./
COPY seed.json ./

# Build a static, stripped QuickNotes binary.
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/quicknotes .

# Build a tiny static healthcheck binary because distroless has no shell/curl.
RUN cat > /tmp/healthcheck.go <<'HEALTH'
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	client := http.Client{Timeout: 2 * time.Second}

	resp, err := client.Get("http://127.0.0.1:8080/health")
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
HEALTH

RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/healthcheck /tmp/healthcheck.go

# Prepare /data with nonroot ownership.
RUN mkdir -p /out/data && touch /out/data/.keep


FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --chown=65532:65532 seed.json /seed.json
COPY --chown=65532:65532 --from=builder /out/data /data

USER 65532:65532

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
