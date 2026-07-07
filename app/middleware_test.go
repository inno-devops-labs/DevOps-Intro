package main

import (
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestSecurityHeadersMiddleware(t *testing.T) {
    testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
    })
    handler := securityHeadersMiddleware(testHandler)

    req := httptest.NewRequest("GET", "/test", nil)
    w := httptest.NewRecorder()
    handler.ServeHTTP(w, req)

    headers := w.Header()
    expectedHeaders := map[string]string{
        "X-Content-Type-Options":  "nosniff",
        "X-Frame-Options":         "DENY",
        "X-XSS-Protection":        "1; mode=block",
        "Content-Security-Policy": "default-src 'none'",
        "Referrer-Policy":         "strict-origin-when-cross-origin",
        "Permissions-Policy":      "geolocation=(), microphone=(), camera=()",
    }

    for key, expected := range expectedHeaders {
        if actual := headers.Get(key); actual != expected {
            t.Errorf("Header %s = %s, expected %s", key, actual, expected)
        }
    }
}
