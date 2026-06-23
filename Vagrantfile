# -*- mode: ruby -*-
# vi: set ft=ruby :

GO_VERSION = "1.24.5"
APP_GUEST_DIR = "/srv/quicknotes/app"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
                    guest: 8080,
                    host: 18080,
                    host_ip: "127.0.0.1",
                    auto_correct: false

  config.vm.synced_folder "./app",
                          APP_GUEST_DIR,
                          type: "rsync",
                          rsync__exclude: ["/data/", "/quicknotes"]

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell",
                      privileged: true,
                      env: {
                        "GO_VERSION" => GO_VERSION,
                        "APP_DIR" => APP_GUEST_DIR
                      },
                      inline: <<-'SHELL'
    set -euo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl tar build-essential

    arch="$(dpkg --print-architecture)"
    case "$arch" in
      amd64) go_arch="amd64" ;;
      arm64) go_arch="arm64" ;;
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
    esac

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
      rm -rf /usr/local/go
      curl -fsSLo /tmp/go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz"
      tar -C /usr/local -xzf /tmp/go.tgz
      rm -f /tmp/go.tgz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    if ! id -u quicknotes >/dev/null 2>&1; then
      useradd --system --home-dir /var/lib/quicknotes --create-home --shell /usr/sbin/nologin quicknotes
    fi
    install -d -o quicknotes -g quicknotes -m 0755 /var/lib/quicknotes

    cd "$APP_DIR"
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .
    chown root:root /usr/local/bin/quicknotes
    chmod 0755 /usr/local/bin/quicknotes

    cat >/etc/systemd/system/quicknotes.service <<EOF
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
User=quicknotes
Group=quicknotes
WorkingDirectory=${APP_DIR}
Environment=ADDR=0.0.0.0:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=${APP_DIR}/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec=2s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now quicknotes
    systemctl restart quicknotes

    /usr/local/bin/go version
    systemctl --no-pager --full status quicknotes || true
  SHELL
end
