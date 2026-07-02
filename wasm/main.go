package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(handleTime)
}

func handleTime(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	moscow := time.Now().In(time.FixedZone("MSK", 3*3600))
	w.Header().Set("Content-Type", "application/json")
	body := fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"moscow_utc_offset":"+03:00"}`,
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		moscow.Format("15:04"),
	)
	fmt.Fprint(w, body)
}

func main() {}
