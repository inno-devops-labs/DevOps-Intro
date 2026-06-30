#!/usr/bin/env bash
set -euo pipefail

public_url="${1:?usage: checkhost-multi-region.sh <public_url> [duration_seconds] [interval_seconds] [output_dir]}"
duration_seconds="${2:-1800}"
interval_seconds="${3:-60}"
output_dir="${4:-monitoring/results/checkhost}"
regions="${CHECKHOST_REGIONS:-DE,SG,US}"
append_mode="${CHECKHOST_APPEND:-0}"

mkdir -p "$output_dir"
raw_file="$output_dir/raw.jsonl"
summary_file="$output_dir/summary.json"
metadata_file="$output_dir/metadata.json"
if [ "$append_mode" != "1" ]; then
  : > "$raw_file"
fi

start_epoch=$(date +%s)
end_epoch=$(( start_epoch + duration_seconds ))

request_check() {
  local response report_url result curl_error

  if ! response=$(curl -fsS -X POST https://api.check-host.cc/http \
    -H 'Content-Type: application/json' \
    -d "{\"target\":\"${public_url}\"}" 2>&1); then
    jq -cn --arg status "request_failed" --arg error "$response" '{status:0, success:false, error:$error, stage:$status, data:{}}'
    return 0
  fi

  report_url=$(printf '%s' "$response" | jq -r '.apiURL // empty')
  if [ -z "$report_url" ]; then
    jq -cn --arg status "missing_api_url" --arg error "$response" '{status:0, success:false, error:$error, stage:$status, data:{}}'
    return 0
  fi

  result=''
  curl_error=''
  for _ in $(seq 1 20); do
    sleep 3
    if result=$(curl -fsS "$report_url" 2>&1); then
      if printf '%s' "$result" | jq -e '.success == true and (.data | type == "object") and ((.data | length) > 0)' >/dev/null 2>&1; then
        printf '%s' "$result"
        return 0
      fi
    else
      curl_error="$result"
    fi
  done

  jq -cn --arg status "report_unavailable" --arg error "$curl_error" '{status:0, success:false, error:$error, stage:$status, data:{}}'
}

while [ "$(date +%s)" -lt "$end_epoch" ]; do
  ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  request=$(curl -fsS -X POST https://api.check-host.cc/http \
    -H 'Content-Type: application/json' \
    -d "{\"target\":\"${public_url}\"}" 2>/dev/null || true)

  if [ -n "$request" ] && printf '%s' "$request" | jq -e '.apiURL' >/dev/null 2>&1; then
    report_url=$(printf '%s' "$request" | jq -r '.apiURL')
    result=''
    curl_error=''
    for _ in $(seq 1 20); do
      sleep 3
      if result=$(curl -fsS "$report_url" 2>&1); then
        if printf '%s' "$result" | jq -e '.success == true and (.data | type == "object") and ((.data | length) > 0)' >/dev/null 2>&1; then
          break
        fi
      else
        curl_error="$result"
      fi
    done
    if [ -z "$result" ] || ! printf '%s' "$result" | jq -e '.success == true and (.data | type == "object") and ((.data | length) > 0)' >/dev/null 2>&1; then
      result=$(jq -cn --arg error "$curl_error" '{status:0, success:false, error:$error, stage:"report_unavailable", data:{}}')
    fi
  else
    if [ -z "$request" ]; then
      request=$(jq -cn '{status:0, success:false, error:"request_failed", data:{}}')
    fi
    result=$(jq -cn --arg error "request bootstrap failed" '{status:0, success:false, error:$error, stage:"request_failed", data:{}}')
  fi

  jq -cn \
    --arg ts "$ts" \
    --arg url "$public_url" \
    --arg regions "$regions" \
    --argjson request "$request" \
    --argjson result "$result" \
    '{timestamp:$ts, url:$url, regions:($regions|split(",")), request:$request, result:$result}' >> "$raw_file"

  now=$(date +%s)
  if [ "$now" -lt "$end_epoch" ]; then
    sleep "$interval_seconds"
  fi
done

python3 - <<'PY' "$raw_file" "$summary_file" "$metadata_file" "$public_url" "$regions" "$interval_seconds"
import json, math, statistics, sys
from datetime import datetime, timezone
from pathlib import Path

raw_path = Path(sys.argv[1])
summary_path = Path(sys.argv[2])
metadata_path = Path(sys.argv[3])
public_url = sys.argv[4]
regions = [x for x in sys.argv[5].split(',') if x]
interval_seconds = int(sys.argv[6])

entries = [json.loads(line) for line in raw_path.read_text().splitlines() if line.strip()]

def parse_ts(value):
    return datetime.strptime(value, '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc)

def percentile(sorted_values, p):
    if not sorted_values:
        return None
    idx = max(0, math.ceil((len(sorted_values) - 1) * p))
    return sorted_values[idx]

start_ts = parse_ts(entries[0]["timestamp"]) if entries else None
end_ts = parse_ts(entries[-1]["timestamp"]) if entries else None

summary = {
    "target": public_url,
    "regions": regions,
    "window": {
        "start": entries[0]["timestamp"] if entries else None,
        "end": entries[-1]["timestamp"] if entries else None,
        "duration_seconds": int((end_ts - start_ts).total_seconds()) if start_ts and end_ts else 0,
        "interval_seconds": interval_seconds,
        "samples": len(entries),
    },
    "selected_nodes": {},
    "nodes": {},
    "overall": {},
}

selected_nodes = {}
for region in regions:
    chosen = None
    for entry in entries:
        data = entry.get("result", {}).get("data", {})
        candidates = []
        for node_name, node in data.items():
            if node.get("countryCode") != region:
                continue
            checks = node.get("checks") or []
            if not checks:
                continue
            candidates.append((0 if node.get("monitoring_allowed") == 1 else 1, node_name, node))
        if candidates:
            _, chosen_name, chosen_node = sorted(candidates, key=lambda item: (item[0], item[1]))[0]
            chosen = {
                "node": chosen_name,
                "country": chosen_node.get("country"),
                "city": chosen_node.get("city"),
                "continent": chosen_node.get("continent"),
                "monitoring_allowed": chosen_node.get("monitoring_allowed"),
            }
            break
    if chosen:
        selected_nodes[region] = chosen

summary["selected_nodes"] = selected_nodes

all_latencies = []
all_errors = 0
all_checks = 0

for region, chosen in selected_nodes.items():
    node_name = chosen["node"]
    latencies = []
    errors = 0
    checks_count = 0
    statuses = []

    for entry in entries:
        data = entry.get("result", {}).get("data", {})
        node = data.get(node_name)
        if not node:
            continue
        checks = node.get("checks") or []
        if not checks:
            errors += 1
            checks_count += 1
            continue
        first = checks[0]
        checks_count += 1
        status = first.get("http_status")
        statuses.append(status)
        latency_ms = first.get("connectiontime")
        if status != 200 or first.get("status") != 1:
            errors += 1
        if latency_ms is not None:
            latencies.append(float(latency_ms) / 1000.0)

    latencies.sort()
    all_latencies.extend(latencies)
    all_errors += errors
    all_checks += checks_count
    summary["nodes"][region] = {
        **chosen,
        "checks": checks_count,
        "errors": errors,
        "statuses": statuses,
        "p50_seconds": statistics.median(latencies) if latencies else None,
        "p95_seconds": percentile(latencies, 0.95),
    }

all_latencies.sort()
summary["overall"] = {
    "checks": all_checks,
    "errors": all_errors,
    "p50_seconds": statistics.median(all_latencies) if all_latencies else None,
    "p95_seconds": percentile(all_latencies, 0.95),
}

summary_path.write_text(json.dumps(summary, indent=2))
metadata_path.write_text(json.dumps({
    "target": public_url,
    "regions": regions,
    "window": summary["window"],
    "samples": len(entries),
}, indent=2))
PY

echo "$summary_file"
