package main

import (
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
)

func TestSecurityHeaders_PresentOnAllRoutes(t *testing.T) {
	srv := newTestServer(t)
	n, err := srv.store.Create("t", "b")
	if err != nil {
		t.Fatalf("seed: %v", err)
	}

	wantHeaders := map[string]string{
		"X-Content-Type-Options":  "nosniff",
		"X-Frame-Options":         "DENY",
		"Content-Security-Policy": "default-src 'none'",
		"Referrer-Policy":         "no-referrer",
	}

	routes := []struct {
		name, method, target string
	}{
		{"health", http.MethodGet, "/health"},
		{"list", http.MethodGet, "/notes"},
		{"get", http.MethodGet, "/notes/" + strconv.Itoa(n.ID)},
		{"metrics", http.MethodGet, "/metrics"},
	}

	for _, r := range routes {
		t.Run(r.name, func(t *testing.T) {
			req := httptest.NewRequest(r.method, r.target, nil)
			rec := httptest.NewRecorder()
			srv.Routes().ServeHTTP(rec, req)
			for hdr, want := range wantHeaders {
				if got := rec.Header().Get(hdr); got != want {
					t.Errorf("%s: got %q, want %q", hdr, got, want)
				}
			}
		})
	}
}
