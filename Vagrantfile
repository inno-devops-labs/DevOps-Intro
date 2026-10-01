# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Lab 5 — QuickNotes in a Vagrant VM
# Provider: VirtualBox (x86_64). Boots Ubuntu 24.04 LTS, installs a pinned
# Go toolchain, syncs ./app into the guest, and forwards
# host 127.0.0.1:18080 -> guest 8080.

GO_VERSION = "1.24.5"

Vagrant.configure("2") do |config|
  # 1. Box — public Ubuntu 24.04 LTS, with the version pinned for reproducibility
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"

  # 2. Hostname identifies the service
  config.vm.hostname = "quicknotes-vm"

  # 3. Port forward: host 127.0.0.1:18080 -> guest 8080 (not exposed to the LAN)
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # 4. Synced folder: push ./app into the guest (one-way, rsync)
  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync",
    rsync__exclude: [".git/", "quicknotes", "data/"]

  # 5. Resources capped at 2 vCPU / 1024 MB
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  # 6. Provision: install a pinned Go on first `vagrant up` (idempotent)
  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    GO_VERSION="#{GO_VERSION}"
    if /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      echo "Go ${GO_VERSION} already installed"; exit 0
    fi
    cd /tmp
    curl -fsSL -O "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    chmod +x /etc/profile.d/go.sh
    /usr/local/go/bin/go version
  SHELL

  # 7. Reproducible: pinned box name + box version + pinned Go version mean any
  #    clean clone on an x86_64 host produces the same working state.
end
