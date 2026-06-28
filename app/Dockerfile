FROM golang:1.24-alpine AS builder

WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o quicknotes .

FROM alpine:3.20

RUN apk --no-cache add ca-certificates && \
    adduser -D -g '' appuser

WORKDIR /app
COPY --from=builder /src/quicknotes .
COPY --from=builder /src/data ./data
COPY --from=builder /src/seed.json .

RUN chown -R appuser:appuser /app

USER appuser

ENV ADDR=:8080
ENV DATA_PATH=/app/data/notes.json
ENV SEED_PATH=/app/seed.json

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

EXPOSE 8080

CMD ["./quicknotes"]
