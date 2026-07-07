FROM golang:1.24-alpine AS builder

WORKDIR /src
COPY go.mod ./
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

FROM scratch

COPY --from=builder /out/quicknotes /quicknotes
COPY seed.json /seed.json

USER 65532:65532
EXPOSE 8080
ENV ADDR=:8080
ENV DATA_PATH=/tmp/notes.json
ENV SEED_PATH=/seed.json
ENTRYPOINT ["/quicknotes"]
