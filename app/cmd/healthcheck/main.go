package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	url := "http://127.0.0.1:8080/health"
	if len(os.Args) == 2 {
		url = os.Args[1]
	}
	client := http.Client{Timeout: 2 * time.Second}
	response, err := client.Get(url)
	if err != nil {
		fmt.Fprintf(os.Stderr, "health request failed: %v\n", err)
		os.Exit(1)
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		fmt.Fprintf(os.Stderr, "health request returned %s\n", response.Status)
		os.Exit(1)
	}
}
