# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Lab 5 — boots an Ubuntu 24.04 VM, installs Go, builds QuickNotes from the
# synced ./app and runs it as a systemd service reachable from the host.
#
# Default provider is VirtualBox (the lab default). This host's VT-x is held by
# UEFI-locked VBS/Hyper-V, so VirtualBox can't accelerate; we run the Hyper-V
# provider instead (`vagrant up --provider=hyperv`). Both are configured below.

GO_VERSION = "1.24.4" # pinned point release (see design question d)

Vagrant.configure("2") do |config|
  # Default box (VirtualBox). The Hyper-V provider overrides it below.
  config.vm.box = "bento/ubuntu-24.04"

  # Hostname identifies the workload.
  config.vm.hostname = "quicknotes-vm"

  # Generous boot timeout for slow first boots.
  config.vm.boot_timeout = 600

  # Port forward host 18080 -> guest 8080 (loopback only). Honored by VirtualBox.
  # Hyper-V has no NAT port-forward; we reproduce it with a host netsh portproxy
  # to the VM's IP (see submissions/lab5.md).
  config.vm.network "forwarded_port",
    guest: 8080, host: 18080, host_ip: "127.0.0.1", id: "quicknotes"

  # The default /vagrant share would also need SMB on Hyper-V — disable it; we
  # only need ./app in the guest.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # --- VirtualBox (lab default) ---
  config.vm.provider "virtualbox" do |vb, override|
    override.vm.synced_folder "./app", "/opt/quicknotes/app", type: "virtualbox"
    vb.cpus = 2
    vb.memory = 1024
    vb.name = "quicknotes-vm"
    vb.gui = false
  end

  # --- Hyper-V (used here: VBS owns VT-x, so VirtualBox can't accelerate) ---
  config.vm.provider "hyperv" do |hv, override|
    override.vm.box = "generic/ubuntu2204" # Ubuntu 22.04 LTS with a Hyper-V variant (bento/generic-2404 have none)
    override.vm.synced_folder "./app", "/opt/quicknotes/app", type: "smb"
    hv.cpus = 2
    hv.memory = 1024
    hv.vmname = "quicknotes-vm"
    hv.linked_clone = true
  end

  # Provision: install a pinned Go, build QuickNotes, run it as a service.
  # Idempotent — safe to re-run with `vagrant provision`.
  config.vm.provision "shell", env: { "GO_VERSION" => GO_VERSION }, inline: <<-'SHELL'
    set -euo pipefail

    # --- Install Go only if the pinned version isn't already present ---
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
      echo "[provision] installing Go ${GO_VERSION}"
      curl -fsSL -o /tmp/go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
      rm -f /tmp/go.tgz
    else
      echo "[provision] Go ${GO_VERSION} already installed"
    fi
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh

    # --- Build QuickNotes from the synced source ---
    echo "[provision] building quicknotes"
    install -d -o vagrant -g vagrant /var/lib/quicknotes
    GOCACHE=/tmp/gocache GOTOOLCHAIN=local \
      /usr/local/go/bin/go build -C /opt/quicknotes/app -o /usr/local/bin/quicknotes .

    # --- systemd unit so it survives reboot / snapshot-restore ---
    cat > /etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes
After=network-online.target
Wants=network-online.target

[Service]
User=vagrant
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/opt/quicknotes/app/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now quicknotes.service
    sleep 1
    systemctl --no-pager --lines=0 status quicknotes.service || true
    echo "[provision] done"
  SHELL
end
