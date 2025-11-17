# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY main.go .

# Build static binary (no CGO, for scratch base)
RUN CGO_ENABLED=0 GOOS=linux \
    go build -tags netgo -trimpath \
    -ldflags="-s -w -extldflags=-static" \
    -o moscow-time main.go

# Run stage - minimal scratch image
FROM scratch

WORKDIR /app
COPY --from=builder /app/moscow-time .

EXPOSE 8080
ENTRYPOINT ["/app/moscow-time"]