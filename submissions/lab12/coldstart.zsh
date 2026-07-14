#!/usr/bin/env zsh
# Lab 12 cold-start measurement: time from launch command to first successful
# HTTP 200, five samples per runtime. Poll granularity = one curl spawn (~few ms).
zmodload zsh/datetime
cd "$(dirname "$0")/../.."   # repo root

# make sure nothing is left over from previous runs
pkill -f 'spin up --listen 127.0.0.1:3300' 2>/dev/null
docker rm -f qn-cold >/dev/null 2>&1
sleep 1

echo "== Spin cold start (5 runs) =="
cd wasm
for i in {1..5}; do
  t0=$EPOCHREALTIME
  spin up --listen 127.0.0.1:3300 >/dev/null 2>&1 &
  pid=$!
  until curl -sf http://127.0.0.1:3300/time >/dev/null 2>&1; do :; done
  printf '%.0f ms\n' $(( (EPOCHREALTIME - t0) * 1000 ))
  kill $pid 2>/dev/null
  wait $pid 2>/dev/null
done | tee ../submissions/lab12/cold-spin.txt
cd ..

echo "== Docker cold start (5 runs) =="
for i in {1..5}; do
  t0=$EPOCHREALTIME
  docker run -d --rm --name qn-cold -p 8081:8080 quicknotes:lab6 >/dev/null
  until curl -sf http://127.0.0.1:8081/health >/dev/null 2>&1; do :; done
  printf '%.0f ms\n' $(( (EPOCHREALTIME - t0) * 1000 ))
  docker rm -f qn-cold >/dev/null
done | tee submissions/lab12/cold-docker.txt

echo "== done =="
