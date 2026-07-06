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
	defer func() {
		_ = resp.Body.Close()
	}()

	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
