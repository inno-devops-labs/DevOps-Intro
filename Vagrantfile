Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/jammy64"
    config.vm.hostname = "quicknotes-vm"
    
    config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"
    
    config.vm.synced_folder "./app", "/home/vagrant/app"
    
    config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
    end
    
    config.vm.provision "shell", inline: <<-SHELL
    set -e
    
    sudo apt-get update
    sudo apt-get install -y curl tar
    
    cd /tmp
    
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go1.24.5"; then
      curl -LO https://go.dev/dl/go1.24.5.linux-amd64.tar.gz
      sudo rm -rf /usr/local/go
      sudo tar -C /usr/local -xzf go1.24.5.linux-amd64.tar.gz
    fi
    
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/go.sh >/dev/null
    
    export PATH=$PATH:/usr/local/go/bin
    
    go version
    
    SHELL
    end
    