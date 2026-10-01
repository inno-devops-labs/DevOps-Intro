# Build stage
FROM golang:1.24 AS builder

WORKDIR /src

# Copy dependency files first for better layer caching
COPY go.mod ./
RUN go mod download

# Copy source code
COPY . .

# Build QuickNotes as a static binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /quicknotes .

# Build healthcheck binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /healthcheck ./cmd/healthcheck

# Prepare writable data directory
RUN mkdir /data


# Runtime stage
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY --from=builder /src/seed.json /app/seed.json

# /data must be writable by the nonroot user
COPY --chown=65532:65532 --from=builder /data /data

EXPOSE 8080

USER 65532:65532

ENTRYPOINT ["/quicknotes"]