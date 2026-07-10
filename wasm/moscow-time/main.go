package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

// Moscow is UTC+3 year-round: Russia abolished DST in 2011, so a fixed
// offset is exact, not an approximation. We construct the zone by hand
// rather than calling time.LoadLocation("Europe/Moscow"), because TinyGo
// ships no embedded tzdata and that call fails at runtime.
var moscow = time.FixedZone("MSK", 3*60*60)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.Header().Set("Allow", "GET")
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		now := time.Now().In(moscow)

		// Hand-rolled JSON via fmt.Sprintf rather than encoding/json on a
		// map[string]any: TinyGo's reflection support is partial, and the
		// interface-typed map is exactly the case that trips it. %q quotes
		// and escapes the string values correctly.
		body := fmt.Sprintf(
			`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":%q,"utc_offset_hours":%d}`,
			now.Unix(),
			now.Format(time.RFC3339),
			now.Format("15:04"),
			"Europe/Moscow",
			3,
		)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, body)
	})
}

// main is required by the Go toolchain but never called: Spin's host
// invokes the handler registered in init() through the exported
// wasi-http entrypoint that -buildmode=c-shared produces.
func main() {}
