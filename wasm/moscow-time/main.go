package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v3/http"
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

		json := fmt.Sprintf(`{"unix":%d,"iso":"%s","hour_minute":"%s"}`, unix, iso, hourMinute)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, json)
	})
}

func main() {}
