// Bonus task: the same Moscow-time logic as a standalone WASI *command*
// module — no Spin SDK, no wasi-http. CGI/WAGI-shaped contract: the "request"
// arrives as environment variables, the "response" leaves via stdout, one
// process per invocation (`wasmtime run`).
package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	if os.Getenv("REQUEST_METHOD") != "GET" || os.Getenv("PATH_INFO") != "/time" {
		fmt.Println(`{"error":"not found"}`)
		os.Exit(1)
	}
	// Same constraints as the Spin component: TinyGo embeds no tzdata
	// (LoadLocation fails) and its encoding/json chokes on map[string]any
	// reflection — FixedZone + fmt-built JSON work everywhere.
	msk := time.FixedZone("MSK", 3*60*60)
	now := time.Now().In(msk)
	fmt.Printf(`{"unix":%d,"iso":%q,"hour_minute":%q,"timezone":"Europe/Moscow (UTC+3)"}`+"\n",
		now.Unix(),
		now.Format(time.RFC3339),
		now.Format("15:04"),
	)
}
