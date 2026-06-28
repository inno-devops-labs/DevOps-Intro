#!/usr/bin/env sh
set -eu

base_url="${BASE_URL:-http://localhost:8080}"
count="${COUNT:-200}"

i=1
while [ "$i" -le "$count" ]; do
  case $((i % 5)) in
    0)
      curl -fsS "$base_url/notes/999999" >/dev/null 2>&1 || true
      ;;
    1)
      curl -fsS "$base_url/health" >/dev/null
      ;;
    2)
      curl -fsS "$base_url/notes" >/dev/null
      ;;
    3)
      curl -fsS -X POST "$base_url/notes" \
        -H "Content-Type: application/json" \
        -d "{\"title\":\"lab8-$i\",\"body\":\"generated traffic\"}" >/dev/null
      ;;
    *)
      curl -fsS -X POST "$base_url/notes" \
        -H "Content-Type: application/json" \
        -d '{"body":"missing title"}' >/dev/null 2>&1 || true
      ;;
  esac
  i=$((i + 1))
done
