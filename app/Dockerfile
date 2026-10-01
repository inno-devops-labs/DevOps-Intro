FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=linux GOARCH=$TARGETARCH \
    go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /quicknotes .

RUN cat > /tmp/healthcheck.go <<'EOF_HEALTH'
package main

import (
	"net/http"
	"os"
)

func main() {
	resp, err := http.Get("http://127.0.0.1:8080/health")
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
EOF_HEALTH

RUN CGO_ENABLED=0 GOOS=linux GOARCH=$TARGETARCH \
    go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /healthcheck /tmp/healthcheck.go

RUN mkdir -p /data

FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --chown=65532:65532 --from=builder /quicknotes /app/quicknotes
COPY --chown=65532:65532 --from=builder /healthcheck /app/healthcheck
COPY --chown=65532:65532 --from=builder /src/seed.json /app/seed.json
COPY --chown=65532:65532 --from=builder /data /data

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/app/quicknotes"]
