package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/time" || r.Method != http.MethodGet {
			http.NotFound(w, r)
			return
		}

		now := time.Now().UTC()
		moscow := now.Add(3 * time.Hour) // Europe/Moscow, UTC+3 (no DST) — TinyGo has no embedded tzdata

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"unix":%d,"iso":%q,"hour_minute":%q,"moscow_time":%q}`,
			now.Unix(),
			moscow.Format("2006-01-02T15:04:05")+"+03:00",
			moscow.Format("15:04"),
			moscow.Format("2006-01-02 15:04:05")+" MSK",
		)
	})
}

// main function must be included for the compiler but is not executed.
func main() {}
