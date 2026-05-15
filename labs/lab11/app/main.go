package main

import (
	"fmt"
	"time"
)

func main() {
	fmt.Println("Built with Nix at compile time")
	fmt.Printf("Running at: %s\n", time.Now().Format(time.RFC3339))
}
