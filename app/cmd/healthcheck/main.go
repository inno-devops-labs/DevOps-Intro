package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	client := http.Client{Timeout: 2 * time.Second}
	response, err := client.Get("http://127.0.0.1:8080/health")
	if err != nil {
		fmt.Fprintf(os.Stderr, "health request failed: %v\n", err)
		os.Exit(1)
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		fmt.Fprintf(os.Stderr, "health request returned %s\n", response.Status)
		os.Exit(1)
	}
	fmt.Printf("healthy: %s\n", response.Status)
}
