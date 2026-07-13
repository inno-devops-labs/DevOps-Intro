// A standalone WASI CLI module — the "CGI over WASM" (WAGI-shaped) model.
//
// There is no HTTP server and no Spin SDK here. The request arrives as
// environment variables (REQUEST_METHOD, PATH_INFO), the response is written to
// stdout, and the process exits. wasmtime runs main() once per invocation.
//
// This is the deliberate contrast with the Task 1 component, which exports a
// wasi-http handler and is instantiated by a long-lived host (Spin).
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

// Same fixed offset as the Spin component: Moscow is UTC+3 year-round, and
// there is no tz database inside the WASM sandbox.
var moscow = time.FixedZone("MSK", 3*60*60)

type timeResponse struct {
	Unix       int64  `json:"unix"`
	ISO        string `json:"iso"`
	HourMinute string `json:"hour_minute"`
	Zone       string `json:"zone"`
}

func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "" && method != "GET" {
		fmt.Println("Status: 405 Method Not Allowed")
		fmt.Println()
		return
	}
	if path != "" && path != "/time" {
		fmt.Println("Status: 404 Not Found")
		fmt.Println()
		return
	}

	now := time.Now().In(moscow)
	resp := timeResponse{
		Unix:       now.Unix(),
		ISO:        now.Format(time.RFC3339),
		HourMinute: now.Format("15:04"),
		Zone:       "Europe/Moscow (UTC+3)",
	}

	// CGI-style: headers, a blank line, then the body — all on stdout.
	fmt.Println("Content-Type: application/json")
	fmt.Println()
	_ = json.NewEncoder(os.Stdout).Encode(resp)
}
