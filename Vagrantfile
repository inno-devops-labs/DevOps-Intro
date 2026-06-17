GO_VERSION = "1.24.13"

Vagrant.configure("2") do |config|

  config.vm.box = "cloudicio/ubuntu-server"
  config.vm.box_version = "24.04.1"
  config.vm.hostname = "quicknotes-vm"
  config.vm.network "forwarded_port",
    guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
    vb.gui = false
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    export DEBIAN_FRONTEND=noninteractive

    command -v curl >/dev/null 2>&1 || { apt-get update && apt-get install -y curl; }

    
    ARCH="$(dpkg --print-architecture)"          
    cd /tmp
    curl -fsSLO "https://go.dev/dl/go#{GO_VERSION}.linux-${ARCH}.tar.gz"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "go#{GO_VERSION}.linux-${ARCH}.tar.gz"
    ln -sf /usr/local/go/bin/go    /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
    go version

    
    install -d -o vagrant -g vagrant /opt/quicknotes
    cp -r /home/vagrant/app/. /opt/quicknotes/
    rm -rf /opt/quicknotes/data                 
    chown -R vagrant:vagrant /opt/quicknotes
    cd /opt/quicknotes
    CGO_ENABLED=0 go build -o /usr/local/bin/quicknotes .

    cat >/etc/systemd/system/quicknotes.service <<'UNIT'

[Unit]
Description=QuickNotes API
After=network.target

[Service]
Environment=ADDR=:8080
Environment=DATA_PATH=/opt/quicknotes/data/notes.json
Environment=SEED_PATH=/opt/quicknotes/seed.json
WorkingDirectory=/opt/quicknotes
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
User=vagrant

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now quicknotes
    systemctl restart quicknotes  
    sleep 2
    curl -fsS http://127.0.0.1:8080/health && echo
  SHELL
end
