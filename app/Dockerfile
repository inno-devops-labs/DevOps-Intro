FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -trimpath -o /quicknotes .

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["/quicknotes", "-health"]

ENTRYPOINT ["/quicknotes"]
