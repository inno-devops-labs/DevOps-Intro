package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSecurityHeaders_OnAllRoutes(t *testing.T) {
	srv := newTestServer(t)
	handler := securityHeaders(srv.Routes())

	for _, path := range []string{"/", "/health", "/notes", "/metrics"} {
		t.Run(path, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(http.MethodGet, path, nil)
			handler.ServeHTTP(rec, req)

			if got := rec.Header().Get("X-Content-Type-Options"); got != "nosniff" {
				t.Fatalf("%s: X-Content-Type-Options = %q, want nosniff", path, got)
			}
			if got := rec.Header().Get("X-Frame-Options"); got != "DENY" {
				t.Fatalf("%s: X-Frame-Options = %q, want DENY", path, got)
			}
			if got := rec.Header().Get("Content-Security-Policy"); got == "" {
				t.Fatalf("%s: Content-Security-Policy missing", path)
			}
		})
	}
}
