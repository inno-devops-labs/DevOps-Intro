package main

import "golang.org/x/text/language"

// runVulnerableDependencyDemo exists only for the Lab 9 corrected
// govulncheck red/green CI demonstration.
func runVulnerableDependencyDemo() {
	_, _ = language.Parse("en-US")
}
