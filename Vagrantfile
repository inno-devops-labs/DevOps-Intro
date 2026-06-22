# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Lab 5 — boots an Ubuntu VM, installs Go, builds QuickNotes and runs it as a
# systemd service reachable from the host.
#
# Default provider is VirtualBox (the lab default, with a real synced folder).
# This host's VT-x is held by UEFI-locked VBS (Memory Integrity stays on), so
# VirtualBox can't accelerate; we use the Hyper-V provider instead. Hyper-V's
# only synced-folder transport is SMB, which crashes Vagrant 2.4.9's credential
# scrubber on a non-ASCII Windows password — so the Hyper-V path fetches the app
# source via git to keep `vagrant up` reproducible and crash-free.

GO_VERSION = "1.24.4" # pinned point release (see design question d)
APP_REPO   = "https://github.com/rikire/DevOps-Intro"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04" # VirtualBox default; Hyper-V overrides below
  config.vm.hostname = "quicknotes-vm"
  config.vm.boot_timeout = 600

  # Port forward host 18080 -> guest 8080 (loopback only). Honored by VirtualBox.
  # Hyper-V has no NAT port-forward; reproduce it with a host netsh portproxy.
  config.vm.network "forwarded_port",
    guest: 8080, host: 18080, host_ip: "127.0.0.1", id: "quicknotes"

  # Don't auto-share the repo root.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # --- VirtualBox (lab default): real synced folder ---
  config.vm.provider "virtualbox" do |vb, override|
    override.vm.synced_folder "./app", "/opt/quicknotes/app", type: "virtualbox"
    vb.cpus = 2
    vb.memory = 1024
    vb.name = "quicknotes-vm"
    vb.gui = false
  end

  # --- Hyper-V (this host): no SMB; pin the switch so `up` is non-interactive ---
  config.vm.provider "hyperv" do |hv, override|
    override.vm.box = "generic/ubuntu2204"
    override.vm.network "public_network", bridge: "Default Switch"
    hv.cpus = 2
    hv.memory = 1024
    hv.vmname = "quicknotes-vm"
    hv.linked_clone = true
  end

  # Provision: install a pinned Go, get the app source (synced folder if present,
  # else git clone), build it, run it as a systemd service. Idempotent.
  config.vm.provision "shell",
    env: { "GO_VERSION" => GO_VERSION, "APP_REPO" => APP_REPO },
    inline: <<-'SHELL'
    set -euo pipefail

    # --- Go (only if the pinned version isn't already present) ---
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
      echo "[provision] installing Go ${GO_VERSION}"
      curl -fsSL -o /tmp/go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
      rm -f /tmp/go.tgz
    fi
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh

    # --- App source: synced folder if mounted, otherwise clone ---
    SRC=/opt/quicknotes/app
    if [ ! -f "$SRC/go.mod" ]; then
      echo "[provision] no synced folder; cloning ${APP_REPO}"
      command -v git >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y -qq git; }
      rm -rf /opt/quicknotes/src
      git clone --depth 1 "$APP_REPO" /opt/quicknotes/src
      SRC=/opt/quicknotes/src/app
    fi

    # --- Build + seed + data dir (fixed paths so source location is irrelevant) ---
    echo "[provision] building quicknotes from $SRC"
    install -d -o vagrant -g vagrant /var/lib/quicknotes
    cp "$SRC/seed.json" /var/lib/quicknotes/seed.json
    GOCACHE=/tmp/gocache GOTOOLCHAIN=local \
      /usr/local/go/bin/go build -C "$SRC" -o /usr/local/bin/quicknotes .

    # --- systemd unit ---
    cat > /etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes
After=network-online.target
Wants=network-online.target

[Service]
User=vagrant
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/var/lib/quicknotes/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now quicknotes.service
    echo "[provision] done"
  SHELL
end
