# QuickNotes development VM (Lab 5).
# Boots Ubuntu 24.04, installs a pinned Go toolchain, syncs ./app into the guest
# and forwards 127.0.0.1:18080 on the host to port 8080 in the guest.

GO_VERSION = "1.24.5"

Vagrant.configure("2") do |config|
  config.vm.box         = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"
  config.vm.hostname    = "quicknotes-vm"

  # Reachable only from this machine, never from the local network.
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  # Installs Go only if the pinned version is not already present, so
  # `vagrant provision` can be re-run safely. The architecture is detected
  # inside the guest, so the same file works on Intel and Apple Silicon hosts.
  config.vm.provision "shell", env: { "GO_VERSION" => GO_VERSION }, inline: <<-SHELL
    set -euo pipefail

    # VirtualBox NAT hands the guest a DNS proxy that forwards to the host's
    # nameservers, which are unreachable when the host sits behind a VPN.
    # Public resolvers work over the same NAT, so point the interface at them
    # for the toolchain download.
    IF="$(ip route | awk '/default/ {print $5; exit}')"
    resolvectl dns "$IF" 1.1.1.1 8.8.8.8

    if /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
      echo "Go ${GO_VERSION} already installed, skipping"
      exit 0
    fi
    ARCH="$(dpkg --print-architecture)"
    echo "Installing Go ${GO_VERSION} for linux-${ARCH}"
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm -f /tmp/go.tar.gz
    ln -sf /usr/local/go/bin/go    /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
    go version
  SHELL
end
