# syntax=docker/dockerfile:1.7

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/quicknotes .

RUN cat <<'EOF' >/tmp/healthcheck.go
package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	if len(os.Args) == 3 && os.Args[1] == "--write-test" {
		if err := os.WriteFile(os.Args[2], []byte("write-test"), 0o644); err != nil {
			fmt.Fprintf(os.Stderr, "write failed: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("write succeeded")
		return
	}

	url := "http://127.0.0.1:8080/health"
	if override := os.Getenv("HEALTHCHECK_URL"); override != "" {
		url = override
	}

	client := http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		fmt.Fprintf(os.Stderr, "healthcheck failed: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		fmt.Fprintf(os.Stderr, "unexpected status: %s\n", resp.Status)
		os.Exit(1)
	}
}
EOF

RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/healthcheck /tmp/healthcheck.go

RUN mkdir -p /out/data /out/root-write-test

FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=nonroot:nonroot /out/data /data
COPY --from=builder --chown=nonroot:nonroot /out/root-write-test /root-write-test
COPY --chown=nonroot:nonroot seed.json /app/seed.json

ENV ADDR=:8080
ENV DATA_PATH=/data/notes.json
ENV SEED_PATH=/app/seed.json

USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
