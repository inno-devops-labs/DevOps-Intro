# Build stage: the full Go toolchain, discarded once the binaries exist.
FROM golang:1.24 AS builder

WORKDIR /src

# Dependency manifest first. This layer stays cached until go.mod itself
# changes, so editing source code does not re-resolve modules.
COPY go.mod ./
RUN go mod download

COPY . .

# Static binary: no libc, no dynamic linker, nothing for the runtime image to
# provide. -trimpath removes local paths so the build is reproducible,
# -s -w drop the symbol table and DWARF data.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

# The runtime image has no shell and no curl, so the healthcheck has to be a
# binary of its own. This one probes /health and answers through its exit code.
RUN mkdir -p /src/healthcheck && printf '%s\n' \
      'package main' \
      '' \
      'import (' \
      '    "net/http"' \
      '    "os"' \
      ')' \
      '' \
      'func main() {' \
      '    resp, err := http.Get("http://127.0.0.1:8080/health")' \
      '    if err != nil || resp.StatusCode != http.StatusOK {' \
      '        os.Exit(1)' \
      '    }' \
      '}' \
      > /src/healthcheck/main.go \
    && cd /src/healthcheck \
    && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck .

# Empty data directory, owned by the unprivileged user. Docker seeds a fresh
# named volume from this path, ownership included.
RUN mkdir -p /out/data && chown 65532:65532 /out/data

# Runtime stage: nothing but the two binaries, the seed file and a data dir.
FROM scratch

COPY --from=builder /out/quicknotes  /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /out/data /data
COPY --chown=65532:65532 seed.json /seed.json

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

# Numeric UID and GID, because a scratch image has no /etc/passwd to look a
# name up in.
USER 65532:65532

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
