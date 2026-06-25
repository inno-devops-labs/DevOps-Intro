#!/usr/bin/env bash
# Snapshot Prometheus golden-signal stats for Lab 8 bonus comparison.
# Run after Checkly has probed for >= 30 minutes.
# Usage: bash monitoring/scripts/bonus-prometheus-snapshot.sh

set -euo pipefail

PROM="${PROM:-http://localhost:9090}"
WINDOW="${WINDOW:-30m}"

query() {
  curl -sG "${PROM}/api/v1/query" --data-urlencode "query=$1" \
    | jq -r '.data.result[0].value[1] // "n/a"'
}

echo "=== Prometheus snapshot (window: ${WINDOW}) ==="
echo
echo "Request rate (traffic proxy, req/s):"
query "rate(quicknotes_http_requests_total[${WINDOW}])"
echo
echo "Error ratio:"
query "sum(rate(quicknotes_http_responses_by_code_total{code=~\"4..|5..\"}[${WINDOW}])) / sum(rate(quicknotes_http_requests_total[${WINDOW}]))"
echo
echo "4xx+5xx count (increase):"
query "sum(increase(quicknotes_http_responses_by_code_total{code=~\"4..|5..\"}[${WINDOW}]))"
echo
echo "Total requests (increase):"
query "sum(increase(quicknotes_http_requests_total[${WINDOW}]))"
echo
echo "Notes stored (gauge, current):"
query "quicknotes_notes_total"
echo
echo "Note: QuickNotes has no request-duration histogram; use Checkly for external p50/p95 latency."
