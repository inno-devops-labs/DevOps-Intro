#!/usr/bin/env bash
# Generate ~200 mixed requests for Lab 8 Task 1 dashboard traffic.
set -euo pipefail
BASE="${1:-http://localhost:8080}"
OUT="${2:-submissions/attachments/lab8/traffic-gen.log}"

echo "Generating traffic against $BASE" | tee "$OUT"
for i in $(seq 1 200); do
  case $((i % 5)) in
    0) curl -s "$BASE/health" >>"$OUT" ;;
    1) curl -s "$BASE/notes" >>"$OUT" ;;
    2) curl -s -X POST "$BASE/notes" -H 'Content-Type: application/json' \
         -d '{"title":"load","body":"traffic"}' >>"$OUT" ;;
    3) curl -s "$BASE/notes/1" >>"$OUT" ;;
    4) curl -s -X POST "$BASE/notes" -H 'Content-Type: application/json' -d '{"bad":true}' >>"$OUT" ;;
  esac
done
echo "done 200 requests" | tee -a "$OUT"
