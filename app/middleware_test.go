package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

// wantSecurityHeaders is the exact set the securityHeaders middleware must apply to
// every response. If the middleware is removed from Server.Handler, none of these are
// present and this test fails.
var wantSecurityHeaders = map[string]string{
	"X-Content-Type-Options":  "nosniff",
	"X-Frame-Options":         "DENY",
	"Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'",
	"Referrer-Policy":         "no-referrer",
}

func TestSecurityHeaders_PresentOnAllRoutes(t *testing.T) {
	srv := newTestServer(t)
	handler := srv.Handler()

	// Exercise a real route, an error route, and an unregistered path to prove the
	// middleware wraps the whole router and not just the happy path.
	routes := []struct{ method, target string }{
		{http.MethodGet, "/health"},
		{http.MethodGet, "/notes"},
		{http.MethodGet, "/notes/999"},     // 404 from a handler
		{http.MethodGet, "/does-not-exist"}, // 404 from the mux itself
	}

	for _, rt := range routes {
		req := httptest.NewRequest(rt.method, rt.target, nil)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)
		for name, want := range wantSecurityHeaders {
			if got := rec.Header().Get(name); got != want {
				t.Errorf("%s %s: header %q = %q, want %q", rt.method, rt.target, name, got, want)
			}
		}
	}
}
