# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Bento 22.04 — built for VirtualBox 7.0.x (stable download; pin avoids broken latest)
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.box_version = "202407.23.0"
  config.vm.hostname = "quicknotes-vm"
  config.vm.boot_timeout = 600
  config.ssh.connect_timeout = 120
  config.ssh.keep_alive = true
  config.ssh.insert_key = false

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "app", "/home/vagrant/quicknotes/app",
    type: "virtualbox",
    mount_options: ["dmode=775", "fmode=664"]

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.memory = 1024
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.vm.provision "shell", path: "vagrant/provision-go.sh"
end
