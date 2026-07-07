#!/usr/bin/env bash
# Warm latency: 5 consecutive requests, print times and p50 (median).
set -euo pipefail

URL="${1:?usage: $0 <base-url>}"
PATH_SUFFIX="${2:-/health}"
TARGET="${URL%/}${PATH_SUFFIX}"

times=()
for _ in 1 2 3 4 5; do
  t=$(curl -w '%{time_total}' -o /dev/null -s "$TARGET")
  times+=("$t")
  printf '%s\n' "$t"
done

python3 - <<'PY' "${times[@]}"
import statistics, sys
vals = [float(x) for x in sys.argv[1:]]
print(f"p50: {statistics.median(vals):.4f}s")
PY
