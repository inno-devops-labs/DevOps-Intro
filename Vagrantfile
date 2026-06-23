Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  config.vm.hostname = "quicknotes-vm"
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app",
    "/home/vagrant/app",
    type: "rsync"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL

    GO_VERSION="1.24.5"

    apt-get update

    apt-get install -y curl tar

    rm -rf /usr/local/go

    curl -LO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz

    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz

    cat >/etc/profile.d/go.sh <<EOF
export PATH=/usr/local/go/bin:$PATH
EOF

    export PATH=/usr/local/go/bin:$PATH

    go version

  SHELL

end