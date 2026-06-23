FROM golang:1.24-alpine AS builder

WORKDIR /build

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o quicknotes . && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o healthcheck ./healthcheck/ && \
    mkdir -p /staging/data

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /build/quicknotes /quicknotes
COPY --from=builder /build/healthcheck /healthcheck
COPY --from=builder /build/seed.json /seed.json
COPY --chown=65532:65532 --from=builder /staging/data /data

USER nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
