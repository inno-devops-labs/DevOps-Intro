# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Box: Ubuntu 24.04 LTS
  # config.vm.box = "ubuntu/noble64"
  config.vm.box = "ubuntu/jammy64"

  # Hostname
  config.vm.hostname = "quicknotes-dev"

  # Port forwarding: host 18080 -> guest 8080, only localhost
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # Synced folder: ./app -> /home/vagrant/app
  # config.vm.synced_folder "./app", "/home/vagrant/app"
  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync", rsync__auto: true, rsync__exclude: [".git/", ".vagrant/"]

  # Resources: 2 vCPU, 1024 MB RAM
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 2
  end

  # Provisioning: install Go 1.24.x
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y wget git

    # Install Go 1.24.4 (фиксированная версия)
    wget -q https://go.dev/dl/go1.24.4.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz
    rm go1.24.4.linux-amd64.tar.gz

    # Add Go to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/vagrant/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc

    # Verify Go installation
    /usr/local/go/bin/go version
  SHELL
end