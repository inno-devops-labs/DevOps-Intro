# syntax=docker/dockerfile:1

# ---- builder stage ----
FROM golang:1.24-alpine AS builder
WORKDIR /src

# Dependency files first, so this layer is cached until go.mod/go.sum change
COPY go.mod go.sum* ./
RUN go mod download

# Source code after that
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/quicknotes . \
 && CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./healthcheck \
 && mkdir /data

# ---- runtime stage ----
FROM gcr.io/distroless/static:nonroot
WORKDIR /app
COPY --from=builder /out/quicknotes /app/quicknotes
COPY --from=builder /out/healthcheck /app/healthcheck
COPY seed.json /app/seed.json
# /data owned by nonroot (65532), so a named volume mounted there is writable
COPY --from=builder --chown=65532:65532 /data /data

ENV ADDR=:8080 DATA_PATH=/data/notes.json SEED_PATH=/app/seed.json
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["/app/quicknotes"]
