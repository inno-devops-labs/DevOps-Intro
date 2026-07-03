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

		if r.URL.Path != "/time" {
			http.NotFound(w, r)
			return
		}

		now := time.Now().UTC()
		moscow := now.Add(3 * time.Hour)

		iso := moscow.Format("2006-01-02T15:04:05") + "+03:00"
		hourMinute := moscow.Format("15:04")

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(
			w,
			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":%q}\n",
			now.Unix(),
			iso,
			hourMinute,
			"UTC+03:00",
		)
	})
}

func main() {}
