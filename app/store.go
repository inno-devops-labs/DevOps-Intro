package main

import (
	"encoding/json"
	"errors"
	"os"
	"sync"
	"time"
)

type Note struct {
	ID        int       `json:"id"`
	Title     string    `json:"title"`
	Body      string    `json:"body"`
	CreatedAt time.Time `json:"created_at"`
}

var ErrNotFound = errors.New("note not found")

type Store struct {
	mu     sync.RWMutex
	notes  map[int]Note
	nextID int
	path   string
}

func NewStore(path string) (*Store, error) {
	s := &Store{
		notes:  make(map[int]Note),
		nextID: 1,
		path:   path,
	}
	if path == "" {
		return s, nil
	}
	if err := s.load(); err != nil && !errors.Is(err, os.ErrNotExist) {
		return nil, err
	}
	return s, nil
}

func (s *Store) load() error {
	data, err := os.ReadFile(s.path)
	if err != nil {
		return err
	}
	var notes []Note
	if err := json.Unmarshal(data, &notes); err != nil {
		return err
	}
	for _, n := range notes {
		s.notes[n.ID] = n
		if n.ID >= s.nextID {
			s.nextID = n.ID + 1
		}
	}
	return nil
}

func (s *Store) persist() error {
	if s.path == "" {
		return nil
	}
	notes := make([]Note, 0, len(s.notes))
	for _, n := range s.notes {
		notes = append(notes, n)
	}
	data, err := json.MarshalIndent(notes, "", "  ")
	if err != nil {
		return err
	}
	tmp := s.path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, s.path)
}

func (s *Store) List() []Note {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]Note, 0, len(s.notes))
	for _, n := range s.notes {
		out = append(out, n)
	}
	return out
}

func (s *Store) Get(id int) (Note, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	n, ok := s.notes[id]
	if !ok {
		return Note{}, ErrNotFound
	}
	return n, nil
}

func (s *Store) Create(title, body string) (Note, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	n := Note{
		ID:        s.nextID,
		Title:     title,
		Body:      body,
		CreatedAt: time.Now().UTC(),
	}
	s.notes[n.ID] = n
	s.nextID++
	if err := s.persist(); err != nil {
		return Note{}, err
	}
	return n, nil
}

func (s *Store) Delete(id int) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.notes[id]; !ok {
		return ErrNotFound
	}
	delete(s.notes, id)
	return s.persist()
}

func (s *Store) Count() int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.notes)
}
