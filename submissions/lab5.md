# Lab 5 submission

**Note on tooling:** HashiCorp restricted access to `releases.hashicorp.com` for my region (HTTP 403 "Content not available in your region"), making Vagrant and the Vagrant Cloud boxes undownloadable through normal channels. I obtained Vagrant 2.4.9 via VPN and used **UTM** (with the `vagrant_utm` plugin) as the virtualization provider — VirtualBox does not run on Apple Silicon (M-series) Macs. All Task 1 and Task 2 requirements were met with this stack.

## Task 1 — Vagrant Up + Run QuickNotes Inside

### 1.1 — Vagrantfile

File: [Vagrantfile](../Vagrantfile) at the repo root.

```ruby
# Vagrantfile — Lab 5: QuickNotes in a Ubuntu VM
Vagrant.configure("2") do |config|
  # 1. Box: Ubuntu 24.04 LTS ARM64
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_architecture = "arm64"

  # 2. Hostname
  config.vm.hostname = "quicknotes-vm"

  # 3. Port forwarding: host 127.0.0.1:18080 → guest :8080
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  # 4. Synced folder: ./app → /home/vagrant/app
  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  # 5. Resources: 2 vCPU + 1 GB RAM
  config.vm.provider "utm" do |utm|
    utm.name = "quicknotes-vm"
    utm.memory = 1024
    utm.cpus = 2
  end

  # 6. Provisioning: install Go 1.24.5
  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    GO_VERSION="1.24.5"
    ARCH="arm64"
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tgz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tgz
    rm /tmp/go.tgz
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    chmod +x /etc/profile.d/go.sh
    grep -q '/usr/local/go/bin' /home/vagrant/.bashrc || \
      echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/vagrant/.bashrc
    /usr/local/go/bin/go version
  SHELL
end
```

### 1.2 — First 10 lines of `vagrant up` output

```
Bringing machine 'default' up with 'utm' provider...
==> default: Checking if box 'bento/ubuntu-24.04' version '202510.26.0' is up to date...
==> default: Setting the name of the VM: quicknotes-vm
==> default: Clearing any previously set forwarded ports...
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
```

The very first `vagrant up` also downloaded the box image and ran the provisioner:

```
==> default: Successfully added box 'bento/ubuntu-24.04' (v202510.26.0) for 'utm (arm64)'!
==> default: Importing base box 'bento/ubuntu-24.04'...
...
    default: go version go1.24.5 linux/arm64
```

### 1.3 — QuickNotes reachable from host

**From inside the VM:**
```
$ vagrant ssh -c '/usr/local/go/bin/go version'
go version go1.24.5 linux/arm64

$ vagrant ssh -c 'cd /home/vagrant/app && /usr/local/go/bin/go build -o /tmp/qn . && (nohup /tmp/qn > /tmp/qn.log 2>&1 &) && sleep 2 && curl -s http://localhost:8080/health'
{"notes":6,"status":"ok"}
```

**From the host Mac (via port forward 18080 → 8080):**
```
$ curl -s http://localhost:18080/health | jq
{
  "notes": 6,
  "status": "ok"
}

$ curl -s -X POST http://localhost:18080/notes \
    -H 'Content-Type: application/json' \
    -d '{"title":"from host","body":"via port forward"}' | jq
{
  "id": 7,
  "title": "from host",
  "body": "via port forward",
  "created_at": "2026-09-25T11:08:32.900831663Z"
}
```

The POST proves the port forward is bidirectional — a request from the host reaches the guest's QuickNotes instance and the response returns through the same tunnel.

### 1.2 — Design questions

**a) Synced folder type — which and why?**

I picked **`rsync`** (one-way, host → guest). Reasons: (1) `nfs` requires running an NFS server on the macOS host, which is fiddly and often conflicts with VPN/firewall rules; (2) `virtualbox` shared folders are not available because we don't use VirtualBox; (3) `smb` requires Samba on macOS with credentials. `rsync` needs nothing — Vagrant syncs on `up`/`reload`/`provision` and the guest sees a normal directory. **Trade-off:** rsync is one-way and only runs when Vagrant triggers it. Changes made *inside the VM* to `/home/vagrant/app` do not flow back to the host. For this lab (source code is edited on the host, built inside the VM) that's exactly the desired direction. If I needed bidirectional sync, `nfs` would be the next choice — at the cost of host-side setup.

**b) NAT vs Bridged vs Host-only — which mode, and why is 127.0.0.1-bound forwarding safer?**

Vagrant's default (and ours) is **NAT** — the VM sits behind a private virtual NAT provided by UTM/QEMU, and the host reaches services through explicitly forwarded ports. Binding the forwarded port to `127.0.0.1` means the port is only reachable **from this Mac** — not from the LAN, not from coffee-shop Wi-Fi, not from any other device. A **Bridged** interface would give the VM its own IP on the physical LAN, which means the unauthenticated QuickNotes API (`:8080`) would be exposed to every device on the network — trivial for a classmate or attacker to hit. For a course exercise where security isn't the point, `127.0.0.1` is the minimum-effort way to keep the surface area tiny.

**c) Provisioning option — which and why?**

I used the built-in **`shell` provisioner** with an inline bash script. Reasons: (1) this is a single, short, imperative task (download Go tarball, extract to `/usr/local`, add to PATH) — `ansible`/`puppet`/`chef` would add an external dependency and a learning curve for zero gain; (2) `shell` runs on the first `vagrant up` and on `vagrant provision` — idempotency is trivial here because we `rm -rf /usr/local/go` before extracting; (3) Lab 7 will introduce Ansible properly, so using it *here* would spoil the pedagogical build-up. The trade-off is that `shell` is not idempotent by default — it's on the author to make the script safe to re-run. My script satisfies that: `rm -rf /usr/local/go` before unpacking, and `grep -q ... || echo ...` for the `.bashrc` line.

**d) Why pin Go to a specific point release (1.24.5) and not 1.24?**

`1.24` is not a real version — it's a shorthand. Go releases are `1.24.0`, `1.24.1`, `1.24.2`, …, `1.24.5`. If we wrote `1.24` in the download URL (`https://go.dev/dl/go1.24.linux-arm64.tar.gz`), the URL would 404. But the deeper reason is **reproducibility**: pinning `1.24.5` means the same `vagrant up` on another machine produces the same compiler, the same standard library, and the same test outcomes. If we instead fetched "latest 1.24.x" every time, a bug on 1.24.6 released tomorrow would silently make our build different from the one described here. This is the exact same principle as SHA-pinning GitHub Actions in Lab 3 — **immutable references for reproducible builds**.

## Task 2 — Snapshots: Save, Break, Restore

### 2.1 — Snapshot lifecycle

**1. Save the snapshot (VM must be halted — `qemu-img` requires offline access):**
```
$ vagrant halt
==> default: Attempting graceful shutdown of VM...

$ vagrant snapshot save clean
==> default: Snapshotting the machine as 'clean'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.

$ vagrant snapshot list
==> default:
clean
```

**2. Bring the VM back up and confirm the healthy state:**
```
$ vagrant up --provider=utm
...
$ vagrant ssh -c '/usr/local/go/bin/go version'
go version go1.24.5 linux/arm64

$ vagrant ssh -c 'cd /home/vagrant/app && /usr/local/go/bin/go build -o /tmp/qn . && (nohup /tmp/qn > /tmp/qn.log 2>&1 &) && sleep 2 && curl -s http://localhost:8080/health'
{"notes":6,"status":"ok"}
```

**3. Break it on purpose — remove the Go toolchain and stop QuickNotes:**
```
$ vagrant ssh -c 'sudo rm -rf /usr/local/go && sudo rm -f /etc/profile.d/go.sh'
$ vagrant ssh -c 'pkill -f /tmp/qn || true; sleep 1'
```

**4. Verify it's actually broken:**
```
$ vagrant ssh -c '/usr/local/go/bin/go version 2>&1 || echo "Go is gone"'
bash: line 1: /usr/local/go/bin/go: No such file or directory
Go is gone

$ vagrant ssh -c 'curl -s -m 3 http://localhost:8080/health || echo "QuickNotes is unreachable"'
QuickNotes is unreachable

$ curl -s -m 3 http://localhost:18080/health || echo "From host: QuickNotes is unreachable"
From host: QuickNotes is unreachable
```

**5. Restore (with timing) — VM must again be halted first:**
```
$ vagrant halt
==> default: Attempting graceful shutdown of VM...

$ time vagrant snapshot restore clean
==> default: Restoring the snapshot 'clean'...
==> default: Booting VM...
==> default: Machine booted and ready!
...
vagrant snapshot restore clean  1,92s user 0,85s system 11% cpu 24,050 total
```

**Restore time: 24.05 seconds.**

**6. Verify recovery:**
```
$ vagrant ssh -c '/usr/local/go/bin/go version'
go version go1.24.5 linux/arm64

$ vagrant ssh -c 'cd /home/vagrant/app && /usr/local/go/bin/go build -o /tmp/qn . && (nohup /tmp/qn > /tmp/qn.log 2>&1 &) && sleep 2 && curl -s http://localhost:8080/health'
{"notes":6,"status":"ok"}

$ curl -s http://localhost:18080/health | jq
{
  "notes": 6,
  "status": "ok"
}
```

Go is back, QuickNotes is serving again, and the port forward works. The whole cycle — from "Go is gone" to "status: ok" — completed in under half a minute.

### 2.2 — Design questions

**e) Snapshots are not backups — why?**

A snapshot lives **inside the same VM/host storage** as the thing it protects. If the host disk dies, the VirtualBox/UTM data directory is corrupted, or the snapshot chain is lost, the snapshot is gone along with the VM. Snapshots also don't help against: (1) **ransomware** that encrypts the entire host filesystem including snapshot files; (2) **accidental deletion of the host VM directory** (`rm -rf ~/Library/Containers/com.utmapp.UTM/Data`); (3) **hardware failure** of the disk. A real backup lives on a **different physical device** (or offsite / different cloud region) and is periodically **verified by restoring it**. Snapshots are a *convenience tool for short-term rollback*, not a durability guarantee.

**f) Copy-on-write — what does it mean for disk usage with 10 snapshots vs 1?**

Snapshots in VirtualBox and QEMU use copy-on-write (COW): when the VM is running, any block that changes is written to a **new** location (the "delta"), and the snapshot keeps pointing at the original block. So the cost of a snapshot is **not** the full disk size — it's only the size of the blocks that *changed after* the snapshot was taken. With **one** snapshot taken on an idle VM, disk overhead is near zero. With **ten** snapshots taken in sequence, each snapshot's overhead is the delta between it and its successor. If nothing changes between snapshots, ten snapshots cost almost nothing. If the VM is actively writing (logs, builds, databases), each snapshot accumulates those writes as long as it exists. The total disk usage = base image + sum of all deltas of all live snapshots. **Worst case:** heavy churn between snapshots can make the combined delta larger than the base image.

**g) When is snapshotting an antipattern?**

Long snapshot **chains** are the classic antipattern. Every snapshot in the chain adds a layer of indirection: reads have to walk the chain, writes have to allocate into the newest delta. With dozens of snapshots, VM performance degrades noticeably (I/O latency grows, compaction takes minutes, restore becomes slow), and disk usage balloons. Worse, deleting a snapshot from the *middle* of a chain forces VirtualBox/QEMU to merge two deltas — a potentially multi-minute operation that can fail or corrupt the chain if interrupted. The pattern to avoid is using snapshots as **version control for the VM's state over weeks**. Snapshots should be short-lived (hours to days): take one before a risky change, roll back if needed, delete it. For long-term versioning, use **immutable images + IaC** (Packer, Terraform, Ansible) to rebuild from scratch, not snapshot chain archaeology.

### Appendix — Deviations from the lab's defaults

- **VirtualBox → UTM** because VirtualBox 7.1 has no reliable support for Apple Silicon Macs (arm64). `vagrant_utm` 0.1.6 exposes the same provider API that Vagrant expects.
- **Vagrant download** required a VPN because `releases.hashicorp.com` returns HTTP 403 "Content not available in your region" for Russian IPs. The box `bento/ubuntu-24.04` (arm64) then downloaded without issues from the same VPN session.
- **Snapshots require `vagrant halt` first** — `vagrant_utm` uses `qemu-img` under the hood, and `qemu-img` refuses to touch a `.qcow2` image that any process holds a write lock on. The lab assumes a live-snapshot-capable provider (VirtualBox); the UTM path is offline-only.
