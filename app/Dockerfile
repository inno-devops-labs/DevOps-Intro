# syntax=docker/dockerfile:1

# ---------- build stage ----------
FROM golang:1.24 AS build
WORKDIR /src

# Dependencies first so the source-copy below doesn't bust this cache layer.
# QuickNotes is std-lib only, so there's just go.mod (no go.sum).
COPY go.mod ./
RUN go mod download

# Now the source.
COPY . .

# Static, stripped, reproducible binary.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

# Distroless has no shell/curl/wget, so the container needs its own probe.
# A tiny static binary that GETs /health and exits 0/1.
COPY <<'EOF' /src/hc/main.go
package main

import (
	"net/http"
	"os"
)

func main() {
	resp, err := http.Get("http://127.0.0.1:8080/health")
	if err != nil || resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
EOF
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./hc

# A writable data dir owned by nonroot (UID 65532). A fresh named volume
# mounted here inherits this ownership, so the app can write notes.json.
RUN mkdir -p /data && chown 65532:65532 /data

# ---------- runtime stage ----------
FROM gcr.io/distroless/static:nonroot

COPY --from=build /out/quicknotes /quicknotes
COPY --from=build /out/healthcheck /healthcheck
COPY --from=build /src/seed.json /seed.json
COPY --from=build --chown=65532:65532 /data /data

ENV ADDR=:8080 \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json

USER 65532:65532
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=3s --retries=3 CMD ["/healthcheck"]
ENTRYPOINT ["/quicknotes"]
