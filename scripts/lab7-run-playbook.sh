#!/bin/bash
set -euo pipefail
export ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg
export ANSIBLE_HOST_KEY_CHECKING=False

cd /vagrant/ansible
mkdir -p /vagrant/submissions/lab7-artifacts

echo "=== ansible version ==="
ansible --version | head -5 | tee /vagrant/submissions/lab7-artifacts/ansible-version.txt

echo "=== FIRST RUN ==="
ansible-playbook -i inventory.local.ini playbook.yaml 2>&1 | tee /vagrant/submissions/lab7-artifacts/play-run1.txt

echo "=== SERVICE STATUS ==="
systemctl is-active quicknotes | tee /vagrant/submissions/lab7-artifacts/service-active.txt
systemctl status quicknotes --no-pager | head -20 | tee /vagrant/submissions/lab7-artifacts/service-status.txt

echo "=== HEALTH / NOTES (guest) ==="
sleep 2
curl -s http://127.0.0.1:8080/health | tee /vagrant/submissions/lab7-artifacts/curl-health-guest.txt
echo
curl -s http://127.0.0.1:8080/notes | tee /vagrant/submissions/lab7-artifacts/curl-notes-guest.txt
echo

echo "=== SECOND RUN (idempotency) ==="
ansible-playbook -i inventory.local.ini playbook.yaml 2>&1 | tee /vagrant/submissions/lab7-artifacts/play-run2.txt
