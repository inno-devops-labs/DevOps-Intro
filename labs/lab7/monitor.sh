#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting GitOps monitoring..."
for i in {1..10}; do
    printf '\n--- Check #%s ---\n' "$i"
    "$SCRIPT_DIR/healthcheck.sh"
    "$SCRIPT_DIR/reconcile.sh"
    sleep 3
done
