# syntax=docker/dockerfile:1

FROM golang:1.24.13-alpine AS builder

WORKDIR /src

# Cache module downloads independently from source-code changes.
COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

# Distroless contains no shell, curl, or wget, so provide a dedicated probe.
RUN <<'EOF'
cat > /tmp/healthcheck.go <<'GO'
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
GO
CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/healthcheck /tmp/healthcheck.go
mkdir /out/data
EOF

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder /src/seed.json /seed.json
# An empty named volume inherits this mount-point ownership on first use.
COPY --chown=65532:65532 --from=builder /out/data /data

USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
