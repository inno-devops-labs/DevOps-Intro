#!/usr/bin/env bash
# Sustained error injection for Lab 8 Task 2 (run ≥6 minutes for 5m alert).
set -euo pipefail
BASE="${1:-http://localhost:8080}"
DURATION="${2:-360}"
OUT="${3:-submissions/attachments/lab8/alert-trigger.log}"

echo "Error injection started $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee "$OUT"
end=$((SECONDS + DURATION))
while [ "$SECONDS" -lt "$end" ]; do
  curl -s "$BASE/health" >/dev/null
  curl -s "$BASE/notes" >/dev/null
  curl -s -X POST "$BASE/notes" -H 'Content-Type: application/json' -d '{"bad":true}' >/dev/null
  sleep 0.5
done
echo "Error injection finished $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$OUT"
