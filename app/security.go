package main

import "net/http"

// SecurityHeaders wraps a handler and sets baseline security headers on every
// response. QuickNotes is a JSON API with no browsable UI, so the CSP is the
// strictest possible ('none') rather than a website-style allowlist.
func SecurityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("Cross-Origin-Resource-Policy", "same-origin")
		h.Set("Content-Security-Policy", "default-src 'none'")
		h.Set("Cache-Control", "no-store")
		next.ServeHTTP(w, r)
	})
}
