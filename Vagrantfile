Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"
  config.vm.box_check_update = false
  config.vm.hostname = "quicknotes-lab5"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", privileged: true, inline: <<-'SHELL'
    set -euxo pipefail

    GO_VERSION="1.24.5"
    GO_ROOT="/usr/local/go"

    apt-get update
    apt-get install -y ca-certificates curl tar

    guest_arch="$(dpkg --print-architecture)"
    case "$guest_arch" in
      amd64)
        go_arch="amd64"
        go_sha256="10ad9e86233e74c0f6590fe5426895de6bf388964210eac34a6d83f38918ecdc"
        ;;
      arm64)
        go_arch="arm64"
        go_sha256="0df02e6aeb3d3c06c95ff201d575907c736d6c62cfa4b6934c11203f1d600ffa"
        ;;
      *)
        echo "Unsupported guest architecture: $guest_arch" >&2
        exit 1
        ;;
    esac

    archive="go${GO_VERSION}.linux-${go_arch}.tar.gz"
    url="https://go.dev/dl/${archive}"
    tmp_archive="/tmp/${archive}"

    installed_version=""
    if [ -x "${GO_ROOT}/bin/go" ]; then
      installed_version="$(${GO_ROOT}/bin/go version | awk '{print $3}')"
    fi

    if [ "$installed_version" != "go${GO_VERSION}" ]; then
      rm -rf "${GO_ROOT}"
      curl -fsSL "${url}" -o "${tmp_archive}"
      echo "${go_sha256}  ${tmp_archive}" | sha256sum --check --status
      tar -C /usr/local -xzf "${tmp_archive}"
      rm -f "${tmp_archive}"
    fi

    ln -sf "${GO_ROOT}/bin/go" /usr/local/bin/go
    ln -sf "${GO_ROOT}/bin/gofmt" /usr/local/bin/gofmt

    cat >/etc/profile.d/go.sh <<'EOF'
export PATH=/usr/local/go/bin:$PATH
EOF
  SHELL
end