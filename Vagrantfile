# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Lab 5 — QuickNotes in a Vagrant VM.
# Boots an Ubuntu 24.04 LTS VM, installs Go 1.24.x, builds QuickNotes from the
# synced ./app folder, and runs it as a systemd service on guest port 8080.
# The host reaches it on http://127.0.0.1:18080.

GO_VERSION = "1.24.5"

Vagrant.configure("2") do |config|
  # Ubuntu 24.04 LTS. The bento box ships VirtualBox Guest Additions, which we
  # need for the default (virtualbox) synced-folder type.
  config.vm.box = "bento/ubuntu-24.04"

  # Identify the VM clearly (shows up in the shell prompt and `vagrant ssh`).
  config.vm.hostname = "quicknotes-vm"

  # Forward host 18080 -> guest 8080, bound to loopback only so the app is not
  # exposed to the local network.
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # Mount the application source into the guest (default type: virtualbox).
  config.vm.synced_folder "./app", "/opt/quicknotes/app"

  # Cap resources at 2 vCPU / 1024 MB RAM (over-provisioning is an antipattern).
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.memory = 1024
    vb.cpus   = 2
  end

  # Provisioning runs on first `vagrant up`; re-run with `vagrant provision`.
  # The script is idempotent, so `vagrant up --provision` is safe to repeat.
  config.vm.provision "shell", inline: <<-SHELL
    #!/usr/bin/env bash
    set -euo pipefail

    GO_VERSION="#{GO_VERSION}"
    GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y curl

    # Install the pinned Go version only if it is not already present.
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
      echo "Installing Go ${GO_VERSION}..."
      curl -fsSL "https://go.dev/dl/${GO_TARBALL}" -o "/tmp/${GO_TARBALL}"
      rm -rf /usr/local/go
      tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
    fi

    # Make Go available on PATH for interactive logins (e.g. `vagrant ssh`).
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh

    # Build QuickNotes from the synced source into a stable location.
    install -d /var/lib/quicknotes
    /usr/local/go/bin/go build -C /opt/quicknotes/app -o /usr/local/bin/quicknotes .

    # Run QuickNotes as a service so it survives reboots and starts on boot.
    cat > /etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/opt/quicknotes/app/seed.json
WorkingDirectory=/var/lib/quicknotes
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable quicknotes
    systemctl restart quicknotes

    echo "Provisioning done. QuickNotes should be live on guest :8080."
  SHELL
end
