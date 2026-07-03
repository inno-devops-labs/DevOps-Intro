package main

import "net/http"

// securityHeaders sets baseline security headers on every response, including
// errors from the mux itself. Fixes the ZAP baseline findings 10021 (missing
// X-Content-Type-Options) and 90004 (Spectre site isolation). The strict CSP
// is safe here because QuickNotes serves JSON only, never HTML.
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
		h.Set("Cross-Origin-Resource-Policy", "same-origin")
		next.ServeHTTP(w, r)
	})
}
