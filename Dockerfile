FROM golang:1.24-alpine AS builder
WORKDIR /build
COPY app/go.mod ./
RUN go mod download
COPY app/ .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -trimpath \
    -o /build/quicknotes .

# ╨б╨╛╨╖╨┤╨░╤С╨╝ ╨┐╨░╨┐╨║╤Г /data ╨╕ ╨┤╨░╤С╨╝ ╨┐╤А╨░╨▓╨░ ╨▓ builder
RUN mkdir -p /data && chown 65532:65532 /data

FROM gcr.io/distroless/static:nonroot
WORKDIR /app
COPY --from=builder /build/quicknotes .
COPY --from=builder /data /data
COPY app/seed.json .
EXPOSE 8080
ENTRYPOINT ["/app/quicknotes"]
