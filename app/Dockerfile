# syntax=docker/dockerfile:1.7

# ---------- Stage 1: builder ----------
FROM golang:1.24-alpine AS builder

WORKDIR /src

# Cache dependencies first (even with no deps, this keeps the pattern correct)
COPY go.mod ./
RUN go mod download

# Copy source and build a fully static binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w" \
    -trimpath \
    -o /out/quicknotes .

# ---------- Stage 2: runtime ----------
FROM gcr.io/distroless/static:nonroot

# Copy binary and seed file
COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json

# Distroless static:nonroot already runs as UID 65532, but be explicit
USER 65532:65532

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]