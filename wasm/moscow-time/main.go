package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		moscowTime := time.Now().UTC().Add(3 * time.Hour)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)

		fmt.Fprintf(w, `{"unix": %d, "iso": %q, "hour_minute": %q}`,
			moscowTime.Unix(),
			moscowTime.Format(time.RFC3339),
			moscowTime.Format("15:04"))
	})
}

func main() {}
