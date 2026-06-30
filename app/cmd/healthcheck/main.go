package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	if len(os.Args) == 3 && os.Args[1] == "--write-test" {
		if err := os.WriteFile(os.Args[2], []byte("write-test"), 0o644); err != nil {
			fmt.Fprintf(os.Stderr, "write failed: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("write succeeded")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	url := "http://127.0.0.1:8080/health"
	if override := os.Getenv("HEALTHCHECK_URL"); override != "" {
		url = override
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		os.Exit(1)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		os.Exit(1)
	}
}
