package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	method := os.Getenv("REQUEST_METHOD")
	if method == "" {
		method = "GET"
	}
	path := os.Getenv("PATH_INFO")
	if path == "" {
		path = "/time"
	}

	if method != "GET" || path != "/time" {
		fmt.Printf(`{"error":%q,"method":%q,"path":%q}`+"\n", "not found", method, path)
		os.Exit(1)
	}

	moscowZone := time.FixedZone("MSK", 3*60*60)
	moscow := time.Now().In(moscowZone)
	fmt.Printf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":%q}`+"\n",
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		moscow.Format("15:04"),
		"Europe/Moscow (UTC+3)",
	)
}
