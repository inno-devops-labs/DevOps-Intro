Vagrant.configure("2") do |config|
  config.vm.box      = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"

  # Port forward: host 127.0.0.1:18080 → guest :8080
  config.vm.network "forwarded_port",
    guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # Sync ./app into the guest (VirtualBox shared folder — works on Windows without rsync)
  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  # Install Go 1.24.5 on first `vagrant up`; idempotent on re-provision
  config.vm.provision "shell", inline: <<-SHELL
    set -e
    GO_VERSION="1.24.5"
    GO_BIN="/usr/local/go/bin/go"

    if "${GO_BIN}" version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      echo "==> Go ${GO_VERSION} already installed — skipping download"
    else
      echo "==> Installing Go ${GO_VERSION}"
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi

    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh

    echo "==> $( ${GO_BIN} version )"
  SHELL
end
