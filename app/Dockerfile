# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

RUN cat > /tmp/healthcheck.go <<'EOF'
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
EOF

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/healthcheck /tmp/healthcheck.go

# Create an empty /data directory that will be copied into the runtime image
RUN mkdir -p /out/data

FROM gcr.io/distroless/static:nonroot

WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck

# Make /data exist in the image and be owned by distroless nonroot UID/GID 65532.
# When Docker creates a fresh named volume, it initializes it from this directory.
COPY --from=builder --chown=65532:65532 /out/data /data

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]