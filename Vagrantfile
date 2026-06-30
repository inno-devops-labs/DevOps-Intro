Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"

  config.vm.boot_timeout = 600
  config.ssh.forward_agent = false

  # Default Vagrant SSH, used by Vagrant itself.
  config.vm.network "forwarded_port",
    guest: 22,
    host: 2222,
    host_ip: "127.0.0.1",
    id: "ssh",
    auto_correct: true

  # Extra SSH forward exposed for WSL Ansible access if needed.
  config.vm.network "forwarded_port",
    guest: 22,
    host: 2223,
    host_ip: "0.0.0.0",
    auto_correct: true

  # QuickNotes app port.
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/opt/quicknotes/app", type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end
end
