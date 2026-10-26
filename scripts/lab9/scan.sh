#!/usr/bin/env bash
# Reproduce Lab 9 without mounting the Docker socket into a scanner.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
report_dir="$repo_dir/submissions/lab9"
work_dir="${LAB9_WORK_DIR:-$(mktemp -d /private/tmp/quicknotes-lab9.XXXXXX)}"
trivy_image='aquasec/trivy:0.76.1'
zap_image='ghcr.io/zaproxy/zaproxy:2.17.0'
phase="${2:-before}"
case "$phase" in before|after) ;; *) echo 'Phase must be before or after' >&2; exit 64 ;; esac
mkdir -p "$report_dir" "$work_dir/trivy-cache"

trivy() {
  docker run --rm \
    -v "$work_dir:/work" \
    -v "$repo_dir:/repo:ro" \
    -v "$report_dir:/reports" \
    "$trivy_image" --cache-dir /work/trivy-cache "$@"
}

case "${1:-}" in
  trivy)
    if [[ "$phase" == before ]]; then app_image='quicknotes:lab6'; else app_image='quicknotes:lab9'; fi
    docker image save "$app_image" -o "$work_dir/image-$phase.tar"
    docker image inspect "$app_image" > "$report_dir/image-$phase-inspect.json"
    trivy image --input "/work/image-$phase.tar" --severity HIGH,CRITICAL \
      --scanners vuln --format json --output "/reports/trivy-image-$phase.json" \
      2>&1 | tee "$report_dir/trivy-image-$phase.log"
    trivy fs --severity HIGH,CRITICAL --scanners vuln,secret \
      --skip-dirs /repo/.git --skip-dirs /repo/.vagrant \
      --skip-dirs /repo/submissions/lab9 --skip-files /repo/.env \
      --format json --output "/reports/trivy-fs-$phase.json" /repo \
      2>&1 | tee "$report_dir/trivy-fs-$phase.log"
    trivy config --skip-dirs /repo/.git --skip-dirs /repo/.vagrant \
      --skip-dirs /repo/submissions/lab9 \
      --format json --output "/reports/trivy-config-$phase.json" /repo \
      2>&1 | tee "$report_dir/trivy-config-$phase.log"
    for target in image fs config; do
      trivy convert --scanners vuln,secret,misconfig --format table --output "/reports/trivy-$target-$phase.txt" \
        "/reports/trivy-$target-$phase.json"
    done
    # `trivy sbom` consumes an existing SBOM. Generation uses `image --format`.
    trivy image --input "/work/image-$phase.tar" --format cyclonedx \
      --output "/reports/quicknotes-$phase.sbom.cdx.json" \
      2>&1 | tee "$report_dir/trivy-sbom-$phase.log"
    ;;
  zap)
    # The network must contain an isolated app with alias `quicknotes`.
    # No ZAP API port is published; no active or AJAX scan is enabled.
    set +e
    docker run --rm --network "${LAB9_NETWORK:-quicknotes-lab9}" \
      -v "$report_dir:/zap/wrk:rw" \
      -v "$repo_dir/scripts/lab9/zap_hooks.py:/zap/hooks.py:ro" \
      "$zap_image" zap-baseline.py --autooff \
      -t http://quicknotes:8080 -m 1 -T 5 \
      --hook /zap/hooks.py \
      -r "zap-$phase.html" -J "zap-$phase.json" \
      2>&1 | tee "$report_dir/zap-$phase.log"
    scan_status=${PIPESTATUS[0]}
    set -e
    printf '%s\n' "$scan_status" > "$report_dir/zap-$phase.exit-code.txt"
    # 2 means completed with passive warnings, not an infrastructure error.
    [[ "$scan_status" == 0 || "$scan_status" == 2 ]]
    ;;
  *) echo 'Usage: bash scripts/lab9/scan.sh {trivy|zap} {before|after}' >&2; exit 64 ;;
esac
