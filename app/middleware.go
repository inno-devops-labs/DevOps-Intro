package main

import "net/http"

// securityHeaders sets baseline security headers on every response.
// QuickNotes is a JSON API: the strictest CSP is safe because responses are
// never rendered as a document that loads sub-resources.
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("Cache-Control", "no-store")
		h.Set("Cross-Origin-Resource-Policy", "same-origin")
		next.ServeHTTP(w, r)
	})
}

// Handler is the full HTTP stack: router wrapped in security middleware.
// main() and the tests must both use this, so the middleware can't be
// silently dropped from production wiring without a test failing.
func (s *Server) Handler() http.Handler {
	return securityHeaders(s.Routes())
}
