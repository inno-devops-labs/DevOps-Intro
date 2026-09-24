// Command healthcheck is a tiny static probe for the distroless image,
// which has no shell, curl or wget. It GETs the /health endpoint and
// exits 0 on HTTP 200, 1 otherwise — exactly what Docker HEALTHCHECK expects.
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	url := "http://127.0.0.1:8080/health"
	if len(os.Args) > 1 {
		url = os.Args[1]
	}

	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		os.Exit(1)
	}
	_ = resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
