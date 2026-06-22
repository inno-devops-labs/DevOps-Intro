package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

func main() {
	// Self-healthcheck mode: the distroless runtime image has no shell or curl,
	// so the container's HEALTHCHECK re-invokes this same binary (the only one in
	// the image) to probe /health. Exit 0 = healthy, 1 = unhealthy.
	if len(os.Args) > 1 && os.Args[1] == "healthcheck" {
		os.Exit(healthcheck())
	}

	addr := envOrDefault("ADDR", ":8080")
	dataPath := envOrDefault("DATA_PATH", "data/notes.json")
	seedPath := envOrDefault("SEED_PATH", "seed.json")

	if err := ensureSeeded(dataPath, seedPath); err != nil {
		log.Fatalf("seed: %v", err)
	}

	store, err := NewStore(dataPath)
	if err != nil {
		log.Fatalf("store: %v", err)
	}

	server := NewServer(store)
	srv := &http.Server{
		Addr:              addr,
		Handler:           server.Routes(),
		ReadHeaderTimeout: 5 * time.Second,
	}

	go func() {
		log.Printf("quicknotes listening on %s (notes loaded: %d)", addr, store.Count())
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("listen: %v", err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
	<-stop
	log.Println("shutting down")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("shutdown: %v", err)
	}
}

func healthcheck() int {
	addr := envOrDefault("ADDR", ":8080")
	host := addr
	if strings.HasPrefix(addr, ":") {
		host = "127.0.0.1" + addr
	}
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://" + host + "/health")
	if err != nil {
		return 1
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK {
		return 1
	}
	return 0
}

func envOrDefault(k, def string) string {
	if v, ok := os.LookupEnv(k); ok && v != "" {
		return v
	}
	return def
}

func ensureSeeded(dataPath, seedPath string) error {
	if _, err := os.Stat(dataPath); err == nil {
		return nil
	}
	if err := os.MkdirAll(dirname(dataPath), 0o755); err != nil {
		return err
	}
	seed, err := os.ReadFile(seedPath)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return os.WriteFile(dataPath, []byte("[]"), 0o644)
		}
		return err
	}
	return os.WriteFile(dataPath, seed, 0o644)
}

func dirname(p string) string {
	for i := len(p) - 1; i >= 0; i-- {
		if p[i] == '/' {
			return p[:i]
		}
	}
	return "."
}
