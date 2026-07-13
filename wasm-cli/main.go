package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method == "GET" && path == "/time" {
		now := time.Now().UTC().Add(3 * time.Hour)
		unix := now.Unix()
		iso := now.Format(time.RFC3339)
		hourMinute := now.Format("15:04")

		fmt.Printf(`{"unix": %d, "iso": "%s", "hour_minute": "%s", "timezone": "Europe/Moscow (UTC+3)"}`+"\n",
			unix, iso, hourMinute)
	} else {
		fmt.Println("Not Found")
		os.Exit(1)
	}
}