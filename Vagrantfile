# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Lab 5 — boots an Ubuntu 24.04 VM, installs a pinned Go toolchain, mounts the
# host's ./app into the guest, and forwards host 127.0.0.1:18080 -> guest 8080.

GO_VERSION = "1.24.5"

Vagrant.configure("2") do |config|
  config.vm.box      = "bento/ubuntu-24.04"   # Ubuntu 24.04 LTS
  config.vm.hostname = "quicknotes-vm"
  config.vm.boot_timeout = 600

  # Only the host can reach QuickNotes (loopback-bound forward, not the LAN).
  config.vm.network "forwarded_port",
    guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # Mount the app source into the guest.
  config.vm.synced_folder "./app", "/opt/quicknotes"

  # Keep the VM small — over-provisioning is the antipattern from Lecture 5.
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-lab5"
    vb.cpus   = 2
    vb.memory = 1024
  end

  # Install Go on the first `vagrant up`. Idempotent: re-running skips the
  # download if the right version is already there.
  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    apt-get update
    apt-get install -y curl ca-certificates

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go#{GO_VERSION}"; then
      curl -fsSL "https://go.dev/dl/go#{GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi

    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    chmod +x /etc/profile.d/go.sh
    ln -sf /usr/local/go/bin/go /usr/local/bin/go
  SHELL
end
