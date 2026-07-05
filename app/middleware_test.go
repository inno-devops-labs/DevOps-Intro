package main

import (
	"net/http"
	"testing"
)

func TestSecurityHeaders_PresentOnEveryRoute(t *testing.T) {
	srv := newTestServer(t)

	for _, target := range []string{"/health", "/notes", "/metrics"} {
		rec := do(t, srv, http.MethodGet, target, nil)
		h := rec.Header()
		checks := map[string]string{
			"X-Content-Type-Options":  "nosniff",
			"X-Frame-Options":         "DENY",
			"Content-Security-Policy": "default-src 'none'",
			"Cache-Control":           "no-store",
		}
		for name, want := range checks {
			if got := h.Get(name); got != want {
				t.Errorf("%s: header %s = %q, want %q", target, name, got, want)
			}
		}
	}
}
