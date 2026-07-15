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

		if r.Method != http.MethodGet {
			w.Header().Set("Allow", http.MethodGet)
			w.WriteHeader(http.StatusMethodNotAllowed)
			fmt.Fprintln(w, `{"error":"method not allowed"}`)
			return
		}

		now := time.Now()
		moscow := now.UTC().Add(3 * time.Hour)
		iso := moscow.Format("2006-01-02T15:04:05") + "+03:00"

		fmt.Fprintf(
			w,
			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q}\n",
			now.Unix(),
			iso,
			moscow.Format("15:04"),
		)
	})
}
