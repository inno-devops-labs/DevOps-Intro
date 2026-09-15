# syntax=docker/dockerfile:1

# Build stage
FROM golang:1.24 AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY *.go ./
COPY cmd/healthcheck ./cmd/healthcheck

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /quicknotes \
    .

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /healthcheck \
    ./cmd/healthcheck

# Runtime stage
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app

COPY --from=builder /quicknotes /app/quicknotes
COPY --from=builder /healthcheck /app/healthcheck
COPY seed.json /app/seed.json

COPY --chown=nonroot:nonroot --from=builder /tmp /data

ENV ADDR=:8080
ENV DATA_PATH=/data/notes.json
ENV SEED_PATH=/app/seed.json

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/app/quicknotes"]