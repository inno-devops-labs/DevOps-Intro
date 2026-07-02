package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	now := time.Now().UTC().Add(3 * time.Hour)
	fmt.Printf(`{"unix":%d,"iso":"%s","hour_minute":"%s"}`+"\n",
		now.Unix(), now.Format(time.RFC3339), now.Format("15:04"))
	os.Exit(0)
}
