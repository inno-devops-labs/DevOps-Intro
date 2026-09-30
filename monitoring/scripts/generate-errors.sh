#!/usr/bin/env bash
set -euo pipefail

base_url="${1:-http://127.0.0.1:8080}"
trap 'exit 0' TERM INT
while true; do
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  bad="$(curl --max-time 5 -sS -o /dev/null -w '%{http_code}' -X POST \
    -H 'Content-Type: application/json' -d '{bad' "$base_url/notes")"
  healthy_1="$(curl --max-time 5 -sS -o /dev/null -w '%{http_code}' "$base_url/health")"
  healthy_2="$(curl --max-time 5 -sS -o /dev/null -w '%{http_code}' "$base_url/health")"
  healthy_3="$(curl --max-time 5 -sS -o /dev/null -w '%{http_code}' "$base_url/notes")"
  printf '%s bad=%s healthy=%s,%s,%s\n' "$timestamp" "$bad" "$healthy_1" "$healthy_2" "$healthy_3"
  sleep 1
done
