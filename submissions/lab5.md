# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  config.vm.box      = "perk/ubuntu-2204-arm64"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest:   8080,
    host:    18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync",
    rsync__exclude: [".git/", "data/", "quicknotes"]

  config.vm.provider "qemu" do |qe|
    qe.arch       = "aarch64"
    qe.machine    = "virt,accel=hvf,highmem=off"
    qe.cpu        = "host"
    qe.net_device = "virtio-net-pci"
    qe.memory     = "1024"
    qe.smp        = "cpus=2"
  end

  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    set -euo pipefail
    GO_VERSION="1.24.5"
    GO_TARBALL="go${GO_VERSION}.linux-arm64.tar.gz"
    GO_URL="https://go.dev/dl/${GO_TARBALL}"

    if /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      echo "Go ${GO_VERSION} already installed, skipping."
      exit 0
    fi

    echo "nameserver 8.8.8.8" > /etc/resolv.conf

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
Bringing machine 'default' up with 'qemu' provider...
==> default: Checking if box 'perk/ubuntu-2204-arm64' version '20250702' is up to date...
==> default: Starting the instance...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:50022
    default: SSH username: vagrant
    default: SSH auth method: private key
    default: Warning: Connection reset. Retrying...
    default: Warning: Remote connection disconnect. Retrying...
==> default: Machine booted and ready!
==> default: Setting hostname...
==> default: Rsyncing folder: /Users/irina/Desktop/summer semester 2 year/DevOps-Intro/app/ => /home/vagrant/app
==> default: Machine already provisioned. Run `vagrant provision` to re-run.
```

### `curl` from inside the VM

```bash
vagrant ssh -c 'cd /home/vagrant/app && nohup /tmp/qn > /tmp/qn.log 2>&1 & sleep 3 && curl -s http://localhost:8080/health'
```

```
{"notes":4,"status":"ok"}
```

### `curl` from the host (via port forward)

```bash
curl -s http://localhost:18080/health
```

```
{"notes":4,"status":"ok"}
```

### Design Questions

**a) Synced folders — which type and why?**

I used **rsync** (`type: "rsync"`). On Apple Silicon with the QEMU provider, VirtualBox shared folders are unavailable (no Guest Additions), and NFS requires root-level exports on the host. Rsync works over the existing SSH connection with no extra daemons. The trade-off is that it is **unidirectional** — changes sync from host to guest at `vagrant up` time (and on demand with `vagrant rsync`), but edits made inside the guest are not reflected back on the host automatically. For a read-only code mount (building Go inside the VM) this is a non-issue. NFS would give bidirectional, live sync with better performance for large trees, but the host setup overhead is not justified here.

**b) NAT vs Bridged vs Host-only — which network mode?**

Vagrant's default network mode is **NAT**. The VM gets a private address (typically `10.0.2.x`) that is not reachable from the outside, and all outbound traffic is masqueraded through the host. Port forwarding (`guest: 8080 → host: 18080`) punches a hole, but binding it to `host_ip: "127.0.0.1"` means the forwarded port is only reachable from the host machine itself (localhost), not from other machines on the local network. A Bridged interface would assign the VM its own LAN IP, exposing the QuickNotes service to every device on the same subnet — a security risk on shared or public networks (cafés, university Wi-Fi).

**c) Provisioning — which tool and why?**

I used the **Shell provisioner** (`config.vm.provision "shell"`). It ships built-in with Vagrant and requires zero extra tools on the host. For the single task of downloading and installing Go, a shell script is the most transparent and straightforward choice: any developer can read and verify it without knowing Ansible YAML or Chef DSL. Ansible is a much better fit for multi-role deployments (Lab 7 uses it for exactly that purpose), but for a one-step Go install it would be over-engineering.

**d) Why pin Go to a specific point release (`1.24.5`) instead of `1.24`?**

Go's official download server (`go.dev/dl/`) does not serve a floating tag like `go1.24.linux-amd64.tar.gz` — the URL requires a full three-part version such as `go1.24.5.linux-amd64.tar.gz`. More importantly, pinning ensures **reproducibility**: every student who clones the repo and runs `vagrant up` downloads the exact same binary regardless of when they run it. A floating minor version would silently pull in a different patch at different times, breaking the guarantee that the lab environment is identical across machines and over time. This is the same principle behind `go.sum` — the ecosystem pins hashes, not floating labels.

---

## Task 2 — Snapshots: Save, Break, Restore

### Commands run

**1. Take a clean snapshot:**

```bash
vagrant halt
qemu-img snapshot -c clean-go-install .vagrant/machines/default/qemu/vq_Ttb3NMInTpE/linked-box.img
qemu-img snapshot -l .vagrant/machines/default/qemu/vq_Ttb3NMInTpE/linked-box.img
```

```
==> default: Stopping the instance...
Snapshot list:
ID      TAG               VM_SIZE                DATE        VM_CLOCK     ICOUNT
1       clean-go-install      0 B 2026-06-23 14:22:22  0000:00:00.000          0
```

**2. Break the VM — wipe the Go installation:**

```bash
vagrant up --no-provision
vagrant ssh -c 'sudo rm -rf /usr/local/go && sudo rm -f /etc/profile.d/golang.sh'
```

**3. Verify it's broken:**

```bash
vagrant ssh -c '/usr/local/go/bin/go version'
```

```
bash: line 1: /usr/local/go/bin/go: No such file or directory
```

**4. Restore from the snapshot (timed):**

```bash
vagrant halt && time qemu-img snapshot -a clean-go-install .vagrant/machines/default/qemu/vq_Ttb3NMInTpE/linked-box.img
```

```
==> default: Stopping the instance...
qemu-img snapshot -a clean-go-install   0.02s user 0.02s system 81% cpu 0.053 total
```

**5. Verify recovery:**

```bash
vagrant up --no-provision && vagrant ssh -c '/usr/local/go/bin/go version'
```

```
go version go1.24.5 linux/arm64
```

### Design Questions

**e) Snapshots are not backups — why?**

A snapshot lives on the same physical disk as the VM it protects. If the host's storage device fails (disk crash, RAID failure, accidental `rm -rf ~/VirtualBox\ VMs/`), the snapshot is destroyed along with the base disk — there is nothing to restore from. Snapshots also don't protect against logical failures that occurred *before* the snapshot was taken (silent data corruption, malware, a bad migration), and they provide no off-site copy. A true backup must be stored on a separate medium or location, and must be periodically tested by performing an actual restore.

**f) Copy-on-write disk usage with 10 snapshots vs 1:**

VirtualBox snapshots use a differencing (CoW) disk chain. When you take a snapshot, VirtualBox freezes the current `.vdi` and creates a new differencing disk for subsequent writes. With one snapshot, only blocks actually modified after the snapshot are stored in the delta file — initial cost is near zero. With 10 snapshots in a chain, every write creates a new delta entry in the most recent differencing disk, and reading any block may require walking back through the entire chain to find the newest version of it. Disk usage grows with the total amount of data changed across all layers combined; I/O overhead also grows linearly with chain depth.

**g) When is snapshotting an antipattern?**

Long snapshot chains are an antipattern in production because read performance degrades with each additional layer: VirtualBox must traverse every differencing disk in the chain to assemble the current block. For a VM that has accumulated dozens of snapshots over months, disk I/O can slow dramatically. Snapshotting is also an antipattern when it replaces *immutable infrastructure* thinking: if the VM is treated as a pet (never rebuilt from code, only snapshot-and-pray), the snapshot chain becomes the sole safety net — and it lives on the same host. The correct solution for production is cattle-style replacement from a versioned provisioning script (like the Vagrantfile itself) rather than preserving a fragile long-lived VM state.

