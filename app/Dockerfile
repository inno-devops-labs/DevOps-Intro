# QuickNotes — multi-stage build -> distroless static, nonroot, <= 25 MB

# ---------- builder ----------
FROM golang:1.24 AS builder
WORKDIR /src

# deps first (go.mod before source) to maximize layer-cache reuse
COPY go.mod ./
RUN go mod download

# source
COPY . .

# static, stripped, reproducible application binary
RUN CGO_ENABLED=0 GOOS=linux go build \
      -trimpath -ldflags='-s -w' -o /out/quicknotes .

# tiny HTTP healthcheck binary — distroless has no shell / curl / wget
RUN mkdir -p /hc && cd /hc && \
    printf 'package main\nimport("net/http";"os")\nfunc main(){r,e:=http.Get("http://127.0.0.1:8080/health");if e!=nil||r.StatusCode!=200{os.Exit(1)};os.Exit(0)}\n' > main.go && \
    go mod init hc >/dev/null 2>&1 && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck .

# /data owned by nonroot so a fresh named volume inherits writable ownership
RUN mkdir -p /data && chown 65532:65532 /data

# ---------- runtime ----------
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder --chown=65532:65532 /data /data
COPY --from=builder /src/seed.json /seed.json

USER 65532:65532
ENV ADDR=:8080 DATA_PATH=/data/notes.json SEED_PATH=/seed.json
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
