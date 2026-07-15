package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "GET" || path != "/time" {
		fmt.Println("Status: 404 Not Found")
		fmt.Println()
		fmt.Println(`{"error":"not found"}`)
		return
	}

	mskLoc := time.FixedZone("MSK", 3*60*60)
	moscow := time.Now().In(mskLoc)

	fmt.Println("Status: 200 OK")
	fmt.Println("Content-Type: application/json")
	fmt.Println()
	fmt.Printf(`{"unix":%d,"iso":%q,"hour_minute":%q}`,
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		moscow.Format("15:04"),
	)
	fmt.Println()
}