#!/usr/bin/env bash
set -euo pipefail

baseline_file="${GOVULNCHECK_BASELINE:-../.github/govulncheck-go1.24-baseline.txt}"
scanner="${GOVULNCHECK_BIN:-$(go env GOPATH)/bin/govulncheck}"

if [[ ! -x "$scanner" ]]; then
    echo "ERROR: govulncheck executable not found: $scanner"
    exit 1
fi

if [[ ! -f "$baseline_file" ]]; then
    echo "ERROR: baseline file not found: $baseline_file"
    exit 1
fi

if grep -vE '^GO-[0-9]{4}-[0-9]+$' "$baseline_file" | grep -q .; then
    echo "ERROR: baseline contains an invalid line"
    exit 1
fi

scan_output="$(mktemp)"
current_ids="$(mktemp)"
baseline_ids="$(mktemp)"
new_ids="$(mktemp)"

cleanup() {
    rm -f "$scan_output" "$current_ids" "$baseline_ids" "$new_ids"
}
trap cleanup EXIT

echo "Go toolchain:"
go version

echo
echo "govulncheck version:"
"$scanner" -version

echo
echo "Running: govulncheck ./..."
set +e
"$scanner" ./... 2>&1 | tee "$scan_output"
scan_status=${PIPESTATUS[0]}
set -e

case "$scan_status" in
    0|3)
        ;;
    *)
        echo "ERROR: govulncheck execution failed with status $scan_status"
        exit "$scan_status"
        ;;
esac

grep -oE 'GO-[0-9]{4}-[0-9]+' "$scan_output" \
    | sort -u \
    > "$current_ids" || true

sort -u "$baseline_file" > "$baseline_ids"

if [[ "$scan_status" -eq 3 && ! -s "$current_ids" ]]; then
    echo "ERROR: govulncheck reported vulnerabilities but no IDs were parsed"
    exit 1
fi

comm -13 "$baseline_ids" "$current_ids" > "$new_ids"

echo
echo "Reviewed Go 1.24 baseline IDs currently present:"
comm -12 "$baseline_ids" "$current_ids" || true

echo
echo "Unexpected reachable vulnerability IDs:"
if [[ -s "$new_ids" ]]; then
    cat "$new_ids"
    echo
    echo "FAIL: new reachable vulnerabilities were detected."
    exit 1
fi

echo "None"
echo
echo "PASS: no new reachable vulnerabilities beyond the reviewed Go 1.24 baseline."
