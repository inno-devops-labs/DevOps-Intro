package main

import (
	"fmt"
	"os"
	"time"
)

// Standalone WASI CLI module (no Spin SDK). It follows the CGI-over-WASM
// shape: read the request from environment variables, write the response
// (CGI headers + body) to stdout. Run it with:
//   wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
func main() {
	method := os.Getenv("REQUEST_METHOD")
	if method == "" {
		method = "GET"
	}
	path := os.Getenv("PATH_INFO")

	// Moscow is UTC+3; TinyGo has no tzdata, so use a fixed zone.
	msk := time.Now().In(time.FixedZone("MSK", 3*60*60))

	// CGI-style response: headers, blank line, then the JSON body.
	fmt.Print("Content-Type: application/json\n\n")
	fmt.Printf(
		"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"zone\":\"Europe/Moscow\",\"offset\":\"+03:00\",\"method\":%q,\"path\":%q}\n",
		msk.Unix(),
		msk.Format(time.RFC3339),
		msk.Format("15:04"),
		method,
		path,
	)
}
