#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ART_DIR="${ROOT_DIR}/lab7-artifacts"
mkdir -p "${ART_DIR}"

cd "${ROOT_DIR}"

bash ansible/scripts/start-docker-vm.sh | tee "${ART_DIR}/vm-start.log"

run_playbook() {
  local name="$1"
  shift
  ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml "$@" \
    | tee "${ART_DIR}/${name}.log"
}

echo "=== first run ===" | tee "${ART_DIR}/summary.txt"
run_playbook run1

curl -s http://127.0.0.1:18080/health | tee "${ART_DIR}/curl-health.txt"

echo "=== second run (idempotency) ===" | tee -a "${ART_DIR}/summary.txt"
run_playbook run2

cp ansible/playbook.yaml "${ART_DIR}/playbook.yaml.bak"
sed -i 's/listen_addr: "0.0.0.0:8080"/listen_addr: "0.0.0.0:9090"/' ansible/playbook.yaml

echo "=== third run (listen_addr -> 9090) ===" | tee -a "${ART_DIR}/summary.txt"
run_playbook run3

sed -i 's/listen_addr: "0.0.0.0:9090"/listen_addr: "0.0.0.0:9191"/' ansible/playbook.yaml

echo "=== check diff run ===" | tee -a "${ART_DIR}/summary.txt"
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff \
  | tee "${ART_DIR}/run-check-diff.log"

cp "${ART_DIR}/playbook.yaml.bak" ansible/playbook.yaml

echo "done" | tee -a "${ART_DIR}/summary.txt"
