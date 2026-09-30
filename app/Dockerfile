# syntax=docker/dockerfile:1

# Build stage
FROM golang:1.24 AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY *.go ./

RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /quicknotes \
    .

# Runtime stage
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app

COPY --from=builder /quicknotes /app/quicknotes
COPY seed.json /app/seed.json

COPY --chown=nonroot:nonroot --from=builder /tmp /data

ENV ADDR=:8080
ENV DATA_PATH=/data/notes.json
ENV SEED_PATH=/app/seed.json

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/app/quicknotes"]