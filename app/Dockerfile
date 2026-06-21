# syntax=docker/dockerfile:1

# ---- builder stage: full Go toolchain, produces a static stripped binary ----
FROM golang:1.24 AS build
WORKDIR /src

# go.mod first (no go.sum: QuickNotes has zero third-party deps) so this layer
# is cached and only re-runs when the module file actually changes.
COPY go.mod ./
RUN go mod download

# now the source — changing code invalidates only from here down
COPY . .

# CGO off => a fully static binary that needs no libc / dynamic linker, which is
# exactly what distroless-static expects. -trimpath + -ldflags '-s -w' strip the
# build for a smaller, reproducible binary.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /qn .

# a tiny health probe binary (distroless has no shell/curl/wget to healthcheck with).
# Built here, copied into the runtime image, invoked by HEALTHCHECK.
RUN <<'EOF'
set -e
cat > /tmp/healthcheck.go <<'GO'
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
GO
CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /healthcheck /tmp/healthcheck.go
# /data created here so the runtime image owns it as nonroot; a named volume
# mounted over it inherits this ownership, so UID 65532 can write notes.json.
mkdir -p /data
EOF

# ---- runtime stage: distroless static, nonroot, no shell, no package manager ----
FROM gcr.io/distroless/static:nonroot

COPY --from=build /qn /qn
COPY --from=build /healthcheck /healthcheck
COPY --from=build /src/seed.json /seed.json
COPY --from=build --chown=65532:65532 /data /data

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

EXPOSE 8080
USER nonroot:nonroot

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/healthcheck"]

ENTRYPOINT ["/qn"]
