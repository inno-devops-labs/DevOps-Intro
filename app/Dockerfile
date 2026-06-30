FROM golang:1.24 AS builder

WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags='-s -w' -trimpath -o /quicknotes
RUN mkdir -p /data && chown 65532:65532 /data

RUN mkdir -p /healthcheck-src && cat > /healthcheck-src/main.go <<'GOEOF'
package main
import (
	"io"
	"net/http"
	"os"
)
func main() {
	resp, err := http.Get("http://localhost:8080/health")
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()
	io.Copy(io.Discard, resp.Body)
	if resp.StatusCode != 200 {
		os.Exit(1)
	}
}
GOEOF
RUN CGO_ENABLED=0 go build -ldflags='-s -w' -o /healthcheck /healthcheck-src/main.go

FROM gcr.io/distroless/static:nonroot

COPY --from=builder --chown=65532:65532 /data /data
COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY --from=builder /src/seed.json /seed.json

EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
