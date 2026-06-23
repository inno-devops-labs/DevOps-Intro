# Lab 5 — QuickNotes in a Vagrant VM (libvirt/KVM)

**Author:** Karim Abdulkin (@GrandAdmiralBee)
**Branch:** `feature/lab5`
**Host:** NixOS 26.05, libvirt 10.x, vagrant 2.4.9, vagrant-libvirt 0.12.2 (qemu:///session)

> ### Note on hypervisor: libvirt/KVM, not VirtualBox
>
> The lab text suggests VirtualBox + Vagrant. My host is NixOS, where VirtualBox is not part of the standard supported toolchain in my configuration; libvirt + KVM is.
> The Lab 5 **acceptance criteria** pin the *outcome* (Ubuntu LTS VM, Go 1.24, `127.0.0.1:18080 → guest:8080` forward, design questions) and not the hypervisor.
> `vagrant-libvirt` is the official equivalent provider plugin, ships in nixpkgs as a `pkgs.vagrant` overlay, and supports all features the lab needs (port-forward, rsync, shell provisioner, snapshots).
> Design questions are answered for libvirt where mechanics differ (e.g. forwarded_port goes through an SSH tunnel in `qemu:///session`).
>
> I like qemu + kvm much more, than vbox, tbh

---

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  go_version = "1.24.5"

  config.vm.box      = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest:   8080,
    host:    18080,
    host_ip: "127.0.0.1"

  # rsync: one-way host→guest. Refresh with `vagrant rsync` or `vagrant rsync-auto`.
  config.vm.synced_folder "./app", "/home/vagrant/app",
    type: "rsync",
    rsync__exclude: ["data/", "quicknotes"]

  config.vm.provider :libvirt do |lv|
    lv.uri    = "qemu:///session"   # user-session libvirt, no sudo
    lv.driver = "kvm"
    lv.cpus   = 2
    lv.memory = 1024
  end

  config.vm.provision "shell",
    name:       "install-go-#{go_version}",
    privileged: true,
    inline: <<~SHELL
      set -euo pipefail
      need="go#{go_version}"
      have="$(/usr/local/go/bin/go version 2>/dev/null | awk '{print $3}' || true)"
      if [ "$have" = "$need" ]; then
        echo "go already at $need — skipping download"
        exit 0
      fi
      tarball="go#{go_version}.linux-amd64.tar.gz"
      cd /tmp
      curl -fsSL -o "$tarball" "https://go.dev/dl/$tarball"
      rm -rf /usr/local/go
      tar -C /usr/local -xzf "$tarball"
      echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
      chmod 0644 /etc/profile.d/go.sh
      /usr/local/go/bin/go version
    SHELL
end
```

### `vagrant up` — first 10 lines (after box cached locally... Russian superior internet)

```
Bringing machine 'default' up with 'libvirt' provider...
[fog][WARNING] Unrecognized arguments: libvirt_ip_command
==> default: Checking if box 'bento/ubuntu-24.04' version '202508.03.0' is up to date...
==> default: Creating image (snapshot of base box volume).
==> default: Creating domain with the following settings...
==> default:  -- Name:              DevOps-Intro_default
==> default:  -- Description:       Source: /home/karim/Dev/DevOps-Intro/Vagrantfile
==> default:  -- Domain type:       kvm
==> default:  -- Cpus:              2
==> default:  -- Feature:           acpi
```

### Evidence — Go installed, sync worked, port-forward reachable

**Inside the VM:**

```console
$ vagrant ssh -c 'go version && ls -la /home/vagrant/app'
go version go1.24.5 linux/amd64
total 52
drwxr-xr-x 2 vagrant vagrant 4096 Jun 23 19:08 .
drwxr-x--- 6 vagrant vagrant 4096 Jun 23 19:08 ..
-rw-r--r-- 1 vagrant vagrant  145 Jun 23 19:08 .golangci.yml
-rw-r--r-- 1 vagrant vagrant   27 Jun 23 19:08 go.mod
-rw-r--r-- 1 vagrant vagrant 4801 Jun 23 19:08 handlers.go
-rw-r--r-- 1 vagrant vagrant 3471 Jun 23 19:08 handlers_test.go
-rw-r--r-- 1 vagrant vagrant 1773 Jun 23 19:08 main.go
-rw-r--r-- 1 vagrant vagrant  316 Jun 23 19:08 Makefile
-rw-r--r-- 1 vagrant vagrant 1151 Jun 23 19:08 README.md
-rw-r--r-- 1 vagrant vagrant  756 Jun 23 19:08 seed.json
-rw-r--r-- 1 vagrant vagrant 2241 Jun 23 19:08 store.go
-rw-r--r-- 1 vagrant vagrant 1819 Jun 23 19:08 store_test.go
```

```console
$ vagrant ssh -c 'cd /home/vagrant/app && go build -o /tmp/qn .'
$ vagrant ssh -c 'nohup /tmp/qn > /tmp/qn.log 2>&1 & disown; sleep 2; head -n 5 /tmp/qn.log'
2026/06/23 19:09:38 quicknotes listening on :8080 (notes loaded: 0)

$ vagrant ssh -c 'curl -s http://localhost:8080/health'
{"notes":0,"status":"ok"}
```

**From the host through the port-forward:**

```console
$ curl -s http://localhost:18080/health
{"notes":0,"status":"ok"}
```

Acceptance criteria met: Ubuntu LTS box boots clean, Go 1.24.5 installed by provisioner, port 18080 on host loopback reaches guest 8080.

### Design questions

#### a) Synced folder type — **rsync**

I picked `rsync`. Trade-off vs the alternatives:

| Type        | Bidirectional | Daemon required | Cross-provider | Notes |
|-------------|---------------|-----------------|----------------|-------|
| `virtualbox`| yes           | guest agent     | VBox only      | Unavailable on libvirt. |
| `nfs`       | yes           | host nfsd + sudo| any            | Needs root on host to manage exports; firewall pain. |
| `smb`       | yes           | Samba           | any            | Heavy; Windows-centric. |
| `rsync`     | **no** (host→guest, one-way) | none (rsync on both ends) | any | What I picked. |

Why rsync wins for this lab:
- **No root**, no daemons on host — important for `qemu:///session` rootless setup.
- **Provider-agnostic** — if I switch back to VirtualBox tomorrow (nah), `Vagrantfile` doesn't change.
- **`.gitignore`-style exclude** built-in (`rsync__exclude: ["data/", "quicknotes"]` keeps the per-VM JSON store and host-side built binary out of the guest).

Cost: changes I make on the host don't auto-propagate into the guest. I have to run `vagrant rsync` after edits, or `vagrant rsync-auto` for a watcher.
This bit me during this lab — the first `vagrant up` was interrupted on the SSH wait (proxychains4 wasn't configured for localnet of vagrant),
so the synced-folder stage never ran, and a manual `vagrant rsync` was needed after `vagrant destroy && vagrant up`.

#### b) NAT vs Bridged vs Host-only — **NAT (default), forward bound to 127.0.0.1**

The VM uses libvirt's default NAT network, and `forwarded_port` declares `host_ip: "127.0.0.1"`. In `qemu:///session` mode vagrant-libvirt implements forwarded_port via an SSH tunnel, which is implicitly loopback-bound — same semantics as VirtualBox's NAT rule with `host_ip`, different mechanism.

Why this is safer than Bridged for a course exercise:

- **Only my machine can access it.** Even if QuickNotes had auth bypass, the only network that can reach `:18080` is `lo` on my host. The dorm wifi and my LAN can't see it.
- **No L2 presence.** Bridged would give the guest a MAC visible to neighbors, a DHCP lease from the LAN router, and broadcast traffic both directions.
None of that is needed for a course exercise. (Remember lection about ISO levels for DevOps)
- **Misconfigured firewall on host can't accidentally expose port.** With NAT + 127.0.0.1 bind, *no firewall* can expose it because the listening socket is on loopback. There is no rule to forget.

Bridged is the right tool when the VM needs to be a real host on the network (e.g., a database that other VMs connect to, home server apps...).
For dev environment, NAT-with-loopback-forward is strictly safer.

#### c) Provisioner — **shell**

For installing one specific Go tarball into a fresh Ubuntu, `shell` is the right tool:
- Logic is visible inline in the Vagrantfile — no separate playbook to grep through.
- Zero extra agents in the guest — `ansible_local` would install Ansible inside the VM only to run six lines of bash.
- **Idempotent** — the inline script reads `/usr/local/go/bin/go version`, compares to the pinned `go1.24.5`, and exits early if already installed. So `vagrant provision` is safe to re-run and `vagrant reload --provision` doesn't redownload.

Ansible earn their keep when there are many cooperating roles (users, services, files, package matrices) that benefit from declarative convergence. Lab 7 will introduce Ansible against this same VM — that's the right point. Shell, here, costs less and reads more clearly.

#### d) Why pin Go to `1.24.5`, not `1.24`

`1.24` is a *moving minor series*. When Go releases `1.24.6` tomorrow, the same Vagrantfile would install a *different* binary. That breaks three things:

1. **Reproducibility.** A classmate who runs `vagrant up` a week later would not get my baseline. The acceptance criterion "another student running `vagrant up` from a clean clone produces the same working state" implicitly requires immutable artefacts.
2. **The snapshot baseline (Task 2).** "Restore to clean-go-installed" must mean the same `go version` six months from now. A floating tag would invalidate the snapshot's meaning over time.
3. **CI/VM parity.** Lab 3's CI uses `1.24` for matrix testing; pinning the VM gives me one anchored end of the comparison if a CI failure ever needs to be reproduced locally.

`1.24.5` is an immutable artefact at a known SHA; `go.dev/dl/go1.24.5.linux-amd64.tar.gz` either resolves or 404s — never something else.

---

## Task 2 — Snapshots: Save, Break, Restore

### Commands run

```console
$ vagrant ssh -c 'pkill -f /tmp/qn || true'   # quiesce QuickNotes

$ vagrant snapshot save clean-go-installed
==> default: Snapshotting the machine as 'clean-go-installed'...
==> default: Snapshot saved! ...

$ vagrant ssh -c '/usr/local/go/bin/go version'
go version go1.24.5 linux/amd64

$ vagrant ssh -c 'sudo rm -rf /usr/local/go && echo DELETED'
DELETED

$ vagrant ssh -c '/usr/local/go/bin/go version' || echo "BROKEN: confirmed exit $?"
bash: line 1: /usr/local/go/bin/go: No such file or directory
BROKEN: confirmed exit 127

$ time vagrant snapshot restore clean-go-installed
==> default: Restoring the snapshot 'clean-go-installed'...
vagrant snapshot restore clean-go-installed  0.66s user 0.16s system 25% cpu 3.274 total

$ vagrant ssh -c '/usr/local/go/bin/go version'
go version go1.24.5 linux/amd64

$ vagrant snapshot list
==> default:
clean-go-installed
```

### Restore time

**`real 3.274 s`** — from "Go install wiped, exit 127" back to a working `go1.24.5 linux/amd64`. That's faster than re-downloading the Go tarball from go.dev, let alone re-provisioning the whole VM (~18s, see Bonus).

### Design questions

#### e) Snapshots are not backups

A snapshot sits on the **same qcow2 file**, in the **same storage pool**, on the **same physical disk**, on the **same host** as the live VM. Anything that takes out one of those takes out both:

- Disk dies → both gone.
- `vagrant destroy` → snapshots gone with the VM (they live with the domain, not separately).
- `rm -rf ~/.local/share/libvirt/images/` → both gone.
- Host bricked, stolen, encrypted by ransomware → both gone.

A backup, properly defined, is *off-host*, *off-disk*, *point-in-time-immutable*. Snapshots are point-in-time but **reversible** and **local**. They're a dev-loop reset tool, not a recovery tool — that's why a 3-second restore is a feature, not a substitute for nightly `borg` to S3.

#### f) Copy-on-write under libvirt — disk math

`qcow2` (libvirt's backing format) implements snapshots as either internal blocks-with-metadata or external overlay files. Both are COW: a fresh snapshot records *only the delta* from the moment it was taken.

| Scenario                   | Disk cost                                  |
|----------------------------|--------------------------------------------|
| 1 snapshot, idle VM        | ~few KB metadata                           |
| 10 snapshots, idle VM      | ~few × 10 KB — basically still nothing     |
| 10 snapshots, busy VM      | proportional to *writes between snapshots* — can balloon |

The reason: snapshots share unchanged blocks. The cost grows only when the VM **modifies** a block — that block has to be duplicated so the older snapshot's view of the disk stays intact (write-on-write). For a VM that mostly sits idle between snapshots, ten of them are nearly free. For a VM running a database with constant writes, each snapshot tax grows fast.

(Same answer applies to VirtualBox VDI differencing disks — same COW pattern, different on-disk format.)

#### g) When is snapshotting an antipattern?

**Long chains.** Every layer adds another COW indirection a read may have to walk to find the actual block. Read performance degrades as the chain grows; backups and migrations get harder; and a corruption anywhere in the chain kills everything above it. The textbook bad case is a VM with 30 snapshots accumulated over a year — that's a *pet*, not cattle.

Snapshots are also an antipattern when used as a substitute for **proper change management** on production: "snapshot before the prod migration" tempts you to skip the dry-run, skip the rehearsal, and skip the postmortem when rollback is one command away. Restorability is real and useful, but it normalizes deploying without reading.

Rule of thumb: snapshots are excellent for the dev loop (lab2, dev2, lab3 today), bad for "indefinite history of my pet VM".

---

## Bonus — VM vs container baseline (real numbers, same hardware, same session)

Measurements taken back-to-back on my NixOS 26.05 PC with the Vagrant VM from Task 1 (idle, QuickNotes stopped) and a Podman container (Docker-compat) running the same QuickNotes from `app/`.

### How the container was started

```bash
docker pull golang:1.24

CID=$(docker run -d -p 28080:8080 -v "$PWD/app:/src" -w /src golang:1.24 \
  sh -c 'go build -o /tmp/qn . && /tmp/qn')
```

(`docker` on my host is a `podman` compat alias via `virtualisation.podman.dockerCompat = true;`. Same metrics either way — both report through the same OCI image/container model.)

### Numbers

| Dimension                    |                              Vagrant VM (libvirt/KVM) |                                    Container (podman) |
|------------------------------|------------------------------------------------------:|------------------------------------------------------:|
| Cold start                   |                          **18.57 s** (`vagrant up`)   |                       **0.10 s** (`docker start`)     |
| Cold stop                    |                          6.33 s (`vagrant halt`)      | 10.18 s (SIGTERM ignored, SIGKILL after 10 s timeout) |
| Idle RAM (guest / container) |                       308 MiB used / 961 MiB capped   |                                              7.51 MB  |
| Process count (guest scope)  |                                                  119  |                                                    2  |
| On-disk size                 |             5.9 GiB overlay + 4.7 GiB base = **10.6 GiB** | 920 MB image + 96 MB container overlay = **1.02 GiB** |

### Reading the numbers

The number that surprised me was **the stop column, not the start column**. I expected the container to win every row — instead `docker stop` took 10 seconds against `vagrant halt`'s 6 seconds. The reason is in the warning Docker printed:

```
StopSignal SIGTERM failed to stop container ... in 10 seconds, resorting to SIGKILL
```

QuickNotes is a vanilla Go `http.Server` that doesn't trap SIGTERM — Docker waits the full grace period, then kills. The VM is faster because Ubuntu's systemd *does* propagate the shutdown signal through its normal stop sequence. So "containers win on lifecycle" is true **if the app is well-behaved**; otherwise the lifecycle slowness shows up at the boundary, not at the kernel level.

Cold *start*, by contrast, is where the container truly wins — **~190× faster** (0.10 s vs 18.57 s). The "container boot" is just `exec` of an existing binary in a new namespace. The VM has to schedule a CPU, run grub, run systemd, parse cloud-init, bring up networking, get a DHCP lease, and start sshd before `vagrant up` declares ready. 119 processes vs 2 explains the RAM gap too — the VM is carrying systemd, journald, snapd, rsyslogd, sshd, cron, agetty, etc. before QuickNotes contributes its 1 MB.

**Which workloads fit which model:**

- VMs win when you need **kernel-level isolation**: different kernel versions per tenant, kernel-exploit boundaries between tenants (cloud sells you VMs for a reason), GPU passthrough, kernel modules. They're also the boundary at the hypervisor in cloud — every EC2/Compute Engine instance is ultimately a VM.
- Containers win for **stateless microservices** where startup cost multiplies with scale events: Kubernetes pod rollouts, serverless burst patterns, CI ephemeral runners, blue/green deploys. 18 s × 200 pods = an outage; 100 ms × 200 pods = a rollout.

**Why containers won the 2014–2020 era for stateless microservices:** the data above is the data. Cloud-native serving turned cold-start latency and per-instance RAM into per-request cost metrics. Shaving 18 seconds off pod startup is a tractable SLO problem; the same shave on a VM was never going to happen — the VM has to *be a host*. Containers traded one kind of isolation (kernel) for another (namespace + cgroup) and got 190× cold start and 40× RAM density in return. For services that don't need kernel isolation, that's a no-brainer trade.

---

## Pitfalls I hit (for the next student)

- **proxychains breaks vagrant SSH** on the libvirt NAT network (192.168.122.0/24). proxychains tried to route a *local-network* SSH connection through my SOCKS proxy. Fix: add `localnet 192.168.122.0/255.255.255.0` to `proxychains.conf`, or just don't run `vagrant up` under proxychains after the box is cached.
- **Interrupted first `vagrant up` skips the rsync stage.** If you Ctrl+C on "SSH connection refused" retries, the second `vagrant up` sees the VM is already running and goes straight to the provisioner — no synced folder. Either `vagrant destroy -f && vagrant up` cleanly, or run `vagrant rsync` manually.
- **`vagrant ssh -c` doesn't load `/etc/profile.d/go.sh`** (non-interactive shell — no `/etc/profile` sourcing). Use the absolute path `/usr/local/go/bin/go` in `vagrant ssh -c` commands, or `vagrant ssh` interactively. The provisioner's PATH setup is for *interactive logins*, which is the right behaviour.
- **Podman/Docker `pull` doesn't honour `proxychains`** — podman is daemonless but spawns helper processes that escape LD_PRELOAD. The clean fix is `HTTPS_PROXY=socks5://...` in the env when you pull, or `~/.config/containers/containers.conf` `[engine].env` entry.

---

## Checklist

- [x] `Vagrantfile` at repo root, `.vagrant/` already in `.gitignore`
- [x] All four Task 1 design questions (a, b, c, d) answered
- [x] Snapshot save → break → restore demonstrated, restore time captured
- [x] All three Task 2 design questions (e, f, g) answered
- [x] Bonus four-row comparison table from real measurements + analysis
- [x] Honest "I used libvirt, not VirtualBox" call-out at the top
- [x] Commits signed (`git log --show-signature`)
