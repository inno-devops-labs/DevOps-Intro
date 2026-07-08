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
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
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

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, body)
	})
}

func main() {}
