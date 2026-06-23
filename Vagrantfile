# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"

  config.vm.hostname = "quicknotes-vm"
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", create: true

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus   = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e
    apt-get update && apt-get install -y curl
    GO_VERSION=1.24.5
    case "$(uname -m)" in
      x86_64)  GOARCH=amd64 ;;
      aarch64) GOARCH=arm64 ;;
      *) echo "unsupported arch $(uname -m)"; exit 1 ;;
    esac
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz" -o /tmp/go.tgz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
    fi
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
  SHELL
end