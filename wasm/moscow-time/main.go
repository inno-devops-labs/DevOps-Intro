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
			http.NotFound(w, r)
			return
		}

		moscow := time.Now().In(time.FixedZone("MSK", 3*60*60))

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(
			w,
			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":%q}\n",
			moscow.Unix(),
			moscow.Format(time.RFC3339),
			moscow.Format("15:04"),
			"UTC+3",
		)
	})
}

// main function must be included for the compiler but is not executed.
func main() {}
