package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestSecurityHeaders_AllRoutes(t *testing.T) {
	tests := []struct {
		name, method, path, body string
		wantStatus               int
	}{
		{"health", "GET", "/health", "", http.StatusOK},
		{"head", "HEAD", "/health", "", http.StatusOK},
		{"metrics", "GET", "/metrics", "", http.StatusOK},
		{"list", "GET", "/notes", "", http.StatusOK},
		{"create", "POST", "/notes", `{"title":"new","body":"text"}`, http.StatusCreated},
		{"get", "GET", "/notes/1", "", http.StatusOK},
		{"delete", "DELETE", "/notes/1", "", http.StatusNoContent},
		{"missing note", "GET", "/notes/999999", "", http.StatusNotFound},
		{"bad id", "GET", "/notes/not-an-int", "", http.StatusBadRequest},
		{"bad JSON", "POST", "/notes", "{invalid", http.StatusBadRequest},
		{"router 404", "GET", "/does-not-exist", "", http.StatusNotFound},
		{"router 405", "PUT", "/health", "", http.StatusMethodNotAllowed},
		// Go releases differ in the canonical-path redirect status (301/307).
		{"router redirect", "GET", "//notes", "", 0},
	}
	wantHeaders := map[string]string{
		"X-Content-Type-Options":       "nosniff",
		"Cross-Origin-Resource-Policy": "same-origin",
		"Content-Security-Policy":      "default-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'",
		"X-Frame-Options":              "DENY",
		"Referrer-Policy":              "no-referrer",
		"Cache-Control":                "no-store",
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			srv := newTestServer(t)
			if _, err := srv.store.Create("existing", "fixture"); err != nil {
				t.Fatal(err)
			}
			req := httptest.NewRequest(tt.method, tt.path, strings.NewReader(tt.body))
			rec := httptest.NewRecorder()
			// Test production wiring, not a manually wrapped test-only handler.
			srv.Routes().ServeHTTP(rec, req)
			if tt.wantStatus == 0 {
				if (rec.Code != http.StatusMovedPermanently && rec.Code != http.StatusTemporaryRedirect) || rec.Header().Get("Location") != "/notes" {
					t.Fatalf("expected canonical-path redirect, got %d to %q", rec.Code, rec.Header().Get("Location"))
				}
			} else if rec.Code != tt.wantStatus {
				t.Fatalf("status: got %d, want %d: %s", rec.Code, tt.wantStatus, rec.Body.String())
			}
			for key, want := range wantHeaders {
				if got := rec.Header().Get(key); got != want {
					t.Errorf("%s: got %q, want %q", key, got, want)
				}
			}
		})
	}
}

func TestSecurityHeaders_SetBeforeNextHandler(t *testing.T) {
	called := false
	next := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		called = true
		if got := w.Header().Get("X-Content-Type-Options"); got != "nosniff" {
			t.Errorf("header must be set before the handler writes: got %q", got)
		}
		w.WriteHeader(http.StatusInternalServerError)
	})
	rec := httptest.NewRecorder()
	securityHeaders(next).ServeHTTP(rec, httptest.NewRequest("GET", "/", nil))
	if !called || rec.Code != http.StatusInternalServerError {
		t.Fatal("middleware must delegate without changing the handler status")
	}
	if got := rec.Result().Header.Get("X-Content-Type-Options"); got != "nosniff" {
		t.Errorf("committed response lost the header: %q", got)
	}
}
