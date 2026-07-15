package main

import (
	"fmt"
	"os"
	"time"
)

// Standalone WASI CLI module (no Spin SDK): the CGI-over-WASM / WAGI-shaped
// model. The request is passed as environment variables and the response is
// written to stdout — run under bare `wasmtime run`.
func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "" && method != "GET" {
		fmt.Fprintln(os.Stderr, "405 method not allowed")
		os.Exit(1)
	}
	if path != "" && path != "/time" {
		fmt.Fprintln(os.Stderr, "404 not found")
		os.Exit(1)
	}

	// Moscow is UTC+3 year-round; TinyGo has no tzdata, so use a fixed zone.
	msk := time.FixedZone("MSK", 3*60*60)
	now := time.Now().In(msk)

	fmt.Printf(
		"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":%q,\"utc_offset\":%q}\n",
		now.Unix(),
		now.Format(time.RFC3339),
		now.Format("15:04"),
		"Europe/Moscow",
		"+03:00",
	)
}
