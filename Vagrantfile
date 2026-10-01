# -*- mode: ruby -*-
# QuickNotes dev VM (Lab 5) - works on Intel (amd64) and Apple Silicon (arm64) hosts

require "etc"

GO_VERSION = "1.24.5"
ARM_HOST   = ["arm64", "aarch64"].include?(Etc.uname[:machine])

Vagrant.configure("2") do |config|
  # Ubuntu 24.04 LTS from a public box source
  config.vm.box = ARM_HOST ? "net9/ubuntu-24.04-arm64" : "bento/ubuntu-24.04"

  config.vm.hostname = "quicknotes-vm"

  # Host 127.0.0.1:18080 -> guest 8080 (not exposed to the network)

  # Sync ./app into the guest with rsync (one-way; re-run `vagrant rsync` after edits)
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  # Resource caps: 2 vCPU, 1024 MB RAM
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
    # Host 127.0.0.1:18080 -> guest 8080 via a VirtualBox NAT rule
    vb.customize ["modifyvm", :id, "--natpf1", "quicknotes,tcp,127.0.0.1,18080,,8080"]
  end

  # Install pinned Go (idempotent: safe to re-run with `vagrant provision`)
  config.vm.provision "shell", env: { "GO_VERSION" => GO_VERSION }, inline: <<-SHELL
    set -euo pipefail
    ARCH="$(dpkg --print-architecture)"
    if /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
      echo "Go ${GO_VERSION} already installed"
    else
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tgz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
      rm /tmp/go.tgz
    fi
    ln -sf /usr/local/go/bin/go    /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
    go version
  SHELL
end
