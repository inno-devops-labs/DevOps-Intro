# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # 1. Box: Ubuntu 22.04 LTS (работает гарантированно)
  config.vm.box = "ubuntu/jammy64"

  # 2. Hostname
  config.vm.hostname = "quicknotes-vm"

  # 3. Boot timeout (для медленных систем)
  config.vm.boot_timeout = 600

  # 4. Port forwarding
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # 5. Synced folder
  config.vm.synced_folder "./app", "/opt/quicknotes/app"

  # 6. Resources
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  # 7. Provision: install Go 1.24.5
  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    GO_VERSION=1.24.5
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tgz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
    fi
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    /usr/local/go/bin/go version
  SHELL
end