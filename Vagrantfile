# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Ubuntu 22.04 LTS
  config.vm.box = "ubuntu/jammy64" 
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
                    guest: 8080, host: 18080,
                    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app",
                          type: "virtualbox",
                          owner: "vagrant", group: "vagrant"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.memory = 1024
    vb.cpus   = 2
  end

  #Go 1.24.5
  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    GO_VERSION="1.24.5"

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      echo ">>> Installing Go ${GO_VERSION}"
      apt-get update -y
      apt-get install -y curl ca-certificates
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
        -o /tmp/go.tgz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
      rm /tmp/go.tgz
      echo 'export PATH=$PATH:/usr/local/go/bin:/home/vagrant/go/bin' \
        > /etc/profile.d/go.sh
    else
      echo ">>> Go ${GO_VERSION} already installed, skipping"
    fi
  SHELL
end
