#!/usr/bin/env bash
# Sustain >=5% errors for >=5 minutes (bad POSTs + some healthy traffic)
set -euo pipefail
BASE="${1:-http://127.0.0.1:8080}"
DURATION_SEC="${2:-330}"
echo "Error inject for ${DURATION_SEC}s against $BASE"
end=$((SECONDS + DURATION_SEC))
while (( SECONDS < end )); do
  # ~1 healthy : 1 bad  => ~50% errors (well above 5%)
  curl -s -o /dev/null "$BASE/health" || true
  curl -s -o /dev/null -X POST -H 'Content-Type: application/json' \
    -d 'not-json' "$BASE/notes" || true
  sleep 1
done
echo "inject finished"
