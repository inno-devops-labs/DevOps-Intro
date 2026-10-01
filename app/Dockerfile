# syntax=docker/dockerfile:1

# ---------- builder ----------
FROM golang:1.24.13-alpine AS builder

WORKDIR /src

# Dependency manifests first: this layer is invalidated only when go.mod /
# go.sum change, so editing .go files still reuses the cached module download.
# (go.sum is globbed because QuickNotes has no third-party dependencies yet.)
COPY go.mod go.sum* ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

# The runtime image has no shell and no wget, so the healthcheck has to be a
# static binary of its own. It lives here rather than in app/ because it is a
# packaging concern, not part of QuickNotes.
COPY <<'EOF' /hc/main.go
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://127.0.0.1:8080/health")
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
EOF

RUN cd /hc && go mod init healthcheck >/dev/null && \
    CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/healthcheck .

# Empty /data owned by the runtime UID. Docker seeds a fresh named volume from
# the image's mount point, so this is what makes the volume writable by a
# nonroot container without any chown at runtime (there is no shell to run one).
RUN mkdir -p /data-template

# ---------- runtime ----------
FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /app/quicknotes
COPY --from=builder /out/healthcheck /app/healthcheck
COPY --from=builder /src/seed.json /app/seed.json
COPY --from=builder --chown=65532:65532 /data-template /data

USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/app/quicknotes"]
