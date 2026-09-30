Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port", guest: 8080, host: 18080,
    host_ip: "127.0.0.1", auto_correct: false

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./app", "/opt/quicknotes", type: "rsync"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-'SHELL'
    set -eu

    case "$(uname -m)" in
      x86_64)
        go_arch=amd64
        go_sha256=10ad9e86233e74c0f6590fe5426895de6bf388964210eac34a6d83f38918ecdc
        ;;
      aarch64)
        go_arch=arm64
        go_sha256=0df02e6aeb3d3c06c95ff201d575907c736d6c62cfa4b6934c11203f1d600ffa
        ;;
      *) echo "Unsupported Go architecture: $(uname -m)" >&2; exit 1 ;;
    esac

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q '^go version go1.24.5 '; then
      archive="/tmp/go1.24.5.linux-${go_arch}.tar.gz"
      curl --fail --location --silent --show-error \
        "https://go.dev/dl/go1.24.5.linux-${go_arch}.tar.gz" --output "$archive"
      echo "$go_sha256  $archive" | sha256sum --check
      rm -rf /usr/local/go
      tar -C /usr/local -xzf "$archive"
      rm -f "$archive"
    fi

    printf '%s\n' 'export PATH=/usr/local/go/bin:$PATH' > /etc/profile.d/go.sh
    ln -sfn /usr/local/go/bin/go /usr/local/bin/go

    if ! id quicknotes >/dev/null 2>&1; then
      useradd --system --home-dir /var/lib/quicknotes --shell /usr/sbin/nologin quicknotes
    fi
    install -d -o quicknotes -g quicknotes /var/lib/quicknotes

    cd /opt/quicknotes
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .

    printf '%s\n' \
      '[Unit]' \
      'Description=QuickNotes HTTP service' \
      'After=network.target' \
      '' \
      '[Service]' \
      'Type=simple' \
      'User=quicknotes' \
      'Group=quicknotes' \
      'WorkingDirectory=/opt/quicknotes' \
      'Environment=ADDR=:8080' \
      'Environment=DATA_PATH=/var/lib/quicknotes/notes.json' \
      'Environment=SEED_PATH=/opt/quicknotes/seed.json' \
      'ExecStart=/usr/local/bin/quicknotes' \
      'Restart=on-failure' \
      '' \
      '[Install]' \
      'WantedBy=multi-user.target' \
      > /etc/systemd/system/quicknotes.service

    systemctl daemon-reload
    systemctl enable quicknotes.service
    systemctl restart quicknotes.service
    curl --fail --retry 10 --retry-delay 1 --retry-connrefused \
      http://127.0.0.1:8080/health
  SHELL
end
