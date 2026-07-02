#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.local/tinygo/bin:/usr/bin:/bin"

CLI_DIR="${CLI_DIR:-$HOME/lab12-wasm-cli}"
SPIN_WASM="${SPIN_WASM:-$HOME/lab12-wasm/main.wasm}"
cd "$CLI_DIR"

echo "spin_wasm_bytes=$(stat -c%s "$SPIN_WASM")"
echo "cli_wasm_bytes=$(stat -c%s main.wasm)"

echo "=== WASMTIME RUN COLD ms (per invocation) ==="
W_COLD=()
for i in 1 2 3 4 5; do
  t0=$(date +%s%3N)
  wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm >/dev/null
  t1=$(date +%s%3N)
  ms=$((t1 - t0))
  echo "run${i}=${ms}"
  W_COLD+=("$ms")
done

printf '%s\n' "${W_COLD[@]}" > /tmp/lab12-wasmtime-cold.txt
python3 - <<'PY'
import statistics
from pathlib import Path
vals = [float(x) for x in Path("/tmp/lab12-wasmtime-cold.txt").read_text().split()]
print(f"wasmtime_cold_p50_ms={statistics.median(vals)}")
PY
