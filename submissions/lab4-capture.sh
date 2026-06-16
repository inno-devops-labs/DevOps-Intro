#!/usr/bin/env bash
# Lab 4 Task 1 — capture + decode one POST /notes, then run the 5 debug commands.
# Run from WSL:  bash submissions/lab4-capture.sh
# It will prompt for your sudo password once (tcpdump needs root).
set -uo pipefail

# WSL's system Go is 1.22; QuickNotes' go.mod needs >= 1.24. Use the user-local
# Go 1.24 we unpacked into ~/go124 and pin GOTOOLCHAIN so it won't try to fetch.
export PATH="$HOME/go124/go/bin:$PATH"
export GOTOOLCHAIN=local

REPO="/mnt/c/study/DEVOPS/DevOps-Intro"
APP="$REPO/app"
OUT="$REPO/submissions"
WORK="$(mktemp -d)"
PCAP="$WORK/lab4-trace.pcap"

echo "[*] Warm up sudo (tcpdump needs root)..."
sudo -v

echo "[*] Starting QuickNotes on :8080 ..."
cd "$APP"
ADDR=:8080 go run . >"$WORK/qn.log" 2>&1 &
QN_PID=$!
for i in $(seq 1 40); do
  ss -tln 2>/dev/null | grep -q ':8080' && break
  sleep 0.3
done
echo "    listening: $(ss -tln | grep ':8080' || echo 'NOT UP — see qn.log'); pid=$QN_PID"

echo "[*] Starting tcpdump on lo ..."
sudo tcpdump -i lo -nn -s 0 -A 'tcp port 8080' -w "$PCAP" >/dev/null 2>&1 &
TCPDUMP_PID=$!
sleep 1.5

echo "[*] Firing one POST /notes (verbose -> lab4-curl.txt) ..."
curl -v -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"trace me","body":"in flight"}' 2>"$OUT/lab4-curl.txt"
echo
sleep 1.5

echo "[*] Stopping capture ..."
sudo kill "$TCPDUMP_PID" 2>/dev/null
wait "$TCPDUMP_PID" 2>/dev/null

echo "[*] Decoding capture -> lab4-trace.txt ..."
sudo tcpdump -r "$PCAP" -nn -A 2>/dev/null | tee "$OUT/lab4-trace.txt" >/dev/null
cp "$PCAP" "$OUT/lab4-trace.pcap" 2>/dev/null
sudo chown "$(id -un)":"$(id -gn)" "$OUT/lab4-trace.txt" "$OUT/lab4-trace.pcap" 2>/dev/null

echo "[*] Running the five debug commands -> lab4-commands.txt ..."
{
  echo "### 1. ss -tlnp | grep :8080  (what's listening?)"
  sudo ss -tlnp | grep ':8080' || echo "(nothing on :8080)"
  echo; echo "### 2. ip route show  (routes from this host)"
  ip route show
  echo; echo "### 3. mtr -rwc 5 localhost  (reachability over lo)"
  sudo mtr -rwc 5 localhost || echo "(mtr unavailable)"
  echo; echo "### 4. dig +short example.com @1.1.1.1  (DNS works?)"
  dig +short example.com @1.1.1.1 || echo "(dig unavailable)"
  echo; echo "### 5. journalctl --user -u quicknotes -n 20  (service logs)"
  journalctl --user -u quicknotes -n 20 2>/dev/null \
    || echo "(QuickNotes is not installed as a systemd unit here — it runs via 'go run', so there is no journald unit; logs went to stdout)"
} | tee "$OUT/lab4-commands.txt"

echo "[*] Cleaning up ..."
kill "$QN_PID" 2>/dev/null
pkill -f '/quicknotes' 2>/dev/null
pkill -f 'go run' 2>/dev/null
rm -rf "$WORK"

echo "[+] Done. Artifacts written to $OUT:"
ls -la "$OUT"/lab4-trace.txt "$OUT"/lab4-curl.txt "$OUT"/lab4-commands.txt "$OUT"/lab4-trace.pcap 2>/dev/null
