package main

import (
	"fmt"
	"os"
	"time"
)

// Same fixed-offset zone as the Spin component: TinyGo embeds no tzdata,
// and Moscow has been UTC+3 year-round since Russia abolished DST in 2011.
var moscow = time.FixedZone("MSK", 3*60*60)

// This is a WASI *command* module, not a reactor: wasmtime calls _start,
// main() runs once, the process exits. The request arrives through the
// environment (the CGI convention) rather than through a wasi-http host,
// and the response goes to stdout rather than to an http.ResponseWriter.
func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "" && method != "GET" {
		fmt.Println("Status: 405 Method Not Allowed")
		fmt.Println("Content-Type: text/plain")
		fmt.Println()
		fmt.Println("method not allowed")
		os.Exit(0)
	}

	if path != "" && path != "/time" {
		fmt.Println("Status: 404 Not Found")
		fmt.Println("Content-Type: text/plain")
		fmt.Println()
		fmt.Println("not found")
		os.Exit(0)
	}

	now := time.Now().In(moscow)
	body := fmt.Sprintf(
		`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":%q,"utc_offset_hours":%d}`,
		now.Unix(),
		now.Format(time.RFC3339),
		now.Format("15:04"),
		"Europe/Moscow",
		3,
	)

	// CGI response: headers, blank line, body.
	fmt.Println("Status: 200 OK")
	fmt.Println("Content-Type: application/json")
	fmt.Println()
	fmt.Println(body)
}
