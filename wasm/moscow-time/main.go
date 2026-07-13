package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/time" {
			http.NotFound(w, r)
			return
		}

		now := time.Now().UTC().Add(3 * time.Hour)
		unix := now.Unix()
		iso := now.Format(time.RFC3339)
		hourMinute := now.Format("15:04")

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)

		fmt.Fprintf(w, `{"unix": %d, "iso": "%s", "hour_minute": "%s", "timezone": "Europe/Moscow (UTC+3)"}`,
			unix, iso, hourMinute)
	})
}

func main() {}