# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

ARG TARGETOS=linux
ARG TARGETARCH=amd64
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes . && \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" -o /out/healthcheck ./cmd/healthcheck && \
    mkdir -p /out/data && \
    touch /out/data/.keep

FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --chown=nonroot:nonroot seed.json /app/seed.json
COPY --from=builder --chown=nonroot:nonroot /out/data /data

USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
