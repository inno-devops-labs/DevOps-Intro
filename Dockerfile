FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY app/go.mod .
RUN go mod download
COPY app/ .
RUN go build -o quicknotes .

FROM alpine:3.21
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/quicknotes .
COPY app/seed.json .
EXPOSE 8080
CMD ["./quicknotes"]
