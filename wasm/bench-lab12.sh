#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.local/tinygo/bin:$PATH"
export CGO_ENABLED=1

REPO="${REPO:-/mnt/c/Users/Selysecr/Desktop/DevOps/My_DevOps-Intro/DevOps-Intro}"
rm -rf "$HOME/lab12-wasm"
cp -r "$REPO/wasm" "$HOME/lab12-wasm"
cd "$HOME/lab12-wasm"
spin build

DOCKER_PORT=18080
SPIN_PORT=13002

DOCKER_SIZE=$(docker images quicknotes:lab6 --format '{{.Size}}' | head -1)
WASM_BYTES=$(stat -c%s main.wasm)

echo "=== ARTIFACTS ==="
echo "docker_size=$DOCKER_SIZE wasm_bytes=$WASM_BYTES"

cold_docker() {
  docker rm -f lab12-qn-cold >/dev/null 2>&1 || true
  local t0 t1
  t0=$(date +%s%3N)
  docker run -d --name lab12-qn-cold -p "${DOCKER_PORT}:8080" quicknotes:lab6 >/dev/null
  until curl -sf "http://127.0.0.1:${DOCKER_PORT}/health" >/dev/null 2>&1; do sleep 0.005; done
  t1=$(date +%s%3N)
  echo $((t1 - t0))
}

cold_spin() {
  pkill -f "spin up --listen 127.0.0.1:${SPIN_PORT}" >/dev/null 2>&1 || true
  sleep 0.3
  local t0 t1
  t0=$(date +%s%3N)
  spin up --listen "127.0.0.1:${SPIN_PORT}" >/dev/null 2>&1 &
  until curl -sf "http://127.0.0.1:${SPIN_PORT}/time" >/dev/null 2>&1; do sleep 0.005; done
  t1=$(date +%s%3N)
  echo $((t1 - t0))
}

echo "=== COLD DOCKER ms ==="
D_COLD=()
for i in 1 2 3 4 5; do
  ms=$(cold_docker)
  echo "run${i}=${ms}"
  D_COLD+=("$ms")
done

echo "=== COLD SPIN ms ==="
S_COLD=()
for i in 1 2 3 4 5; do
  ms=$(cold_spin)
  echo "run${i}=${ms}"
  S_COLD+=("$ms")
done

docker rm -f lab12-qn-cold >/dev/null 2>&1 || true
docker run -d --name lab12-qn-warm -p "${DOCKER_PORT}:8080" quicknotes:lab6 >/dev/null
sleep 1
until curl -sf "http://127.0.0.1:${DOCKER_PORT}/health" >/dev/null; do sleep 0.05; done

pkill -f "spin up --listen 127.0.0.1:${SPIN_PORT}" >/dev/null 2>&1 || true
sleep 0.3
spin up --listen "127.0.0.1:${SPIN_PORT}" >/dev/null 2>&1 &
sleep 1
until curl -sf "http://127.0.0.1:${SPIN_PORT}/time" >/dev/null; do sleep 0.05; done

warm_runs() {
  local url=$1 warmup=$2 runs=$3
  local i t0 t1 ms
  for ((i=0; i<warmup; i++)); do curl -sf -o /dev/null "$url"; done
  for ((i=0; i<runs; i++)); do
    t0=$(date +%s%N)
    curl -sf -o /dev/null "$url"
    t1=$(date +%s%N)
    ms=$(( (t1 - t0) / 1000000 ))
    echo "$ms"
  done
}

echo "=== WARM DOCKER ms ==="
mapfile -t D_WARM < <(warm_runs "http://127.0.0.1:${DOCKER_PORT}/health" 5 50)
printf '%s\n' "${D_WARM[@]}"

echo "=== WARM SPIN ms ==="
mapfile -t S_WARM < <(warm_runs "http://127.0.0.1:${SPIN_PORT}/time" 5 50)
printf '%s\n' "${S_WARM[@]}"

printf '%s\n' "${D_COLD[@]}" > /tmp/lab12-docker-cold.txt
printf '%s\n' "${S_COLD[@]}" > /tmp/lab12-spin-cold.txt
printf '%s\n' "${D_WARM[@]}" > /tmp/lab12-docker-warm.txt
printf '%s\n' "${S_WARM[@]}" > /tmp/lab12-spin-warm.txt

python3 - <<PY
import json
import statistics
from pathlib import Path

def pct(vals, p):
    vals = sorted(vals)
    k = (len(vals) - 1) * p / 100
    f = int(k)
    c = min(f + 1, len(vals) - 1)
    return vals[f] + (vals[c] - vals[f]) * (k - f)

def read_nums(path):
    return [float(x) for x in Path(path).read_text().split() if x.strip()]

dc = read_nums("/tmp/lab12-docker-cold.txt")
sc = read_nums("/tmp/lab12-spin-cold.txt")
dw = read_nums("/tmp/lab12-docker-warm.txt")
sw = read_nums("/tmp/lab12-spin-warm.txt")

summary = {
    "docker_size": "${DOCKER_SIZE}",
    "wasm_bytes": ${WASM_BYTES},
    "docker_cold_ms": dc,
    "spin_cold_ms": sc,
    "docker_cold_p50_ms": statistics.median(dc),
    "spin_cold_p50_ms": statistics.median(sc),
    "docker_warm_p50_ms": round(statistics.median(dw), 2),
    "docker_warm_p95_ms": round(pct(dw, 95), 2),
    "spin_warm_p50_ms": round(statistics.median(sw), 2),
    "spin_warm_p95_ms": round(pct(sw, 95), 2),
}
Path("/tmp/lab12-bench-summary.json").write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
PY

docker rm -f lab12-qn-warm lab12-qn-cold >/dev/null 2>&1 || true
pkill -f "spin up --listen 127.0.0.1:${SPIN_PORT}" >/dev/null 2>&1 || true
