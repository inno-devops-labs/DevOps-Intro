package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

var moscow = time.FixedZone("MSK", 3*60*60)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		if r.Method != http.MethodGet {
			w.Header().Set("Allow", http.MethodGet)
			w.WriteHeader(http.StatusMethodNotAllowed)
			_, _ = w.Write([]byte(`{"error":"method not allowed"}`))
			return
		}

		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(moscowTimeJSON(time.Now())))
	})
}

func main() {}

func moscowTimeJSON(now time.Time) string {
	local := now.In(moscow)
	return fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":%q,"utc_offset":%q}`,
		local.Unix(),
		local.Format(time.RFC3339),
		local.Format("15:04"),
		"Europe/Moscow",
		"+03:00",
	)
}
