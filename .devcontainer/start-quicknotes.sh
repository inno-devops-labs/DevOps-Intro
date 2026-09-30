#!/usr/bin/env bash
set -euo pipefail

image=ghcr.io/sanyalikeit/devops-intro/quicknotes:v0.1.1
container=quicknotes-lab10
data_dir=/workspaces/.quicknotes-lab10-data

for attempt in {1..60}; do
  if docker info >/dev/null 2>&1; then break; fi
  sleep 2
done
docker info >/dev/null
docker pull "$image"

sudo mkdir -p "$data_dir"
sudo chown 65532:65532 "$data_dir"
sudo chmod 0755 "$data_dir"

expected_id=$(docker image inspect --format '{{.Id}}' "$image")
if docker container inspect "$container" >/dev/null 2>&1; then
  actual_id=$(docker container inspect --format '{{.Image}}' "$container")
  if [[ "$actual_id" != "$expected_id" ]]; then
    docker rm -f "$container"
  fi
fi

if ! docker container inspect "$container" >/dev/null 2>&1; then
  docker run -d \
    --name "$container" \
    --restart unless-stopped \
    -p 8080:8080 \
    -e ADDR=0.0.0.0:8080 \
    -e DATA_PATH=/data/notes.json \
    -e SEED_PATH=/app/seed.json \
    --mount "type=bind,source=$data_dir,target=/data" \
    "$image"
elif [[ "$(docker inspect --format '{{.State.Running}}' "$container")" != true ]]; then
  docker start "$container"
fi

for attempt in {1..60}; do
  if curl -fsS http://127.0.0.1:8080/health >/dev/null; then
    docker ps --filter "name=^/${container}$" --format 'QuickNotes running: {{.Image}} {{.Status}}'
    exit 0
  fi
  sleep 2
done

docker logs "$container"
exit 1
