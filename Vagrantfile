Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes"

  # Bound to the loopback address, so the guest's 8080 is reachable at
  # 127.0.0.1:18080 on this machine and nowhere else on the network.
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # Only app/ is shared: the VM has no reason to see .git or submissions/.
  config.vm.synced_folder "./app", "/srv/quicknotes"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 1024
  end

  # Installs a pinned Go from the upstream tarball. Re-running `vagrant provision`
  # is a no-op once the right version is in place.
  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    GO_VERSION=1.24.13
    ARCH="$(dpkg --print-architecture)"

    if [ "$(/usr/local/go/bin/go version 2>/dev/null | awk '{print $3}')" = "go${GO_VERSION}" ]; then
      echo "go${GO_VERSION} already installed, nothing to do"
      exit 0
    fi

    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm -f /tmp/go.tar.gz

    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    chmod +x /etc/profile.d/go.sh

    /usr/local/go/bin/go version
  SHELL
end
