package main

import (
 "fmt"
 "time"
)

func main() {
 fmt.Println("Built reproducibly with Nix")
 fmt.Printf("Running at: %s\n", time.Now().UTC().Format(time.RFC3339))
}
