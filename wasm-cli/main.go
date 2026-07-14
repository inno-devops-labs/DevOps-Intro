package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	method := os.Getenv("REQUEST_METHOD")
	path := os.Getenv("PATH_INFO")

	if method != "GET" || path != "/time" {
		fmt.Fprintln(os.Stderr, "expected GET /time")
		os.Exit(1)
	}

	moscow := time.Now().In(time.FixedZone("MSK", 3*60*60))
	fmt.Printf(
		"{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q,\"timezone\":%q}\n",
		moscow.Unix(),
		moscow.Format(time.RFC3339),
		moscow.Format("15:04"),
		"UTC+3",
	)
}
