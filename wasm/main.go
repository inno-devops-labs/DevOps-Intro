package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(handle)
}

func handle(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		w.Header().Set("Allow", "GET, HEAD")
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// FixedZone avoids TinyGo's missing tzdata (time.LoadLocation("Europe/Moscow") fails).
	msk := time.FixedZone("MSK", 3*60*60)
	now := time.Now().In(msk)

	// fmt.Sprintf avoids TinyGo reflection issues with encoding/json + map[string]any.
	body := fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow","offset":"+03:00"}`+"\n",
		now.Unix(),
		now.Format(time.RFC3339),
		now.Format("15:04"),
	)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(body))
}
