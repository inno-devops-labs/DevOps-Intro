FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /quicknotes .


FROM gcr.io/distroless/static:nonroot

WORKDIR /

COPY --from=builder /quicknotes /quicknotes

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/quicknotes"]