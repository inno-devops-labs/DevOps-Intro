package main

import (
	"fmt"
	"os"
	"time"
)



var msk = time.FixedZone("MSK", 3*60*60)

func main() {
	if os.Getenv("REQUEST_METHOD") != "GET" || os.Getenv("PATH_INFO") != "/time" {
		fmt.Println(`{"error":"only GET /time is served"}`)
		os.Exit(1)
	}
	now := time.Now().In(msk)
	fmt.Printf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow (UTC+3)"}`+"\n",
		now.Unix(),
		now.Format(time.RFC3339),
		now.Format("15:04"),
	)
}
