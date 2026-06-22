Vagrant.configure("2") do |config|

  config.vm.box = "bento/ubuntu-24.04"

  config.vm.hostname = "quicknotes"

  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/opt/quicknotes/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-lab5"
    vb.cpus   = 2
    vb.memory = 1024
    vb.customize ["modifyvm", :id, "--paravirtprovider", "legacy"] 
  end

  config.vm.provision "shell", inline: <<-SHELL
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go1.24.5"; then
      curl -fsSL "https://go.dev/dl/go1.24.5.linux-amd64.tar.gz" -o /tmp/go.tgz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
    fi
    export PATH=$PATH:/usr/local/go/bin
    ln -sf /usr/local/go/bin/go    /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
    mkdir -p /opt/quicknotes/bin /var/lib/quicknotes
    cd /opt/quicknotes/app
    go build -o /opt/quicknotes/bin/qn .
    cat > /etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes
After=network.target

[Service]
WorkingDirectory=/opt/quicknotes/app
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/opt/quicknotes/app/seed.json
ExecStart=/opt/quicknotes/bin/qn
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
    systemctl daemon-reload
    systemctl enable --now quicknotes
    sleep 2
    systemctl --no-pager status quicknotes | head -n 5
    SHELL
end