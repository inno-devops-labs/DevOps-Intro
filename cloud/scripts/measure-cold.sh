#!/usr/bin/env bash
# Single request after idle sleep — use between runs when Space is sleeping.
set -euo pipefail

URL="${1:?usage: $0 <base-url>}"
PATH_SUFFIX="${2:-/health}"
TARGET="${URL%/}${PATH_SUFFIX}"

curl -w 'time_total=%{time_total}s http_code=%{http_code}\n' -o /dev/null -s "$TARGET"
