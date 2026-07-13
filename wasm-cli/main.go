package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	if os.Getenv("REQUEST_METHOD") != "GET" || os.Getenv("PATH_INFO") != "/time" {
		fmt.Println("Status: 404 Not Found")
		fmt.Println("Content-Type: application/json")
		fmt.Println()
		fmt.Println(`{"error":"not found"}`)
		return
	}

	moscow := time.Now().UTC().In(time.FixedZone("Europe/Moscow", 3*60*60))

	fmt.Println("Content-Type: application/json")
	fmt.Println()
	fmt.Printf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow","utc_offset":"+03:00"}`+"\n",
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		moscow.Format("15:04"),
	)
}
