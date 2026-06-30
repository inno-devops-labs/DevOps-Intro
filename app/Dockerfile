# --- Builder stage ---
FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git

WORKDIR /build

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build \
    -ldflags='-s -w' \
    -trimpath \
    -o /quicknotes .

# --- Runtime stage (минимальный alpine) ---
FROM alpine:3.19

# Устанавливаем wget (меньше curl) и удаляем кэш
RUN apk add --no-cache wget && rm -rf /var/cache/apk/*

COPY --from=builder /quicknotes /app/quicknotes

EXPOSE 8080

ENTRYPOINT ["/app/quicknotes"]
