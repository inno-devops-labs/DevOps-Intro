// Standalone WASI CLI version of the Moscow-time endpoint.
//
// Same JSON payload as the Spin component, but shaped as CGI-over-WASM:
// read REQUEST_METHOD / PATH_INFO from the environment, write a full HTTP
// response (status line, headers, blank line, body) to stdout. Runs
// under bare `wasmtime run` with no wasi-http host.
//
// Compile: tinygo build -o main.wasm -target=wasi -no-debug .
// Run:     wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
package main

import (
	"fmt"
	"os"
	"time"
)

// Moscow is UTC+3 year-round (no DST since 2011). Constructed manually
// because TinyGo doesn't bundle tzdata.
var moscow = time.FixedZone("MSK", 3*60*60)

func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "GET" {
		writeResponse(405, "text/plain", "Allow: GET\r\n", "method not allowed\n")
		return
	}
	if path != "/time" {
		writeResponse(404, "text/plain", "", "not found\n")
		return
	}

	now := time.Now().In(moscow)
	body := fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"tz":%q,"offset_seconds":%d}`,
		now.Unix(),
		now.Format(time.RFC3339),
		now.Format("15:04"),
		"MSK",
		3*60*60,
	)
	writeResponse(200, "application/json", "Cache-Control: no-store\r\n", body)
}

func writeResponse(status int, contentType, extraHeaders, body string) {
	fmt.Printf("Status: %d\r\n", status)
	fmt.Printf("Content-Type: %s\r\n", contentType)
	if extraHeaders != "" {
		fmt.Print(extraHeaders)
	}
	fmt.Print("\r\n")
	fmt.Print(body)
}
