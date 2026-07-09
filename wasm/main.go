package main

import (
	"encoding/json"
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
		// Moscow is UTC+3 with no DST — a FixedZone avoids needing embedded tzdata,
		// which TinyGo does not ship.
		msk := time.Now().In(time.FixedZone("MSK", 3*60*60))
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"unix":        msk.Unix(),
			"iso":         msk.Format(time.RFC3339),
			"hour_minute": msk.Format("15:04"),
			"timezone":    "Europe/Moscow (UTC+3)",
		})
	})
}

// main is required by the compiler but never executed (the Spin host invokes the handler).
func main() {}
