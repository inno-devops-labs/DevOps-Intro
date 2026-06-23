FROM golang:1.24.0-alpine3.21 AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY *.go ./
COPY seed.json ./

RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json

ENV ADDR=:8080 \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json

USER 65532:65532
EXPOSE 8080

ENTRYPOINT ["/quicknotes"]