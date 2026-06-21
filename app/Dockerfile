# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

RUN cat > /tmp/healthcheck.go <<'GOEOF'
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

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		os.Exit(1)
	}
}
GOEOF

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/healthcheck /tmp/healthcheck.go

RUN mkdir -p /out/data

FROM gcr.io/distroless/static:nonroot

WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY --from=builder /src/seed.json /seed.json

USER 65532:65532

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
