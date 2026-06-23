Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/opt/quicknotes/app", type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"
    GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"

    apt-get update
    apt-get install -y curl ca-certificates build-essential

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSLo "/tmp/${GO_TARBALL}" "https://go.dev/dl/${GO_TARBALL}"
      tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
      ln -sf /usr/local/go/bin/go /usr/local/bin/go
      ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
    fi

    cd /opt/quicknotes/app
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .

    cat >/etc/systemd/system/quicknotes.service <<'EOF'
[Unit]
Description=QuickNotes service
After=network.target

[Service]
WorkingDirectory=/opt/quicknotes/app
Environment=ADDR=:8080
ExecStart=/usr/local/bin/quicknotes
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable quicknotes
    systemctl restart quicknotes
  SHELL
end