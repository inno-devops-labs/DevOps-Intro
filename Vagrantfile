Vagrant.configure("2") do |config|
  config.vm.box      = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest:   8080,
    host:    18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    set -euo pipefail
    GO_VERSION="1.24.5"
    GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
    GO_URL="https://go.dev/dl/${GO_TARBALL}"

    if /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      echo "Go ${GO_VERSION} already installed, skipping."
      exit 0
    fi

    echo ">>> Installing Go ${GO_VERSION}..."
    apt-get update -qq
    apt-get install -y -qq wget ca-certificates

    wget -q "${GO_URL}" -O "/tmp/${GO_TARBALL}"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
    rm "/tmp/${GO_TARBALL}"

    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
    chmod +x /etc/profile.d/golang.sh

    /usr/local/go/bin/go version
    echo ">>> Go installed successfully."
  SHELL
end
