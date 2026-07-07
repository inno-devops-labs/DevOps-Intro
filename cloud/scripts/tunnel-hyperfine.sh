#!/usr/bin/env bash
# Bonus: warm p50/p95 via hyperfine (50 runs) against a public tunnel URL.
set -euo pipefail

URL="${1:?usage: $0 <https://xxx.trycloudflare.com>}"
TARGET="${URL%/}/health"

command -v hyperfine >/dev/null || { echo "install hyperfine: brew install hyperfine"; exit 1; }

hyperfine --warmup 5 --runs 50 --export-json /dev/stdout \
  "curl -fsS -o /dev/null $TARGET" | python3 -c "
import json, sys, statistics
d = json.load(sys.stdin)
t = [r['times'][0] for r in d['results']]
t.sort()
n = len(t)
p50 = t[n//2]
p95 = t[int(n*0.95)-1]
print(f'p50: {p50:.4f}s')
print(f'p95: {p95:.4f}s')
"
