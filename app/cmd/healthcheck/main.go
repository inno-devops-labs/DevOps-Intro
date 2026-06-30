// Command healthcheck is a tiny HTTP probe baked into the distroless image.
// Distroless has no shell, curl, or wget, so the compose healthcheck runs this
// binary instead. It does a GET /health and exits 0 on 200, 1 otherwise.
package main

import (
	"net/http"
	"os"
	"strings"
	"time"
)

func main() {
	addr := os.Getenv("ADDR")
	if addr == "" {
		addr = ":8080"
	}
	// ADDR is in host:port form. A leading ":" means "all interfaces", so the
	// probe has to dial loopback explicitly.
	if strings.HasPrefix(addr, ":") {
		addr = "127.0.0.1" + addr
	}

	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://" + addr + "/health")
	if err != nil {
		os.Exit(1)
	}
	_ = resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
