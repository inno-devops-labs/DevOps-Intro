Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-lab5"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "app", "/opt/quicknotes/app", type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", privileged: true, inline: <<~SHELL
    set -euxo pipefail

    GO_VERSION="1.24.5"
    apt-get update
    apt-get install -y ca-certificates curl

    if ! test -x /usr/local/go/bin/go || ! /usr/local/go/bin/go version | grep -q "go${GO_VERSION} "; then
      curl -fsSLo /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm -f /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go

    cat > /etc/profile.d/go.sh <<'EOF'
    export PATH=$PATH:/usr/local/go/bin
    EOF

    install -d -m 0755 /var/lib/quicknotes
    cd /opt/quicknotes/app
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .

    cat > /etc/systemd/system/quicknotes.service <<'EOF'
    [Unit]
    Description=QuickNotes application
    After=network.target

    [Service]
    Type=simple
    WorkingDirectory=/opt/quicknotes/app
    Environment=DATA_PATH=/var/lib/quicknotes/notes.json
    Environment=SEED_PATH=/opt/quicknotes/app/seed.json
    ExecStart=/usr/local/bin/quicknotes
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    EOF

    systemctl daemon-reload
    systemctl enable --now quicknotes.service
    curl --fail --silent http://127.0.0.1:8080/health
  SHELL
end
