package main

import (
	"fmt"
	"os"
	"time"
)

// Standalone WASI CLI module: no Spin SDK. Mirrors the older CGI-over-WASM
// (WAGI) model, reading the "request" from environment variables and
// writing the response body straight to stdout.
func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "GET" || path != "/time" {
		fmt.Printf(`{"error":"not found","method":%q,"path":%q}`+"\n", method, path)
		return
	}

	// Same tzdata-free Moscow (UTC+3) approach as the Spin component.
	now := time.Now().UTC()
	moscow := now.Add(3 * time.Hour)

	fmt.Printf(`{"unix":%d,"iso":%q,"hour_minute":%q}`+"\n",
		now.Unix(),
		moscow.Format("2006-01-02T15:04:05")+"+03:00",
		moscow.Format("15:04"),
	)
}
