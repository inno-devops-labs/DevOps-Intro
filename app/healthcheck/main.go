// healthcheck is a tiny probe for the distroless image (no shell, no curl).
// Exit code 0 means /health answered 200, anything else means unhealthy.
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	client := http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://127.0.0.1:8080/health")
	if err != nil {
		os.Exit(1)
	}
	code := resp.StatusCode
	_ = resp.Body.Close()
	if code != http.StatusOK {
		os.Exit(1)
	}
}
