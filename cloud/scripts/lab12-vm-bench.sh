#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-/root/lab12-work/DevOps-Intro}"
OUT="${ROOT}/submissions/attachments/lab12"
export PATH="${HOME}/.nix-profile/bin:${HOME}/.wasmtime/bin:${PATH}"

mkdir -p "${OUT}"

cd "${ROOT}"

# --- Lab 6 Docker baseline ---
if ! docker image inspect quicknotes:lab6 >/dev/null 2>&1; then
  docker build -t quicknotes:lab6 ./app
fi
docker rm -f qn-lab6 2>/dev/null || true
docker run -d --name qn-lab6 -p 18080:8080 quicknotes:lab6
trap 'docker rm -f qn-lab6 2>/dev/null; pkill -f "spin up" 2>/dev/null || true' EXIT

for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:18080/health >/dev/null 2>&1; then break; fi
  sleep 1
done
curl -fsS http://127.0.0.1:18080/health | tee "${OUT}/docker-health.json"

# --- Spin WASM ---
cd "${ROOT}/wasm"
if [[ ! -f main.wasm ]]; then
  GOMAXPROCS=1 spin build 2>&1 | tee "${OUT}/spin-build.log"
else
  echo "Reusing existing main.wasm" | tee "${OUT}/spin-build.log"
fi
ls -la main.wasm | tee "${OUT}/wasm-size.txt"
pkill -f "spin up" 2>/dev/null || true
sleep 1
spin up --listen 127.0.0.1:3000 >/tmp/spin.log 2>&1 &
SPIN_PID=$!
sleep 2
curl -fsS http://127.0.0.1:3000/time | python3 -m json.tool | tee "${OUT}/spin-time.json"

# --- wasm-cli bonus ---
cd "${ROOT}/wasm-cli"
if [[ ! -f main.wasm ]]; then
  GOMAXPROCS=1 tinygo build -o main.wasm -target=wasi -no-debug ./main.go 2>&1 | tee "${OUT}/wasm-cli-build.log"
else
  echo "Reusing existing wasm-cli main.wasm" | tee "${OUT}/wasm-cli-build.log"
fi
ls -la main.wasm | tee -a "${OUT}/wasm-size.txt"
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm \
  | tee "${OUT}/wasm-cli-raw.txt" \
  | awk 'BEGIN{body=0} /^\r?$/ {body=1; next} body' \
  | python3 -m json.tool | tee "${OUT}/wasm-cli-time.json"

# --- Sizes ---
{
  echo "=== Artifact sizes ==="
  echo -n "main.wasm (spin): "
  stat -c%s "${ROOT}/wasm/main.wasm"
  echo -n "main.wasm (wasm-cli): "
  stat -c%s "${ROOT}/wasm-cli/main.wasm"
  echo -n "docker image: "
  docker image inspect quicknotes:lab6 --format='{{.Size}}'
} | tee "${OUT}/sizes.txt"

# --- Warm latency ---
hyperfine --warmup 5 --runs 50 --export-json "${OUT}/warm-spin.json" \
  'curl -fsS http://127.0.0.1:3000/time >/dev/null' 2>&1 | tee "${OUT}/warm-spin.txt"

hyperfine --warmup 5 --runs 50 --export-json "${OUT}/warm-docker.json" \
  'curl -fsS http://127.0.0.1:18080/health >/dev/null' 2>&1 | tee "${OUT}/warm-docker.txt"

# --- Cold start: Spin ---
{
  echo "=== Spin cold start (5 samples) ==="
  for n in 1 2 3 4 5; do
    pkill -f "spin up" 2>/dev/null || true
    sleep 1
    start=$(date +%s%3N)
    spin up --listen 127.0.0.1:3000 >/tmp/spin.log 2>&1 &
    SPIN_PID=$!
    for _ in $(seq 1 200); do
      if curl -fsS http://127.0.0.1:3000/time >/dev/null 2>&1; then break; fi
      sleep 0.05
    done
    end=$(date +%s%3N)
    echo "sample${n}: $((end - start)) ms"
  done
} | tee "${OUT}/cold-spin.txt"

# --- Cold start: Docker ---
{
  echo "=== Docker cold start (5 samples) ==="
  for n in 1 2 3 4 5; do
    docker rm -f qn-lab6 2>/dev/null || true
    sleep 1
    start=$(date +%s%3N)
    docker run -d --name qn-lab6 -p 18080:8080 quicknotes:lab6 >/dev/null
    until curl -fsS http://127.0.0.1:18080/health >/dev/null 2>&1; do sleep 0.05; done
    end=$(date +%s%3N)
    echo "sample${n}: $((end - start)) ms"
  done
} | tee "${OUT}/cold-docker.txt"

# --- Cold start: wasmtime run (bonus) ---
{
  echo "=== wasmtime run cold (5 samples) ==="
  cd "${ROOT}/wasm-cli"
  for n in 1 2 3 4 5; do
    start=$(date +%s%3N)
    wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm >/dev/null
    end=$(date +%s%3N)
    echo "sample${n}: $((end - start)) ms"
  done
} | tee "${OUT}/cold-wasmtime.txt"

echo "Benchmark artifacts written to ${OUT}"
