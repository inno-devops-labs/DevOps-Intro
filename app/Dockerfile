FROM golang:1.24-alpine AS builder

WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/quicknotes . && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/healthcheck ./cmd/healthcheck && \
    mkdir -p /out/data

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY seed.json /app/seed.json
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
