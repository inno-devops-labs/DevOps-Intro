#!/bin/bash
set -euo pipefail
export PATH="/usr/local/go/bin:$PATH"
export GOCACHE=/tmp/gocache
pkill -f '/tmp/qn$' 2>/dev/null || true
rm -rf /tmp/qn-src && mkdir -p /tmp/qn-src
cp /home/vagrant/app/*.go /home/vagrant/app/go.mod /home/vagrant/app/seed.json /tmp/qn-src/
cd /tmp/qn-src
CGO_ENABLED=0 go build -o /tmp/qn .
nohup /tmp/qn >/tmp/qn.log 2>&1 &
sleep 2
curl -s http://127.0.0.1:8080/health; echo
