package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	if len(os.Args) == 3 && os.Args[1] == "--expect-write-failure" {
		path := os.Args[2]
		err := os.WriteFile(path, []byte("lab6 write probe\n"), 0o600)
		if err == nil {
			_ = os.Remove(path)
			fmt.Fprintf(os.Stderr, "unexpectedly wrote to %s\n", path)
			os.Exit(1)
		}
		fmt.Printf("write blocked as expected: %v\n", err)
		return
	}

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
	fmt.Printf("healthy: %s\n", response.Status)
}
