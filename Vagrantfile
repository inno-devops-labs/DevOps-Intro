Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/opt/quicknotes/app",
    type: "virtualbox",
    owner: "vagrant",
    group: "vagrant"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"

    apt-get update
    apt-get install -y curl ca-certificates tar build-essential

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    install -d -o vagrant -g vagrant /var/lib/quicknotes

    cd /opt/quicknotes/app
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .

    cat >/etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes API
After=network.target

[Service]
User=vagrant
Group=vagrant
WorkingDirectory=/opt/quicknotes/app
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/opt/quicknotes/app/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable quicknotes
    systemctl restart quicknotes
  SHELL
end