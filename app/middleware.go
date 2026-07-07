package main

import "net/http"

// securityHeaders wraps the router and sets a fixed set of defensive
// response headers on every route. CSP is `default-src 'none'` because
// QuickNotes serves only JSON — strictest is safe here.
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Content-Security-Policy", "default-src 'none'")
		h.Set("Referrer-Policy", "no-referrer")
		next.ServeHTTP(w, r)
	})
}
