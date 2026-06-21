# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Lab 5 — boots an Ubuntu 24.04 VM, provisions Go, runs QuickNotes inside,
# and forwards a loopback-bound host port to the guest.

Vagrant.configure("2") do |config|
  # 1. Box: Ubuntu 24.04 LTS (bento publishes VirtualBox-ready 24.04 images)
  config.vm.box = "bento/ubuntu-24.04"

  # 2. Identifying hostname
  config.vm.hostname = "quicknotes-vm"

  # Generous boot timeout: on hosts where Hyper-V is active, VirtualBox runs via
  # the slower NEM/WHP backend and the guest takes longer to come up.
  config.vm.boot_timeout = 600

  # 3. Port forwarding: host 18080 -> guest 8080, bound to 127.0.0.1 only
  #    (not reachable from the LAN — safer than a bridged interface)
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # 4. Sync only the app source into the guest
  config.vm.synced_folder "./app", "/opt/quicknotes/app"

  # 5. Cap resources — no over-provisioning
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  # 6. Provision: install a pinned Go point release (idempotent)
  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    GO_VERSION=1.24.5
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tgz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
    fi
    # make go available on every login shell
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    /usr/local/go/bin/go version
  SHELL
end
