Vagrant.configure("2") do |config|
  # 1. Box: Ubuntu 22.04 (Jammy) or 24.04 (Noble)
  config.vm.box = "ubuntu/jammy64" 

  # 2. Hostname
  config.vm.hostname = "quicknotes-vm"

  # 3. Port Forwarding (Host 18080 -> Guest 8080, bound to localhost for safety)
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # 4. Synced Folder (Map host ./app to guest /home/vagrant/app)
  # Using rsync is often more reliable on Windows than VirtualBox shared folders
  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  # 5. Resources (Cap at 2 CPU, 1024 MB RAM)
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 2
  end

  # 6. Provisioning: Install Go 1.24.x
  config.vm.provision "shell", inline: <<-SHELL
    # Install prerequisites
    apt-get update
    apt-get install -y wget tar
    
    # Download and install Go 1.24.5 (Check go.dev for latest 1.24 point release)
    wget https://go.dev/dl/go1.24.5.linux-amd64.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.24.5.linux-amd64.tar.gz
    
    # Set PATH for all users/shells
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    chmod +x /etc/profile.d/go.sh
    
    # Clean up
    rm go1.24.5.linux-amd64.tar.gz
  SHELL
end