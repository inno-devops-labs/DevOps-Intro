Vagrant.configure("2") do |config|
  # Ubuntu 24.04 LTS.
  # Vagrant 2.4+ automatically selects the architecture matching the host.
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_check_update = false
  config.vm.box_version = "202510.26.0"
  config.vm.box_architecture = :auto

  config.vm.hostname = "quicknotes-vm"

  # Host 127.0.0.1:18080 -> guest :8080
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1",
    auto_correct: false

  # Sync only the application directory into the VM.
  config.vm.synced_folder "./app",
    "/home/vagrant/quicknotes",
    type: "rsync"

  # Lab resource limits.
  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
    # Let the VirtualBox NAT engine resolve DNS through the host.
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # Install a pinned Go release and start QuickNotes automatically.
  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates

    GO_VERSION="1.24.5"

    case "$(uname -m)" in
      aarch64|arm64)
        GO_ARCH="arm64"
        ;;
      x86_64|amd64)
        GO_ARCH="amd64"
        ;;
      *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
    esac

    curl -fsSL \
      "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" \
      -o /tmp/go.tar.gz

    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    cd /home/vagrant/quicknotes
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .

    cat > /etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes
After=network.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/home/vagrant/quicknotes
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable quicknotes
    systemctl restart quicknotes

    /usr/local/go/bin/go version
    systemctl --no-pager status quicknotes || true
  SHELL
end
