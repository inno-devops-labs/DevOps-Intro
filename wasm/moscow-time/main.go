package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}
		msk := time.Now().UTC().Add(3 * time.Hour)
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"unix":%d,"iso":%q,"hour_minute":%q,"zone":"Europe/Moscow (UTC+3)"}`,
			msk.Unix(),
			msk.Format(time.RFC3339),
			msk.Format("15:04"),
		)
	})
}

// main function must be included for the compiler but is not executed.
func main() {}