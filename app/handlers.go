package main

import (
	"encoding/json"
	"errors"
	"net/http"
	"sort"
	"strconv"
	"sync/atomic"
)

type Server struct {
	store          *Store
	notesCreated   atomic.Uint64
	notesDeleted   atomic.Uint64
	requestsTotal  atomic.Uint64
	requestsByCode map[int]*atomic.Uint64
}

func NewServer(store *Store) *Server {
	codes := []int{200, 201, 204, 400, 404, 405, 500}
	by := make(map[int]*atomic.Uint64, len(codes))
	for _, c := range codes {
		by[c] = new(atomic.Uint64)
	}
	return &Server{store: store, requestsByCode: by}
}

func (s *Server) Routes() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", s.wrap(s.handleHealth))
	mux.HandleFunc("GET /metrics", s.wrap(s.handleMetrics))
	mux.HandleFunc("GET /notes", s.wrap(s.handleListNotes))
	mux.HandleFunc("POST /notes", s.wrap(s.handleCreateNote))
	mux.HandleFunc("GET /notes/{id}", s.wrap(s.handleGetNote))
	mux.HandleFunc("DELETE /notes/{id}", s.wrap(s.handleDeleteNote))
	return mux
}

func (s *Server) Handler() http.Handler {
	return securityHeaders(s.Routes())
}

type statusWriter struct {
	http.ResponseWriter
	code int
}

func (sw *statusWriter) WriteHeader(code int) {
	sw.code = code
	sw.ResponseWriter.WriteHeader(code)
}

func (s *Server) wrap(h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		sw := &statusWriter{ResponseWriter: w, code: 200}
		h(sw, r)
		s.requestsTotal.Add(1)
		if c, ok := s.requestsByCode[sw.code]; ok {
			c.Add(1)
		}
	}
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"status": "ok",
		"notes":  s.store.Count(),
	})
}

func (s *Server) handleMetrics(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain; version=0.0.4")
	w.WriteHeader(http.StatusOK)

	scalar := func(name, help, kind string, value uint64) {
		_, _ = w.Write([]byte("# HELP " + name + " " + help + "\n"))
		_, _ = w.Write([]byte("# TYPE " + name + " " + kind + "\n"))
		_, _ = w.Write([]byte(name + " " + strconv.FormatUint(value, 10) + "\n"))
	}
	scalar("quicknotes_notes_total", "Notes currently stored.", "gauge", uint64(s.store.Count()))
	scalar("quicknotes_notes_created_total", "Notes created since process start.", "counter", s.notesCreated.Load())
	scalar("quicknotes_notes_deleted_total", "Notes deleted since process start.", "counter", s.notesDeleted.Load())
	scalar("quicknotes_http_requests_total", "All HTTP requests.", "counter", s.requestsTotal.Load())

	const byCodeName = "quicknotes_http_responses_by_code_total"
	_, _ = w.Write([]byte("# HELP " + byCodeName + " Responses by status code.\n"))
	_, _ = w.Write([]byte("# TYPE " + byCodeName + " counter\n"))
	codes := make([]int, 0, len(s.requestsByCode))
	for c := range s.requestsByCode {
		codes = append(codes, c)
	}
	sort.Ints(codes)
	for _, code := range codes {
		_, _ = w.Write([]byte(byCodeName + `{code="` + strconv.Itoa(code) + `"} ` + strconv.FormatUint(s.requestsByCode[code].Load(), 10) + "\n"))
	}
}

func (s *Server) handleListNotes(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, s.store.List())
}

func (s *Server) handleGetNote(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "id must be an integer")
		return
	}
	n, err := s.store.Get(id)
	if errors.Is(err, ErrNotFound) {
		writeError(w, http.StatusNotFound, "note not found")
		return
	}
	writeJSON(w, http.StatusOK, n)
}

type createNoteRequest struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

func (s *Server) handleCreateNote(w http.ResponseWriter, r *http.Request) {
	var req createNoteRequest
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}
	if req.Title == "" {
		writeError(w, http.StatusBadRequest, "title required")
		return
	}
	n, err := s.store.Create(req.Title, req.Body)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to persist note")
		return
	}
	s.notesCreated.Add(1)
	writeJSON(w, http.StatusCreated, n)
}

func (s *Server) handleDeleteNote(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "id must be an integer")
		return
	}
	if err := s.store.Delete(id); errors.Is(err, ErrNotFound) {
		writeError(w, http.StatusNotFound, "note not found")
		return
	}
	s.notesDeleted.Add(1)
	w.WriteHeader(http.StatusNoContent)
}

func writeJSON(w http.ResponseWriter, code int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(body)
}

func writeError(w http.ResponseWriter, code int, msg string) {
	writeJSON(w, code, map[string]string{"error": msg})
}
