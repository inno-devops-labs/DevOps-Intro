package main

import "golang.org/x/text/language"

func parsePreferredLanguageForVulnDemo(header string) {
	_, _, _ = language.ParseAcceptLanguage(header)
}
