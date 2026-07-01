package main

import (
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestSecurityHeaders(t *testing.T) {
    handler := SecurityHeadersMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
    }))

    req := httptest.NewRequest("GET", "/health", nil)
    rec := httptest.NewRecorder()
    handler.ServeHTTP(rec, req)

    headers := map[string]string{
        "X-Content-Type-Options":    "nosniff",
        "X-Frame-Options":           "DENY",
        "Content-Security-Policy":   "default-src 'none'",
        "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
        "Referrer-Policy":           "no-referrer",
    }

    for header, expected := range headers {
        if got := rec.Header().Get(header); got != expected {
            t.Errorf("Header %s = %q, want %q", header, got, expected)
        }
    }
}

