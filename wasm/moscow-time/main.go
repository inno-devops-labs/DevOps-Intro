package main

import (
	"encoding/json"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

// Moscow has been UTC+3 year-round since Russia abolished DST in 2014, so a
// fixed offset is both correct and avoids depending on the IANA tz database
// being present inside the WASM sandbox (there is no /usr/share/zoneinfo in
// there, which is why time.LoadLocation("Europe/Moscow") is a classic WASM
// footgun).
var moscow = time.FixedZone("MSK", 3*60*60)

// A struct, not map[string]any: struct marshalling avoids the reflection-heavy
// code paths that TinyGo's encoding/json struggles with, so this same handler
// compiles under either toolchain.
type timeResponse struct {
	Unix       int64  `json:"unix"`
	ISO        string `json:"iso"`
	HourMinute string `json:"hour_minute"`
	Zone       string `json:"zone"`
}

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		now := time.Now().In(moscow)

		resp := timeResponse{
			Unix:       now.Unix(),
			ISO:        now.Format(time.RFC3339),
			HourMinute: now.Format("15:04"),
			Zone:       "Europe/Moscow (UTC+3)",
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(resp)
	})
}

// main must exist for the compiler but is never executed: the Spin host invokes
// the handler registered in init() through the wasi-http component interface.
func main() {}
