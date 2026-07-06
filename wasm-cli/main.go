// Standalone WASI CLI module: reads the request from environment variables
// (CGI-style) and prints Moscow-time JSON to stdout. Runs under bare wasmtime.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")
	if method != "GET" || path != "/time" {
		fmt.Println(`{"error":"not found"}`)
		return
	}
	// Moscow = UTC+3, no DST; fixed offset avoids TinyGo's missing tzdata.
	msk := time.FixedZone("MSK", 3*60*60)
	now := time.Now().In(msk)
	b, _ := json.Marshal(map[string]any{
		"unix":        now.Unix(),
		"iso":         now.Format(time.RFC3339),
		"hour_minute": now.Format("15:04"),
	})
	fmt.Println(string(b))
}
