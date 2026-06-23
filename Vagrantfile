# Lab 5 - QuickNotes in a Vagrant VM

Vagrant.configure("2") do |config|
  # Public Ubuntu 24.04 LTS Vagrant box
  config.vm.box = "bento/ubuntu-24.04"

  # Identifies the VM clearly
  config.vm.hostname = "quicknotes-vm"

  # Host 127.0.0.1:18080 -> Guest 8080
  # Bound to localhost so it is not exposed publicly
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  # Sync only the app directory into the VM
  config.vm.synced_folder "./app", "/opt/quicknotes/app", type: "virtualbox"

  # Resource limits: 2 vCPU and 1024 MB RAM
  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  # Install Go 1.24.5, build QuickNotes, and run it as a systemd service
  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"

    apt-get update
    apt-get install -y curl ca-certificates build-essential

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    cd /opt/quicknotes/app
    /usr/local/go/bin/go mod download
    /usr/local/go/bin/go build -o /opt/quicknotes/qn .

    cat >/etc/systemd/system/quicknotes.service <<'EOF'
[Unit]
Description=QuickNotes Go App
After=network.target

[Service]
WorkingDirectory=/opt/quicknotes/app
ExecStart=/opt/quicknotes/qn
Environment=ADDR=:8080
Restart=always
User=vagrant
Group=vagrant

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable quicknotes
    systemctl restart quicknotes
  SHELL
end