package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "GET" {
		fmt.Fprintf(os.Stderr, "method not allowed: %s\n", method)
		os.Exit(1)
	}

	if path != "/time" {
		fmt.Fprintf(os.Stderr, "not found: %s\n", path)
		os.Exit(1)
	}

	now := time.Now().UTC()
	moscow := now.Add(3 * time.Hour)

	iso := moscow.Format("2006-01-02T15:04:05") + "+03:00"
	hourMinute := moscow.Format("15:04")

	fmt.Printf(
		"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":%q}\n",
		now.Unix(),
		iso,
		hourMinute,
		"UTC+03:00",
	)
}
