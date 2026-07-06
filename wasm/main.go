package main

import (
	"encoding/json"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet || r.URL.Path != "/time" {
			http.NotFound(w, r)
			return
		}
		// Moscow is UTC+3 with no DST. TinyGo has no embedded tzdata, so
		// time.LoadLocation("Europe/Moscow") would fail — use a fixed offset.
		msk := time.FixedZone("MSK", 3*60*60)
		now := time.Now().In(msk)

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"unix":        now.Unix(),
			"iso":         now.Format(time.RFC3339),
			"hour_minute": now.Format("15:04"),
		})
	})
}

func main() {}
