package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
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
var nextID = 3

func main() {
	// Get port from environment variable, default to :8080
	addr := os.Getenv("ADDR")
	if addr == "" {
		addr = ":8080"
	}

	// Get data path from environment variable
	dataPath := os.Getenv("DATA_PATH")
	if dataPath == "" {
		dataPath = "/var/lib/quicknotes"
	}

	// Routes
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello from QuickNotes!\n")
	})

	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/notes", notesHandler)
	http.HandleFunc("/notes/", noteHandler)

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
	w.Header().Set("Content-Type", "application/json")
	switch r.Method {
	case "GET":
		json.NewEncoder(w).Encode(notes)
	case "POST":
		var note Note
		if err := json.NewDecoder(r.Body).Decode(&note); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		note.ID = nextID
		nextID++
		notes = append(notes, note)
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(note)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func noteHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	// Parse ID from URL
	var id int
	if _, err := fmt.Sscanf(r.URL.Path, "/notes/%d", &id); err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	for _, note := range notes {
		if note.ID == id {
			json.NewEncoder(w).Encode(note)
			return
		}
	}
	http.Error(w, "Note not found", http.StatusNotFound)
}
