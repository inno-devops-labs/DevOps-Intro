# syntax=docker/dockerfile:1.7

# Stage 1: builder
FROM golang:1.24.13-alpine AS builder
WORKDIR /src

# Layer-cache: dependencies before source
COPY go.mod ./
RUN go mod download

COPY . .

ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

RUN go build -trimpath -ldflags='-s -w' -o /out/quicknotes . \
 && go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./cmd/healthcheck \
 && mkdir -p /out/data

# Stage 2: runtime — distroless static, nonroot
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /out/quicknotes  /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder /src/seed.json   /seed.json
COPY --from=builder --chown=65532:65532 /out/data /data

ENV ADDR=:8080 \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json

EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/quicknotes"]
