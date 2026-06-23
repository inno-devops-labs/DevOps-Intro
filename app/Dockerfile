# Stage 1: builder stage
FROM golang:1.24 AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

RUN mkdir -p /data

COPY . .

RUN CGO_ENABLED=0 GOOS=linux \
    go build -trimpath -ldflags='-s -w' -o /quicknotes .

# Stage 2: runtime stage
FROM gcr.io/distroless/static:nonroot

USER 65532:65532

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder --chown=65532:65532 /data /data

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]