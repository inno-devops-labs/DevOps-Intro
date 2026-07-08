#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.nix-profile/bin:${HOME}/.wasmtime/bin:${PATH}"
ROOT="${1:-/root/lab12-work/DevOps-Intro}"
OUT="${ROOT}/submissions/attachments/lab12"
mkdir -p "${OUT}"

{
  echo "=== Spin cold start (5 samples) ==="
  for n in 1 2 3 4 5; do
    pkill -f "spin up" 2>/dev/null || true
    sleep 1
    start=$(date +%s%3N)
    spin up --listen 127.0.0.1:3000 >/tmp/spin.log 2>&1 &
    for _ in $(seq 1 200); do
      curl -fsS http://127.0.0.1:3000/time >/dev/null 2>&1 && break
      sleep 0.05
    done
    end=$(date +%s%3N)
    echo "sample${n}: $((end - start)) ms"
  done
} | tee "${OUT}/cold-spin.txt"

{
  echo "=== Docker cold start (5 samples) ==="
  for n in 1 2 3 4 5; do
    docker rm -f qn-lab6 2>/dev/null || true
    sleep 1
    start=$(date +%s%3N)
    docker run -d --name qn-lab6 -p 18080:8080 quicknotes:lab6 >/dev/null
    for _ in $(seq 1 200); do
      curl -fsS http://127.0.0.1:18080/health >/dev/null 2>&1 && break
      sleep 0.05
    done
    end=$(date +%s%3N)
    echo "sample${n}: $((end - start)) ms"
  done
} | tee "${OUT}/cold-docker.txt"

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
