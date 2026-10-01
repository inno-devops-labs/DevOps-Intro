FROM golang:1.24.13-alpine AS builder

WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/quicknotes . \
    && mkdir -p /out/data

FROM gcr.io/distroless/static-debian13:nonroot

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json
COPY --from=builder --chown=65532:65532 /out/data /data

ENV ADDR=:8080 \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
