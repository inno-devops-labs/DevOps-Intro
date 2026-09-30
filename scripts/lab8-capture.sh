#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

mode=${1:-baseline}
evidence_dir=submissions/evidence/lab8
mkdir -p "$evidence_dir"

: "${GRAFANA_ADMIN_PASSWORD:?export GRAFANA_ADMIN_PASSWORD before running this script}"
grafana_user=${GRAFANA_ADMIN_USER:-lab8admin}
generator_pid=

cleanup_generator() {
  if [[ -n "$generator_pid" ]] && kill -0 "$generator_pid" 2>/dev/null; then
    kill "$generator_pid"
    wait "$generator_pid" 2>/dev/null || true
  fi
}
trap cleanup_generator EXIT

capture_baseline() {
  docker compose version | tee "$evidence_dir/compose-version.txt"
  docker compose pull prometheus grafana
  docker compose up --build -d

  for attempt in $(seq 1 24); do
    target_health=$(
      curl -fsS http://127.0.0.1:9090/api/v1/targets 2>/dev/null \
        | jq -r '.data.activeTargets[]? | select(.labels.job == "quicknotes") | .health'
    ) || true
    if [[ "$target_health" == "up" ]]; then
      break
    fi
    echo "Waiting for the QuickNotes target (${attempt}/24)..."
    sleep 5
  done
  [[ "${target_health:-}" == "up" ]]

  for attempt in $(seq 1 24); do
    if curl -fsS http://127.0.0.1:3000/api/health >/dev/null 2>&1; then
      break
    fi
    echo "Waiting for Grafana (${attempt}/24)..."
    sleep 5
  done
  curl -fsS http://127.0.0.1:3000/api/health >/dev/null

  docker compose ps | tee "$evidence_dir/compose-ps.txt"
  scripts/lab8-generate-traffic.sh mixed

  curl -fsS http://127.0.0.1:9090/api/v1/targets \
    | jq '.data.activeTargets[] | select(.labels.job == "quicknotes")' \
    | tee "$evidence_dir/prometheus-target.json"

  curl -fsS -u "$grafana_user:$GRAFANA_ADMIN_PASSWORD" \
    http://127.0.0.1:3000/api/dashboards/uid/quicknotes-golden-signals \
    | jq '{title: .dashboard.title, uid: .dashboard.uid, panels: [.dashboard.panels[].title]}' \
    | tee "$evidence_dir/grafana-dashboard-api.json"

  curl -fsSG http://127.0.0.1:9090/api/v1/query \
    --data-urlencode 'query=up{job="quicknotes"}' \
    | jq . | tee "$evidence_dir/prometheus-up-query.json"

  echo "Baseline evidence captured. Open http://127.0.0.1:3000 and save dashboard.png."
}

capture_alert() {
  curl -fsS http://127.0.0.1:9090/api/v1/rules \
    | jq '.data.groups[].rules[] | select(.name == "QuickNotesHighErrorRate")' \
    | tee "$evidence_dir/alert-inactive.json"
  inactive_state=$(jq -r '.state' "$evidence_dir/alert-inactive.json")
  echo "QuickNotesHighErrorRate initial state: $inactive_state"
  [[ "$inactive_state" == "inactive" ]]

  scripts/lab8-generate-traffic.sh errors &
  generator_pid=$!

  echo "Waiting 45 seconds to capture the pending state..."
  sleep 45
  curl -fsS http://127.0.0.1:9090/api/v1/rules \
    | jq '.data.groups[].rules[] | select(.name == "QuickNotesHighErrorRate")' \
    | tee "$evidence_dir/alert-pending.json"
  pending_state=$(jq -r '.state' "$evidence_dir/alert-pending.json")
  echo "QuickNotesHighErrorRate intermediate state: $pending_state"
  [[ "$pending_state" == "pending" ]]

  wait "$generator_pid"
  generator_pid=
  echo "Waiting for the next Prometheus evaluation..."
  sleep 20

  curl -fsS http://127.0.0.1:9090/api/v1/rules \
    | jq '.data.groups[].rules[] | select(.name == "QuickNotesHighErrorRate")' \
    | tee "$evidence_dir/alert-rule.json"

  alert_state=$(jq -r '.state' "$evidence_dir/alert-rule.json")
  echo "QuickNotesHighErrorRate state: $alert_state" \
    | tee "$evidence_dir/alert-state.txt"
  [[ "$alert_state" == "firing" ]]

  echo "Alert evidence captured. Save the Prometheus Alerts page as alert-firing.png now."
}

case "$mode" in
  baseline)
    capture_baseline
    ;;
  alert)
    capture_alert
    ;;
  all)
    capture_baseline
    capture_alert
    ;;
  *)
    echo "Usage: $0 [baseline|alert|all]" >&2
    exit 2
    ;;
esac
