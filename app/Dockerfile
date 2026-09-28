# syntax=docker/dockerfile:1.7

FROM golang:1.24-alpine AS builder
WORKDIR /src

# Keep dependency download cacheable when application source changes. This
# project currently has no go.sum because it only uses the standard library.
COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go test ./... && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes . && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./cmd/healthcheck && \
    mkdir -p /out/data && cp seed.json /out/data/notes.json

FROM gcr.io/distroless/static-debian12:nonroot AS runtime
WORKDIR /app

COPY --from=builder --chown=65532:65532 /out/quicknotes /quicknotes
COPY --from=builder --chown=65532:65532 /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY --chown=65532:65532 seed.json /app/seed.json

USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
