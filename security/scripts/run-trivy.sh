#!/usr/bin/env bash
# Lab 9 Task 1 — run Trivy image, fs, config scans + CycloneDX SBOM.
# Usage: bash security/scripts/run-trivy.sh
# Requires: Docker, quicknotes:lab6 image built.

set -euo pipefail

TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:0.59.1}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="${REPO_ROOT}/security/reports"
mkdir -p "${OUT_DIR}"

echo "==> Trivy image scan (HIGH,CRITICAL)"
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  "${TRIVY_IMAGE}" image --severity HIGH,CRITICAL quicknotes:lab6 \
  | tee "${OUT_DIR}/trivy-image.txt"

echo "==> Trivy filesystem scan (HIGH,CRITICAL)"
docker run --rm \
  -v "${REPO_ROOT}:/repo" \
  "${TRIVY_IMAGE}" fs --severity HIGH,CRITICAL /repo \
  | tee "${OUT_DIR}/trivy-fs.txt"

echo "==> Trivy config scan"
docker run --rm \
  -v "${REPO_ROOT}:/repo" \
  "${TRIVY_IMAGE}" config /repo \
  | tee "${OUT_DIR}/trivy-config.txt"

echo "==> Trivy SBOM (CycloneDX)"
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "${OUT_DIR}:/out" \
  "${TRIVY_IMAGE}" image --format cyclonedx --output /out/quicknotes-sbom.json quicknotes:lab6

echo "Reports written to ${OUT_DIR}/"
