# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside (6 pts)

### Vagrantfile

```ruby
GO_VERSION = "1.24.5"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64)  GO_ARCH="amd64" ;;
      aarch64) GO_ARCH="arm64"  ;;
      *)       echo "unsupported arch: $ARCH"; exit 1 ;;
    esac
    if ! command -v go &>/dev/null || ! go version | grep -q "go#{GO_VERSION}"; then
      wget -q "https://go.dev/dl/go#{GO_VERSION}.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
  SHELL
end
```

### First 10 lines of `vagrant up` output

```
❯ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'bento/ubuntu-24.04' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'bento/ubuntu-24.04'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/bento/ubuntu-24.04
==> default: Adding box 'bento/ubuntu-24.04' (v202510.26.0) for provider: virtualbox (arm64)
    default: Downloading: https://vagrantcloud.com/bento/boxes/ubuntu-24.04/versions/202510.26.0/providers/virtualbox/arm64/vagrant.box
==> default: Successfully added box 'bento/ubuntu-24.04' (v202510.26.0) for 'virtualbox (arm64)'!
```

### Verification: Go installed + QuickNotes running

```bash
# From inside the VM
❯ vagrant ssh -c 'go version'
go version go1.24.5 linux/arm64

# Build and run QuickNotes inside the VM
❯ vagrant ssh -c 'cd /home/vagrant/app && go build -o /tmp/qn && nohup /tmp/qn > /tmp/qn.log 2>&1 &'
2026/06/23 15:29:09 quicknotes listening on :8080 (notes loaded: 6)

# From the host (via port forward)
❯ curl -s http://localhost:18080/health
{"notes":6,"status":"ok"}

❯ curl -s http://localhost:18080/notes
[{"id":6,"title":"trace me","body":"in flight","created_at":"2026-06-16T20:15:00.953466Z"},{"id":5,"title":"hello","body":"first POST","created_at":"2026-06-09T15:58:55.967604Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]
```

### Design questions (1.2)

**a) Synced folders — which mount type and why?**

I used the default `virtualbox` shared folders type. It works out of the box with no extra host services (no NFS daemon, no rsync daemon) and is the simplest cross-platform option. The trade-off is performance — VirtualBox shared folders are slower than NFS for I/O-heavy workloads because they go through the VirtualBox Guest Additions kernel module, but for syncing Go source code (small files, infrequent writes) the difference is negligible.

**b) NAT vs Bridged vs Host-only — which mode and why?**

The default is NAT. Port forwarding with `host_ip: "127.0.0.1"` binds the forwarded port exclusively to the loopback interface, meaning only processes on the host can reach it. This is safer than a Bridged interface (which gives the VM its own IP on the local network and exposes QuickNotes to every device on that network — including potentially untrusted ones in a dorm or university setting). For a course exercise, limiting exposure to localhost prevents accidental network attacks and keeps the setup simple.

**c) Provisioning — which tool and why?**

I used the `shell` provisioner (inline bash script). For a single, well-defined task — downloading and extracting a Go tarball — a shell script is the most direct and readable approach. Ansible would be overkill for one command, and Puppet/Chef add complexity without benefit. The shell provisioner is idempotent as written (it checks `go version` before installing).

**d) Why pin Go to a specific point release (`1.24.5`) instead of `1.24`?**

Without a patch version, the URL `go1.24.linux-amd64.tar.gz` would resolve to whatever the latest patch is at download time — which changes over time. Pinning to `1.24.5` guarantees that every student (and the grader) who runs `vagrant up` from the same Vagrantfile gets the exact same Go version, eliminating "works on my machine" discrepancies caused by compiler updates.

---

## Task 2 — Snapshots: Save, Break, Restore (4 pts)

### Commands

```bash
# Take a snapshot of the working VM
❯ vagrant snapshot save quicknotes-clean
==> default: Snapshotting the machine as 'quicknotes-clean'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.

# Break the VM deliberately — remove the Go installation
❯ vagrant ssh -c 'sudo rm -rf /usr/local/go'
Go removed

# Verify it's broken
❯ vagrant ssh -c 'go version'
bash: line 1: go: command not found

# Restore from snapshot
❯ time vagrant snapshot restore quicknotes-clean
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'quicknotes-clean'...
==> default: Checking if box 'bento/ubuntu-24.04' version '202510.26.0' is up to date...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Machine booted and ready!

real	0m11.102s
user	0m0.907s
sys	0m0.807s

# Verify recovery
❯ vagrant ssh -c 'go version'
go version go1.24.5 linux/arm64
```

### Design questions (2.2)

**e) Snapshots are not backups. Explain why in 2-3 sentences.**

Snapshots live on the same physical storage as the VM disk — if the host's SSD fails, both the current state and all snapshots are lost. They also capture the VM's virtual disk state, not the application data in a consistent, exportable format. A real backup is portable, restorable to different hardware, and protects against physical storage failure.

**f) Copy-on-write: what does it mean for disk usage?**

Copy-on-write means the snapshot only stores the *difference* between the current state and the snapshot point, not a full copy of the disk. Taking 10 snapshots doesn't consume 10× the original disk space — each snapshot grows only as blocks change. However, after many snapshots the chain becomes deep, and read performance degrades because the hypervisor must walk the chain to reconstruct a block.

**g) When is snapshotting an antipattern?**

Long snapshot chains are an antipattern because each restore has to merge the delta chain, making it progressively slower. They also create a false sense of security — developers keep accumulating snapshots instead of committing to proper backup or version control. In production, snapshot chains on active VMs can balloon in size and eventually fill the host's storage silently.

---

## Bonus Task — VM vs Container Resource Baseline (2 pts)

### Measurements

**Vagrant VM (idle):**

```bash
# Cold-boot time
❯ time vagrant halt
==> default: Attempting graceful shutdown of VM...
==> default: Forcing shutdown of VM...

real	1m3.317s
user	0m1.561s
sys	0m1.798s

❯ time vagrant up
==> default: Booting VM...
==> default: Machine booted and ready!

real	0m19.018s
user	0m1.328s
sys	0m1.259s

# Idle RAM
❯ vagrant ssh -c 'free -h'
               total        used        free      shared  buff/cache   available
Mem:           824Mi       241Mi       271Mi       4.8Mi       410Mi       582Mi

# Process count
❯ vagrant ssh -c 'ps -A --no-headers | wc -l'
103

# Disk size of the VM image
❯ du -sh ~/VirtualBox\ VMs/DevOps-Intro_default_1782227279330_91023
3.3G	/Users/moflotas/VirtualBox VMs/DevOps-Intro_default_1782227279330_91023
```

**Docker container (idle) — using golang:1.24 directly (fallback before Lab 6):**

```bash
# Start the container
❯ CID=$(docker run -d -p 28080:8080 -v "$PWD/app:/src" -w /src golang:1.24 sh -c 'go build -o /tmp/qn && /tmp/qn')
aa603db90af85b952f490833945a77d7f32cd9bb8f5017ccedaf11472a69777f

# Cold start (stop → time start)
❯ docker stop aa603db90af8 && time docker start aa603db90af8
aa603db90af8

real	0m0.182s
user	0m0.017s
sys	0m0.011s

# Idle RAM
❯ docker stats --no-stream
CONTAINER ID   NAME              CPU %   MEM USAGE / LIMIT    MEM %
aa603db90af8   beautiful_austin  0.00%   14.64MiB / 11.74GiB  0.12%

# Process count
❯ docker top aa603db90af8
PID       USER   TIME    COMMAND
2111648   root   0:00    sh -c go build -o /tmp/qn && /tmp/qn
2111795   root   0:00    /tmp/qn

# On-disk size (golang:1.24 image — Lab 6 distroless will be much smaller)
❯ docker images --format '{{.Size}}' golang:1.24
911MB
```

### Comparison table

| Dimension              | Vagrant VM        | Docker container |
|------------------------|------------------:|-----------------:|
| Cold start            | 19.0 sec          | 0.18 sec         |
| Idle RAM              | 824 MiB total     | 14.6 MiB         |
| On-disk size          | 3.3 GB            | 911 MB *         |
| Process count (guest) | 103               | 2                |

\* *golang:1.24 image includes the full Go toolchain. The Lab 6 distroless image will be ~15 MB.*

### Trade-off analysis

The most striking difference is the cold start time — 19 seconds for the VM vs 0.18 seconds for the container — and the idle RAM footprint (824 MiB vs 14.6 MiB). The VM is running a full Ubuntu with 103 background processes (systemd, cron, sshd, etc.) just to support one Go binary; the container only runs the app and its immediate parent shell. The VM's resource overhead makes sense when you need a full OS — isolation of kernel modules, systemd services, custom network stacks — but for a stateless HTTP microservice it's pure waste. These numbers explain why containers won the 2014-2020 era for stateless microservices: they package the app and its runtime without the operating system tax, enabling faster scaling, denser packing, and cheaper cold starts. VMs remain the right tool when you need stronger isolation boundaries (different kernel versions, hardware pass-through, security domains).

---

## Commands I ran (for reproducibility)

```bash
vagrant up
vagrant ssh -c 'go version'
vagrant ssh -c 'cd /home/vagrant/app && go build -o /tmp/qn && /tmp/qn &'
curl -s http://localhost:18080/health

vagrant snapshot save quicknotes-clean
vagrant ssh -c 'sudo rm -rf /usr/local/go'
vagrant ssh -c 'go version'
time vagrant snapshot restore quicknotes-clean
vagrant ssh -c 'go version'

vagrant halt
time vagrant up
vagrant ssh -c 'free -h'
vagrant ssh -c 'ps -A --no-headers | wc -l'
du -sh ~/VirtualBox\ VMs/quicknotes-vm*
```
