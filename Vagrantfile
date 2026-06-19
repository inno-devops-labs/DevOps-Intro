# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Ubuntu 22.04 LTS — reliable download on Vagrant Cloud (bento URLs often 404)
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"
  config.vm.hostname = "quicknotes-vm"
  config.vm.boot_timeout = 1200
  config.ssh.connect_timeout = 60
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
    # Avoid serial-console stalls that block SSH on some Windows + VirtualBox setups
    vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
  end

  config.vm.provision "shell", path: "vagrant/provision-go.sh"
end
