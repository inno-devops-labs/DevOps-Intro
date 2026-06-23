# syntax=docker/dockerfile:1

FROM golang:1.24.5-alpine AS builder
WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -trimpath -ldflags='-s -w' -o /quicknotes .

# Tiny static HTTP probe — distroless has no shell/curl for HEALTHCHECK
RUN printf '%s\n' \
    'package main' \
    'import ("net/http"; "os")' \
    'func main() {' \
    '  r, err := http.Get("http://127.0.0.1:8080/health")' \
    '  if err != nil || r == nil || r.StatusCode != http.StatusOK { os.Exit(1) }' \
    '}' \
    > /healthcheck.go && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -trimpath -ldflags='-s -w' -o /healthcheck /healthcheck.go

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY seed.json /seed.json

EXPOSE 8080
USER nonroot
ENTRYPOINT ["/quicknotes"]
