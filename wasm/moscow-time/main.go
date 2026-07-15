package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		mskLoc := time.FixedZone("MSK", 3*60*60)
		moscow := time.Now().In(mskLoc)

		fmt.Fprintf(w, `{"unix":%d,"iso":%q,"hour_minute":%q}`,
			moscow.Unix(),
			moscow.Format(time.RFC3339),
			moscow.Format("15:04"),
		)
	})
}

func main() {}