package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSecurityHeaders_OnAllRoutes(t *testing.T) {
	srv := newTestServer(t)
	handler := SecurityHeaders(srv.Routes())

	for _, path := range []string{"/health", "/notes", "/metrics"} {
		t.Run(path, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, path, nil)
			rec := httptest.NewRecorder()
			handler.ServeHTTP(rec, req)

			want := map[string]string{
				"X-Content-Type-Options":     "nosniff",
				"X-Frame-Options":            "DENY",
				"Content-Security-Policy":    "default-src 'none'",
				"Referrer-Policy":            "no-referrer",
				"Cross-Origin-Opener-Policy": "same-origin",
				"Cross-Origin-Resource-Policy": "same-origin",
			}
			for header, value := range want {
				if got := rec.Header().Get(header); got != value {
					t.Fatalf("%s on %s: got %q, want %q", header, path, got, value)
				}
			}
		})
	}
}
