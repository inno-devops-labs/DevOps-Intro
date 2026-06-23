# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  config.vm.box      = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest:   8080,
    host:    18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    set -euo pipefail
    GO_VERSION="1.24.5"
    GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
    GO_URL="https://go.dev/dl/${GO_TARBALL}"

    if /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      echo "Go ${GO_VERSION} already installed, skipping."
      exit 0
    fi

    echo ">>> Installing Go ${GO_VERSION}..."
    apt-get update -qq
    apt-get install -y -qq wget ca-certificates

    wget -q "${GO_URL}" -O "/tmp/${GO_TARBALL}"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
    rm "/tmp/${GO_TARBALL}"

    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
    chmod +x /etc/profile.d/golang.sh

    /usr/local/go/bin/go version
    echo ">>> Go installed successfully."
  SHELL
end
```

### First 10 lines of `vagrant up`

```
[OUTPUT]
```

### `curl` from inside the VM

```bash
vagrant ssh -c 'cd /home/vagrant/app && /usr/local/go/bin/go build -o /tmp/qn . && /tmp/qn &'
vagrant ssh -c 'sleep 2 && curl -s http://localhost:8080/health'
```

```
[OUTPUT]
```

### `curl` from the host (via port forward)

```bash
curl -s http://localhost:18080/health
```

```
[OUTPUT]
```

### Design Questions

**a) Synced folders — which type and why?**

I used VirtualBox shared folders (the Vagrant default — no `type:` argument needed). This is the simplest option: the `ubuntu/jammy64` box ships with VirtualBox Guest Additions pre-installed, so no extra setup is required. The trade-off is I/O speed: VirtualBox shared folders are slower than NFS, especially for many small files or intensive file-watching workloads, because every filesystem call crosses the host–guest boundary through the VirtualBox kernel module. NFS would be faster but requires an NFS daemon on the host and `root`-level NFS exports, which adds friction for a course lab. `rsync` would be unidirectional (host → guest only) and would not reflect in-guest changes back to the host without `vagrant rsync-auto`.

**b) NAT vs Bridged vs Host-only — which network mode?**

Vagrant's default network mode is **NAT**. The VM gets a private address (typically `10.0.2.x`) that is not reachable from the outside, and all outbound traffic is masqueraded through the host. Port forwarding (`guest: 8080 → host: 18080`) punches a hole, but binding it to `host_ip: "127.0.0.1"` means the forwarded port is only reachable from the host machine itself (localhost), not from other machines on the local network. A Bridged interface would assign the VM its own LAN IP, exposing the QuickNotes service to every device on the same subnet — a security risk on shared or public networks (cafés, university Wi-Fi).

**c) Provisioning — which tool and why?**

I used the **Shell provisioner** (`config.vm.provision "shell"`). It ships built-in with Vagrant and requires zero extra tools on the host. For the single task of downloading and installing Go, a shell script is the most transparent and straightforward choice: any developer can read and verify it without knowing Ansible YAML or Chef DSL. Ansible is a much better fit for multi-role deployments (Lab 7 uses it for exactly that purpose), but for a one-step Go install it would be over-engineering.

**d) Why pin Go to a specific point release (`1.24.5`) instead of `1.24`?**

Go's official download server (`go.dev/dl/`) does not serve a floating tag like `go1.24.linux-amd64.tar.gz` — the URL requires a full three-part version such as `go1.24.5.linux-amd64.tar.gz`. More importantly, pinning ensures **reproducibility**: every student who clones the repo and runs `vagrant up` downloads the exact same binary regardless of when they run it. A floating minor version would silently pull in a different patch at different times, breaking the guarantee that the lab environment is identical across machines and over time. This is the same principle behind `go.sum` — the ecosystem pins hashes, not floating labels.

---

## Task 2 — Snapshots: Save, Break, Restore

### Commands run

**1. Take a clean snapshot after the app is running:**

```bash
vagrant snapshot save clean-go-install
```

```
[OUTPUT]
```

**2. Break the VM — wipe the Go installation:**

```bash
vagrant ssh -c 'sudo rm -rf /usr/local/go && sudo rm -f /etc/profile.d/golang.sh'
```

**3. Verify it's broken:**

```bash
vagrant ssh -c 'go version'
```

```
[OUTPUT — expected: "go: command not found" or similar error]
```

**4. Restore from the snapshot (timed):**

```bash
time vagrant snapshot restore clean-go-install
```

```
[OUTPUT including real/user/sys time]
```

**5. Verify recovery:**

```bash
vagrant ssh -c 'go version'
```

```
[OUTPUT — expected: go1.24.5 linux/amd64]
```

### Design Questions

**e) Snapshots are not backups — why?**

A snapshot lives on the same physical disk as the VM it protects. If the host's storage device fails (disk crash, RAID failure, accidental `rm -rf ~/VirtualBox\ VMs/`), the snapshot is destroyed along with the base disk — there is nothing to restore from. Snapshots also don't protect against logical failures that occurred *before* the snapshot was taken (silent data corruption, malware, a bad migration), and they provide no off-site copy. A true backup must be stored on a separate medium or location, and must be periodically tested by performing an actual restore.

**f) Copy-on-write disk usage with 10 snapshots vs 1:**

VirtualBox snapshots use a differencing (CoW) disk chain. When you take a snapshot, VirtualBox freezes the current `.vdi` and creates a new differencing disk for subsequent writes. With one snapshot, only blocks actually modified after the snapshot are stored in the delta file — initial cost is near zero. With 10 snapshots in a chain, every write creates a new delta entry in the most recent differencing disk, and reading any block may require walking back through the entire chain to find the newest version of it. Disk usage grows with the total amount of data changed across all layers combined; I/O overhead also grows linearly with chain depth.

**g) When is snapshotting an antipattern?**

Long snapshot chains are an antipattern in production because read performance degrades with each additional layer: VirtualBox must traverse every differencing disk in the chain to assemble the current block. For a VM that has accumulated dozens of snapshots over months, disk I/O can slow dramatically. Snapshotting is also an antipattern when it replaces *immutable infrastructure* thinking: if the VM is treated as a pet (never rebuilt from code, only snapshot-and-pray), the snapshot chain becomes the sole safety net — and it lives on the same host. The correct solution for production is cattle-style replacement from a versioned provisioning script (like the Vagrantfile itself) rather than preserving a fragile long-lived VM state.

---

## Bonus — VM vs Container Resource Baseline

### Measurements

**Vagrant VM (idle, after `vagrant up` with provisioning done):**

```bash
time vagrant halt && time vagrant up --no-provision   # cold boot only
vagrant ssh -c 'free -h'
vagrant ssh -c 'ps -A --no-headers | wc -l'
du -sh ~/VirtualBox\ VMs/quicknotes-vm/
```

**Docker container (same QuickNotes):**

```bash
docker run -d --name qn-bench -p 28080:8080 \
  -v "$PWD/app:/src" -w /src golang:1.24 \
  sh -c 'go build -o /tmp/qn && /tmp/qn'

docker stop qn-bench && time docker start qn-bench
docker stats qn-bench --no-stream
docker top qn-bench
docker images golang:1.24 --format '{{.Size}}'
```

### Comparison Table

| Dimension             | Vagrant VM | Docker container |
|-----------------------|-----------:|-----------------:|
| Cold start            |          ? |                ? |
| Idle RAM              |          ? |                ? |
| On-disk size          |          ? |                ? |
| Process count (guest) |          ? |                ? |

### Analysis

[4-5 sentences to be filled in after running the measurements above. Expected observations: the VM cold start takes 30-60 seconds vs under 1 second for a stopped container; idle RAM will be ~200-400 MB for the VM (full kernel + init system) vs ~10-30 MB for the container; the Ubuntu box image is several GB vs ~1 GB for golang:1.24; process count in the VM will be 80-120 (full OS) vs 3-5 in the container. The data explains why containers became dominant for stateless microservices: faster startup, lower memory density, and a much smaller on-disk footprint enable far higher process density per host.]
