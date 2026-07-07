package main

// TEMPORARY — Lab 9 bonus demo only. Delete this file (and run `go mod tidy`)
// after showing the govulncheck CI gate turn RED.
//
// It imports golang.org/x/text (pinned to a vulnerable v0.3.0) and calls
// language.ParseAcceptLanguage, which is the function affected by GO-2021-0113
// (index out of range panic). Because we actually CALL it, govulncheck reports
// it as REACHABLE and fails the CI job.

import "golang.org/x/text/language"

func init() {
	_, _, _ = language.ParseAcceptLanguage("en-US")
}
