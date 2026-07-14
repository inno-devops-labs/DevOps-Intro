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
		fmt.Println(`{"error":"not found"}`)
		return
	}
	msk := time.Now().UTC().Add(3 * time.Hour)
	fmt.Printf(`{"unix":%d,"iso":%q,"hour_minute":%q}`+"\n",
		msk.Unix(), msk.Format(time.RFC3339), msk.Format("15:04"))
}