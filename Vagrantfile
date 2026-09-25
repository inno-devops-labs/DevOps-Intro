
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_architecture = "arm64"

  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  config.vm.provider "utm" do |utm|
    utm.name = "quicknotes-vm"
    utm.memory = 1024
    utm.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    GO_VERSION="1.24.5"
    ARCH="arm64"
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tgz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tgz
    rm /tmp/go.tgz
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    chmod +x /etc/profile.d/go.sh
    # also for interactive shell
    grep -q '/usr/local/go/bin' /home/vagrant/.bashrc || \
      echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/vagrant/.bashrc
    /usr/local/go/bin/go version
  SHELL
end
