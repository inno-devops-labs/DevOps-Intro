package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

// Moscow is UTC+3 year-round (no DST since 2011). Constructing the
// zone manually avoids TinyGo's missing tzdata (see design question d).
var moscow = time.FixedZone("MSK", 3*60*60)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.Header().Set("Allow", "GET")
			http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
			return
		}
		if r.URL.Path != "/time" {
			http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
			return
		}

		now := time.Now().In(moscow)

		// Hand-formatted JSON via fmt.Sprintf + %q. TinyGo's
		// encoding/json can be flaky with map[string]any due to
		// reflection limits; a fixed-shape response is safer here.
		body := fmt.Sprintf(
			`{"unix":%d,"iso":%q,"hour_minute":%q,"tz":%q,"offset_seconds":%d}`,
			now.Unix(),
			now.Format(time.RFC3339),
			now.Format("15:04"),
			"MSK",
			3*60*60,
		)

		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "no-store")
		fmt.Fprint(w, body)
	})
}

func main() {}
