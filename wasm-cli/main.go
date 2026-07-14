// A standalone WASI CLI module — the "CGI over WASM" model. No Spin SDK: the
// request arrives as environment variables, the response goes to stdout, and the
// module exits. One process per invocation, run under bare `wasmtime run`.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

// Same fixed UTC+3 as the Spin component — TinyGo embeds no tzdata.
var moscow = time.FixedZone("MSK", 3*60*60)

type timeResponse struct {
	Unix       int64  `json:"unix"`
	ISO        string `json:"iso"`
	HourMinute string `json:"hour_minute"`
	Moscow     string `json:"moscow"`
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
	body, err := json.Marshal(timeResponse{
		Unix:       now.Unix(),
		ISO:        now.Format(time.RFC3339),
		HourMinute: now.Format("15:04"),
		Moscow:     now.Format("2006-01-02 15:04:05"),
		Zone:       "Europe/Moscow (UTC+3)",
	})
	if err != nil {
		fmt.Println("Status: 500 Internal Server Error")
		fmt.Println()
		return
	}

	// CGI-shaped response: headers, blank line, body.
	fmt.Println("Content-Type: application/json")
	fmt.Println()
	fmt.Println(string(body))
}
