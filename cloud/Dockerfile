FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -trimpath -o /quicknotes .

FROM alpine:3.21
RUN apk add --no-cache ca-certificates curl
COPY --from=builder /quicknotes /quicknotes
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
ENTRYPOINT ["/quicknotes"]
