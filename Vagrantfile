# -*- mode: ruby -*-
# vi: set ft=ruby :

GO_VERSION = "1.24.5"

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"          # Ubuntu 22.04 LTS
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail

    if ! command -v go >/dev/null 2>&1 || ! go version | grep -q "go#{GO_VERSION}"; then
      curl -fsSL "https://go.dev/dl/go#{GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi

    if ! grep -q '/usr/local/go/bin' /etc/profile.d/go.sh 2>/dev/null; then
      echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
      chmod +x /etc/profile.d/go.sh
    fi
  SHELL
end
