# frozen_string_literal: true

GO_VERSION = "1.24.5"
GO_SHA256 = "10ad9e86233e74c0f6590fe5426895de6bf388964210eac34a6d83f38918ecdc"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"
  # The shell provisioner sets quicknotes-lab5 in /etc/hostname directly.
  # This avoids a known systemd-networkd timeout when Vagrant restarts the
  # network solely to apply config.vm.hostname on this box/provider pair.
  # Vagrant's first adapter remains NAT. Only this loopback-bound forwarded
  # port is reachable from the host.
  config.vm.network "forwarded_port",
                    guest: 8080,
                    host: 18080,
                    host_ip: "127.0.0.1",
                    auto_correct: false

  # rsync avoids dependency on matching VirtualBox Guest Additions. It is a
  # one-way source sync; run `vagrant rsync` after changing app/ on the host.
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./app", "/opt/quicknotes/app",
                          type: "rsync",
                          rsync__exclude: ["data/", "quicknotes"]

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell",
                      path: "scripts/lab5-provision.sh",
                      args: [GO_VERSION, GO_SHA256],
                      privileged: true
end
