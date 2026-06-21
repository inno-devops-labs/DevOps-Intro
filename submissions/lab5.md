# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

Done for real with VirtualBox 7.2.10 + Vagrant 2.4.9 on Windows. The
[`Vagrantfile`](../Vagrantfile) lives at the repo root; `.vagrant/` is gitignored.

> Note on the host: this is a Windows 11 machine where the hypervisor was active
> (WSL2 + Memory Integrity/VBS). VirtualBox could only run the guest via its slow
> NEM/Hyper-V backend, which timed out on SSH. To get native AMD-V I disabled
> `hypervisorlaunchtype` and Memory Integrity/VBS and rebooted; after that
> VirtualBox uses hardware AMD-V (`HM: AMD-V w/ nested paging`) and the VM runs
> normally. All outputs below are from that native run.

---

## Task 1 — Vagrant up + run QuickNotes inside

### 1.1 The Vagrantfile (requirements → lines)

| # | Requirement | How |
|---|-------------|-----|
| 1 | Ubuntu LTS box | `bento/ubuntu-24.04` |
| 2 | Identifying hostname | `config.vm.hostname = "quicknotes-vm"` |
| 3 | host 18080 → guest 8080, loopback-bound | `forwarded_port guest: 8080, host: 18080, host_ip: "127.0.0.1"` |
| 4 | Sync `./app` into the guest | `synced_folder "./app", "/opt/quicknotes/app"` |
| 5 | 2 vCPU / 1024 MB | `vb.cpus = 2`, `vb.memory = 1024` |
| 6 | Install Go 1.24.x on `up` | shell provisioner installs Go **1.24.5** from the official tarball |
| 7 | Reproducible | pinned box + pinned Go point release + idempotent provisioner |

### 1.2 Design questions

**a) Which synced-folder type and why?** I used the **VirtualBox shared folder**
(the default). It needs zero host setup, works out of the box with bento's
pre-installed Guest Additions, and gives live two-way sync of `./app`. The
trade-off: VirtualBox shared folders are slower for heavy file I/O and have
occasional permission/symlink quirks. **NFS** is much faster for big trees but
needs an NFS server on the host (not native on Windows) and `sudo`; **rsync** is
fast inside the guest but is a one-shot host→guest copy (no live edits unless you
run `rsync-auto`); **SMB** needs Windows share credentials. For a small source
folder, the VirtualBox driver is the simplest adequate choice.

**b) NAT vs Bridged vs Host-only?** I'm using the default, **NAT**, with a
forwarded port. NAT keeps the guest off the LAN — it has no routable address of
its own, and the forwarded port is bound to `127.0.0.1`, so only *my host* can
reach QuickNotes, nothing else on the network. A **Bridged** interface would give
the VM its own LAN IP and expose an unauthenticated QuickNotes to every machine on
the network — wrong for a course exercise. (Host-only would also isolate it, but
NAT + port-forward is the least-surprise default.)

**c) Which provisioner and why?** **shell.** Installing one pinned Go tarball is a
three-line script; `shell` has no prerequisites, while `ansible`/`puppet`/`chef`
all require their own toolchain (and `ansible_local` would pull Ansible into the
guest) for no benefit at this size. For a single, transparent install step, shell
is the lowest-overhead option. (If provisioning grew to many roles, I'd switch to
`ansible_local` — which is exactly where Lab 7 goes.)

**d) Why pin `1.24.5` instead of `1.24`?** Two reasons. Practically, `1.24` isn't
a downloadable artifact — `https://go.dev/dl/` needs a full version string. More
importantly, pinning the exact patch makes the build **reproducible**: every
`vagrant up`, on any student's machine, installs the identical toolchain, so a
behavior change or fix in a later 1.24.x can't silently alter results between runs.
A floating minor would drift over time and reintroduce "works on my machine."

### 1.3 `vagrant up` output

First lines of a clean `vagrant up` (box import → boot → folder mount → Go provision):

```
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
==> default: Machine booted and ready!
==> default: Setting hostname...
==> default: Mounting shared folders...
    default: D:/Repos/Masters/DevOps/DevOps-Intro/app => /opt/quicknotes/app
==> default: Running provisioner: shell...
    default: go version go1.24.5 linux/amd64
```

### 1.4 Verification (guest + host)

```
# inside the guest:
$ go version
go version go1.24.5 linux/amd64
$ cd /opt/quicknotes/app && go build -o /tmp/qn . && /tmp/qn &
2026/06/21 16:39:03 quicknotes listening on :8080 (notes loaded: 4)
$ curl -s http://localhost:8080/health      # from INSIDE the guest
{"notes":4,"status":"ok"}

# from the HOST, through the forwarded port:
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

The same `{"notes":4,"status":"ok"}` from both the guest's own loopback and the
host's `:18080` proves the NAT port-forward (host 18080 → guest 8080) works.

---

## Task 2 — Snapshots: Save, Break, Restore

The exact cycle (save → break → verify → restore → verify):

```
$ vagrant snapshot save clean-working
==> default: Snapshot saved! ...

# break it: wipe the Go install
$ vagrant ssh -c "sudo rm -rf /usr/local/go && echo removed-go"
removed-go

# verify it's broken
$ vagrant ssh -c "/usr/local/go/bin/go version"
bash: line 1: /usr/local/go/bin/go: No such file or directory   # GO_IS_BROKEN

# restore from the snapshot (timed)
$ time vagrant snapshot restore clean-working
==> default: Restoring the snapshot 'clean-working'...
==> default: Machine booted and ready!
RESTORE_SECONDS = 29.1

# verify recovery
$ vagrant ssh -c "/usr/local/go/bin/go version"
go version go1.24.5 linux/amd64

$ vagrant snapshot list
clean-working
```

The wiped Go toolchain is fully back after a **29.1 s** restore — the whole
"break something, roll back in ~30 s" cattle-not-pets point of the lab.

### 2.2 Design questions

**e) Snapshots are not backups — why?** A snapshot sits on the **same disk and
host** as the VM and in VirtualBox's own format. If the physical disk fails, the
laptop is lost or stolen, ransomware encrypts the files, or the VM directory is
deleted, the snapshot dies with the VM. It protects you from *in-guest* mistakes
(a bad config, an `rm`), not from hardware loss, host compromise, or accidental
deletion of the VM itself — those need copies on *other* media/hosts.

**f) Copy-on-write — 10 snapshots vs 1?** A VirtualBox snapshot freezes the
current disk as a read-only base and sends all later writes to a new
*differencing* disk. So snapshots store **deltas, not full copies**: 10 snapshots
cost roughly base + the sum of changes between each, not 10× the full image. If
little changes between them, 10 snapshots can be barely larger than 1.

**g) When is snapshotting an antipattern?** **Long chains.** Every differencing
disk in the chain adds read-amplification (a read may walk the whole chain) and
write overhead, so a deep chain steadily degrades performance and makes the VM
fragile; merging or deleting a long chain is slow and can corrupt the VM. It's
also an antipattern to use snapshots as durable backups, or as a substitute for
rebuilding from the `Vagrantfile` — that's keeping a "pet" alive by patching from
snapshots instead of treating the VM as reproducible "cattle."

---

## Bonus — VM vs Container Resource Baseline

The VM numbers below are measured from this running Vagrant box. The container
column is the QuickNotes image from **Lab 6** — on-disk size is directly measured
there; idle RAM / process count / cold start need Docker running, which on this
host needs Hyper-V/VBS *on* — the exact opposite of what this lab's VM needs — so
those cells are the well-established characteristics of a distroless single-binary
container rather than numbers I captured in this same boot (noted honestly).

Measured VM baseline (idle): `free -h` → **337 MiB used / 961 MiB total**;
`ps -A` → **150 processes**; VM dir on disk → **2.65 GB**; cold cycle → halt
**7.9 s**, boot **32.8 s**.

| Dimension | Vagrant VM (measured) | Docker container (QuickNotes, Lab 6) |
|-----------|----------------------:|-------------------------------------:|
| Cold start | ~33 s (full OS boot) | < 1 s (just the process) |
| Idle RAM | ~337 MiB | single-digit MiB (one Go binary) |
| On-disk size | 2.65 GB | 22.7 MB (measured in Lab 6) |
| Process count (guest) | 150 | 1 |

**What surprised me / what it means.** The gap is enormous in every dimension —
~120× on disk, ~30–50× on RAM, and the VM runs **150 processes** (a whole
systemd userland: udev, journald, cron, ssh, networkd, …) to serve the *same one*
QuickNotes binary the container runs as **PID 1 alone**. A VM virtualizes
hardware and boots a full guest kernel + OS, so you pay for an entire machine; a
container shares the host kernel and isolates only the process tree, so you pay
for ~one process. That's exactly why containers won 2014–2020 for stateless
microservices: when the unit of deployment is a single stateless binary, the
VM's OS overhead is pure waste, and the container's sub-second start + tiny
footprint let you pack far more services per host and scale them in seconds. The
VM still wins when you need a *different kernel*, full OS isolation, or to run
something that genuinely expects a whole machine — which is why this very lab
needed a real VM, not a container.
