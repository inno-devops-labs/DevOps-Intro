Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202508.03.0"
  config.vm.box_architecture = "amd64"
  config.vm.box_check_update = false
  config.vm.hostname = "quicknotes-lab5"

  config.vm.network "forwarded_port", guest: 8080, host: 18080,
                    host_ip: "127.0.0.1", auto_correct: false

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./app", "/home/vagrant/quicknotes", type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "file", source: "provision/lab5-quicknotes.service",
                              destination: "/tmp/quicknotes.service"
  config.vm.provision "shell", path: "provision/lab5-provision.sh"
end
