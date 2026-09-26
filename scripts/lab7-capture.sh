#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

ansible_playbook=${ANSIBLE_PLAYBOOK:-.venv/bin/ansible-playbook}
evidence_dir=submissions/evidence/lab7
mkdir -p "$evidence_dir"

"$ansible_playbook" --version | tee "$evidence_dir/ansible-version.txt"

"$ansible_playbook" -i ansible/inventory.ini ansible/playbook.yaml \
  --check --diff | tee "$evidence_dir/check-before-deploy.txt"

"$ansible_playbook" -i ansible/inventory.ini ansible/playbook.yaml \
  | tee "$evidence_dir/first-run.txt"

curl -fsS http://127.0.0.1:18080/health \
  | tee "$evidence_dir/health.txt"
printf '\n'
curl -fsS http://127.0.0.1:18080/notes \
  | tee "$evidence_dir/notes.txt"
printf '\n'

"$ansible_playbook" -i ansible/inventory.ini ansible/playbook.yaml \
  | tee "$evidence_dir/second-run.txt"

"$ansible_playbook" -i ansible/inventory.ini ansible/playbook.yaml \
  -e quicknotes_restart_sec=3s \
  | tee "$evidence_dir/selective-change.txt"

"$ansible_playbook" -i ansible/inventory.ini ansible/playbook.yaml \
  -e quicknotes_restart_sec=4s --check --diff \
  | tee "$evidence_dir/check-diff.txt"

# I restore the reviewed default and prove that the final state is converged.
"$ansible_playbook" -i ansible/inventory.ini ansible/playbook.yaml \
  | tee "$evidence_dir/restore-default.txt"
"$ansible_playbook" -i ansible/inventory.ini ansible/playbook.yaml \
  | tee "$evidence_dir/final-idempotency.txt"

ssh_options=(
  -i .vagrant/machines/default/virtualbox/private_key
  -p 2222
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
)

ssh "${ssh_options[@]}" vagrant@127.0.0.1 \
  'systemctl list-timers ansible-pull.timer --all --no-pager' \
  | tee "$evidence_dir/ansible-pull-timer.txt"
ssh "${ssh_options[@]}" vagrant@127.0.0.1 \
  'sudo journalctl -u ansible-pull.service --no-pager -n 100' \
  | tee "$evidence_dir/ansible-pull-journal.txt"
