Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e

    GO_VERSION="1.24.5"

    ARCH="$(dpkg --print-architecture)"

    case "$ARCH" in
      arm64) GO_ARCH="arm64" ;;
      amd64) GO_ARCH="amd64" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      apt-get update
      apt-get install -y curl

      rm -rf /usr/local/go

      curl -fsSL \
        "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" \
        -o /tmp/go.tar.gz

      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go

    go version
  SHELL
end