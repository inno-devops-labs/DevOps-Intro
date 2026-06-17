# frozen_string_literal: true

GO_VERSION = "1.24.5"
APP_GUEST_PATH = "/opt/quicknotes/app"

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.vm.boot_timeout = 900
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
                    guest: 8080,
                    host: 18080,
                    host_ip: "127.0.0.1",
                    auto_correct: false

  config.vm.synced_folder "./app",
                          APP_GUEST_PATH,
                          type: "virtualbox",
                          owner: "vagrant",
                          group: "vagrant",
                          SharedFoldersEnableSymlinksCreate: false,
                          mount_options: ["dmode=775", "fmode=664"]

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell",
                      privileged: true,
                      env: {
                        "APP_DIR" => APP_GUEST_PATH,
                        "GO_VERSION" => GO_VERSION
                      },
                      inline: <<-'SHELL'
    set -euxo pipefail
    export DEBIAN_FRONTEND=noninteractive

    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl build-essential

    case "$(dpkg --print-architecture)" in
      amd64) GO_ARCH="amd64" ;;
      arm64) GO_ARCH="arm64" ;;
      *) echo "unsupported CPU architecture"; exit 1 ;;
    esac

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tgz
      tar -C /usr/local -xzf /tmp/go.tgz
      rm -f /tmp/go.tgz
    fi

    cat >/etc/profile.d/go.sh <<'EOF'
export PATH=/usr/local/go/bin:$PATH
EOF

    install -d -o vagrant -g vagrant /var/lib/quicknotes

    cd "${APP_DIR}"
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .

    cat >/etc/systemd/system/quicknotes.service <<EOF
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
User=vagrant
Group=vagrant
WorkingDirectory=${APP_DIR}
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=${APP_DIR}/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now quicknotes.service
    systemctl --no-pager --full status quicknotes.service
  SHELL
end
