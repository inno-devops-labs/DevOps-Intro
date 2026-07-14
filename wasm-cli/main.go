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
		path = "/"
	}
	if method != "GET" || (path != "/time" && path != "/time/") {
		fmt.Printf("Status: 404\nContent-Type: text/plain\n\nnot found\n")
		return
	}

	msk := time.FixedZone("MSK", 3*60*60)
	now := time.Now().In(msk)
	body := fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow","offset":"+03:00"}`+"\n",
		now.Unix(),
		now.Format(time.RFC3339),
		now.Format("15:04"),
	)
	fmt.Printf("Content-Type: application/json\n\n%s", body)
}
