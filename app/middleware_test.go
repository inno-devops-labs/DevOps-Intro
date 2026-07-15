// app/middleware_test.go
package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSecurityHeadersPresent(t *testing.T) {
	inner := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	ts := httptest.NewServer(SecurityHeaders(inner))
	defer ts.Close()

	resp, err := http.Get(ts.URL)
	if err != nil {
		t.Fatal(err)
	}
	if resp.Header.Get("X-Content-Type-Options") != "nosniff" {
		t.Fatal("expected X-Content-Type-Options: nosniff, got none")
	}
	if resp.Header.Get("Cross-Origin-Opener-Policy") != "same-origin" {
		t.Fatal("expected Cross-Origin-Opener-Policy: same-origin, got none")
	}
}