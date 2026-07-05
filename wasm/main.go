package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		// time.LoadLocation("Europe/Moscow") is unavailable in TinyGo (no embedded tzdata).
		// Moscow is permanently UTC+3 (no DST since 2014), so a fixed zone is exact.
		moscowLoc := time.FixedZone("Moscow/UTC+3", 3*60*60)
		moscow := time.Now().In(moscowLoc)

		w.Header().Set("Content-Type", "application/json")
		// Build JSON with fmt.Fprintf — TinyGo's reflect support limits encoding/json
		// on map[string]any; string formatting is always safe.
		fmt.Fprintf(w,
			`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow (UTC+3)"}`,
			moscow.Unix(),
			moscow.Format(time.RFC3339),
			moscow.Format("15:04"),
		)
	})
}

func main() {}
