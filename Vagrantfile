# -*- mode: ruby -*-
# vi: set ft=ruby :

GO_VERSION = "1.24.5".freeze

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"
  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", env: { "GO_VERSION" => GO_VERSION }, inline: <<-'SHELL'
    set -euo pipefail

    if command -v go >/dev/null 2>&1 && go version | grep -q "go${GO_VERSION} "; then
      echo "Go ${GO_VERSION} already installed; skipping."
      exit 0
    fi

    echo "Installing Go ${GO_VERSION}..."
    tarball="go${GO_VERSION}.linux-amd64.tar.gz"
    curl -fsSLO "https://go.dev/dl/${tarball}"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "${tarball}"
    rm -f "${tarball}"

    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    chmod 644 /etc/profile.d/go.sh

    # symlink so non-interactive `vagrant ssh -c 'go ...'` (no /etc/profile.d) finds go
    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    /usr/local/go/bin/go version
  SHELL
end
