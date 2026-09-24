FROM golang:1.24 AS builder
WORKDIR /src

COPY go.mod go.sum* ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

RUN mkdir -p /data && chown 65532:65532 /data

RUN mkdir -p /hc && \
    printf 'package main\nimport ("net/http"; "os")\nfunc main() {\n  r, err := http.Get("http://localhost:8080/health")\n  if err != nil || r.StatusCode != 200 {\n    os.Exit(1)\n  }\n}\n' > /hc/main.go && \
    cd /hc && go mod init hc && \
    CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/healthcheck .

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY seed.json /seed.json
COPY --chown=nonroot:nonroot --from=builder /data /data
EXPOSE 8080
USER nonroot
ENTRYPOINT ["/quicknotes"]
