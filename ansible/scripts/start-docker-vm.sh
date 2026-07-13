#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTAINER="quicknotes-lab7-vm"
IMAGE="quicknotes-lab7-vm:systemd"
VAGRANT_KEY="${ROOT_DIR}/ansible/files/vagrant_insecure_key"

if [[ ! -f "${VAGRANT_KEY}" ]]; then
  curl -fsSL -o "${VAGRANT_KEY}" \
    https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant
  chmod 0600 "${VAGRANT_KEY}"
fi

ssh-keygen -y -f "${VAGRANT_KEY}" > "${ROOT_DIR}/ansible/files/vagrant_insecure_key.pub"

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  docker build -f "${ROOT_DIR}/ansible/Dockerfile.lab7-vm" \
    -t "${IMAGE}" "${ROOT_DIR}/ansible"
fi

docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true

docker run -d --name "${CONTAINER}" \
  --privileged \
  --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -p 127.0.0.1:2222:22 \
  -p 127.0.0.1:18080:8080 \
  "${IMAGE}" >/dev/null

echo "waiting for SSH on 127.0.0.1:2222"
for _ in $(seq 1 60); do
  if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=3 -i "${VAGRANT_KEY}" -p 2222 vagrant@127.0.0.1 'echo ready' >/dev/null 2>&1; then
    echo "SSH ready (docker target ${CONTAINER})"
    exit 0
  fi
  sleep 2
done

echo "SSH not ready after timeout" >&2
exit 1
