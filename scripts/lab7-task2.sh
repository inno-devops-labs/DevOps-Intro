#!/bin/bash
set -euo pipefail
export ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg
cd /vagrant/ansible
ART=/vagrant/submissions/lab7-artifacts

# --- Selective change: listen_addr :8080 -> :9090 ---
cp playbook.yaml playbook.yaml.bak
sed -i 's/listen_addr: ":8080"/listen_addr: ":9090"/' playbook.yaml
grep listen_addr playbook.yaml | tee "$ART/var-tweak-listen.txt"

echo "=== SELECTIVE RUN (listen_addr=:9090) ==="
ansible-playbook -i inventory.local.ini playbook.yaml 2>&1 | tee "$ART/play-run3-selective.txt"

echo "=== unit excerpt after tweak ==="
grep -E 'ADDR|Environment' /etc/systemd/system/quicknotes.service | tee "$ART/unit-after-9090.txt"
ss -ltnp | grep -E '8080|9090' | tee "$ART/ss-after-9090.txt" || true

# --- check --diff with a third change (listen_addr :9090 -> :8081) ---
sed -i 's/listen_addr: ":9090"/listen_addr: ":8081"/' playbook.yaml
grep listen_addr playbook.yaml | tee "$ART/var-tweak-checkdiff.txt"

echo "=== CHECK --DIFF ==="
ansible-playbook -i inventory.local.ini playbook.yaml --check --diff 2>&1 | tee "$ART/play-check-diff.txt"

# Restore production listen_addr :8080 and converge
mv playbook.yaml.bak playbook.yaml
echo "=== RESTORE :8080 ==="
ansible-playbook -i inventory.local.ini playbook.yaml 2>&1 | tee "$ART/play-restore-8080.txt"
sleep 2
curl -s http://127.0.0.1:8080/health | tee "$ART/curl-health-after-restore.txt"
echo
