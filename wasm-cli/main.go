package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	if os.Getenv("REQUEST_METHOD") != "GET" || os.Getenv("PATH_INFO") != "/time" {
		fmt.Fprintln(os.Stderr, "expected GET /time")
		os.Exit(1)
	}

	moscow := time.Now().UTC().In(time.FixedZone("MSK", 3*60*60))
	fmt.Printf("{\"unix\":%d,\"iso\":%q,\"hour_minute\":%q}\n",
		moscow.Unix(), moscow.Format(time.RFC3339), moscow.Format("15:04"))
}
