#!/usr/bin/env bash
# Capture Lab 8 evidence after `docker compose up -d`.
set -euo pipefail
cd "$(dirname "$0")/.."
ATT=submissions/attachments/lab8
mkdir -p "$ATT"

docker compose ps | tee "$ATT/compose-ps.txt"
curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool | tee "$ATT/prometheus-targets.json"
curl -s http://localhost:9090/api/v1/targets | python3 -c "import sys,json; d=json.load(sys.stdin); print([t['health'] for t in d['data']['activeTargets']])" | tee "$ATT/targets-health.txt"
curl -s -u admin:lab8-grafana-dev http://localhost:3000/api/search?query=Golden | tee "$ATT/grafana-dashboard-search.json"
curl -s http://localhost:9090/api/v1/alerts | python3 -m json.tool | tee "$ATT/prometheus-alerts.json"
echo "Evidence captured in $ATT"
