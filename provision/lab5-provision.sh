#!/usr/bin/env bash
set -euo pipefail

GO_VERSION=1.24.13
GO_SHA256=1fc94b57134d51669c72173ad5d49fd62afb0f1db9bf3f798fd98ee423f8d730
GO_ARCHIVE=/tmp/go-${GO_VERSION}.linux-amd64.tar.gz

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates curl

if [ ! -x /usr/local/go/bin/go ] ||
   [ "$(/usr/local/go/bin/go version)" != "go version go${GO_VERSION} linux/amd64" ]; then
  curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o "$GO_ARCHIVE"
  printf '%s  %s\n' "$GO_SHA256" "$GO_ARCHIVE" | sha256sum -c -
  rm -rf /usr/local/go
  tar -C /usr/local -xzf "$GO_ARCHIVE"
fi
ln -sfn /usr/local/go/bin/go /usr/local/bin/go

install -d -o vagrant -g vagrant -m 0755 /var/lib/quicknotes
cd /home/vagrant/quicknotes
CGO_ENABLED=0 GOFLAGS=-buildvcs=false /usr/local/go/bin/go build -o /tmp/quicknotes .
install -m 0755 /tmp/quicknotes /usr/local/bin/quicknotes.new
mv -f /usr/local/bin/quicknotes.new /usr/local/bin/quicknotes

install -m 0644 /tmp/quicknotes.service /etc/systemd/system/quicknotes.service
systemctl daemon-reload
systemctl enable quicknotes
systemctl restart quicknotes
curl --retry 10 --retry-delay 1 --retry-connrefused -fsS http://127.0.0.1:8080/health
