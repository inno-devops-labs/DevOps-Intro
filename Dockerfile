FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY app/ .
RUN go mod download && go build -o /tmp/qn .

FROM alpine:latest
COPY --from=builder /tmp/qn /usr/local/bin/qn
EXPOSE 8080
CMD ["/usr/local/bin/qn"]