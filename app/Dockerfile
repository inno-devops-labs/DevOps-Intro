# syntax=docker/dockerfile:1

# ---- builder stage ----------------------------------------------------------
FROM golang:1.24 AS builder
WORKDIR /src

# Cache-optimized layer ordering: copy only the module file(s) first so the
# `go mod download` layer is reused unless dependencies change, not on every
# source edit. (QuickNotes has zero dependencies, so there is no go.sum.)
COPY go.mod ./
RUN go mod download

# Now bring in the source and build.
COPY . .

# Static (CGO disabled), stripped, reproducible binaries for app + healthcheck.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes . \
 && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./healthcheck

# Pre-create the data directory owned by the nonroot UID. When an empty named
# volume is first mounted at /data, Docker initializes it from this path and
# preserves the ownership — so the nonroot process can write even though
# distroless cannot chown at runtime.
RUN install -d -o 65532 -g 65532 /out/data

# ---- runtime stage ----------------------------------------------------------
FROM gcr.io/distroless/static:nonroot
WORKDIR /app

COPY --from=builder /out/quicknotes /app/quicknotes
COPY --from=builder /out/healthcheck /app/healthcheck
COPY --from=builder /src/seed.json /app/seed.json
COPY --from=builder --chown=65532:65532 /out/data /data

# Non-root (distroless 'nonroot' == UID/GID 65532).
USER 65532:65532
EXPOSE 8080

# Fixes Trivy config AVD-DS-0026; reuses the shell-less static probe binary.
HEALTHCHECK --interval=10s --timeout=3s --start-period=2s --retries=3 CMD ["/app/healthcheck"]

ENTRYPOINT ["/app/quicknotes"]
