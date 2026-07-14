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

	moscow := time.Now().In(time.FixedZone("MSK", 3*60*60))
	fmt.Printf(
		"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":\"Europe/Moscow\",\"utc_offset\":\"+03:00\"}\n",
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		moscow.Format("15:04"),
	)
}
