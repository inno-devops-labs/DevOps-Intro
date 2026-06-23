FROM golang:1.24-alpine AS builder
WORKDIR /build
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags='-s -w' \
    -trimpath \
    -o quicknotes .

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /build/quicknotes /app/quicknotes
WORKDIR /app
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/app/quicknotes"]
