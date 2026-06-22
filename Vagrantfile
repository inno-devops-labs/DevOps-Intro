# -*- mode: ruby -*-
# vi: set ft=ruby :
# Lab 5 - QuickNotes inside a Vagrant VM

Vagrant.configure("2") do |config|
  # Box: Ubuntu 22.04 LTS (Jammy) - official, well-maintained image
  config.vm.box = "ubuntu/jammy64"

  # Hostname identifies this VM clearly
  config.vm.hostname = "quicknotes-vm"

  # Port forwarding: host 18080 -> guest 8080, bound to localhost only
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # Synced folder: host ./app mounted into the guest
  config.vm.synced_folder "./app", "/home/vagrant/app"

  # Resources capped per Lecture 5 (no over-provisioning)
  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-vm"
    vb.cpus = 2
    vb.memory = 1024
  end

  # Provisioning: install Go 1.24.5 from the upstream tarball (idempotent)
  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    GO_VERSION="1.24.5"
    TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
    if command -v /usr/local/go/bin/go >/dev/null 2>&1 && \
       /usr/local/go/bin/go version | grep -q "go${GO_VERSION}"; then
      echo "Go ${GO_VERSION} already installed, skipping."
    else
      echo "Installing Go ${GO_VERSION}..."
      curl -fsSL "https://go.dev/dl/${TARBALL}" -o "/tmp/${TARBALL}"
      rm -rf /usr/local/go
      tar -C /usr/local -xzf "/tmp/${TARBALL}"
      rm -f "/tmp/${TARBALL}"
    fi
    if ! grep -q "/usr/local/go/bin" /etc/profile.d/go-path.sh 2>/dev/null; then
      echo "export PATH=\$PATH:/usr/local/go/bin" | tee /etc/profile.d/go-path.sh
      chmod +x /etc/profile.d/go-path.sh
    fi
    /usr/local/go/bin/go version
  SHELL
end
