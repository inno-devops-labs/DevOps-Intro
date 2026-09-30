#!/usr/bin/env bash
set -euo pipefail

base_url=${QUICKNOTES_URL:-http://127.0.0.1:8080}
mode=${1:-mixed}

case "$mode" in
  mixed)
    for request_number in $(seq 1 200); do
      if (( request_number % 10 == 0 )); then
        curl -fsS "$base_url/notes/999999" >/dev/null || true
      elif (( request_number % 4 == 0 )); then
        curl -fsS "$base_url/health" >/dev/null
      else
        curl -fsS "$base_url/notes" >/dev/null
      fi
    done
    echo "Generated 200 mixed requests."
    ;;
  errors)
    echo "Generating sustained errors for six minutes..."
    end_time=$((SECONDS + 360))
    next_report=$((SECONDS + 30))
    while (( SECONDS < end_time )); do
      curl -fsS "$base_url/health" >/dev/null
      curl -fsS "$base_url/notes" >/dev/null
      curl -sS -o /dev/null -X POST \
        -H 'Content-Type: application/json' \
        --data '{malformed-json' \
        "$base_url/notes"
      if (( SECONDS >= next_report )); then
        echo "$((end_time - SECONDS)) seconds remaining..."
        next_report=$((next_report + 30))
      fi
      sleep 1
    done
    echo "Finished the six-minute error stream."
    ;;
  *)
    echo "Usage: $0 [mixed|errors]" >&2
    exit 2
    ;;
esac
