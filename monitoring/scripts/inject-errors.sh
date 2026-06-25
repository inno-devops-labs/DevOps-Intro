#!/usr/bin/env bash
# Inject sustained 4xx errors alongside healthy traffic (Lab 8 Task 2).
# Run for >= 6 minutes so the 5m "for:" window can fire HighErrorRate.
# Usage: ./monitoring/scripts/inject-errors.sh

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
DURATION_SEC="${DURATION_SEC:-360}"

echo "Injecting errors for ${DURATION_SEC}s against ${BASE_URL} ..."

end=$((SECONDS + DURATION_SEC))
while [ "$SECONDS" -lt "$end" ]; do
  curl -sf "${BASE_URL}/health" -o /dev/null || true
  curl -sf "${BASE_URL}/notes" -o /dev/null || true
  # Malformed JSON -> 400
  curl -s -X POST "${BASE_URL}/notes" \
    -H 'Content-Type: application/json' \
    -d '{"title":""}' -o /dev/null || true
  curl -s -X POST "${BASE_URL}/notes" \
    -H 'Content-Type: application/json' \
    -d 'not-json' -o /dev/null || true
  sleep 1
done

echo "Done."
