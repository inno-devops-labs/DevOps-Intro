Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  config.vm.hostname = "quicknotes-host"
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./app", "/mnt/host/app", type: "rsync"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = "2"
    vb.memory = "1024"
  end

  config.vm.provision "shell", inline: <<-SHELL
    echo "Installing Go 1.24.5..."
    cd /tmp
    curl -LO https://go.dev/dl/go1.24.5.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.24.5.linux-amd64.tar.gz
    rm go1.24.5.linux-amd64.tar.gz
    if [ ! -f /etc/profile.d/go.sh ]; then
      echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
      chmod +x /etc/profile.d/go.sh
    fi
    echo "Installed Go 1.24.5."
  SHELL
end
