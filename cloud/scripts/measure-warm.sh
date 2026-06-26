#!/usr/bin/env bash
# Lab 10 — measure HTTP latency (warm p50). Usage:
#   bash cloud/scripts/measure-warm.sh https://your-space.hf.space/health
#   bash cloud/scripts/measure-warm.sh https://random.trycloudflare.com/health

set -euo pipefail

URL="${1:?usage: measure-warm.sh <url>}"
RUNS="${RUNS:-5}"

if command -v hyperfine >/dev/null 2>&1; then
  hyperfine --runs "$RUNS" --warmup 1 "curl -fsS -o /dev/null '$URL'"
  exit 0
fi

echo "hyperfine not found; using curl loop ($RUNS runs)"
times=()
for _ in $(seq 1 "$RUNS"); do
  t=$(curl -w '%{time_total}' -o /dev/null -s "$URL")
  times+=("$t")
  echo "  ${t}s"
done
printf '%s\n' "${times[@]}" | sort -n | awk -v n="$RUNS" '
  { a[NR]=$1 }
  END {
    mid = int((n+1)/2)
  if (n%2) printf "p50: %ss\n", a[mid]
  else printf "p50: %ss\n", (a[mid]+a[mid+1])/2
  }'
