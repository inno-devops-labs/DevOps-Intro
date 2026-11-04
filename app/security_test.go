package main

import (
	"net/http"
	"testing"
)

func TestRoutesSecurityHeaders(t *testing.T) {
	srv := newTestServer(t)
	_, err := srv.store.Create("test", "body")
	if err != nil {
		t.Fatal(err)
	}
	cases := []struct {
		method string
		path   string
		body   any
	}{
		{http.MethodGet, "/health", nil},
		{http.MethodGet, "/metrics", nil},
		{http.MethodGet, "/notes", nil},
		{http.MethodPost, "/notes", map[string]string{"title": "new"}},
		{http.MethodGet, "/notes/1", nil},
		{http.MethodGet, "/notes/999", nil},
		{http.MethodGet, "/notes/not-an-id", nil},
		{http.MethodDelete, "/notes/1", nil},
		{http.MethodGet, "/missing", nil},
		{http.MethodPut, "/health", nil},
	}
	for _, tc := range cases {
		t.Run(tc.method+tc.path, func(t *testing.T) {
			rec := do(t, srv, tc.method, tc.path, tc.body)
			for name, want := range map[string]string{
				"Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
				"X-Content-Type-Options":  "nosniff",
				"X-Frame-Options":         "DENY",
				"Referrer-Policy":         "no-referrer",
				"Cache-Control":           "no-store",
			} {
				if got := rec.Header().Get(name); got != want {
					t.Errorf("%s = %q, want %q (status %d)", name, got, want, rec.Code)
				}
			}
		})
	}
}
