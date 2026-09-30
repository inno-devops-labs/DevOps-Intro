# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Lab 5 — QuickNotes in a Vagrant VM
# Repo-root Vagrantfile: Ubuntu 24.04, Go 1.24.x, port 18080→8080, 2 vCPU / 1024 MB

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04" # Ubuntu 24.04 LTS (public box)
  config.vm.hostname = "quicknotes-vm"

  # Host-only binding: reachable from this machine, not the LAN
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1",
    auto_correct: true

  # VirtualBox shared folder (default on Windows; no extra host packages)
  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  # Shell provisioner: install pinned Go 1.24.5 (idempotent)
  config.vm.provision "shell", path: "scripts/lab5-provision.sh", privileged: true
end
