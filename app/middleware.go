package main

import "net/http"

// securityHeaders sets response headers ZAP's passive baseline scan checks for
// on every route, since QuickNotes is a JSON API with no need to be framed,
// sniffed, or cached by intermediaries.
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Content-Security-Policy", "default-src 'none'")
		h.Set("Cache-Control", "no-store")
		next.ServeHTTP(w, r)
	})
}
