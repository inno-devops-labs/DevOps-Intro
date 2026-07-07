package main

import "net/http"

// securityHeaders wraps a handler and sets HTTP response security headers on
// every route (Lab 9). Implemented as middleware — wrapping the whole mux —
// so the headers apply uniformly to all endpoints instead of being sprinkled
// across individual handlers.
//
// Addresses these OWASP ZAP baseline findings:
//   - 10021 X-Content-Type-Options Header Missing  -> X-Content-Type-Options: nosniff
//   - 90004 Insufficient Site Isolation (Spectre)  -> Cross-Origin-Resource-Policy
//   - 10049 Storable and Cacheable Content         -> Cache-Control: no-store
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		// Stop browsers MIME-sniffing responses away from their declared type.
		h.Set("X-Content-Type-Options", "nosniff")
		// QuickNotes is a JSON API that serves no HTML, so lock the document
		// context down entirely. default-src 'none' = "load nothing"; safe for
		// an API, would break a real website (see design question f).
		h.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
		// Legacy clickjacking protection for browsers that ignore CSP.
		h.Set("X-Frame-Options", "DENY")
		// Cross-origin isolation (Spectre): other origins can't embed our data.
		h.Set("Cross-Origin-Resource-Policy", "same-origin")
		h.Set("Cross-Origin-Opener-Policy", "same-origin")
		// API responses are per-request data — never cache them.
		h.Set("Cache-Control", "no-store")
		// Don't leak the request URL to other origins via the Referer header.
		h.Set("Referrer-Policy", "no-referrer")
		next.ServeHTTP(w, r)
	})
}
