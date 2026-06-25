#!/usr/bin/env bash
# Lab 9 Task 2 — OWASP ZAP baseline (passive) against running QuickNotes.
# Usage: bash security/scripts/run-zap-baseline.sh
# Requires: QuickNotes on http://localhost:8080

set -euo pipefail

ZAP_IMAGE="${ZAP_IMAGE:-ghcr.io/zaproxy/zaproxy:2.16.1}"
TARGET="${TARGET:-http://host.docker.internal:8080/health}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="${REPO_ROOT}/security/reports"
mkdir -p "${OUT_DIR}"

docker run --rm \
  -v "${OUT_DIR}:/zap/wrk:rw" \
  --add-host=host.docker.internal:host-gateway \
  "${ZAP_IMAGE}" zap-baseline.py \
  -t "${TARGET}" \
  -r zap-baseline.html \
  -J zap-baseline.json \
  -I

echo "ZAP reports: ${OUT_DIR}/zap-baseline.html and zap-baseline.json"
