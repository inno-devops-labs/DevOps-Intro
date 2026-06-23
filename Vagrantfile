# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Lab 5 — QuickNotes VM (libvirt/KVM provider).
# See submissions/lab5.md for the design rationale and the libvirt-vs-VirtualBox note.

Vagrant.configure("2") do |config|
  go_version = "1.24.5"

  config.vm.box      = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest:   8080,
    host:    18080,
    host_ip: "127.0.0.1"

  # rsync: one-way host→guest. Refresh with `vagrant rsync` or `vagrant rsync-auto`.
  config.vm.synced_folder "./app", "/home/vagrant/app",
    type: "rsync",
    rsync__exclude: ["data/", "quicknotes"]

  config.vm.provider :libvirt do |lv|
    lv.uri    = "qemu:///session" 
    lv.driver = "kvm"
    lv.cpus   = 2
    lv.memory = 1024
  end

  config.vm.provision "shell",
    name:       "install-go-#{go_version}",
    privileged: true,
    inline: <<~SHELL
      set -euo pipefail
      need="go#{go_version}"
      have="$(/usr/local/go/bin/go version 2>/dev/null | awk '{print $3}' || true)"
      if [ "$have" = "$need" ]; then
        echo "go already at $need — skipping download"
        exit 0
      fi
      tarball="go#{go_version}.linux-amd64.tar.gz"
      cd /tmp
      curl -fsSL -o "$tarball" "https://go.dev/dl/$tarball"
      rm -rf /usr/local/go
      tar -C /usr/local -xzf "$tarball"
      echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
      chmod 0644 /etc/profile.d/go.sh
      /usr/local/go/bin/go version
    SHELL
end
