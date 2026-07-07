package main

import "net/http"

// securityHeaders applies baseline HTTP security headers to every response.
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Content-Security-Policy", "default-src 'none'")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("Permissions-Policy", "geolocation=(), microphone=(), camera=()")
		h.Set("Cache-Control", "no-cache, no-store, must-revalidate, private")
		h.Set("Pragma", "no-cache")
		next.ServeHTTP(w, r)
	})
}
