package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v3/http"
)

var msk = time.FixedZone("MSK", 3*60*60)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		now := time.Now().In(msk)
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w,
			`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow (UTC+3)"}`,
			now.Unix(),
			now.Format(time.RFC3339),
			now.Format("15:04"),
		)
	})
}

func main() {}
