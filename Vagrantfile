# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use Ubuntu 24.04 LTS
  config.vm.box = "ubuntu/noble64"
  
  # Set hostname to identify QuickNotes
  config.vm.hostname = "quicknotes-vm"
  
  # Port forwarding: host 18080 -> guest 8080, bound to 127.0.0.1
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"
  
  # Synced folder: mount host's ./app to guest
  config.vm.synced_folder "./app", "/home/vagrant/app"
  
  # VirtualBox-specific configuration
  config.vm.provider "virtualbox" do |vb|
    # Cap resources: 2 vCPU, 1024 MB RAM
    vb.cpus = 2
    vb.memory = 1024
  end
  
  # Provisioning: Install Go 1.24.5
  config.vm.provision "shell", inline: <<-SHELL
    # Download and install Go 1.24.5
    wget https://go.dev/dl/go1.24.5.linux-amd64.tar.gz -O /tmp/go1.24.5.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go1.24.5.linux-amd64.tar.gz
    
    # Add Go to PATH for all users
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/vagrant/.bashrc
    
    # Verify installation
    /usr/local/go/bin/go version
  SHELL
end
