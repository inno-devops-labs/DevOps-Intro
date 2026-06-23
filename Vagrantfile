# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Lab 5 — provisions an Ubuntu 24.04 VM, installs a pinned Go 1.24.x,
# builds and runs QuickNotes as a systemd service, and forwards the API to the
# host on 127.0.0.1:18080. Reproducible from a clean clone: `vagrant up`.

GO_VERSION = "1.24.4" # pinned point release (see design answer in submissions/lab5.md)

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04" # Ubuntu 24.04 LTS
  config.vm.hostname = "quicknotes-lab5"

  # Forward the guest API to the host, bound to loopback only (not 0.0.0.0),
  # so the service is not exposed on the host's network interfaces.
  config.vm.network "forwarded_port",
    guest: 8080, host: 18080, host_ip: "127.0.0.1", id: "quicknotes"

  # Mount the application source read/write into the guest.
  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-lab5"
    vb.cpus   = 2
    vb.memory = 1024
  end

  # --- Provisioning: install pinned Go, build & run QuickNotes via systemd ---
  config.vm.provision "shell", env: { "GO_VERSION" => GO_VERSION }, inline: <<-'SHELL'
    set -euo pipefail
    ARCH=amd64
    TARBALL="go${GO_VERSION}.linux-${ARCH}.tar.gz"

    # Install Go only if the pinned version isn't already present (idempotent).
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
      curl -fsSL -o "/tmp/${TARBALL}" "https://go.dev/dl/${TARBALL}"
      rm -rf /usr/local/go
      tar -C /usr/local -xzf "/tmp/${TARBALL}"
    fi
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh

    # Keep persistent data OUTSIDE the synced folder (avoids host/guest perms).
    install -d -o vagrant -g vagrant /home/vagrant/app-data

    # Run QuickNotes as a managed service so it survives reboots/restores.
    cat > /etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes API
After=network-online.target

[Service]
User=vagrant
WorkingDirectory=/home/vagrant/app
Environment=ADDR=:8080
Environment=DATA_PATH=/home/vagrant/app-data/notes.json
Environment=SEED_PATH=/home/vagrant/app/seed.json
ExecStartPre=/usr/local/go/bin/go build -o /home/vagrant/quicknotes .
ExecStart=/home/vagrant/quicknotes
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now quicknotes
    sleep 2
    echo "--- provision check: GET /health from inside the guest ---"
    curl -s http://localhost:8080/health || true
  SHELL
end
