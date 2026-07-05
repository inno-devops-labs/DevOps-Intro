package main

import (
	"net/http"
	"testing"
)

// Guards the security headers fix: if the securityHeaders wrap is removed
// from Routes, every assertion here fails.
func TestSecurityHeaders_OnAllRoutes(t *testing.T) {
	srv := newTestServer(t)
	want := map[string]string{
		"X-Content-Type-Options":       "nosniff",
		"Content-Security-Policy":      "default-src 'none'; frame-ancestors 'none'",
		"Cross-Origin-Resource-Policy": "same-origin",
	}
	for _, target := range []string{"/health", "/notes"} {
		rec := do(t, srv, http.MethodGet, target, nil)
		if rec.Code != http.StatusOK {
			t.Fatalf("GET %s: status %d", target, rec.Code)
		}
		for header, value := range want {
			if got := rec.Header().Get(header); got != value {
				t.Errorf("GET %s header %s: got %q, want %q", target, header, got, value)
			}
		}
	}
}