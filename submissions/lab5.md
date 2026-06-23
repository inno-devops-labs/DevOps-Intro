# Lab 5 Submission — Virtualization with Vagrant

The VM is defined in [../Vagrantfile](../Vagrantfile). It boots Ubuntu 24.04 LTS,
pins Go 1.24.4, builds and runs QuickNotes as a systemd service, and forwards the
API to the host on `127.0.0.1:18080`.

> The command outputs marked _(paste from your machine)_ require VirtualBox +
> Vagrant locally — run `vagrant up` on your host and paste the real output. The
> design answers and the container side of the bonus are complete.

---

## Task 1 — The Vagrantfile

### How each requirement is met

| Requirement | Where in `Vagrantfile` |
|---|---|
| Ubuntu 22.04/24.04 LTS | `config.vm.box = "bento/ubuntu-24.04"` |
| Identifying hostname | `config.vm.hostname = "quicknotes-lab5"` |
| Forward host 18080 → guest 8080, bound to 127.0.0.1 | `forwarded_port guest:8080 host:18080 host_ip:"127.0.0.1"` |
| Synced folder `./app` | `config.vm.synced_folder "./app", "/home/vagrant/app"` |
| 2 vCPU, 1024 MB | `vb.cpus = 2`, `vb.memory = 1024` |
| Install Go 1.24.x | provisioning downloads `go1.24.4.linux-amd64.tar.gz` |
| Reproducible from clean clone | idempotent shell provisioner, pinned versions, `.vagrant/` git-ignored |

### Verification (paste from your machine)

```bash
vagrant up                 # first 10 lines below
vagrant ssh -c "curl -s http://localhost:8080/health"   # from INSIDE the VM
curl -s http://localhost:18080/health                   # from the HOST (port forward)
```

**First 10 lines of `vagrant up`:** _(paste from your machine)_
```text
<!-- TODO: paste the first 10 lines of `vagrant up` output -->
```

**`curl` from inside the VM (guest :8080):** _(paste from your machine)_
```text
<!-- TODO: e.g. {"notes":4,"status":"ok"} -->
```

**`curl` from the host (forwarded :18080):** _(paste from your machine)_
```text
$ curl -s http://localhost:18080/health
<!-- TODO: should match the guest output -->
```

### Design answers

**Synced-folder types — trade-offs.**
- **virtualbox** (default, vboxsf): zero setup, works everywhere VirtualBox does,
  but slow for many small files and has occasional permission/owner quirks. Fine
  for editing source.
- **rsync**: one-way host→guest *copy* at `up`/`rsync-auto`; fastest in-guest I/O
  (it's native FS) and works over any provider, but changes don't sync back and
  you must re-sync after edits.
- **nfs**: fast bidirectional sync for large trees, good for heavy I/O, but
  requires an NFS server on the host (root/sudo, firewall) and is awkward on
  Windows.
- **smb**: the Windows-host counterpart to nfs (needs credentials/SMB service).
  I chose **virtualbox** synced folders: simplest and reproducible for a small
  source tree, and the persistent data lives *outside* the synced folder
  (`/home/vagrant/app-data`) so sync speed/permissions never affect the database.

**Network mode & why `127.0.0.1` binding is safer than bridged.**
I use NAT with a **forwarded port** bound to `host_ip: "127.0.0.1"`. With bridged
networking the VM gets its own IP on the physical LAN, so QuickNotes (which has no
auth) would be reachable by anyone on the network. Binding the forward to
`127.0.0.1` exposes the service **only to the local host** — not to other machines,
Wi-Fi peers, or the internet — shrinking the attack surface to the developer's own
box, which is the right default for an unauthenticated dev service.

**Provisioning method.**
**Shell** provisioner. The setup is a handful of imperative steps (download a
pinned tarball, drop a systemd unit, enable it) with no multi-host orchestration,
so a self-contained, dependency-free shell script is the simplest *reproducible*
choice — no control machine, no extra runtime to install. The script is
**idempotent** (skips the Go install if the pinned version is already present), so
re-provisioning is safe. Ansible/Puppet would add value only for fleets or complex
config drift, which this single VM doesn't have.

**Why pin Go to a specific point release, not a major version.**
A "major"/minor track like `go1.24` is a *moving target* — the toolchain changes as
patch releases land, so two `vagrant up`s weeks apart could install different
compilers and produce different binaries or surface new behavior, breaking
reproducibility. Pinning `go1.24.4` makes the build **deterministic and
auditable**: every clean provision installs the exact same toolchain, and upgrades
become an explicit, reviewable change to one constant.

---

## Task 2 — Snapshot Lifecycle (paste from your machine)

```bash
vagrant up
vagrant snapshot save clean-baseline           # 1) named snapshot
# 2) deliberately break the VM:
vagrant ssh -c "sudo systemctl stop quicknotes && sudo rm -f /home/vagrant/quicknotes"
# 3) verify failure:
curl -s http://localhost:18080/health || echo "DOWN (expected)"
# 4) restore + time it:
time vagrant snapshot restore clean-baseline
# 5) verify recovery:
curl -s http://localhost:18080/health
```

- **Snapshot name:** `clean-baseline`
- **Break command + failure proof:** _(paste output — connection refused / DOWN)_
- **Restore time:** _(paste the `time` result, e.g. `real 0m12.3s`)_
- **Recovery proof:** _(paste `{"status":"ok",...}` after restore)_

### Design answers

**Why snapshots aren't backups (2–3 sentences).**
A snapshot lives in the *same* storage as the VM and depends on the original disk's
base image, so if that disk, the host, or the hypervisor is lost or corrupted, the
snapshot dies with it. Backups are independent, off-host copies you can restore
elsewhere. Snapshots are a fast local *undo* for the current machine, not disaster
recovery.

**Copy-on-write implications for multiple snapshots.**
Taking a snapshot freezes the current disk and starts a new copy-on-write
**differencing** layer: subsequent writes go to the new layer while unchanged blocks
are still read from the parent. Each additional snapshot adds another CoW layer, so
a read may walk a chain of layers (read amplification → slower I/O) and total disk
usage grows with the *changed* blocks across all layers, not a fixed cost.

**When snapshot chains become problematic.**
Long chains degrade performance (every read traverses more layers) and balloon disk
usage; merging/deleting a mid-chain snapshot becomes slow and risky, and a corrupt
parent invalidates every child. Live, long-lived snapshots (especially "I'll keep
this for weeks") are an anti-pattern — keep chains short and delete snapshots once
you no longer need the rollback.

---

## Bonus — VM vs Container Resource Comparison

Container side measured here on `quicknotes:lab6`; **VM side: paste from your machine**
(e.g. `time vagrant up` for cold boot, `free -m`/`VBoxManage` for RAM, `ps aux | wc -l`,
and the `.vdi` size or `VBoxManage showvminfo`).

| Metric | VM (Vagrant/VirtualBox) | Container (Docker) |
|---|---|---|
| Cold-boot time | _(paste — typically 20–60 s)_ | **~0.3 s** (to first `200 /health`) |
| Idle RAM | _(paste — typically 300–600 MB)_ | **~1.7 MiB** (process RSS via `docker stats`) |
| Process count | _(paste — 100+ system processes)_ | **1** (just the app binary) |
| Disk size | _(paste — ~1–3 GB box/.vdi)_ | **~13 MB** (image) |

**Analysis (4–5 sentences).** The container is orders of magnitude lighter on every
axis because it shares the host kernel and ships only the app binary plus a ~2 MB
distroless rootfs, whereas the VM virtualizes hardware and boots a full Ubuntu
guest with its own kernel, init, and ~100 background services. That makes containers
ideal for fast, dense, disposable workloads — seconds to start, MBs of RAM, trivial
disk. The VM's cost buys **stronger isolation** (its own kernel) and the ability to
run a different OS/kernel than the host, which a container cannot. The right tool
depends on the need: containers for packaging/shipping one app cheaply (Lab 6), VMs
when you need kernel-level isolation or a genuinely different operating system.

---

## Submission Checklist

- [ ] `Vagrantfile` at repo root; `.vagrant/` is git-ignored (already in `.gitignore`)
- [ ] `submissions/lab5.md` (this file) with all design answers
- [ ] First 10 lines of `vagrant up`
- [ ] `curl` output from both the VM (`:8080`) and the host forward (`:18080`)
- [ ] Snapshot lifecycle: save → break → verify failure → restore → verify + timing
- [ ] PR `feature/lab5 → main` against **upstream** and against **your fork**
- [ ] Both PR URLs in Moodle
