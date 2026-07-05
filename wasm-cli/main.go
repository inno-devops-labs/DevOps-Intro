package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method == "" {
		method = "GET"
	}
	if path == "" {
		path = "/time"
	}

	if method != "GET" || path != "/time" {
		fmt.Println(`{"error":"not found"}`)
		os.Exit(1)
	}

	// Moscow is permanently UTC+3 (no DST since 2014).
	moscowLoc := time.FixedZone("Moscow/UTC+3", 3*60*60)
	moscow := time.Now().In(moscowLoc)

	fmt.Printf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow (UTC+3)"}`,
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		moscow.Format("15:04"),
	)
	fmt.Println()
}
