# Builder stage
FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/healthcheck ./cmd/healthcheck

RUN mkdir -p /out/data

# Runtime stage
FROM gcr.io/distroless/static:nonroot

COPY --from=builder /out/quicknotes /quicknotes

COPY --from=builder /out/healthcheck /healthcheck

COPY --from=builder --chown=nonroot:nonroot /out/data /data

COPY seed.json /seed.json

EXPOSE 8080

USER nonroot

ENTRYPOINT ["/quicknotes"]