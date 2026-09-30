#!/usr/bin/env bash
# Lab 5 — install Go 1.24.5 into the Vagrant guest (idempotent)
set -euo pipefail

GO_VERSION="1.24.5"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl ca-certificates build-essential >/dev/null

if command -v go >/dev/null 2>&1; then
  cur="$(go version 2>/dev/null || true)"
  if echo "$cur" | grep -q "go${GO_VERSION}"; then
    echo "Go ${GO_VERSION} already installed: $cur"
    exit 0
  fi
fi

echo "Installing Go ${GO_VERSION}..."
curl -fsSL -o "/tmp/${GO_TARBALL}" "${GO_URL}"
rm -rf /usr/local/go
tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
rm -f "/tmp/${GO_TARBALL}"

# System-wide PATH for interactive + non-interactive shells
cat >/etc/profile.d/golang.sh <<'EOF'
export PATH="/usr/local/go/bin:$PATH"
EOF
chmod 644 /etc/profile.d/golang.sh

# Also for the default vagrant login shell
if ! grep -q '/usr/local/go/bin' /home/vagrant/.bashrc 2>/dev/null; then
  echo 'export PATH="/usr/local/go/bin:$PATH"' >> /home/vagrant/.bashrc
fi

export PATH="/usr/local/go/bin:$PATH"
go version
echo "Go ${GO_VERSION} provision complete."
