package main

import (
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
)

// TestSecurityHeaders_PresentOnAllRoutes goes through Server.Handler() — the
// exact stack main() serves. If securityHeaders is removed from Handler(),
// every assertion here fails.
func TestSecurityHeaders_PresentOnAllRoutes(t *testing.T) {
	srv := newTestServer(t)
	n, err := srv.store.Create("t", "b")
	if err != nil {
		t.Fatalf("create: %v", err)
	}

	want := map[string]string{
		"Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'",
		"X-Content-Type-Options":  "nosniff",
		"X-Frame-Options":         "DENY",
		"Referrer-Policy":         "no-referrer",
		"Cache-Control":           "no-store",

		"Cross-Origin-Resource-Policy": "same-origin",
	}

	targets := []struct{ method, path string }{
		{http.MethodGet, "/health"},
		{http.MethodGet, "/metrics"},
		{http.MethodGet, "/notes"},
		{http.MethodGet, "/notes/" + strconv.Itoa(n.ID)},
		{http.MethodGet, "/no-such-route"}, // 404s must carry headers too
	}

	for _, tc := range targets {
		req := httptest.NewRequest(tc.method, tc.path, nil)
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)
		for header, value := range want {
			if got := rec.Header().Get(header); got != value {
				t.Errorf("%s %s: header %s = %q, want %q", tc.method, tc.path, header, got, value)
			}
		}
	}
}
