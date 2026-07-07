package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSecurityHeaders_SetOnEveryRoute(t *testing.T) {
	srv := newTestServer(t)
	handler := SecurityHeaders(srv.Routes())

	cases := []struct {
		method, target string
	}{
		{"GET", "/health"},
		{"GET", "/metrics"},
		{"GET", "/notes"},
	}

	wantHeaders := map[string]string{
		"X-Content-Type-Options":       "nosniff",
		"Cross-Origin-Resource-Policy": "same-origin",
		"Content-Security-Policy":      "default-src 'none'",
		"Cache-Control":                "no-store",
	}

	for _, c := range cases {
		req := httptest.NewRequest(c.method, c.target, nil)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		for name, want := range wantHeaders {
			got := rec.Header().Get(name)
			if got != want {
				t.Errorf("%s %s: header %q = %q, want %q", c.method, c.target, name, got, want)
			}
		}
	}
}

func TestSecurityHeaders_WrapsHandler(t *testing.T) {
	inner := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	rec := httptest.NewRecorder()
	SecurityHeaders(inner).ServeHTTP(rec, httptest.NewRequest("GET", "/", nil))

	if got := rec.Header().Get("X-Content-Type-Options"); got != "nosniff" {
		t.Errorf("X-Content-Type-Options = %q, want %q", got, "nosniff")
	}
}
