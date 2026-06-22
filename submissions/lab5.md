# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

Host: Windows 11 + **VirtualBox 7.1.6** + **Vagrant 2.4.9**. The `Vagrantfile`
lives at the repo root: [`../Vagrantfile`](../Vagrantfile).

> Note: Hyper-V is enabled on this host (WSL2 from Lab 4 needs it), so VirtualBox
> 7.1 runs on the Windows Hypervisor Platform backend — VMs boot, just a little
> slower than on bare VT-x.

---

## Task 1 — Vagrant Up + Run QuickNotes Inside

### What the Vagrantfile does

| Requirement | How |
|-------------|-----|
| Ubuntu 24.04 LTS box | `bento/ubuntu-24.04` |
| Hostname | `quicknotes-vm` |
| Port forward | `127.0.0.1:18080 → guest:8080` (loopback-bound) |
| Synced folder | `./app → /opt/quicknotes/app` (virtualbox) |
| Resources | 2 vCPU, 1024 MB |
| Provision | shell: install Go 1.24.4, build QuickNotes, run as a systemd service |

The provisioner is idempotent (re-runnable with `vagrant provision`): it installs
Go only if the pinned version is missing, rebuilds the binary, and (re)starts the
`quicknotes.service` systemd unit — so `curl :18080/health` works straight after
`vagrant up`, no manual SSH step.

### First 10 lines of `vagrant up`

```text
<!-- TODO: paste first ~10 lines of `vagrant up` (box download / boot / provision) -->
```

### Verification — guest and host

```text
# inside the guest
$ vagrant ssh -c '/usr/local/go/bin/go version'
<!-- TODO: go1.24.4 linux/amd64 -->

$ vagrant ssh -c 'curl -s http://localhost:8080/health'
<!-- TODO: {"notes":4,"status":"ok"} -->

# from the host, via the port forward
$ curl -s http://localhost:18080/health
<!-- TODO: {"notes":4,"status":"ok"} -->
```

### 1.2 Design questions

**a) Synced-folder type and trade-off.**
I used the **VirtualBox shared folder** (`type: "virtualbox"`, the default for
this box since bento ships guest additions). It's bidirectional and live — host
edits to `./app` appear instantly in the guest with zero extra setup. Trade-offs
vs the alternatives: **rsync** is a one-way push (host→guest) at `vagrant up` /
`vagrant rsync`, very fast and dependency-light, but guest changes don't sync
back and edits aren't live; **nfs** is fast and bidirectional but needs an NFS
server on the host (root, firewall rules) and is painful on Windows; **smb**
works on Windows but wants credentials. Our source tree is small and read-mostly
(we only build from it), so the live VirtualBox mount is the least-friction
choice; for a large tree with thousands of files I'd switch to rsync to avoid the
shared-folder I/O penalty.

**b) Network mode; why loopback forwarding beats bridged.**
The default mode is **NAT** — the guest sits behind the host's NAT with a private
address and is unreachable from the LAN except through the explicit port
forwards I declare. I bound the forward to **`127.0.0.1`**, so only the host's
loopback can reach `:18080`; nothing else on the network can. A **bridged**
interface would instead give the VM its own IP directly on the physical LAN,
reachable by every machine on the network — for a course VM (default creds,
unhardened) that's needless exposure. Loopback-bound NAT forwarding keeps the
blast radius to this one machine.

**c) Provisioner choice.**
**shell.** Installing a Go tarball and dropping in a systemd unit is a short
sequence of imperative steps that needs *zero* extra tooling on host or guest —
no Ansible/Puppet/Chef runtime to install first. It's transparent and easy to
read for a single-machine bootstrap. `ansible_local` would be overkill here, and
host-driven `ansible` is exactly what **Lab 7** will use against this same VM —
so I keep the Vagrant provisioning minimal and leave real config management for
then.

**d) Why pin `1.24.4` (point release) instead of `1.24`.**
`1.24` names a *language line*, not a downloadable artifact — there's no
`go1.24.linux-amd64.tar.gz`; you must name a concrete point release to fetch.
More importantly, a floating "latest 1.24.x" makes the build **non-reproducible**:
a teammate provisioning next week could silently get `1.24.7` with a different
compiler, runtime, and security patches, so "works on my VM" starts to diverge.
Pinning the exact point release makes `vagrant up` deterministic — everyone gets
a byte-identical toolchain — and a Go upgrade becomes a reviewed one-line change
instead of a surprise.

---

## Task 2 — Snapshots: Save, Break, Restore

### Commands run

```text
# 1. snapshot the working VM
$ vagrant snapshot save clean-baseline
<!-- TODO -->

# 2. break it: wipe the Go install AND the running binary
$ vagrant ssh -c 'sudo rm -rf /usr/local/go /usr/local/bin/quicknotes && sudo systemctl stop quicknotes'
<!-- TODO -->

# 3. verify broken
$ vagrant ssh -c '/usr/local/go/bin/go version || echo GO_GONE'
$ curl -s http://localhost:18080/health || echo HEALTH_DOWN
<!-- TODO: GO_GONE / HEALTH_DOWN -->

# 4. restore (timed)
$ time vagrant snapshot restore clean-baseline
<!-- TODO -->

# 5. verify recovery
$ vagrant ssh -c '/usr/local/go/bin/go version'
$ curl -s http://localhost:18080/health
<!-- TODO: go1.24.4 / {"status":"ok"} -->
```

### Restore time

```text
<!-- TODO: paste the `time vagrant snapshot restore` real/user/sys output -->
```

### 2.2 Design questions

**e) Snapshots are not backups.**
A snapshot lives on the **same disk and host** as the VM, so it's useless against
exactly the failures backups exist for: a dead disk, a lost/stolen laptop,
ransomware, or an accidental `vagrant destroy` / deletion of the VirtualBox VM
folder takes the snapshot with it. It's also not off-site or independently
versioned, and it only freezes a point in time — if data corruption slips in and
you keep snapshotting, every snapshot just preserves the same bad state. Snapshots
are for fast *local rollback*, not durable recovery.

**f) Copy-on-write: 10 snapshots vs 1.**
VirtualBox snapshots are copy-on-write: taking one freezes the current disk
read-only and opens a new **differencing image** that stores only blocks changed
afterward. So each snapshot starts at ~0 bytes and grows only with subsequent
writes — 10 snapshots cost roughly the **sum of the deltas** between them, not
10× the base disk. The cost of many snapshots isn't a 10× copy, it's a long
**chain**: reads must walk the differencing images, so deep chains add I/O
latency and accumulated delta storage compared to a single diff.

**g) When is snapshotting an antipattern?**
**Long chains.** Stacking many snapshots (or using them as a versioning/backup
system) bloats disk with accumulated deltas and slows every read, because the
disk subsystem has to traverse the whole differencing chain; restores and merges
get slow and fragile. Snapshots are meant to be **short-lived** — snapshot → make
a risky change → restore or delete — not a permanent ladder of states. For
long-term history, rebuild from code or use real images/backups (cattle, not
pets).

---

## Bonus — VM vs Container Resource Baseline

<!-- TODO: fill table + analysis from real measurements -->

| Dimension              | Vagrant VM | Docker container |
|------------------------|-----------:|-----------------:|
| Cold start             |          ? |                ? |
| Idle RAM               |          ? |                ? |
| On-disk size           |          ? |                ? |
| Process count (guest)  |          ? |                ? |
