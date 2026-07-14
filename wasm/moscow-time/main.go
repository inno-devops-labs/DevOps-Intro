package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v3/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet || r.URL.Path != "/time" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusNotFound)
			fmt.Fprint(w, `{"error":"not found"}`)
			return
		}

		moscowLocation := time.FixedZone("MSK", 3*60*60)
		moscow := time.Now().In(moscowLocation)

		body := fmt.Sprintf(
			`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow","utc_offset":"+03:00"}`,
			moscow.Unix(),
			moscow.Format(time.RFC3339),
			moscow.Format("15:04"),
		)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, body)
	})
}

// main function must be included for the compiler but is not executed.
func main() {}
