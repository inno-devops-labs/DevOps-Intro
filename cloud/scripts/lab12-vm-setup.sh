#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq curl wget hyperfine docker.io python3 git

systemctl enable --now docker 2>/dev/null || service docker start

if ! command -v spin >/dev/null; then
  curl -fsSL https://github.com/spinframework/spin/releases/download/v3.4.0/spin-v3.4.0-linux-amd64.tar.gz \
    | tar -xz -C /usr/local/bin spin
fi

if ! command -v tinygo >/dev/null; then
  wget -q -O /tmp/tinygo.deb https://github.com/tinygo-org/tinygo/releases/download/v0.41.0/tinygo_0.41.0_amd64.deb
  dpkg -i /tmp/tinygo.deb || apt-get install -f -y -qq
fi

if ! command -v wasmtime >/dev/null; then
  curl -fsSL https://wasmtime.dev/install.sh | bash -s -- --version v29.0.0
fi

export PATH="${HOME}/.wasmtime/bin:${PATH}"

spin --version
tinygo version
wasmtime --version
hyperfine --version
docker --version
