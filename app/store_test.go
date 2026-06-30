package main

import (
	"path/filepath"
	"testing"
)

func newTestStore(t *testing.T) *Store {
	t.Helper()
	path := filepath.Join(t.TempDir(), "notes.json")
	s, err := NewStore(path)
	if err != nil {
		t.Fatalf("NewStore: %v", err)
	}
	return s
}

func TestStore_CreateAndGet(t *testing.T) {
	s := newTestStore(t)
	n, err := s.Create("shopping list", "milk, bread")
	if err != nil {
		t.Fatalf("Create: %v", err)
	}
	if n.ID != 1 {
		t.Fatalf("expected ID=1, got %d", n.ID)
	}
	got, err := s.Get(n.ID)
	if err != nil {
		t.Fatalf("Get: %v", err)
	}
	if got.Title != "shopping list" || got.Body != "milk, bread" {
		t.Errorf("round-trip mismatch: %+v", got)
	}
}

func TestStore_NextIDIncrements(t *testing.T) {
	s := newTestStore(t)
	for i := 1; i <= 3; i++ {
		n, _ := s.Create("note", "")
		if n.ID != i {
			t.Errorf("expected ID=%d, got %d", i, n.ID)
		}
	}
}

func TestStore_Delete(t *testing.T) {
	s := newTestStore(t)
	n, _ := s.Create("ephemeral", "")
	if err := s.Delete(n.ID); err != nil {
		t.Fatalf("Delete: %v", err)
	}
	if _, err := s.Get(n.ID); err != ErrNotFound {
		t.Errorf("expected ErrNotFound after delete, got %v", err)
	}
	if err := s.Delete(n.ID); err != ErrNotFound {
		t.Errorf("expected ErrNotFound on second delete, got %v", err)
	}
}

func TestStore_PersistsAcrossReload(t *testing.T) {
	path := filepath.Join(t.TempDir(), "notes.json")
	s1, _ := NewStore(path)
	n, _ := s1.Create("durable", "see you later")

	s2, err := NewStore(path)
	if err != nil {
		t.Fatalf("reload: %v", err)
	}
	got, err := s2.Get(n.ID)
	if err != nil {
		t.Fatalf("get after reload: %v", err)
	}
	if got.Body != "see you later" {
		t.Errorf("body lost on reload: %q", got.Body)
	}

	if next, _ := s2.Create("next", ""); next.ID != n.ID+1 {
		t.Errorf("nextID not restored: got %d, want %d", next.ID, n.ID+1)
	}
}
