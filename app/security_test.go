package main

import (
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestSecurityHeaders(t *testing.T) {
    req := httptest.NewRequest("GET", "/health", nil)
    w := httptest.NewRecorder()
    handler := SecurityHeaders(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
    }))
    handler.ServeHTTP(w, req)

    if w.Header().Get("X-Content-Type-Options") != "nosniff" {
        t.Error("X-Content-Type-Options header missing")
    }
    if w.Header().Get("X-Frame-Options") != "DENY" {
        t.Error("X-Frame-Options header missing")
    }
    if w.Header().Get("Content-Security-Policy") != "default-src 'none'" {
        t.Error("Content-Security-Policy header missing")
    }
    if w.Header().Get("Referrer-Policy") != "no-referrer" {
        t.Error("Referrer-Policy header missing")
    }
}