#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VM_DIR="${ROOT_DIR}/qemu-vm"
IMG="${VM_DIR}/noble-server-cloudimg-amd64.img"
DISK="${VM_DIR}/disk.qcow2"
SEED="${VM_DIR}/seed.iso"
PID_FILE="${VM_DIR}/qemu.pid"
LOG_FILE="${VM_DIR}/qemu.log"
VAGRANT_KEY="${ROOT_DIR}/ansible/files/vagrant_insecure_key"

mkdir -p "${VM_DIR}/cloud-init"

if [[ ! -f "${IMG}" ]]; then
  curl -fsSL -o "${IMG}" \
    https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
fi

if [[ ! -f "${VAGRANT_KEY}" ]]; then
  curl -fsSL -o "${VAGRANT_KEY}" \
    https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant
  chmod 0600 "${VAGRANT_KEY}"
fi

cat > "${VM_DIR}/cloud-init/meta-data" <<EOF
instance-id: quicknotes-lab7
local-hostname: quicknotes-vm
EOF

cat > "${VM_DIR}/cloud-init/user-data" <<'EOF'
#cloud-config
users:
  - default
  - name: vagrant
    gecos: Vagrant User
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQ+wXKxOk1qnZCkiNe6HyhJoidKNCd3vlRydH6qg/7p7UhKaqZtrSd2HMooKXlBUfqBVWpkKAJ+lWga1WQY/yueW5K3N0QG5ZUKjCsvPKWbV+ILvwehvA0lE31gP70EfPdtZU7b874zcH99BnKJpQ2F2WG3Ai4Ka6Lh5acdptxAPYeFX76ekJg2vwDHuyItD0tuys+Ab7mmMqayBs2CDQN/vi+D5Eor5S0vnfD5morEvZs2bCTBOdLFeFDBO/4/kExBbrhCblQPzQpq3ig9f80PinpXF86BPe6Ykekuv5exduZfGKjbZFLUt3O6+JNDlZTv5BDOq+UiQv4Q== vagrant insecure public key
package_update: true
packages:
  - python3
  - python3-apt
ssh_pwauth: false
EOF

genisoimage -output "${SEED}" -volid cidata -joliet -rock \
  "${VM_DIR}/cloud-init/meta-data" "${VM_DIR}/cloud-init/user-data" >/dev/null

qemu-img create -f qcow2 -F qcow2 -b "${IMG}" "${DISK}" 10G >/dev/null

if [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null; then
  echo "qemu VM already running (pid $(cat "${PID_FILE}"))"
  exit 0
fi

pkill -f "${DISK}" 2>/dev/null || true
sleep 1

nohup qemu-system-x86_64 \
  -machine type=pc \
  -cpu qemu64 \
  -m 1024 \
  -smp 2 \
  -display none \
  -drive "file=${DISK},format=qcow2,if=virtio" \
  -drive "file=${SEED},format=raw,if=virtio" \
  -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:18080-:8080" \
  -device virtio-net-pci,netdev=net0 \
  -daemonize \
  -pidfile "${PID_FILE}" \
  > "${LOG_FILE}" 2>&1

echo "started qemu VM, waiting for SSH on 127.0.0.1:2222"
for _ in $(seq 1 60); do
  if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=3 -i "${VAGRANT_KEY}" -p 2222 vagrant@127.0.0.1 'echo ready' >/dev/null 2>&1; then
    echo "SSH ready"
    exit 0
  fi
  sleep 5
done

echo "SSH not ready after timeout" >&2
exit 1
