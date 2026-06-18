#!/usr/bin/env bash
set -euo pipefail

GO_VERSION="1.24.5"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"

export DEBIAN_FRONTEND=noninteractive

if command -v go >/dev/null 2>&1 && go version | grep -q "go${GO_VERSION} "; then
  echo "Go ${GO_VERSION} already installed: $(go version)"
  exit 0
fi

apt-get update -qq
apt-get install -y -qq curl ca-certificates

curl -fsSL "https://go.dev/dl/${GO_TARBALL}" -o "/tmp/${GO_TARBALL}"
rm -rf /usr/local/go
tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
rm -f "/tmp/${GO_TARBALL}"

cat >/etc/profile.d/golang.sh <<'EOF'
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/home/vagrant/go
EOF
chmod 644 /etc/profile.d/golang.sh

export PATH="/usr/local/go/bin:${PATH}"
go version
