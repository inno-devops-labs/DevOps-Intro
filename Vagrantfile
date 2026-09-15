Vagrant.configure("2") do |config|
  # Ubuntu 24.04 LTS ARM64 for Apple Silicon
  config.vm.box = "net9/ubuntu-24.04-arm64"
  config.vm.box_version = "1.1"

  # Identify the VM as QuickNotes
  config.vm.hostname = "quicknotes-vm"

  # Forward host 127.0.0.1:18080 -> guest :8080
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  # Share the QuickNotes application with the VM
  config.vm.synced_folder "./app", "/home/vagrant/quicknotes"

  # Resource limits
  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 1024
  end

  # Provision the VM
  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    # Work around VirtualBox NAT DNS issue on this environment
    sudo resolvectl dns eth0 1.1.1.1
    sudo resolvectl flush-caches

    # Install required packages
    sudo apt-get update
    sudo apt-get install -y curl ca-certificates

    # Install a pinned Go 1.24.x release
    GO_VERSION="1.24.7"

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      curl -fsSL \
        "https://go.dev/dl/go${GO_VERSION}.linux-arm64.tar.gz" \
        -o /tmp/go.tar.gz

      sudo rm -rf /usr/local/go
      sudo tar -C /usr/local -xzf /tmp/go.tar.gz
      rm -f /tmp/go.tar.gz
    fi

    # Make Go available to the vagrant user
    grep -qxF 'export PATH=$PATH:/usr/local/go/bin' /home/vagrant/.profile || \
      echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/vagrant/.profile

    # Also make Go available system-wide
    sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
    sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    # Verify installation
    go version
  SHELL
end