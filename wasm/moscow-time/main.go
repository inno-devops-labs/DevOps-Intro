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

		now := time.Now().UTC().Add(3 * time.Hour)

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(
			w,
			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":\"Europe/Moscow\",\"utc_offset\":\"+03:00\"}\n",
			now.Unix(),
			now.Format(time.RFC3339),
			now.Format("15:04"),
		)
	})
}
