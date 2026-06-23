# ─── builder stage ───
FROM golang:1.24-alpine AS builder
WORKDIR /src


COPY go.mod ./
RUN go mod download

# Then the source.
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /quicknotes .

RUN mkdir -p /data && chown 65532:65532 /data

# ─── runtime stage ───
FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder --chown=65532:65532 /data /data
COPY --chown=65532:65532 seed.json /seed.json

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

USER nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
