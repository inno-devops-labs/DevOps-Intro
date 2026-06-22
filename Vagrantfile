Vagrant.configure("2") do |config|
  # box type
  config.vm.box = "bento/ubuntu-22.04"

  # hostname
  config.vm.hostname = "quicknotes-vm"

  # forwarded port
  config.vm.network "forwarded_port", guest: 8080, host: 18080

  # synced folder
  config.vm.synced_folder "./app", "/app", type: "rsync", rsync__exclude: ".git/"

  # set a provider
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 2
  end

  # set a provision
  config.vm.provision "download-go",
    type: "shell",
    preserve_order: true,
    inline: "wget -P /tmp https://go.dev/dl/go1.24.5.linux-arm64.tar.gz"

  config.vm.provision "unpack-go",
    type: "shell",
    preserve_order: true,
    inline: "rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go1.24.5.linux-arm64.tar.gz"

  config.vm.provision "add-go-to-path",
    type: "shell",
    preserve_order: true,
    inline: "echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile.d/go.sh"
end
