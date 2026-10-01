#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/submissions/evidence/lab9"
TRIVY_CACHE="$ROOT_DIR/.goenv/trivy-cache"
TRIVY_IMAGE="aquasec/trivy:0.59.1"
ZAP_IMAGE="ghcr.io/zaproxy/zaproxy:2.16.1"
TARGET="http://127.0.0.1:8080"

mkdir -p "$EVIDENCE_DIR" "$TRIVY_CACHE"

prepare() {
  docker compose -f "$ROOT_DIR/compose.yaml" up -d --build quicknotes
  for _ in {1..30}; do
    if curl -fsS "$TARGET/health" >/dev/null; then
      echo "QuickNotes is healthy at $TARGET"
      return
    fi
    sleep 1
  done
  docker compose -f "$ROOT_DIR/compose.yaml" logs --no-color quicknotes
  echo "QuickNotes did not become healthy" >&2
  exit 1
}

trivy() {
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$TRIVY_CACHE:/root/.cache/" \
    "$TRIVY_IMAGE" image --severity HIGH,CRITICAL --no-progress quicknotes:lab6 \
    | tee "$EVIDENCE_DIR/trivy-image.txt"
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$TRIVY_CACHE:/root/.cache/" \
    "$TRIVY_IMAGE" image --severity HIGH,CRITICAL --no-progress --format json \
    quicknotes:lab6 >"$EVIDENCE_DIR/trivy-image.json"

  docker run --rm \
    -v "$ROOT_DIR:/workspace:ro" \
    -v "$TRIVY_CACHE:/root/.cache/" \
    "$TRIVY_IMAGE" fs --severity HIGH,CRITICAL --no-progress \
    --skip-dirs /workspace/.git --skip-dirs /workspace/.goenv \
    --skip-dirs /workspace/.venv --skip-dirs /workspace/.vagrant \
    /workspace \
    | tee "$EVIDENCE_DIR/trivy-filesystem.txt"
  docker run --rm \
    -v "$ROOT_DIR:/workspace:ro" \
    -v "$TRIVY_CACHE:/root/.cache/" \
    "$TRIVY_IMAGE" fs --severity HIGH,CRITICAL --no-progress --format json \
    --skip-dirs /workspace/.git --skip-dirs /workspace/.goenv \
    --skip-dirs /workspace/.venv --skip-dirs /workspace/.vagrant \
    /workspace \
    >"$EVIDENCE_DIR/trivy-filesystem.json"

  docker run --rm \
    -v "$ROOT_DIR:/workspace:ro" \
    -v "$TRIVY_CACHE:/root/.cache/" \
    "$TRIVY_IMAGE" config --severity HIGH,CRITICAL \
    --skip-dirs /workspace/.git --skip-dirs /workspace/.goenv \
    --skip-dirs /workspace/.venv --skip-dirs /workspace/.vagrant \
    /workspace \
    | tee "$EVIDENCE_DIR/trivy-config.txt"
  docker run --rm \
    -v "$ROOT_DIR:/workspace:ro" \
    -v "$TRIVY_CACHE:/root/.cache/" \
    "$TRIVY_IMAGE" config --severity HIGH,CRITICAL --format json \
    --skip-dirs /workspace/.git --skip-dirs /workspace/.goenv \
    --skip-dirs /workspace/.venv --skip-dirs /workspace/.vagrant \
    /workspace \
    >"$EVIDENCE_DIR/trivy-config.json"

  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$TRIVY_CACHE:/root/.cache/" \
    "$TRIVY_IMAGE" image --no-progress --format cyclonedx \
    quicknotes:lab6 >"$EVIDENCE_DIR/quicknotes-lab6.cdx.json"
  echo "Trivy evidence saved in $EVIDENCE_DIR"
}

zap() {
  local stage="${1:-}"
  if [[ "$stage" != "before" && "$stage" != "after" ]]; then
    echo "Usage: $0 zap before|after" >&2
    exit 2
  fi
  curl -fsS "$TARGET/health" >/dev/null || {
    echo "QuickNotes is not reachable at $TARGET; run '$0 prepare' first" >&2
    exit 1
  }

  set +e
  docker run --rm --network host \
    -v "$EVIDENCE_DIR:/zap/wrk/:rw" \
    "$ZAP_IMAGE" zap-baseline.py -t "$TARGET" \
    -r "zap-$stage.html" -J "zap-$stage.json"
  local status=$?
  set -e
  printf '%s\n' "$status" >"$EVIDENCE_DIR/zap-$stage.exit-code.txt"

  if (( status >= 3 )); then
    echo "ZAP failed with exit code $status" >&2
    exit "$status"
  fi
  echo "ZAP $stage evidence saved (scanner exit code $status)."
}

case "${1:-}" in
  prepare) prepare ;;
  trivy) trivy ;;
  zap) zap "${2:-}" ;;
  *)
    echo "Usage: $0 {prepare|trivy|zap before|zap after}" >&2
    exit 2
    ;;
esac
