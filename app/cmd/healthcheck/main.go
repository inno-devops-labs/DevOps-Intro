package main

import (
	"net/http"
	"os"
	"time"
)

// Tiny static healthcheck for distroless (no shell/wget/curl in the runtime image).
func main() {
	url := os.Getenv("HEALTH_URL")
	if url == "" {
		url = "http://127.0.0.1:8080/health"
	}
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
