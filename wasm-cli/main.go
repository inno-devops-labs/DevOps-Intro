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
		fmt.Fprintln(os.Stderr, "method not allowed")
		os.Exit(1)
	}

	if path != "/time" {
		fmt.Fprintln(os.Stderr, "not found")
		os.Exit(1)
	}

	now := time.Now().UTC().Add(3 * time.Hour)
	iso := now.Format("2006-01-02T15:04:05") + "+03:00"

	fmt.Printf(
		`{"unix":%d,"iso":"%s","hour_minute":"%s"}`+"\n",
		now.Unix(),
		iso,
		now.Format("15:04"),
	)
}
