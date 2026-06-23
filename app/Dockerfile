# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/quicknotes"]