// Command healthcheck is a tiny static binary used as the container
// healthcheck. Distroless images have no shell, wget, or curl, so we ship this
// instead. It performs a single GET /health and exits 0 on HTTP 200, else 1.
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	addr := os.Getenv("HEALTHCHECK_URL")
	if addr == "" {
		addr = "http://127.0.0.1:8080/health"
	}

	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(addr)
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
	os.Exit(0)
}
