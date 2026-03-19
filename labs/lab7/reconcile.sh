#!/bin/bash
set -euo pipefail

# Keep file paths stable even if the script is launched from another directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESIRED_FILE="$SCRIPT_DIR/desired-state.txt"
CURRENT_FILE="$SCRIPT_DIR/current-state.txt"

if ! cmp -s "$DESIRED_FILE" "$CURRENT_FILE"; then
    echo "$(date) - DRIFT DETECTED!"
    echo "Reconciling current state with desired state..."
    cp "$DESIRED_FILE" "$CURRENT_FILE"
    echo "$(date) - Reconciliation complete"
else
    echo "$(date) - States synchronized"
fi
