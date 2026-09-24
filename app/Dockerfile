FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY *.go ./
COPY seed.json ./
RUN mkdir -p /src/data

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags='-s -w' \
    -o /quicknotes .

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

	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
GOEOF

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags='-s -w' \
    -o /healthcheck /tmp/healthcheck.go


FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY --from=builder /src/seed.json /seed.json
COPY --from=builder --chown=65532:65532 /src/data /data

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/quicknotes"]
