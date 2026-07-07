package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSecurityHeaders(t *testing.T) {
	handler := securityHeaders(
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusOK)
		}),
	)

	req := httptest.NewRequest(
		http.MethodGet,
		"/",
		nil,
	)

	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	tests := map[string]string{
		"X-Content-Type-Options":   "nosniff",
		"X-Frame-Options":          "DENY",
		"Content-Security-Policy":  "default-src 'none'",
	}

	for header, expected := range tests {
		got := rec.Header().Get(header)

		if got != expected {
			t.Errorf(
				"%s = %q, want %q",
				header,
				got,
				expected,
			)
		}
	}
}