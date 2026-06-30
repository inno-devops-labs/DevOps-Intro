#!/usr/bin/env bash
set -euo pipefail

base_url="${1:-http://localhost:8080}"
duration_seconds="${2:-330}"
end_epoch=$(( $(date +%s) + duration_seconds ))

while [ "$(date +%s)" -lt "$end_epoch" ]; do
  curl -fsS "$base_url/health" >/dev/null || true
  curl -fsS -X POST "$base_url/notes" \
    -H 'Content-Type: application/json' \
    -d '{"title":"healthy","body":"ok"}' >/dev/null || true
  curl -sS -X POST "$base_url/notes" \
    -H 'Content-Type: application/json' \
    -d '{"title":' >/dev/null || true
  curl -sS "$base_url/notes/not-an-int" >/dev/null || true
  sleep 1
done
