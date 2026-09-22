Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e

    GO_VERSION="1.24.5"

    if [ ! -x /usr/local/go/bin/go ] || [ "$(/usr/local/go/bin/go version | awk '{print $3}')" != "go${GO_VERSION}" ]; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-arm64.tar.gz" -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm -f /tmp/go.tar.gz
    fi

    grep -qxF 'export PATH=/usr/local/go/bin:$PATH' /etc/profile || \
      echo 'export PATH=/usr/local/go/bin:$PATH' >> /etc/profile

    export PATH=/usr/local/go/bin:$PATH
    go version
  SHELL
end
