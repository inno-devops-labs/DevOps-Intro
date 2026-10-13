require "vagrant/util/is_port_open"

module Vagrant
  module Util
    module IsPortOpen
      def is_port_open?(host, port)
        socket = Socket.tcp(host, port, connect_timeout: 0.1)
        socket.remote_address
        true
      rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
             Errno::ENETUNREACH, Errno::EACCES, Errno::ENOTCONN,
             Errno::EALREADY, Errno::EINVAL
        false
      ensure
        socket&.close
      end
    end
  end
end

Vagrant.configure("2") do |config|
  # Ubuntu 24.04 LTS.
  # Vagrant 2.4+ selects the host-compatible architecture automatically.
  config.vm.box = "gutehall/ubuntu24-04"

  # Parallels may report the guest IP before its shared-network route is ready.
  # Allow enough time for SSH to become reachable during the first boot.
  config.ssh.connect_retries = 30
  config.ssh.connect_retry_delay = 2
  config.ssh.connect_timeout = 15

  # The Parallels shared-network route (10.211.55.0/24) may appear after the
  # provider has already started SSH. Use Parallels NAT via localhost for the
  # Vagrant communicator so boot and provisioning do not depend on that route.
  config.vm.network "forwarded_port",
    guest: 22,
    host: 22022,
    id: "quicknotes-vagrant-ssh",
    host_ip: "127.0.0.1",
    auto_correct: false
  config.ssh.host = "127.0.0.1"
  config.ssh.port = 22022

  # Make the guest easy to identify.
  config.vm.hostname = "quicknotes-vm"

  # Host 127.0.0.1:18080 -> guest :8080.
  # Binding to loopback prevents exposure to the external network.
  # If 18080 is busy, Vagrant selects a free port from this range.
  config.vm.usable_port_range = 18080..18180

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    id: "quicknotes-http",
    host_ip: "127.0.0.1",
    auto_correct: true

  # Copy the host app directory into the guest.
  # rsync is provider-independent and works with both Parallels and VirtualBox.
  config.vm.synced_folder "./app", "/opt/quicknotes",
    type: "rsync",
    rsync__exclude: [".git/"]

  # Parallels configuration for Apple Silicon/macOS.
  config.vm.provider "parallels" do |prl|
    prl.memory = 1024
    prl.cpus = 2
  end

  # Install a pinned Go release.
  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"

    case "$(uname -m)" in
      x86_64)
        GO_ARCH="amd64"
        ;;
      aarch64|arm64)
        GO_ARCH="arm64"
        ;;
      *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
    esac

    apt-get update
    apt-get install -y curl ca-certificates

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSL \
        "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" \
        -o /tmp/go.tar.gz

      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm -f /tmp/go.tar.gz
    fi

    cat >/etc/profile.d/go.sh <<'PROFILE'
export PATH=/usr/local/go/bin:$PATH
PROFILE

    ln -sf /usr/local/go/bin/go /usr/local/bin/go

    go version
  SHELL
end
