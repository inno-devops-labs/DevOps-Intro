package main

import (
	"fmt"
	"os"
	"time"
)

func moscowTimeJSON() string {
	moscow := time.Now().In(time.FixedZone("MSK", 3*3600))
	return fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"moscow_utc_offset":"+03:00"}`,
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		moscow.Format("15:04"),
	)
}

func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "GET" || path != "/time" {
		fmt.Println("Status: 404 Not Found")
		fmt.Println("Content-Type: text/plain")
		fmt.Println()
		fmt.Println("not found")
		return
	}

	fmt.Println("Status: 200 OK")
	fmt.Println("Content-Type: application/json")
	fmt.Println()
	fmt.Print(moscowTimeJSON())
}
