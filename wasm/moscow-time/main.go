package main

import (
	"encoding/json"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/time" {
			http.NotFound(w, r)
			return
		}
		now := time.Now().UTC().Add(3 * time.Hour)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{
			"unix":        now.Unix(),
			"iso":         now.Format(time.RFC3339),
			"hour_minute": now.Format("15:04"),
		})
	})
}

func main() {}