# QuickNotes in GitHub Codespaces

Render requested card verification, so no payment method was added. Lab 10's Codespaces Option B is used.

The devcontainer configuration is [`.devcontainer/devcontainer.json`](../.devcontainer/devcontainer.json). It uses the official Ubuntu devcontainer base, Docker-in-Docker and SSH features, forwards TCP port 8080, and runs [the startup script](../.devcontainer/start-quicknotes.sh) on each Codespace start. The SSH feature enables the GitHub CLI to inspect the running container and collect logs.

The script pulls and runs `ghcr.io/sanyalikeit/devops-intro/quicknotes:v0.1.1`. It checks the container's image ID, starts an existing stopped container when possible, and recreates it only if the release image differs. It maps port 8080, sets `ADDR=0.0.0.0:8080`, `DATA_PATH=/data/notes.json`, and `SEED_PATH=/app/seed.json`. QuickNotes runs as UID 65532, so the persistent host directory `/workspaces/.quicknotes-lab10-data` is owned by that UID and mounted at `/data`. The runtime notes file stays outside the Git repository.

Port forwarding is declared in the devcontainer; public visibility must be set separately after creation. The verified Codespace was created with:

```bash
gh codespace create -R SanyaLikeIT/DevOps-Intro -b feature/lab10 \
  --devcontainer-path .devcontainer/devcontainer.json \
  --display-name quicknotes-lab10-verified --machine basicLinux32gb \
  --idle-timeout 30m --status
```

Generated name: `quicknotes-lab10-verified-xj5jj5797p4c9qr7`. The chosen machine has 2 cores, 8 GB RAM, and 32 GB storage. The first Codespace created during setup (`quicknotes-lab10-x5r7p5x9wwg3vjrp`) was stopped after an SSH feature issue; it is not the measured instance.

Port 8080 was made public with:

```bash
gh codespace ports visibility 8080:public -c quicknotes-lab10-verified-xj5jj5797p4c9qr7
gh codespace ports -c quicknotes-lab10-verified-xj5jj5797p4c9qr7 \
  --json sourcePort,browseUrl,visibility
```

The CLI returned `sourcePort=8080`, `visibility=public`, and `browseUrl=https://quicknotes-lab10-verified-xj5jj5797p4c9qr7-8080.app.github.dev`. Unauthenticated local-laptop `curl` requests to `/health` and `/notes` both returned HTTP 200. `docker inspect` inside the Codespace confirmed the exact immutable image, running state, and the `/workspaces/.quicknotes-lab10-data` bind mount. The Codespace logs confirmed that `postStartCommand` pulled the release image and started QuickNotes after a restart.

Each cold measurement used:

```bash
gh codespace stop -c quicknotes-lab10-verified-xj5jj5797p4c9qr7
gh api /user/codespaces/quicknotes-lab10-verified-xj5jj5797p4c9qr7 --jq .state
curl --max-time 30 -sS -o /tmp/lab10-stopped-body \
  -w '%{http_code} %{time_total}' \
  https://quicknotes-lab10-verified-xj5jj5797p4c9qr7-8080.app.github.dev/health
gh api --method POST /user/codespaces/quicknotes-lab10-verified-xj5jj5797p4c9qr7/start
```

After each manual start, port 8080 had reverted to private, so `gh codespace ports visibility 8080:public -c quicknotes-lab10-verified-xj5jj5797p4c9qr7` was run again. The timer stopped at the first unauthenticated public `/health` HTTP 200. Three raw cycle records are in [the cold-start evidence](../evidence/lab10/05-codespace-cold.txt).
