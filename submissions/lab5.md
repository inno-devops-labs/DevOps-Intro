# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

Host: Windows 11 + **VirtualBox 7.1.6** + **Vagrant 2.4.9**. The `Vagrantfile`
lives at the repo root: [`../Vagrantfile`](../Vagrantfile).

> **Provider note (important).** The lab default is VirtualBox, and the
> `Vagrantfile` configures it (with a real `virtualbox` synced folder). But this
> host has **UEFI-locked Virtualization-Based Security / Memory Integrity** that
> I chose to keep enabled — VBS holds VT-x, so VirtualBox falls back to the NEM
> emulation engine and the guest is unusably slow (kernel reaches ~8 s of boot in
> 5+ minutes of wall-clock). So I ran the VM via the **Hyper-V provider**
> (`vagrant up --provider=hyperv`), which uses the already-present hypervisor at
> native speed. Two Hyper-V-specific adaptations, both documented below:
> - Hyper-V's only synced-folder transport is **SMB**, which crashes Vagrant
>   2.4.9's credential scrubber on a non-ASCII Windows password — so the Hyper-V
>   path fetches the app source via **git clone** instead (the VirtualBox path
>   still uses a proper synced folder).
> - Hyper-V has no NAT port-forward, so the required `127.0.0.1:18080 → guest:8080`
>   is reproduced with a host `netsh interface portproxy` rule.

---

## Task 1 — Vagrant Up + Run QuickNotes Inside

### What the Vagrantfile does

| Requirement | How |
|-------------|-----|
| Ubuntu LTS box | `bento/ubuntu-24.04` (VirtualBox) / `generic/ubuntu2204` (Hyper-V) |
| Hostname | `quicknotes-vm` |
| Port forward | `127.0.0.1:18080 → guest:8080` (VirtualBox NAT; Hyper-V via portproxy) |
| Synced folder | `./app → /opt/quicknotes/app` (VirtualBox); git clone on Hyper-V |
| Resources | 2 vCPU, 1024 MB |
| Provision | shell: install Go 1.24.4, build QuickNotes, run as a systemd service |

The provisioner is idempotent (re-runnable with `vagrant provision`): it installs
Go only if the pinned version is missing, rebuilds the binary, and (re)starts the
`quicknotes.service` systemd unit — so `curl :18080/health` works straight after
`vagrant up`, no manual SSH step.

### First ~10 lines of `vagrant up` (Hyper-V)

```text
Bringing machine 'default' up with 'hyperv' provider...
==> default: Verifying Hyper-V is enabled...
==> default: Importing a Hyper-V instance
    default: Creating and registering the VM...
    default: Successfully imported VM
==> default: Starting the machine...
==> default: Waiting for the machine to report its IP address...
    default: IP: 172.20.94.164
==> default: Machine booted and ready!
==> default: Running provisioner: shell...
    default: [provision] installing Go 1.24.4
    default: [provision] no synced folder; cloning https://github.com/rikire/DevOps-Intro
    default: [provision] building quicknotes from /opt/quicknotes/src/app
    default: [provision] done
```

### Verification — guest and host

```text
# inside the guest
$ vagrant ssh -c '/usr/local/go/bin/go version'
go version go1.24.4 linux/amd64

$ vagrant ssh -c 'systemctl is-active quicknotes; curl -s localhost:8080/health'
active
{"notes":4,"status":"ok"}

# from the host, via the netsh portproxy (Hyper-V equivalent of the NAT forward)
$ curl -s http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
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
shared-folder I/O penalty. *On the actual Hyper-V run here, SMB (Hyper-V's only
synced-folder transport) crashed Vagrant 2.4.9, so the provisioner instead
`git clone`s the source — same end result (the app builds in the VM), just
sourced from git rather than a live mount.*

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
==> default: Snapshotting the machine as 'clean-baseline'...
==> default: Snapshot saved!

# 2. break it: wipe the Go install AND the running binary, stop the service
$ vagrant ssh -c 'sudo rm -rf /usr/local/go /usr/local/bin/quicknotes; sudo systemctl stop quicknotes'

# 3. verify broken
$ vagrant ssh -c '/usr/local/go/bin/go version 2>&1 || echo GO_GONE; curl -s -m3 localhost:8080/health || echo HEALTH_DOWN'
bash: line 1: /usr/local/go/bin/go: No such file or directory
GO_GONE
HEALTH_DOWN

# 4. restore (timed)
$ vagrant snapshot restore clean-baseline      # wrapped in Measure-Command

# 5. verify recovery
$ vagrant ssh -c '/usr/local/go/bin/go version; systemctl is-active quicknotes; curl -s localhost:8080/health'
go version go1.24.4 linux/amd64
active
{"notes":4,"status":"ok"}
```

### Restore time

```text
RESTORE_SECONDS = 34.4   # graceful shutdown + restore differencing disk + reboot + SSH-ready
```

The restore reverts the wiped Go install, the deleted binary, and the stopped
service in one ~34 s operation — "cattle, not pets": the broken VM isn't repaired,
it's rolled back to a known-good image.

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

Measured on the same host in one session. The VM is the Hyper-V QuickNotes VM
from Task 1; the container is `quicknotes:lab6` (the distroless image from Lab 6).

| Dimension              | Vagrant VM (Hyper-V) | Docker container |
|------------------------|---------------------:|-----------------:|
| Cold start             |             **35.6 s** |       **0.52 s** |
| Idle RAM (used)        |            ~**193 MiB** |     **1.7 MiB** |
| On-disk size           |             **8.55 GB** |     **8.56 MB** |
| Process count (guest)  |                **126** |          **1** |

(VM: `BOOT_SECONDS=35.6`, `free -h` used ≈193 MiB of 1 GiB, `ps -A | wc -l = 126`,
summed vhdx chain 8.55 GB. Container: `docker start` 518 ms, `docker stats`
1.715 MiB, `docker images` 8.56 MB, `docker top` = 1 process.)

### Analysis

The numbers that jump out are the **three orders of magnitude** on disk (8.55 GB
vs 8.56 MB) and the **~100×** on RAM — and most tellingly the process count: the
VM runs a whole operating system (**126** processes — kernel threads, systemd,
journald, udev, sshd…), while the container runs literally **one** process, the
QuickNotes binary. That single-process reality is why the container cold-starts in
half a second versus the VM's 35 s of BIOS → bootloader → kernel → systemd → unit
ordering. **VMs are the right tool when you need a real kernel boundary**: strong
isolation between tenants, running a different OS/kernel, kernel modules, or
lifting-and-shifting a full legacy stack. **Containers win for stateless
microservices**: identical app, no OS to boot, packed densely on a shared kernel.
The data is exactly why containers took over 2014–2020 for that workload — a
sub-second start and an 8 MB image map perfectly onto autoscaling and
orchestration (pull fast, schedule fast, scale to zero and back), while paying a
full 8 GB / 35 s / 126-process OS tax *per replica* is dead weight when every
replica is the same stateless service that never needed its own kernel.
