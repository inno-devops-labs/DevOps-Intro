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
	hourMinute := fmt.Sprintf("%02d:%02d", moscow.Hour(), moscow.Minute())
	body := fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"moscow":%q,"tz":"UTC+3"}`,
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		hourMinute,
		moscow.Format("2006-01-02 15:04:05"),
	)

	fmt.Printf("Content-Type: application/json\r\n\r\n%s", body)
}
