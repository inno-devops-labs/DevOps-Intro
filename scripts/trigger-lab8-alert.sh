#!/usr/bin/env sh
set -eu

base_url="${BASE_URL:-http://localhost:8080}"
duration_seconds="${DURATION_SECONDS:-360}"

end=$(( $(date +%s) + duration_seconds ))
while [ "$(date +%s)" -lt "$end" ]; do
  curl -fsS "$base_url/health" >/dev/null || true
  curl -fsS -X POST "$base_url/notes" \
    -H "Content-Type: application/json" \
    -d '{"body":"missing title"}' >/dev/null 2>&1 || true
  sleep 1
done
