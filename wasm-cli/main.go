// The wasm/ logic as a WAGI-shaped WASI command module: request from env
// vars, CGI response on stdout, no Spin SDK.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

// Fixed offset because time.LoadLocation needs tzdata, which TinyGo lacks.
var moscow = time.FixedZone("MSK", 3*60*60)

type timeResponse struct {
	Unix       int64  `json:"unix"`
	ISO        string `json:"iso"`
	HourMinute string `json:"hour_minute"`
	Timezone   string `json:"timezone"`
}

func main() {
	if os.Getenv("REQUEST_METHOD") != "GET" || os.Getenv("PATH_INFO") != "/time" {
		fmt.Println("Status: 404 Not Found")
		fmt.Println()
		os.Exit(1)
	}
	now := time.Now().In(moscow)
	body, err := json.Marshal(timeResponse{
		Unix:       now.Unix(),
		ISO:        now.Format(time.RFC3339),
		HourMinute: now.Format("15:04"),
		Timezone:   "MSK (UTC+3)",
	})
	if err != nil {
		fmt.Println("Status: 500 Internal Server Error")
		fmt.Println()
		os.Exit(1)
	}
	fmt.Println("Content-Type: application/json")
	fmt.Println()
	fmt.Println(string(body))
}
