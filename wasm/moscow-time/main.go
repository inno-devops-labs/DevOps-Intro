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

		moscowZone := time.FixedZone("MSK", 3*60*60)
		moscow := time.Now().In(moscowZone)
		body := fmt.Sprintf(
			`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":%q}`,
			moscow.Unix(),
			moscow.Format(time.RFC3339),
			moscow.Format("15:04"),
			"Europe/Moscow (UTC+3)",
		)

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, body)
	})
}
