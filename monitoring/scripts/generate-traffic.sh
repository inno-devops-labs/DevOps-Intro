#!/usr/bin/env bash
set -euo pipefail

base_url="${1:-http://127.0.0.1:8080}"
count="${2:-200}"
for ((i=1; i<=count; i++)); do
  if ((i % 50 == 0)); then
    curl -sS -o /dev/null -w '%{http_code}\n' -X POST \
      -H 'Content-Type: application/json' \
      -d "{\"title\":\"Lab 8 sample $i\",\"body\":\"Monitoring traffic\"}" \
      "$base_url/notes"
  elif ((i % 10 == 0)); then
    curl -sS -o /dev/null -w '%{http_code}\n' -X POST \
      -H 'Content-Type: application/json' -d '{bad' "$base_url/notes"
  elif ((i % 2 == 0)); then
    curl -sS -o /dev/null -w '%{http_code}\n' "$base_url/notes"
  else
    curl -sS -o /dev/null -w '%{http_code}\n' "$base_url/health"
  fi
  sleep 0.25
done
