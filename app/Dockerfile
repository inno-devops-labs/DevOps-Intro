# syntax=docker/dockerfile:1

# ---- builder stage ----
FROM golang:1.24.13-alpine AS builder

WORKDIR /src

# copy go.mod/go.sum first so dependency download is cached
# across rebuilds that only change source code
COPY go.mod go.sum* ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags='-s -w' -trimpath \
    -o /out/quicknotes .

# distroless has no shell, curl or wget, so build a tiny static binary
# that just GETs /health and exits 0/1 - used as the HEALTHCHECK command
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
CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck /tmp/healthcheck.go
EOF

# empty dir owned by nonroot, baked in so a fresh named volume
# mounted at /data inherits this ownership instead of root's
RUN mkdir /out/data && chown 65532:65532 /out/data

# ---- runtime stage ----
FROM gcr.io/distroless/static:nonroot AS runtime

WORKDIR /app

COPY --from=builder /out/quicknotes /app/quicknotes
COPY --from=builder /out/healthcheck /app/healthcheck
COPY --from=builder /src/seed.json /app/seed.json
COPY --from=builder --chown=65532:65532 /out/data /data

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/app/quicknotes"]
