# syntax=docker/dockerfile:1

# ---- builder ---------------------------------------------------------------
FROM golang:1.24 AS builder
WORKDIR /src

# Copy the module manifest first so `go mod download` is cached independently
# of the source — edits to .go files don't bust the dependency layer.
COPY go.mod ./
RUN go mod download

# Now the source.
COPY . .

# Static, stripped, reproducible binary. CGO off so distroless-static (which has
# no libc / dynamic linker) can run it.
RUN CGO_ENABLED=0 GOOS=linux GOTOOLCHAIN=local \
    go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

# A /data dir owned by the nonroot uid, so a fresh named volume mounted here
# inherits writable ownership instead of root-owned.
RUN mkdir -p /data && chown 65532:65532 /data

# ---- runtime ---------------------------------------------------------------
FROM gcr.io/distroless/static:nonroot

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json
COPY --from=builder --chown=65532:65532 /data /data

ENV ADDR=:8080 \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json

EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/quicknotes"]
