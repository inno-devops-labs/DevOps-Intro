# syntax=docker/dockerfile:1
# Lab 6 — multi-stage QuickNotes (≤ 25 MB, distroless nonroot)

# ─── builder ───
FROM golang:1.24-alpine AS builder
WORKDIR /src

# Cache deps before copying source (maximize layer reuse)
COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/quicknotes .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./cmd/healthcheck
# Pre-create /data owned by distroless nonroot (UID 65532) so named volumes inherit writable perms
RUN mkdir -p /out/data && chown 65532:65532 /out/data

# ─── runtime ───
FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY seed.json /seed.json

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

EXPOSE 8080
USER nonroot:nonroot

# Distroless has no shell/wget — use our static healthcheck binary
HEALTHCHECK --interval=5s --timeout=2s --start-period=3s --retries=3 \
  CMD ["/healthcheck"]

ENTRYPOINT ["/quicknotes"]
