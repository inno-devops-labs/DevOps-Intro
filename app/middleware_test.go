package main

import (
	"net/http"
	"testing"
)

func TestSecurityHeadersApplyToAllRoutes(t *testing.T) {
	srv := newTestServer(t)

	tests := []struct {
		name   string
		method string
		target string
	}{
		{
			name:   "health route",
			method: http.MethodGet,
			target: "/health",
		},
		{
			name:   "notes route",
			method: http.MethodGet,
			target: "/notes",
		},
		{
			name:   "unmatched route",
			method: http.MethodGet,
			target: "/not-a-route",
		},
	}

	wantHeaders := map[string]string{
		"Cache-Control":           "no-store",
		"Content-Security-Policy": "default-src 'none'",
		"Permissions-Policy":      "camera=(), geolocation=(), microphone=()",
		"Referrer-Policy":         "no-referrer",
		"X-Content-Type-Options":  "nosniff",
		"X-Frame-Options":         "DENY",
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			response := do(
				t,
				srv,
				test.method,
				test.target,
				nil,
			)

			for name, want := range wantHeaders {
				if got := response.Header().Get(name); got != want {
					t.Errorf(
						"%s header: got %q, want %q",
						name,
						got,
						want,
					)
				}
			}
		})
	}
}
