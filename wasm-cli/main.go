// Standalone WASI CLI module (no Spin SDK): the "CGI-over-WASM" model.
// Reads the request from env vars, writes the same Moscow-time JSON to stdout,
// and exits. Run with: wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

func main() {
	if m := os.Getenv("REQUEST_METHOD"); m != "" && m != "GET" {
		fmt.Fprintln(os.Stderr, "method not allowed")
		os.Exit(1)
	}
	msk := time.Now().In(time.FixedZone("MSK", 3*60*60))
	b, _ := json.Marshal(map[string]any{
		"unix":        msk.Unix(),
		"iso":         msk.Format(time.RFC3339),
		"hour_minute": msk.Format("15:04"),
		"timezone":    "Europe/Moscow (UTC+3)",
		"path":        os.Getenv("PATH_INFO"),
	})
	fmt.Println(string(b))
}
