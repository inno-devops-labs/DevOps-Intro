package main

import (
	"net/http"
	"testing"
)

// TestSecurityHeaders_PresentOnAllRoutes asserts the securityHeaders middleware
// sets the expected headers on a normal response. It fails if the middleware is
// removed from Routes(), so the fix is genuinely guarded (Lab 9 Task 2.3).
func TestSecurityHeaders_PresentOnAllRoutes(t *testing.T) {
	srv := newTestServer(t)
	rec := do(t, srv, http.MethodGet, "/notes", nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status: %d", rec.Code)
	}

	want := map[string]string{
		"X-Content-Type-Options":       "nosniff",       // ZAP 10021
		"Cross-Origin-Resource-Policy": "same-origin",   // ZAP 90004
		"Cache-Control":                "no-store",       // ZAP 10049
	}
	for header, expected := range want {
		if got := rec.Header().Get(header); got != expected {
			t.Errorf("%s = %q, want %q", header, got, expected)
		}
	}

	if got := rec.Header().Get("Content-Security-Policy"); got == "" {
		t.Error("Content-Security-Policy header missing")
	}
}
