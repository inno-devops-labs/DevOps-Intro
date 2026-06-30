GO_VERSION = "1.24.5"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64)  GO_ARCH="amd64" ;;
      aarch64) GO_ARCH="arm64"  ;;
      *)       echo "unsupported arch: $ARCH"; exit 1 ;;
    esac
    if ! command -v go &>/dev/null || ! go version | grep -q "go#{GO_VERSION}"; then
      wget -q "https://go.dev/dl/go#{GO_VERSION}.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
  SHELL
end
