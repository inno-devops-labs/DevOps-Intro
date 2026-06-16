// Lab 4 Bonus — a minimal TLS-terminating reverse proxy.
// Listens HTTPS on :8443, forwards plaintext to QuickNotes on :8080.
// Run: go run lab4-tlsproxy.go  (expects cert.pem/key.pem in the working dir)
package main

import (
	"crypto/tls"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
)

func main() {
	backend, err := url.Parse("http://127.0.0.1:8080")
	if err != nil {
		log.Fatal(err)
	}
	srv := &http.Server{
		Addr:    ":8443",
		Handler: httputil.NewSingleHostReverseProxy(backend),
		// Go's defaults: min TLS 1.2, prefers TLS 1.3. We leave them as-is so the
		// capture shows what a modern server negotiates out of the box.
		TLSConfig: &tls.Config{MinVersion: tls.VersionTLS12},
	}
	log.Println("TLS proxy listening on :8443 -> http://127.0.0.1:8080")
	log.Fatal(srv.ListenAndServeTLS("cert.pem", "key.pem"))
}
