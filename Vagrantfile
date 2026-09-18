Vagrant.configure("2") do |config|
  # Ubuntu 24.04 LTS public Vagrant box
  config.vm.box = "ubuntu/jammy64"

  # Identify the VM clearly
  config.vm.hostname = "quicknotes-vm"

  # Host 127.0.0.1:18080 -> Guest :8080
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  # Sync only the application directory into the VM
  config.vm.synced_folder "./app",
    "/home/vagrant/app",
    type: "rsync"

  # VirtualBox resource limits
  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  # Install a pinned Go 1.24.x release automatically
  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"

    apt-get update
    apt-get install -y curl ca-certificates

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
        -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm -f /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    go version
  SHELL
end
