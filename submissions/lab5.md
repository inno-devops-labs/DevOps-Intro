# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

See [`Vagrantfile`](../Vagrantfile) at the repo root. It boots an Ubuntu 22.04 LTS VM, forwards `127.0.0.1:18080 -> guest:8080`, syncs `./app` into the guest, caps the VM at 2 vCPU / 1024 MB RAM, and installs Go 1.24.5 via a shell provisioner.

### `vagrant up` output (first lines)

```
==> default: Box 'ubuntu/jammy64' could not be found. Attempting to find and install...
==> default: Adding box 'ubuntu/jammy64' (v20241002.0.0) for provider: virtualbox
==> default: Successfully added box 'ubuntu/jammy64' (v20241002.0.0) for 'virtualbox'!
==> default: Importing base box 'ubuntu/jammy64'...
==> default: Setting the name of the VM: quicknotes-vm
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
==> default: Mounting shared folders...
    default: C:/Users/ivana/DevOps-Intro/app => /home/vagrant/app
==> default: Running provisioner: shell...
    default: Installing Go 1.24.5...
    default: go version go1.24.5 linux/amd64
```

> Note: on the very first `vagrant up` the guest exceeded the default boot timeout once; `vagrant reload` booted it cleanly (first-boot disk warm-up). Subsequent boots are ~45s (see Bonus).

### QuickNotes started as a service inside the VM

```bash
vagrant ssh -c "sudo systemd-run --unit=quicknotes --working-directory=/home/vagrant/app /tmp/qn"
# Running as unit: quicknotes.service
```

### `curl` output — from inside the VM

```bash
vagrant ssh -c "curl -s http://localhost:8080/health"
{"notes":4,"status":"ok"}
```

### `curl` output — from the host (via port forward)

```powershell
curl.exe http://localhost:18080/health
{"notes":4,"status":"ok"}
```

The host hitting `:18080` reaches the app on the guest's `:8080` through the NAT port forward — Task 1 verified end to end.

### Design questions

**a) Synced folders — which type and why?**

We use the default VirtualBox shared-folder type (`config.vm.synced_folder "./app", "/home/vagrant/app"` with no explicit `type:`), implemented via VirtualBox Guest Additions. The trade-off: it's the only option that needs zero extra tooling on a Windows host — `rsync` syncing needs an `rsync` binary on the host (not present on plain Windows), and NFS syncing needs an NFS client, which Windows doesn't ship either. The cost is performance: VirtualBox shared folders are slower for I/O-heavy workloads (lots of small file reads/writes) than NFS or rsync, because every file operation crosses the guest-additions driver. For a small Go app with a handful of source files, that performance hit is irrelevant, so we accept it for the portability win.

**b) NAT vs Bridged vs Host-only — which mode, and why is `127.0.0.1` safer?**

We're using NAT, which is Vagrant's default network mode for VirtualBox — the guest gets a private, host-only-visible network address and reaches the internet through the host's IP. Combined with `host_ip: "127.0.0.1"` on the forwarded port, port 18080 is only reachable from processes running on the host machine itself — nothing on the local Wi-Fi/LAN can hit it. A Bridged interface, by contrast, puts the VM directly on the physical network with its own IP, visible to every other device on that network. For a course exercise running an unauthenticated demo app, that would expose QuickNotes to anyone on the same network — there's no reason to take that risk when NAT + localhost-bound forwarding gives the same functionality for the student.

**c) Provisioning options — which did you pick and why?**

We used the `shell` provisioner (inline script in the Vagrantfile) to install Go. The alternative, `ansible`/`ansible_local`, would be more powerful for managing many settings declaratively, but it's overkill for a single task ("install one specific Go version") and adds a dependency (Ansible itself, or `ansible_local` needing Ansible installed inside the guest). A plain shell script downloading the official tarball and extracting it to `/usr/local` is the simplest, most transparent option for this scope — and it sets up directly for Lab 7, where the *real* Ansible playbook will take over more complex configuration.

**d) Why pin Go to `1.24.5` instead of `1.24`?**

`1.24` alone is a moving target — it implicitly means "whatever the latest patch release of the 1.24 line is at download time," which can silently change between your `vagrant up` today and a classmate's (or your own, after `vagrant destroy && vagrant up`) next week. Pinning to `1.24.5` guarantees the exact same toolchain bytes are installed every time, anywhere — which is the entire point of Task 1's requirement #7 ("reproducible: another student running `vagrant up` from a clean clone produces the same working state"). Unpinned versions are how "works on my machine" bugs creep in.

---

## Task 2 — Snapshots: Save, Break, Restore

### Commands run

```powershell
# 1) snapshot the working VM
vagrant snapshot save clean-state
# ==> default: Snapshotting the machine as 'clean-state'...
# ==> default: Snapshot saved!

# 2) break it deliberately — wipe the Go install
vagrant ssh -c "sudo rm -rf /usr/local/go && echo removed"
# removed

# 3) verify it's broken
vagrant ssh -c "/usr/local/go/bin/go version || echo 'BROKEN: go not found'"
# bash: line 1: /usr/local/go/bin/go: No such file or directory
# BROKEN: go not found

# 4) restore from snapshot (timed below)
vagrant snapshot restore clean-state

# 5) verify recovery
vagrant ssh -c "/usr/local/go/bin/go version"
# go version go1.24.5 linux/amd64
```

### Restore timing

```powershell
Measure-Command { vagrant snapshot restore clean-state } | Select-Object TotalSeconds
# TotalSeconds : 36.22
```

Restore took **~36 seconds** to bring the VM from "Go wiped, broken" back to a fully working state — the cattle-vs-pets pattern in action: instead of debugging and reinstalling, we rolled the whole machine back in half a minute.

### Design questions

**e) Why are snapshots not backups?**

A snapshot lives inside the same VirtualBox disk-image files on the *same host disk* as the VM itself — if that disk fails, gets corrupted, or the host machine is lost or stolen, the snapshot is gone along with everything else. Snapshots also aren't versioned off-site or encrypted independently, and deleting the VM usually deletes its snapshots too. A real backup is a copy stored independently of the original — different disk, different machine, ideally different physical location — specifically so that losing the original doesn't lose the copy.

**f) Copy-on-write — disk usage at 10 snapshots vs 1?**

Copy-on-write means a snapshot doesn't duplicate the whole disk image; it freezes the current disk state as a base and starts writing all *new* changes to a fresh differencing file layered on top. So one snapshot costs almost nothing extra at the moment it's taken — disk usage only grows as new writes accumulate afterward. With 10 snapshots you get a *chain* of 10 differencing layers, each holding only the deltas since the previous one — so total disk usage is roughly the sum of all the changes made across the whole chain, not 10x the full VM size. The catch is read/restore performance: VirtualBox may need to walk back through multiple layers to reconstruct a given block, so long chains get slower to use.

**g) When is snapshotting an antipattern?**

Long chains are the problem: each additional snapshot adds another differencing-disk layer, so disk reads (and therefore restores) have to traverse more layers to find the actual data, making the VM progressively slower the longer the chain gets. It's also an antipattern to treat snapshots as a substitute for proper configuration management — if you only know how to get back to a "good" state by replaying a snapshot rather than understanding what your provisioning script does, you've effectively turned a reproducible "cattle" VM back into a hand-nursed "pet." Snapshots are best for short-lived, deliberate checkpoints (like this exercise) — not as a long-term undo history.

---

## Bonus Task — VM vs Container Resource Baseline

### B.1 — Vagrant VM (idle) measurements

```powershell
Measure-Command { vagrant up } | Select-Object TotalSeconds   # 45.15
vagrant ssh -c "free -h"                                       # used: 178Mi / total: 957Mi
vagrant ssh -c "ps -A --no-headers | wc -l"                    # 105
# disk: ~/VirtualBox VMs/quicknotes-vm folder = 2.57 GB
```

### B.2 — Docker container measurements

```powershell
docker run -d -p 28080:8080 -v "${PWD}/app:/src" -w /src golang:1.24 sh -c "go build -o /tmp/qn . && /tmp/qn"
docker stats --no-stream     # MEM USAGE: 23.05MiB
docker top <id>              # 2 processes (sh + /tmp/qn)
docker images golang:1.24 --format "{{.Size}}"   # 1.32GB
docker stop <id>; Measure-Command { docker start <id> }   # 0.23s
```

Container health check (from host): `curl.exe http://localhost:28080/health` → `{"notes":4,"status":"ok"}`

### B.3 — Comparison table

| Dimension              | Vagrant VM | Docker container |
|------------------------|-----------:|------------------:|
| Cold start             |    45.1 s  |          0.23 s   |
| Idle RAM               |   178 MiB  |          23 MiB   |
| On-disk size           |   2.57 GB  |          1.32 GB  |
| Process count (guest)  |      105   |             2     |

### Trade-off analysis

The cold-start gap was the most striking number: the container restarts ~195x faster than the VM boots (0.23s vs 45s), because the container reuses the host's already-running kernel while the VM cold-boots an entire operating system from scratch. The process count tells the same story from another angle — 105 processes (a full systemd/init/daemon stack) versus just 2 (the shell and the app), which is also why idle RAM differs ~8x. A VM is the right tool when you need real isolation, a different kernel, or to emulate a full machine (kernel modules, OS-level testing, strong security boundaries); a container is the right tool for stateless services that just need their app plus dependencies and should scale up and down fast. This data is exactly why containers won the 2014-2020 era for stateless microservices: when you're packing hundreds of short-lived service instances onto a cluster, sub-second start times and tiny per-instance memory overhead translate directly into density and cost savings that VMs structurally can't match. The one number that's *not* flattering to containers here is on-disk size (1.32 GB), but that's an artifact of using the full `golang:1.24` build image — a production multi-stage build shipping only the compiled binary would be a few MB, widening the gap further.

---

## Summary

| Task | Status |
|------|--------|
| Task 1 — Vagrantfile + QuickNotes reachable from host | ✅ `:18080/health` → 200 |
| Task 2 — snapshot save → break → restore (~36s) | ✅ |
| Bonus — VM vs container baseline | ✅ 4-metric table + analysis |
