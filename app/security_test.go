package main

import (
"net/http"
"net/http/httptest"
"testing"
)

func TestSecurityHeadersMiddleware(t *testing.T) {
next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
w.WriteHeader(http.StatusOK)
})

handler := securityHeaders(next)

req := httptest.NewRequest(http.MethodGet, "/health", nil)
rr := httptest.NewRecorder()

handler.ServeHTTP(rr, req)

tests := map[string]string{
"Cache-Control":           "no-store",
"Content-Security-Policy": "default-src 'none'",
"X-Content-Type-Options":  "nosniff",
"Referrer-Policy":         "no-referrer",
"X-Frame-Options":         "DENY",
}

for header, want := range tests {
if got := rr.Header().Get(header); got != want {
t.Fatalf("%s = %q, want %q", header, got, want)
}
}
}
