Vagrant.configure("2") do |config|
  # Ubuntu 24.04 LTS
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes"

  # Host 127.0.0.1:18080 -> guest :8080
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  # Sync the QuickNotes application into the VM
  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  # VM resource limits
  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 1024
  end

  # Install a pinned Go version
  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"
    ARCH="$(dpkg --print-architecture)"

    case "$ARCH" in
      amd64|arm64)
        ;;
      *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
    esac

    apt-get update
    apt-get install -y curl ca-certificates

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm -f /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    go version
  SHELL
end
