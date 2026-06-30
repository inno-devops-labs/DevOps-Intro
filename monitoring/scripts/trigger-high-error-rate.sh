#!/usr/bin/env bash
# Drive QuickNotes with a sustained ~40% error ratio so the high-error-rate
# alert transitions Normal -> Pending -> Firing. The alert uses a 5m rate
# window plus a 5m "for" hold, so run this for at least ~6 minutes.
#
# Each loop sends 3 healthy reads (200) + 1 malformed POST (400) + 1 missing
# note (404). No notes are created, so it is safe to run repeatedly.
#
# Watch the alert at http://localhost:9090/alerts while this runs.
#
# Usage: ./trigger-high-error-rate.sh [base_url] [duration_seconds]
#   base_url           default http://localhost:8080
#   duration_seconds   default 420 (7 minutes)
set -euo pipefail

BASE="${1:-http://localhost:8080}"
DURATION="${2:-420}"
end=$(( $(date +%s) + DURATION ))

echo "injecting ~40% errors at $BASE for ${DURATION}s (watch :9090/alerts)..."
n=0
while [ "$(date +%s)" -lt "$end" ]; do
  curl -s -o /dev/null "$BASE/notes"                                              # 200
  curl -s -o /dev/null "$BASE/health"                                             # 200
  curl -s -o /dev/null "$BASE/notes/1"                                            # 200
  curl -s -o /dev/null -X POST "$BASE/notes" \
       -H 'Content-Type: application/json' -d 'not json'                          # 400
  curl -s -o /dev/null "$BASE/notes/999999"                                       # 404
  n=$((n + 5))
done
echo "done, sent ~${n} requests (~40% errors)."
