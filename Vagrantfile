Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./app", "/opt/quicknotes", type: "rsync"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e

    GO_VERSION="1.24.5"

    apt-get update
    apt-get install -y curl ca-certificates

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSLo /tmp/go.tar.gz \
        "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go

    cd /opt/quicknotes
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes

    cat > /etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes
After=network.target

[Service]
ExecStart=/usr/local/bin/quicknotes
Environment=ADDR=:8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now quicknotes
  SHELL
end
