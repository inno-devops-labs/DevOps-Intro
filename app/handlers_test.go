package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

func newTestServer(t *testing.T) *Server {
	t.Helper()
	path := filepath.Join(t.TempDir(), "notes.json")
	store, err := NewStore(path)
	if err != nil {
		t.Fatalf("NewStore: %v", err)
	}
	return NewServer(store)
}

func do(t *testing.T, srv *Server, method, target string, body any) *httptest.ResponseRecorder {
	t.Helper()
	var buf bytes.Buffer
	if body != nil {
		if err := json.NewEncoder(&buf).Encode(body); err != nil {
			t.Fatalf("encode: %v", err)
		}
	}
	req := httptest.NewRequest(method, target, &buf)
	rec := httptest.NewRecorder()
	srv.Routes().ServeHTTP(rec, req)
	return rec
}

func TestHealth_ReportsCount(t *testing.T) {
	srv := newTestServer(t)
	_, _ = srv.store.Create("a", "")
	rec := do(t, srv, http.MethodGet, "/health", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("status: %d", rec.Code)
	}
	var got map[string]any
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if got["status"] != "ok" {
		t.Errorf("status field: %v", got["status"])
	}
	if got["notes"].(float64) != 1 {
		t.Errorf("notes count: %v", got["notes"])
	}
}

func TestCreateNote_RoundTrip(t *testing.T) {
	srv := newTestServer(t)
	rec := do(t, srv, http.MethodPost, "/notes", map[string]string{
		"title": "first",
		"body":  "hello",
	})
	if rec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", rec.Code, rec.Body.String())
	}
	var n Note
	if err := json.NewDecoder(rec.Body).Decode(&n); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if n.ID == 0 || n.Title != "first" {
		t.Errorf("created note: %+v", n)
	}
}

func TestCreateNote_RejectsEmptyTitle(t *testing.T) {
	srv := newTestServer(t)
	rec := do(t, srv, http.MethodPost, "/notes", map[string]string{"body": "no title"})
	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestCreateNote_RejectsUnknownField(t *testing.T) {
	srv := newTestServer(t)
	rec := do(t, srv, http.MethodPost, "/notes", map[string]any{
		"title":  "x",
		"hacker": "y",
	})
	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestGetNote_NotFound(t *testing.T) {
	srv := newTestServer(t)
	rec := do(t, srv, http.MethodGet, "/notes/999", nil)
	if rec.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", rec.Code)
	}
}

func TestDeleteNote_RemovesAndReturns204(t *testing.T) {
	srv := newTestServer(t)
	n, _ := srv.store.Create("doomed", "")
	rec := do(t, srv, http.MethodDelete, "/notes/"+strconv.Itoa(n.ID), nil)
	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d", rec.Code)
	}
	rec = do(t, srv, http.MethodGet, "/notes/"+strconv.Itoa(n.ID), nil)
	if rec.Code != http.StatusNotFound {
		t.Errorf("note still readable after delete: %d", rec.Code)
	}
}

func TestMetrics_ExposesPrometheusFormat(t *testing.T) {
	srv := newTestServer(t)
	_ = do(t, srv, http.MethodPost, "/notes", map[string]string{"title": "x"})
	rec := do(t, srv, http.MethodGet, "/metrics", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("metrics status: %d", rec.Code)
	}
	body := rec.Body.String()
	for _, want := range []string{
		"# TYPE quicknotes_notes_total gauge",
		"# TYPE quicknotes_http_requests_total counter",
		"quicknotes_notes_created_total 1",
	} {
		if !strings.Contains(body, want) {
			t.Errorf("metrics missing %q", want)
		}
	}
}

func TestSecurityHeaders_PresentOnEveryResponse(t *testing.T) {
	srv := newTestServer(t)
	// Hit an ordinary route; the headers come from the router-level middleware,
	// so this fails if securityHeaders() is removed from Routes().
	rec := do(t, srv, http.MethodGet, "/health", nil)
	want := map[string]string{
		"X-Content-Type-Options":  "nosniff",
		"Content-Security-Policy": "default-src 'none'",
		"X-Frame-Options":         "DENY",
		"Referrer-Policy":         "no-referrer",
		"Cache-Control":           "no-store",
	}
	for k, v := range want {
		if got := rec.Header().Get(k); got != v {
			t.Errorf("header %s = %q, want %q", k, got, v)
		}
	}
}

