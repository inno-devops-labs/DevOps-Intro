# syntax=docker/dockerfile:1.7

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/quicknotes .

RUN mkdir -p /out/data

FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder --chown=nonroot:nonroot /out/data /data
COPY --chown=nonroot:nonroot seed.json /app/seed.json

ENV ADDR=:8080
ENV DATA_PATH=/data/notes.json
ENV SEED_PATH=/app/seed.json

USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
