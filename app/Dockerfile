# syntax=docker/dockerfile:1

# ---- builder stage ----
FROM golang:1.24 AS build

WORKDIR /src

# Copy go.mod first for layer caching
COPY go.mod ./
RUN go mod download

# Copy source code
COPY . .

# Build main binary
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /qn .

# Create healthcheck.go inside the container
RUN echo 'package main\n\nimport (\n\t"net/http"\n\t"os"\n)\n\nfunc main() {\n\tresp, err := http.Get("http://127.0.0.1:8080/health")\n\tif err != nil || resp.StatusCode != http.StatusOK {\n\t\tos.Exit(1)\n\t}\n}' > /tmp/healthcheck.go

# Build healthcheck binary
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /healthcheck /tmp/healthcheck.go

# Create /data directory with nonroot permissions
RUN mkdir -p /data && chown 65532:65532 /data

# ---- runtime stage ----
FROM gcr.io/distroless/static:nonroot

WORKDIR /app

# Copy binaries and seed.json
COPY --from=build /qn /app/quicknotes
COPY --from=build /healthcheck /app/healthcheck
COPY --from=build /src/seed.json /app/seed.json
COPY --from=build --chown=65532:65532 /data /data

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/app/seed.json"

EXPOSE 8080

USER nonroot:nonroot

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/app/healthcheck"]

ENTRYPOINT ["/app/quicknotes"]