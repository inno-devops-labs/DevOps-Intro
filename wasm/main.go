package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

// Moscow is UTC+3 year-round (no DST since 2014). TinyGo ships no tzdata, so a
// fixed zone is used instead of time.LoadLocation("Europe/Moscow").
func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		msk := time.FixedZone("MSK", 3*60*60)
		now := time.Now().In(msk)

		// Built with fmt.Sprintf + %q rather than encoding/json: TinyGo's
		// reflection-based json marshalling of map[string]any is unreliable.
		body := fmt.Sprintf(
			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":%q,\"utc_offset\":%q}\n",
			now.Unix(),
			now.Format(time.RFC3339),
			now.Format("15:04"),
			"Europe/Moscow",
			"+03:00",
		)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, body)
	})
}
