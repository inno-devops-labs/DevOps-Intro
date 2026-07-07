# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags='-s -w' \
    -o /quicknotes .

FROM busybox:1.36-musl AS busybox

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json
COPY --from=busybox /bin/busybox /busybox
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
