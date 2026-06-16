#!/usr/bin/env bash
# Lab 4 Task 2 — reproduce a broken deploy (port already in use) and walk the
# outside-in debugging chain, then repair and re-verify.
# Run from WSL:  bash submissions/lab4-debug.sh   (writes /tmp/lab4-task2.txt)
set -uo pipefail
export PATH="$HOME/go124/go/bin:/usr/sbin:/usr/bin:/bin:$PATH"
export GOTOOLCHAIN=local

APP="/mnt/c/study/DEVOPS/DevOps-Intro/app"
OUT="/mnt/c/study/DEVOPS/DevOps-Intro/submissions/lab4-task2.txt"
cd "$APP"
pkill -f /quicknotes 2>/dev/null; sleep 1

# all report output -> file (so background jobs never hold the caller's pipe)
exec >"$OUT" 2>&1

echo "=== 2.1  Start instance #1 (takes :8080) ==="
ADDR=:8080 nohup go run . >/tmp/qn1.log 2>&1 </dev/null &
P1=$!; disown
for i in $(seq 1 80); do ss -tln 2>/dev/null | grep -q :8080 && break; sleep 0.3; done
echo "instance #1: go-pid=$P1, listeners on :8080 = $(ss -tln | grep -c :8080)"

echo
echo "=== 2.1  Start instance #2 on the SAME port (must fail) ==="
ADDR=:8080 go run . >/tmp/qn2.log 2>&1 </dev/null
echo "instance #2 exit code = $?"
echo "--- exact error ---"
cat /tmp/qn2.log

echo
echo "=== 2.2  OUTSIDE-IN CHAIN ==="
echo "### 1) is it running?   ps -ef | grep quicknotes"
ps -ef | grep -E "quicknotes|go run \." | grep -v grep
echo
echo "### 2) is it listening?  ss -tlnp | grep 8080"
ss -tlnp 2>/dev/null | grep 8080
echo
echo "### 3) reachable from host?  curl /health"
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8080/health
echo
echo "### 4) firewall blocking?  iptables/nft  (needs sudo; run separately if empty here)"
{ sudo -n iptables -L -n -v 2>/dev/null || sudo -n nft list ruleset 2>/dev/null; } \
  || echo "(could not read firewall non-interactively — see note in submission)"
echo
echo "### 5) DNS?  dig +short localhost  (+ /etc/hosts)"
dig +short localhost 2>/dev/null
echo "/etc/hosts: $(grep -w localhost /etc/hosts | tr '\n' ' ')"

echo
echo "=== 2.3  REPAIR: kill the conflicting #1, restart, re-verify ==="
kill "$P1" 2>/dev/null
pkill -f /quicknotes 2>/dev/null
sleep 2
ADDR=:8080 nohup go run . >/tmp/qn3.log 2>&1 </dev/null &
disown
for i in $(seq 1 80); do ss -tln 2>/dev/null | grep -q :8080 && break; sleep 0.3; done
echo "after repair, /health = $(curl -s http://localhost:8080/health)"
pkill -f /quicknotes 2>/dev/null
echo
echo "=== DONE ==="
