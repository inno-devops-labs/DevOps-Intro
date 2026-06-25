#!/usr/bin/env bash
# Generate mixed traffic against QuickNotes (Lab 8 Task 1).
# Usage: ./monitoring/scripts/generate-traffic.sh

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
COUNT="${COUNT:-200}"

echo "Sending ${COUNT} requests to ${BASE_URL} ..."

for i in $(seq 1 "$COUNT"); do
  case $((i % 4)) in
    0) curl -sf "${BASE_URL}/health" -o /dev/null ;;
    1) curl -sf "${BASE_URL}/notes" -o /dev/null ;;
    2) curl -sf -X POST "${BASE_URL}/notes" \
         -H 'Content-Type: application/json' \
         -d "{\"title\":\"traffic-${i}\",\"body\":\"lab8\"}" -o /dev/null ;;
    3) curl -sf "${BASE_URL}/notes/1" -o /dev/null || true ;;
  esac
done

echo "Done."
