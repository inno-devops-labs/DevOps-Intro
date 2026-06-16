#!/usr/bin/env bash
# Lab 4 Bonus — terminate TLS in front of QuickNotes and capture the handshake.
# Run from WSL:  echo <pw> | sudo -S -v ; bash submissions/lab4-tls.sh
# (sudo is needed for tcpdump; warm it once before calling.)
set -uo pipefail
export PATH="$HOME/go124/go/bin:/usr/sbin:/usr/bin:/bin:$PATH"
export GOTOOLCHAIN=local

SUB="/mnt/c/study/DEVOPS/DevOps-Intro/submissions"
APP="/mnt/c/study/DEVOPS/DevOps-Intro/app"
W="/tmp/lab4tls"
rm -rf "$W"; mkdir -p "$W"; cd "$W"
pkill -f /quicknotes 2>/dev/null; pkill -f lab4-tlsproxy 2>/dev/null; sleep 1

# self-signed cert for localhost
openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 1 \
  -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost" >/dev/null 2>&1

exec >"$SUB/lab4-tls-capture.txt" 2>&1   # report to file (bg jobs won't hold the pipe)

echo "=== start QuickNotes (:8080) and TLS proxy (:8443) ==="
( cd "$APP" && ADDR=:8080 nohup go run . >/tmp/qn.log 2>&1 </dev/null & )
nohup go run "$SUB/lab4-tlsproxy.go" >/tmp/proxy.log 2>&1 </dev/null &
disown
for i in $(seq 1 100); do
  ss -tln 2>/dev/null | grep -q :8443 && ss -tln 2>/dev/null | grep -q :8080 && break
  sleep 0.4
done
echo "listeners: 8080=$(ss -tln|grep -c :8080)  8443=$(ss -tln|grep -c :8443)"
echo "proxy.log: $(cat /tmp/proxy.log)"

echo
echo "=== capture handshake on lo:8443 ==="
sudo tcpdump -i lo -nn -s0 -w "$W/lab4-tls.pcap" 'tcp port 8443' >/dev/null 2>&1 &
TPID=$!
sleep 1.5
echo "--- curl -vk https://localhost:8443/health (verbose -> lab4-tls-curl.txt) ---"
curl -vk https://localhost:8443/health 2>"$SUB/lab4-tls-curl.txt"
echo
sleep 1.5
sudo kill "$TPID" 2>/dev/null; wait "$TPID" 2>/dev/null
sudo pkill -f "tcpdump -i lo" 2>/dev/null

cp "$W/lab4-tls.pcap" "$SUB/lab4-tls.pcap" 2>/dev/null
sudo chown "$(id -un)":"$(id -gn)" "$SUB/lab4-tls.pcap" 2>/dev/null

echo "=== certificate chain (openssl s_client -showcerts) ==="
echo | openssl s_client -connect localhost:8443 -showcerts 2>/dev/null > "$SUB/lab4-tls-cert.txt"
openssl x509 -in "$W/cert.pem" -noout -subject -issuer -dates

echo
echo "=== negotiated session (openssl s_client summary) ==="
echo | openssl s_client -connect localhost:8443 2>/dev/null \
  | grep -E "Protocol|Cipher|Server public key|Verify|Verification" | head -8

pkill -f /quicknotes 2>/dev/null; pkill -f lab4-tlsproxy 2>/dev/null
echo
echo "=== DONE. pcap: $(ls -la "$SUB/lab4-tls.pcap" 2>/dev/null) ==="
