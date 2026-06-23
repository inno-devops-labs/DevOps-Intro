#!/usr/bin/env bash
# Idempotent Go 1.24.5 install for Lab 5 VM (amd64 or arm64 guest).
set -euo pipefail

GO_VERSION="1.24.5"
ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64)  GOARCH="amd64" ;;
  aarch64) GOARCH="arm64" ;;
  *) echo "unsupported arch: ${ARCH}" >&2; exit 1 ;;
esac

TARBALL="go${GO_VERSION}.linux-${GOARCH}.tar.gz"
URL="https://go.dev/dl/${TARBALL}"

if command -v go >/dev/null 2>&1 && go version | grep -q "go${GO_VERSION} "; then
  echo "Go ${GO_VERSION} already installed: $(go version)"
  exit 0
fi

echo "Installing Go ${GO_VERSION} (${GOARCH}) from ${URL}"
apt-get update -qq
apt-get install -y -qq curl ca-certificates
curl -fsSL "${URL}" -o "/tmp/${TARBALL}"
rm -rf /usr/local/go
tar -C /usr/local -xzf "/tmp/${TARBALL}"
rm -f "/tmp/${TARBALL}"

cat >/etc/profile.d/go-path.sh <<'EOF'
export PATH=/usr/local/go/bin:$PATH
EOF
chmod 644 /etc/profile.d/go-path.sh
export PATH="/usr/local/go/bin:${PATH}"

go version
