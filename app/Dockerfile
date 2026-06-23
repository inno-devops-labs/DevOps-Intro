FROM golang:1.24-alpine AS builder

WORKDIR /build

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build \
    -ldflags='-s -w' \
    -trimpath \
    -o /qn \
    .

RUN CGO_ENABLED=0 go build \
    -ldflags='-s -w' \
    -trimpath \
    -o /healthcheck \
    ./healthcheck


FROM gcr.io/distroless/static:nonroot

COPY --from=builder /qn /qn
COPY --from=builder /healthcheck /healthcheck
COPY --from=builder /build/seed.json /seed.json

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/healthcheck"]

ENTRYPOINT ["/qn"]
