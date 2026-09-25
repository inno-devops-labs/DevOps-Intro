#!/usr/bin/env bash
set -euo pipefail

label="${1:-a}"

rm -rf /tmp/qn
mkdir /tmp/qn
cp -a /repo/. /tmp/qn/
rm -rf /tmp/qn/.git
cd /tmp/qn

nix --extra-experimental-features nix-command --extra-experimental-features flakes build .#quicknotes 2>&1 | tee "/repo/nix-quicknotes-build-${label}.log"

store_path="$(readlink -f result)"
{
  echo "store_path=${store_path}"
  nix-store --query --hash "${store_path}"
} | tee "/repo/nix-quicknotes-hash-${label}.txt"

ADDR=:8080 DATA_PATH="/tmp/notes-${label}.json" SEED_PATH=/tmp/qn/app/seed.json ./result/bin/quicknotes >"/tmp/quicknotes-${label}.log" 2>&1 &
pid="$!"
trap 'kill "${pid}" 2>/dev/null || true' EXIT

for _ in 1 2 3 4 5 6 7 8 9 10; do
  if (echo >/dev/tcp/127.0.0.1/8080) >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

exec 3<>/dev/tcp/127.0.0.1/8080
printf 'GET /health HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' >&3
cat <&3 | tee "/repo/nix-health-${label}.txt"
kill "${pid}"
wait "${pid}" 2>/dev/null || true
trap - EXIT

nix --extra-experimental-features nix-command --extra-experimental-features flakes build .#docker 2>&1 | tee "/repo/nix-docker-build-${label}.log"
sha256sum result | tee "/repo/nix-docker-sha-${label}.txt"
du -h result | tee "/repo/nix-docker-size-${label}.txt"

if [[ "${label}" == "a" ]]; then
  cp -L result "/repo/quicknotes-nix-${label}.tar"
fi

cp -f flake.lock /repo/flake.lock
