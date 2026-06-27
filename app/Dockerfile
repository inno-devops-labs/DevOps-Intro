FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o quicknotes .

FROM alpine:3.21
RUN apk add --no-cache curl
COPY --from=builder /app/quicknotes /usr/local/bin/quicknotes
EXPOSE 8080
CMD ["quicknotes"]