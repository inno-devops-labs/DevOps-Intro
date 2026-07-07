#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "" ]; then
  echo "usage: $0 <url> [runs]" >&2
  exit 2
fi

url="$1"
runs="${2:-5}"

tmp="$(mktemp)"
sorted="$(mktemp)"
trap 'rm -f "$tmp" "$sorted"' EXIT

for i in $(seq 1 "$runs"); do
  curl -o /dev/null -s -w '%{time_total}\n' "$url" | tee -a "$tmp"
done

sort -n "$tmp" > "$sorted"
count="$(wc -l < "$sorted" | tr -d ' ')"
p50_index=$(( (count + 1) * 50 / 100 ))
p95_index=$(( (count + 1) * 95 / 100 ))
[ "$p50_index" -lt 1 ] && p50_index=1
[ "$p95_index" -lt 1 ] && p95_index=1
[ "$p50_index" -gt "$count" ] && p50_index="$count"
[ "$p95_index" -gt "$count" ] && p95_index="$count"

p50="$(sed -n "${p50_index}p" "$sorted")"
p95="$(sed -n "${p95_index}p" "$sorted")"

printf 'runs=%s\n' "$count"
printf 'p50=%ss\n' "$p50"
printf 'p95=%ss\n' "$p95"
