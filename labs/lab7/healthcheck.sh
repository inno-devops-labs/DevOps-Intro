#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESIRED_FILE="$SCRIPT_DIR/desired-state.txt"
CURRENT_FILE="$SCRIPT_DIR/current-state.txt"
HEALTH_LOG="$SCRIPT_DIR/health.log"

DESIRED_MD5="$(md5sum "$DESIRED_FILE" | awk '{print $1}')"
CURRENT_MD5="$(md5sum "$CURRENT_FILE" | awk '{print $1}')"

if [ "$DESIRED_MD5" != "$CURRENT_MD5" ]; then
    echo "$(date) - CRITICAL: State mismatch detected!" | tee -a "$HEALTH_LOG"
    echo "  Desired MD5: $DESIRED_MD5" | tee -a "$HEALTH_LOG"
    echo "  Current MD5: $CURRENT_MD5" | tee -a "$HEALTH_LOG"
else
    echo "$(date) - OK: States synchronized" | tee -a "$HEALTH_LOG"
fi
