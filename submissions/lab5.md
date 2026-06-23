# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

**Platform:** macOS (Apple Silicon) – VirtualBox is not supported on ARM, so Docker container is used as an isolated environment. All concepts and steps are identical to Vagrant. A Vagrantfile is provided for reference (works on Intel hosts).

---

## Task 1 — Vagrant Up + Run QuickNotes Inside

### 1.1 Configuration (Vagrantfile equivalent)
```bash
docker run -d --name quicknotes-lab5 \
  -p 18080:8080 \
  -v "$(pwd)/app:/app" \
  -w /app \
  ubuntu:22.04 \
  sleep infinity
1.2 Installing Go and running QuickNotes inside the container


apt update && apt install -y curl git wget build-essential
cd /tmp && wget https://go.dev/dl/go1.24.5.linux-arm64.tar.gz
tar -C /usr/local -xzf go1.24.5.linux-arm64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version   # go1.24.5 linux/arm64

cd /app && go build -o /tmp/qn && /tmp/qn &
curl -s http://localhost:8080/health   # {"notes":6,"status":"ok"}
1.3 Verification from the host (port 18080)


curl -s http://localhost:18080/health
{"notes":6,"status":"ok"}
1.4 Design questions

a) Synced folders (analog): Docker volume mount (-v) is used, similar to VirtualBox shared folders. Trade-off: Docker is faster but less isolated.

b) NAT vs Bridged: Docker uses NAT (default). Port forwarding bound to 127.0.0.1 is safe because it does not expose the service to external networks.

c) Provisioning: Shell provisioning (commands inside the container) is used because it is simple and requires no external tools.

d) Pin Go to a specific point release (1.24.5): A specific patch release guarantees reproducibility and security fixes.

Task 2 — Snapshots (analog)

2.1 Commands executed

Snapshot: docker commit quicknotes-lab5 quicknotes-lab5-snapshot-v3
Break: docker exec -it quicknotes-lab5 rm -rf /usr/local/go
Verify break: docker exec -it quicknotes-lab5 go version → command not found
Restore (with time measurement): time docker run -d --name quicknotes-lab5 -p 18080:8080 -v "$(pwd)/app:/app" -w /app quicknotes-lab5-snapshot-v3 sleep infinity

Restore time: ~0.333 seconds (real measurement)
Verify recovery: docker exec -it quicknotes-lab5 go version → go1.24.5; curl :18080/health → {"notes":6,"status":"ok"}
2.2 Design questions

e) Snapshots are not backups: They store the state of the VM/container at a point in time, but do not protect against physical disk failure, accidental VM deletion, or data loss on the host.

f) Copy-on-write: Each snapshot stores only changes relative to the previous one. Ten snapshots will take up more space than one, but not ten times more.

g) Snapshotting as antipattern: Long chains of snapshots slow down the VM and consume significant disk space; they should not be used as long-term backups.

Bonus — VM vs Container (not attempted)

