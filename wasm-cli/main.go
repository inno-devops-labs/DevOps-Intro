package main

import (
	"fmt"
	"os"
	"time"
)

var moscow = time.FixedZone("MSK", 3*60*60)

func main() {
	method := envOrDefault("REQUEST_METHOD", "GET")
	path := envOrDefault("PATH_INFO", "/time")

	fmt.Println("Content-Type: application/json")

	if method != "GET" {
		fmt.Println("Status: 405 Method Not Allowed")
		fmt.Println()
		fmt.Println(`{"error":"method not allowed"}`)
		return
	}
	if path != "/time" {
		fmt.Println("Status: 404 Not Found")
		fmt.Println()
		fmt.Println(`{"error":"not found"}`)
		return
	}

	fmt.Println("Status: 200 OK")
	fmt.Println()
	fmt.Println(moscowTimeJSON(time.Now()))
}

func envOrDefault(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func moscowTimeJSON(now time.Time) string {
	local := now.In(moscow)
	return fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":%q,"utc_offset":%q}`,
		local.Unix(),
		local.Format(time.RFC3339),
		local.Format("15:04"),
		"Europe/Moscow",
		"+03:00",
	)
}
