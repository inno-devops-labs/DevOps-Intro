package main

import (
	"fmt"
	"net/http"
	"time"

	spinhttp "github.com/spinframework/spin-go-sdk/v3/http"
)

// Moscow is UTC+3 year-round (no DST since 2014). The wasip1 sandbox has no
// /usr/share/zoneinfo, so time.LoadLocation("Europe/Moscow") fails at runtime;
// FixedZone is pure arithmetic and needs no tzdata.
var msk = time.FixedZone("MSK", 3*60*60)

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		now := time.Now().In(msk)
		w.Header().Set("Content-Type", "application/json")
		// fmt-built JSON keeps the module free of encoding/json's reflection
		// (a hard requirement under TinyGo, a size win under big Go);
		// %q handles all string escaping.
		fmt.Fprintf(w,
			`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow (UTC+3)"}`,
			now.Unix(),
			now.Format(time.RFC3339),
			now.Format("15:04"),
		)
	})
}

// main function must be included for the compiler but is not executed.
func main() {}
