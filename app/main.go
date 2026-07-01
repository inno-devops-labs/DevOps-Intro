package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"sync/atomic"
)

type Note struct {
	ID      int    `json:"id"`
	Title   string `json:"title"`
	Content string `json:"content"`
}

var notes = []Note{
	{ID: 1, Title: "Welcome", Content: "Welcome to QuickNotes!"},
	{ID: 2, Title: "Getting Started", Content: "This is your first note"},
}
var nextID int32 = 3
var requestCount int64 = 0
var errorCount int64 = 0

func main() {
	addr := os.Getenv("ADDR")
	if addr == "" {
		addr = ":8080"
	}

	dataPath := os.Getenv("DATA_PATH")
	if dataPath == "" {
		dataPath = "/var/lib/quicknotes"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello from QuickNotes!\n")
	})

	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/notes", notesHandler)
	http.HandleFunc("/notes/", noteHandler)
	http.HandleFunc("/metrics", metricsHandler)

	log.Printf("Server listening on %s (DATA_PATH=%s)", addr, dataPath)
	log.Fatal(http.ListenAndServe(addr, nil))
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "ok",
		"notes":  len(notes),
	})
}

func notesHandler(w http.ResponseWriter, r *http.Request) {
	atomic.AddInt64(&requestCount, 1)
	w.Header().Set("Content-Type", "application/json")
	switch r.Method {
	case "GET":
		json.NewEncoder(w).Encode(notes)
	case "POST":
		var note Note
		if err := json.NewDecoder(r.Body).Decode(&note); err != nil {
			atomic.AddInt64(&errorCount, 1)
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		note.ID = int(atomic.AddInt32(&nextID, 1))
		notes = append(notes, note)
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(note)
	default:
		atomic.AddInt64(&errorCount, 1)
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func noteHandler(w http.ResponseWriter, r *http.Request) {
	atomic.AddInt64(&requestCount, 1)
	w.Header().Set("Content-Type", "application/json")
	var id int
	if _, err := fmt.Sscanf(r.URL.Path, "/notes/%d", &id); err != nil {
		atomic.AddInt64(&errorCount, 1)
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	for _, note := range notes {
		if note.ID == id {
			json.NewEncoder(w).Encode(note)
			return
		}
	}
	atomic.AddInt64(&errorCount, 1)
	http.Error(w, "Note not found", http.StatusNotFound)
}

func metricsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain; version=0.0.4")

	var sb strings.Builder

	sb.WriteString("# HELP quicknotes_http_requests_total Total number of HTTP requests\n")
	sb.WriteString("# TYPE quicknotes_http_requests_total counter\n")
	sb.WriteString(fmt.Sprintf("quicknotes_http_requests_total %d\n", atomic.LoadInt64(&requestCount)))

	sb.WriteString("# HELP quicknotes_http_errors_total Total number of HTTP errors\n")
	sb.WriteString("# TYPE quicknotes_http_errors_total counter\n")
	sb.WriteString(fmt.Sprintf("quicknotes_http_errors_total %d\n", atomic.LoadInt64(&errorCount)))

	sb.WriteString("# HELP quicknotes_notes_total Current number of notes\n")
	sb.WriteString("# TYPE quicknotes_notes_total gauge\n")
	sb.WriteString(fmt.Sprintf("quicknotes_notes_total %d\n", len(notes)))

	fmt.Fprint(w, sb.String())
}
