#!/usr/bin/env bash
set -euo pipefail

base_url="${1:-http://localhost:8080}"
count="${2:-200}"

for i in $(seq 1 "$count"); do
  curl -fsS "$base_url/health" >/dev/null
  curl -fsS "$base_url/notes" >/dev/null
  curl -fsS -X POST "$base_url/notes" \
    -H 'Content-Type: application/json' \
    -d "{\"title\":\"note-$i\",\"body\":\"traffic\"}" >/dev/null
  if (( i % 10 == 0 )); then
    curl -sS "$base_url/notes/999999" >/dev/null || true
  fi
  sleep 0.1
done
