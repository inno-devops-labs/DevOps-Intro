package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSecurityHeaders_Present(t *testing.T) {
	srv := newTestServer(t)
	handler := securityHeaders(srv.Routes())

	endpoints := []struct {
		method string
		path   string
	}{
		{http.MethodGet, "/health"},
		{http.MethodGet, "/notes"},
		{http.MethodGet, "/metrics"},
	}

	want := map[string]string{
		"X-Content-Type-Options":  "nosniff",
		"X-Frame-Options":         "DENY",
		"Content-Security-Policy": "default-src 'none'",
		"Referrer-Policy":         "no-referrer",
	}

	for _, ep := range endpoints {
		req := httptest.NewRequest(ep.method, ep.path, nil)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		for header, expected := range want {
			got := rec.Header().Get(header)
			if got != expected {
				t.Errorf("%s %s: header %q = %q, want %q", ep.method, ep.path, header, got, expected)
			}
		}
	}
}

func TestSecurityHeaders_MissingWithoutMiddleware(t *testing.T) {
	srv := newTestServer(t)
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()
	srv.Routes().ServeHTTP(rec, req)

	if rec.Header().Get("X-Content-Type-Options") != "" {
		t.Error("expected no X-Content-Type-Options without middleware")
	}
}
