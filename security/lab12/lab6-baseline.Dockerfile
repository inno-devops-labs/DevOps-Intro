FROM golang:1.24-alpine AS builder

WORKDIR /src
COPY go.mod ./
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .
RUN mkdir -p /out/data && chmod 0777 /out/data

FROM scratch

COPY --from=builder /out/quicknotes /quicknotes
COPY --chmod=0777 --from=builder /out/data /data
COPY seed.json /seed.json
COPY --chown=65532:65532 seed.json /data/notes.json

USER 65532:65532
EXPOSE 8080
ENV ADDR=:8080
ENV DATA_PATH=/data/notes.json
ENV SEED_PATH=/seed.json
ENTRYPOINT ["/quicknotes"]
