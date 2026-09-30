#!/usr/bin/env bash
# Generate mixed healthy traffic against QuickNotes (~200 requests)
set -euo pipefail
BASE="${1:-http://127.0.0.1:8080}"
echo "Traffic against $BASE"
for i in $(seq 1 150); do
  curl -s -o /dev/null "$BASE/health" || true
  curl -s -o /dev/null "$BASE/notes" || true
done
for i in $(seq 1 25); do
  curl -s -o /dev/null -X POST -H 'Content-Type: application/json' \
    -d "{\"title\":\"t$i\",\"body\":\"b$i\"}" "$BASE/notes" || true
done
echo "done ~325 calls"
