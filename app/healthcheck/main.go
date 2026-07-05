// Command healthcheck is a tiny, dependency-free HTTP probe used as the
// container HEALTHCHECK. The distroless runtime image has no shell and no
// curl/wget, so the check ships as its own static binary: it performs a GET
// on /health and maps the result to an exit code (0 = healthy, 1 = not).
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	addr := os.Getenv("HEALTH_ADDR")
	if addr == "" {
		addr = "http://127.0.0.1:8080/health"
	}
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(addr)
	if err != nil {
		os.Exit(1)
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
	os.Exit(0)
}
