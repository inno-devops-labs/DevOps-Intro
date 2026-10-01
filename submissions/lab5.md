# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

- Student: Arina Nikolaeva (Nik-ari-ai)
- Fork: https://github.com/Nik-ari-ai/DevOps-Intro
- Branch: feature/lab5

## Environment & platform constraints

This work was done on an **Apple M3 Pro (arm64 / Apple Silicon)**, macOS Sonoma.

What this machine runs well: arm64 virtual machines and containers natively, Docker Desktop (through its own lightweight arm64 Linux VM), and x86 userland binaries under Rosetta 2.

What it cannot do: boot an **x86_64 guest OS under VirtualBox**. VirtualBox virtualizes the x86 architecture, and there is no build of it for Apple Silicon that can run an x86_64 guest; the `bento/ubuntu-24.04` box is published for x86_64 only. As a result, `vagrant up` with the `virtualbox` provider does not start this guest on this hardware.

Concretely, the steps that require a booted guest — `vagrant up`, the in-guest Go build and run, the host→guest check through the port forward, and the snapshot save / break / restore cycle with its restore timing — were not executed on this laptop. The `Vagrantfile` is written to the lab's VirtualBox specification and is correct for an x86_64 host; the commands to produce each piece of evidence are given below so the run is reproducible on x86 hardware.

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile (repo root)

```ruby
GO_VERSION = "1.24.5"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync",
    rsync__exclude: [".git/", "quicknotes", "data/"]

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    GO_VERSION="#{GO_VERSION}"
    if /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      echo "Go ${GO_VERSION} already installed"; exit 0
    fi
    cd /tmp
    curl -fsSL -O "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    chmod +x /etc/profile.d/go.sh
    /usr/local/go/bin/go version
  SHELL
end
```

How each requirement is met:

| # | Requirement | Where |
|---|-------------|-------|
| 1 | Ubuntu 24.04 LTS public box | `config.vm.box = "bento/ubuntu-24.04"` |
| 2 | Identifying hostname | `config.vm.hostname = "quicknotes-vm"` |
| 3 | `127.0.0.1:18080 -> guest:8080` | `forwarded_port ... host_ip: "127.0.0.1"` |
| 4 | Sync `./app` into guest | `synced_folder "./app", "/home/vagrant/app", type: "rsync"` |
| 5 | 2 vCPU / 1024 MB | `vb.cpus = 2`, `vb.memory = 1024` |
| 6 | Install Go 1.24.5 on `vagrant up` | shell provisioner (idempotent) |
| 7 | Reproducible | pinned box **name + version** (`box_version = "202510.26.0"`) + pinned `GO_VERSION` |

### Run commands (x86_64 host)

```bash
vagrant up
vagrant ssh -c '/usr/local/go/bin/go version'          # go version go1.24.5 linux/amd64
vagrant ssh -c 'cd /home/vagrant/app && /usr/local/go/bin/go build -o /tmp/qn && ADDR=:8080 /tmp/qn &'
vagrant ssh -c 'curl -s http://localhost:8080/health'  # from inside the VM
curl -s http://localhost:18080/health                  # from the host via the port forward
# both return: {"notes":4,"status":"ok"}
```

`.vagrant/` is covered by the repo `.gitignore`, so per-machine state is not committed.

### 1.2 Design questions

**a) Which synced-folder type and why? Trade-off.**
I used **rsync**. rsync is a one-way, point-in-time push from host to guest that works on every provider and host OS and needs nothing extra inside the guest; reads inside the VM are then native-filesystem fast (no per-read round-trip). The trade-off is that it is one-way and not live — host edits are not reflected until `vagrant rsync` runs, and changes made in the guest never flow back. VirtualBox shared folders (`virtualbox`) are two-way and live but need guest additions and are slow on large trees; `nfs`/`smb` are live and fast but need a host daemon and firewall rules. For building QuickNotes from a fixed source snapshot, one-way rsync is the right trade.

**b) NAT vs Bridged vs Host-only; why is 127.0.0.1 port-forwarding safer than Bridged?**
The default NIC here is **NAT**, which is what I use, plus a forwarded port. NAT puts the guest behind the host so it has no address on the LAN; binding the forward to `127.0.0.1` means only processes on the host can reach `:18080`. A **Bridged** interface would give the VM its own LAN IP and expose QuickNotes — which has no auth — to every machine on the same network. For a course exercise that is needless attack surface, so `127.0.0.1`-bound NAT forwarding is the safer default.

**c) Which provisioner for installing Go and why?**
**shell.** Installing one pinned Go toolchain is a few imperative steps (download tarball, extract to `/usr/local`, set PATH) with no need for a configuration-management engine. shell has zero dependencies in the guest and is transparent to read. `ansible`/`puppet`/`chef` add a toolchain and DSL that only pay off once provisioning grows into many managed resources — which is exactly what Lab 7's Ansible does.

**d) Why pin Go to `1.24.5` instead of `1.24`?**
`1.24` floats to whatever the latest patch is at download time, so two students running `vagrant up` a month apart can get different toolchains — which breaks the "reproducible" requirement and hides patch-level behaviour and security differences. Pinning `1.24.5` makes the build deliberate and reproducible: the version changes only when someone edits the `Vagrantfile`.

## Task 2 — Snapshots: Save, Break, Restore

### 2.1 Procedure (x86_64 host)

The save → break → verify → restore → verify → time sequence:

```bash
# 1. snapshot the working VM
vagrant snapshot save clean-go1.24

# 2. break it deliberately — wipe the Go install
vagrant ssh -c 'sudo rm -rf /usr/local/go'

# 3. verify broken
vagrant ssh -c '/usr/local/go/bin/go version'   # No such file or directory

# 4. restore from the snapshot
vagrant snapshot restore clean-go1.24

# 5. verify recovery
vagrant ssh -c '/usr/local/go/bin/go version'   # go version go1.24.5 linux/amd64

# 6. timed restore
time vagrant snapshot restore clean-go1.24
```

### 2.2 Design questions

**e) Why are snapshots not backups? (2-3 sentences)**
A snapshot lives on the same physical disk and inside the same VirtualBox metadata as the VM it captures, so it dies with them. It is useless for the failure modes backups exist for: the host disk failing, the VM being `vagrant destroy`ed, corruption or ransomware reaching the whole VirtualBox directory, or the laptop being lost or stolen. A backup is an independent copy on separate (ideally offsite) storage; a snapshot is only a fast in-place rollback point on the live disk.

**f) Copy-on-write: 10 snapshots vs 1?**
VirtualBox snapshots are copy-on-write differencing disks: taking one does not copy the whole disk — it freezes the current image read-only and writes only changed blocks to a new delta file. So 10 snapshots do not cost 10× the disk of 1; each delta grows only by the blocks changed since the previous snapshot, and the total extra disk is roughly the sum of the deltas (the churn), not ten full images. What you pay for is the chain of deltas the VM must read through.

**g) When is snapshotting an antipattern? (long chains)**
Long snapshot chains are the antipattern. Every read has to walk the delta chain from newest to base, so a deep chain steadily degrades disk performance while the accumulated deltas quietly consume space. Snapshots are meant to be short-lived — take one, do the risky thing, then restore or delete. Keeping a long chain as pseudo-version-control or long-term history is where it becomes a liability; the right tool there is a real backup or a rebuild from code (cattle, not pets).

## Bonus — VM vs Container Baseline

The comparison needs real cold-boot, RAM, disk and process numbers from a running VM, which this arm64 host cannot produce under the VirtualBox provider, so the bonus is not included.
