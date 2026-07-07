# ─── builder stage ───
# 1.26: Go 1.24 stdlib (1.24.13) carries 10 HIGH CVEs, fixes only land in 1.25.8+/1.26.x
FROM golang:1.26-alpine AS builder
WORKDIR /src


COPY go.mod ./
RUN go mod download

# Then the source.
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /quicknotes .

RUN mkdir -p /data && chown 65532:65532 /data

# ─── runtime stage ───
FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder --chown=65532:65532 /data /data
COPY --chown=65532:65532 seed.json /seed.json

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

USER nonroot
EXPOSE 8080
# exec form: distroless has no shell; the binary self-probes /health (Trivy AVD-DS-0026)
HEALTHCHECK --interval=10s --timeout=3s --retries=5 CMD ["/quicknotes", "healthcheck"]
ENTRYPOINT ["/quicknotes"]
