package main

import (
	"encoding/json"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

// Moscow has been a fixed UTC+3 with no DST since 2014. We use a FixedZone
// rather than time.LoadLocation("Europe/Moscow") because TinyGo embeds no
// tzdata at all — LoadLocation would fail at runtime inside the wasm module.
var moscow = time.FixedZone("MSK", 3*60*60)

// A concrete struct (not map[string]any): TinyGo's reflection support is
// limited, and reflection-heavy encoding of dynamic maps is a known rough edge.
type timeResponse struct {
	Unix       int64  `json:"unix"`
	ISO        string `json:"iso"`
	HourMinute string `json:"hour_minute"`
	Moscow     string `json:"moscow"`
	Zone       string `json:"zone"`
}

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		now := time.Now().In(moscow)
		resp := timeResponse{
			Unix:       now.Unix(),
			ISO:        now.Format(time.RFC3339),
			HourMinute: now.Format("15:04"),
			Moscow:     now.Format("2006-01-02 15:04:05"),
			Zone:       "Europe/Moscow (UTC+3)",
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(resp)
	})
}

// main must exist for the compiler, but it is never executed: the Spin host
// invokes the handler registered in init() through the component's export.
func main() {}
