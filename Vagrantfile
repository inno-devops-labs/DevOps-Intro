# -*- mode: ruby -*-
# Lab 5 — QuickNotes inside a Vagrant VM (VirtualBox provider).
# Works on both x86_64 and Apple Silicon hosts: bento publishes the box for
# amd64 and arm64, and the provisioner picks the matching Go tarball.

GO_VERSION = "1.24.13"
GO_SHA256 = {
  "amd64" => "1fc94b57134d51669c72173ad5d49fd62afb0f1db9bf3f798fd98ee423f8d730",
  "arm64" => "74d97be1cc3a474129590c67ebf748a96e72d9f3a2b6fef3ed3275de591d49b3",
}

Vagrant.configure("2") do |config|
  # 1. Box: Ubuntu 24.04 LTS, pinned version for reproducibility
  config.vm.box         = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"

  # 2. Hostname
  config.vm.hostname = "quicknotes-vm"

  # 3. Port forwarding: host 127.0.0.1:18080 -> guest 8080 (NAT, not public)
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # 4. Synced folder: ./app -> /home/vagrant/app (rsync, one-way host -> guest)
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync",
    rsync__exclude: ["quicknotes", "data/"]

  # 5. Resources: 2 vCPU, 1024 MB RAM
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  # 6. Provisioning: install pinned Go (idempotent, checksum-verified)
  config.vm.provision "shell", name: "install-go",
    env: { "GO_VERSION" => GO_VERSION,
           "GO_SHA_AMD64" => GO_SHA256["amd64"],
           "GO_SHA_ARM64" => GO_SHA256["arm64"] },
    inline: <<-SHELL
      set -euo pipefail
      ARCH="$(dpkg --print-architecture)"            # amd64 | arm64
      case "$ARCH" in
        amd64) SHA="$GO_SHA_AMD64" ;;
        arm64) SHA="$GO_SHA_ARM64" ;;
        *) echo "unsupported arch: $ARCH"; exit 1 ;;
      esac

      if /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
        echo "Go ${GO_VERSION} already installed - skipping"
      else
        TGZ="go${GO_VERSION}.linux-${ARCH}.tar.gz"
        curl -fsSL -o "/tmp/${TGZ}" "https://go.dev/dl/${TGZ}"
        echo "${SHA}  /tmp/${TGZ}" | sha256sum -c -
        rm -rf /usr/local/go
        tar -C /usr/local -xzf "/tmp/${TGZ}"
        rm -f "/tmp/${TGZ}"
      fi

      # Put Go on PATH for every login shell (and for `vagrant ssh -c`)
      echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
      ln -sf /usr/local/go/bin/go    /usr/local/bin/go
      ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
      go version
    SHELL
end
