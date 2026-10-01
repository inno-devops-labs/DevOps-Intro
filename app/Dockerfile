# syntax=docker/dockerfile:1

# ---------- builder ----------
FROM golang:1.24 AS builder
WORKDIR /src

# deps first (go.mod before source) to maximize layer cache reuse
COPY go.mod ./
RUN go mod download

# now the source
COPY . .

# static, stripped, reproducible binary
RUN CGO_ENABLED=0 GOOS=linux go build \
      -trimpath -ldflags='-s -w' -o /out/quicknotes .

# a /data dir owned by nonroot so the named volume inherits writable ownership
RUN mkdir -p /data && chown 65532:65532 /data

# ---------- runtime ----------
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder --chown=65532:65532 /data /data
COPY --from=builder /src/seed.json /seed.json

USER 65532:65532
ENV ADDR=:8080 DATA_PATH=/data/notes.json SEED_PATH=/seed.json
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
