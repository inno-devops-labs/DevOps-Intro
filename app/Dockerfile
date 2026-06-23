FROM golang:1.24.5-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /quicknotes

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json

EXPOSE 8080

USER 65532:65532

ENTRYPOINT ["/quicknotes"]