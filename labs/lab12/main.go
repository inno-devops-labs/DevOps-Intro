package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

type TimeResponse struct {
	MoscowTime string `json:"moscow_time"`
	Timestamp  int64  `json:"timestamp"`
}

func getMoscowTime() TimeResponse {
	msk := time.FixedZone("MSK", 3*60*60) // UTC+3
	t := time.Now().In(msk)
	return TimeResponse{
		MoscowTime: t.Format("2006-01-02 15:04:05 MST"),
		Timestamp:  t.Unix(),
	}
}

const pageHTML = `<!DOCTYPE html>
<html>
<head>
  <title>Moscow Time</title>
  <style>
    body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px;
           background: linear-gradient(135deg,#667eea 0%,#764ba2 100%); color: white; }
    .container { background: rgba(255,255,255,.1); padding: 40px; border-radius: 10px;
                 backdrop-filter: blur(10px); max-width: 600px; margin: 0 auto; }
    h1 { margin-bottom: 30px; }
    #time { font-size: 3em; font-weight: bold; margin: 20px 0; text-shadow: 2px 2px 4px rgba(0,0,0,.3); }
    a { color:#ffd700; text-decoration:none; font-size:1.2em; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🕰️ Current Time in Moscow</h1>
    <div id="time">Loading...</div>
    <p><a href="/api/time">📊 View JSON API</a></p>
  </div>
  <script>
    async function updateTime(){
      try{
        const r=await fetch('/api/time'); const d=await r.json();
        document.getElementById('time').textContent=d.moscow_time;
      }catch(e){ console.error(e); document.getElementById('time').textContent='Error loading time'; }
    }
    updateTime(); setInterval(updateTime,1000);
  </script>
</body>
</html>`

// ---- Spin (WAGI) adapter: same file, no Spin SDK needed ----
func runWagiOnce() {
	// Minimal CGI/WAGI response: print headers, blank line, body.
	path := os.Getenv("PATH_INFO")
	switch path {
	case "", "/":
		fmt.Println("Content-Type: text/html; charset=utf-8")
		fmt.Println()
		fmt.Print(pageHTML)
	case "/api/time":
		fmt.Println("Content-Type: application/json")
		fmt.Println()
		_ = json.NewEncoder(os.Stdout).Encode(getMoscowTime())
	default:
		fmt.Println("Status: 404 Not Found")
		fmt.Println("Content-Type: text/plain; charset=utf-8")
		fmt.Println()
		fmt.Println("not found")
	}
}

func isWagi() bool {
	// WAGI/CGI style envs are set by Spin’s WAGI executor.
	// REQUEST_METHOD is required; PATH_INFO is typically present.
	return os.Getenv("REQUEST_METHOD") != ""
}

// ---- net/http server handlers (traditional Docker) ----
func homeHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprint(w, pageHTML)
}
func timeAPIHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(getMoscowTime())
}

func main() {
	// CLI benchmark mode (both Docker & WASM containers)
	if os.Getenv("MODE") == "once" {
		b, _ := json.MarshalIndent(getMoscowTime(), "", "  ")
		fmt.Println(string(b))
		return
	}

	// Spin WAGI mode: handle a single HTTP request and exit.
	if isWagi() {
		runWagiOnce()
		return
	}

	// Traditional net/http server (Docker native)
	http.HandleFunc("/", homeHandler)
	http.HandleFunc("/api/time", timeAPIHandler)
	port := ":8080"
	log.Printf("Server starting on %s\n", port)
	log.Fatal(http.ListenAndServe(port, nil))
}
