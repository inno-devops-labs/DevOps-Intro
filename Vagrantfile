# frozen_string_literal: true

# Lab 5 — QuickNotes dev VM (VirtualBox + Ubuntu 24.04 + Go 1.24.5)
# Apple Silicon: uses arm64 box + linux-arm64 Go tarball (auto-detected in provisioner).
# Box: bento/ubuntu-24.04 (generic/ubuntu2404 returned 404 on Vagrant Cloud).

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-dev"
  config.vm.boot_timeout = 600

  config.vm.network "forwarded_port",
                    guest: 8080,
                    host: 18080,
                    host_ip: "127.0.0.1",
                    id: "quicknotes"

  config.vm.synced_folder "app", "/home/vagrant/quicknotes",
                          type: "rsync",
                          rsync__auto: true,
                          rsync__exclude: [".git/"]

  config.vm.provider "virtualbox" do |vb|
    vb.name = "devops-intro-quicknotes"
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", path: "scripts/vagrant-provision.sh"
end
