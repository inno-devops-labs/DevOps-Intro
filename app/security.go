package main

import "net/http"

func securityHeaders(next http.Handler) http.Handler {
return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
w.Header().Set("Cache-Control", "no-store")
w.Header().Set("Content-Security-Policy", "default-src 'none'")
w.Header().Set("X-Content-Type-Options", "nosniff")
w.Header().Set("Referrer-Policy", "no-referrer")
w.Header().Set("X-Frame-Options", "DENY")

next.ServeHTTP(w, r)
})
}
