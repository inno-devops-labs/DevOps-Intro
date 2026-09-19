#!/usr/bin/env bash
set -eu

go_version=$1
go_sha256=$2
export DEBIAN_FRONTEND=noninteractive

printf '%s\n' quicknotes-lab5 >/etc/hostname
hostname quicknotes-lab5
if grep -q '^127\.0\.1\.1' /etc/hosts; then
  sed -i 's/^127\.0\.1\.1.*/127.0.1.1 quicknotes-lab5/' /etc/hosts
else
  printf '%s\n' '127.0.1.1 quicknotes-lab5' >>/etc/hosts
fi
apt-get update -qq
apt-get install -y -qq ca-certificates curl

if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${go_version} "; then
  archive="/tmp/go${go_version}.linux-amd64.tar.gz"
  curl -fsSL "https://go.dev/dl/go${go_version}.linux-amd64.tar.gz" -o "$archive"
  printf '%s  %s\n' "$go_sha256" "$archive" | sha256sum -c -
  rm -rf /usr/local/go
  tar -C /usr/local -xzf "$archive"
  rm -f "$archive"
fi

cat >/etc/profile.d/go.sh <<'EOF'
export PATH=/usr/local/go/bin:$PATH
EOF

cd /opt/quicknotes/app
/usr/local/go/bin/go test ./...
/usr/local/go/bin/go build -trimpath -o /usr/local/bin/quicknotes .

if ! id quicknotes >/dev/null 2>&1; then
  useradd --system --home /var/lib/quicknotes --shell /usr/sbin/nologin quicknotes
fi
install -d -o quicknotes -g quicknotes /var/lib/quicknotes

cat >/etc/systemd/system/quicknotes.service <<'EOF'
[Unit]
Description=QuickNotes Lab 5 service
After=network.target

[Service]
User=quicknotes
Group=quicknotes
Environment=ADDR=0.0.0.0:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/opt/quicknotes/app/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable quicknotes.service
systemctl restart quicknotes.service
