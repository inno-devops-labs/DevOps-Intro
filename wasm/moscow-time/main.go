package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v2/http"
)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		// Moscow is UTC+3. TinyGo ships no tzdata, so a fixed zone is used
		// instead of time.LoadLocation("Europe/Moscow") (which fails in TinyGo).
		msk := time.Now().In(time.FixedZone("MSK", 3*60*60))

		w.Header().Set("Content-Type", "application/json")
		// JSON is built as a string (not json.Encode of a map[string]any,
		// which is unreliable under TinyGo's reflection).
		fmt.Fprintf(w,
			"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"zone\":\"Europe/Moscow\",\"offset\":\"+03:00\"}\n",
			msk.Unix(),
			msk.Format(time.RFC3339),
			msk.Format("15:04"),
		)
	})
}

// main is required by the compiler but is not executed by the Spin host.
func main() {}
