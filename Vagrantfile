Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  config.vm.hostname = "quicknotes-vm"

  config.vm.network "private_network",
    ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-vm"
    vb.memory = 2048
    vb.cpus = 2
  end
end
