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

		now := time.Now().UTC().Add(3 * time.Hour)
		
		iso := now.Format("2006-01-02T15:04:05") + "+03:00"

		w.Header().Set("Content-Type", "application/json")

		fmt.Fprintf(
			w,
			`{"unix":%d,"iso":"%s","hour_minute":"%s"}`,
			now.Unix(),
			iso,
			now.Format("15:04"),
		)
	})
}

func main() {}