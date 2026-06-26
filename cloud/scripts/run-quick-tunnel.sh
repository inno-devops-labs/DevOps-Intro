#!/usr/bin/env bash
# Lab 10 bonus — Cloudflare quick tunnel to local QuickNotes.
# Usage: bash cloud/scripts/run-quick-tunnel.sh
# Requires: cloudflared, QuickNotes on http://localhost:8080

set -euo pipefail

if ! curl -fsS http://localhost:8080/health >/dev/null 2>&1; then
  echo "Start QuickNotes first: docker compose up -d quicknotes"
  exit 1
fi

echo "Starting quick tunnel (Ctrl+C to stop)..."
exec cloudflared tunnel --url http://localhost:8080
