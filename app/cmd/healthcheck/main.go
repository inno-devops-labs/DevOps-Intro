package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	url := os.Getenv("HC_URL")
	if url == "" {
		url = "http://127.0.0.1:8080/health"
	}
	c := http.Client{Timeout: 2 * time.Second}
	r, err := c.Get(url)
	if err != nil {
		os.Exit(1)
	}
	r.Body.Close()
	if r.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
