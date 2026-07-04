package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSecurityHeaders_PresentOnAllRoutes(t *testing.T) {
	srv := newTestServer(t)
	handler := srv.Routes()

	endpoints := []struct {
		method string
		path   string
	}{
		{http.MethodGet, "/health"},
		{http.MethodGet, "/notes"},
		{http.MethodGet, "/metrics"},
	}

	for _, ep := range endpoints {
		req := httptest.NewRequest(ep.method, ep.path, nil)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		for header, want := range map[string]string{
			"X-Content-Type-Options":  "nosniff",
			"X-Frame-Options":         "DENY",
			"Content-Security-Policy": "default-src 'none'",
			"Referrer-Policy":         "no-referrer",
		} {
			if got := rec.Header().Get(header); got != want {
				t.Errorf("%s %s: header %q = %q, want %q", ep.method, ep.path, header, got, want)
			}
		}
	}
}

func TestSecurityHeaders_FailsWithoutMiddleware(t *testing.T) {
	srv := newTestServer(t)
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", srv.handleHealth)

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if got := rec.Header().Get("X-Content-Type-Options"); got != "" {
		t.Fatalf("expected no header without middleware, got %q", got)
	}
}
