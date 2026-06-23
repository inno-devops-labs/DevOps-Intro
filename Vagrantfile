# frozen_string_literal: true

require "rbconfig"

GO_VERSION = "1.24.5"
HOST_CPU = RbConfig::CONFIG.fetch("host_cpu")
HOST_ARM64 = HOST_CPU.include?("arm") || HOST_CPU.include?("aarch64")

Vagrant.configure("2") do |config|
  config.vm.boot_timeout = 900

  if HOST_ARM64
    config.vm.box = "net9/ubuntu-24.04-arm64"
    config.vm.box_version = "1.1"
    config.vm.box_architecture = "arm64"
  else
    config.vm.box = "bento/ubuntu-24.04"
    config.vm.box_version = "202510.26.0"
    config.vm.box_architecture = "amd64"
  end

  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
                    guest: 8080,
                    host: 18080,
                    host_ip: "127.0.0.1",
                    auto_correct: false

  config.vm.synced_folder "./app",
                          "/opt/quicknotes/app",
                          type: "rsync",
                          rsync__exclude: [".git/", "data/"]

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    if HOST_ARM64
      vb.customize ["modifyvm", :id, "--firmware", "efi"]
      vb.customize ["modifyvm", :id, "--chipset", "ich9"]
    end
  end

  config.vm.provision "shell", privileged: true, env: { "GO_VERSION" => GO_VERSION }, inline: <<~'SHELL'
    set -eu

    arch="$(uname -m)"
    case "$arch" in
      x86_64) go_arch="amd64" ;;
      aarch64|arm64) go_arch="arm64" ;;
      *) echo "unsupported architecture: $arch" >&2; exit 1 ;;
    esac

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
      url="https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz"
      if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o /tmp/go.tgz
      elif command -v wget >/dev/null 2>&1; then
        wget -qO /tmp/go.tgz "$url"
      else
        python3 -c 'import sys, urllib.request; urllib.request.urlretrieve(sys.argv[1], "/tmp/go.tgz")' "$url"
      fi
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
      rm -f /tmp/go.tgz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    install -d -o vagrant -g vagrant /var/lib/quicknotes
    cd /opt/quicknotes/app
    CGO_ENABLED=0 GOTOOLCHAIN=local GOMAXPROCS=1 /usr/local/bin/go build -p=1 -o /usr/local/bin/quicknotes .

    cat >/etc/systemd/system/quicknotes.service <<'UNIT'
    [Unit]
    Description=QuickNotes API
    After=network-online.target

    [Service]
    User=vagrant
    WorkingDirectory=/opt/quicknotes/app
    Environment=ADDR=0.0.0.0:8080
    Environment=DATA_PATH=/var/lib/quicknotes/notes.json
    Environment=SEED_PATH=/opt/quicknotes/app/seed.json
    ExecStart=/usr/local/bin/quicknotes
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable --now quicknotes.service
  SHELL
end
