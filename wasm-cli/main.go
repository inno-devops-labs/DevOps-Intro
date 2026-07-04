package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	if os.Getenv("REQUEST_METHOD") != "GET" || os.Getenv("PATH_INFO") != "/time" {
		fmt.Print("Status: 404 Not Found\r\nContent-Type: text/plain\r\n\r\nnot found")
		return
	}

	moscow := time.Now().UTC().Add(3 * time.Hour)
	body := fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q}`,
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		moscow.Format("15:04"),
	)

	fmt.Printf("Status: 200 OK\r\nContent-Type: application/json\r\n\r\n%s", body)
}
