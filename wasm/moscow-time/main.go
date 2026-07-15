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

		// TinyGo ships no embedded tzdata, so time.LoadLocation("Europe/Moscow")
		// fails at runtime. Moscow has been a fixed UTC+3 offset since 2014, so
		// shifting the UTC wall clock is the robust substitute.
		now := time.Now().UTC()
		moscow := now.Add(3 * time.Hour)

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"unix":%d,"iso":%q,"hour_minute":%q}`+"\n",
			now.Unix(),
			moscow.Format("2006-01-02T15:04:05")+"+03:00",
			moscow.Format("15:04"),
		)
	})
}
