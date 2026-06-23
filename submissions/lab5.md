# Lab 5 Submission

## Task 1: Vagrant Up + Run QuickNotes Inside

### Vagrantfile

The `Vagrantfile` at the repo root:

- uses the `bento/ubuntu-24.04` box (Ubuntu 24.04 LTS)
- sets the hostname to `quicknotes-vm`
- forwards `127.0.0.1:18080` -> guest `:8080`
- syncs host `./app` -> guest `/home/vagrant/app`
- caps the VM at 2 vCPU / 1024 MB RAM
- installs Go 1.24.5 via an idempotent shell provisioner

See [Vagrantfile](../Vagrantfile).

### `vagrant up` — first 10 lines

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'bento/ubuntu-24.04' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'bento/ubuntu-24.04'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/bento/ubuntu-24.04
==> default: Adding box 'bento/ubuntu-24.04' (v202510.26.0) for provider: virtualbox (amd64)
    default: Downloading: https://vagrantcloud.com/bento/boxes/ubuntu-24.04/versions/202510.26.0/providers/virtualbox/amd64/vagrant.box
==> default: Successfully added box 'bento/ubuntu-24.04' (v202510.26.0) for 'virtualbox (amd64)'!
==> default: Importing base box 'bento/ubuntu-24.04'...
```

Tail of provisioning confirms the Go install:

```text
==> default: Mounting shared folders...
    default: D:/Desktop/DevOps-Intro/app => /home/vagrant/app
==> default: Running provisioner: shell...
    default: Installing Go 1.24.5...
    default: go version go1.24.5 linux/amd64
```

> **Environment notes:**
>
> - Vagrant 2.4.9 crashes with `Log level must be in 0..8` when fetching a box. Fix: set `VAGRANT_CLOUD_LOG=error` before `vagrant up`.
> - Host had Hyper-V active (WSL2 + Docker). VirtualBox 7.2 ran the VM anyway, so no need to disable it.

### Verify

**Inside the VM:**

```bash
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64

$ vagrant ssh -c 'cd /home/vagrant/app && go build -o /tmp/qn . \
    && (DATA_PATH=/tmp/notes.json setsid /tmp/qn >/tmp/qn.log 2>&1 </dev/null &) \
    && sleep 3 && curl -s http://localhost:8080/health'
{"notes":4,"status":"ok"}

$ vagrant ssh -c 'ss -ltnp | grep 8080'
LISTEN 0  4096  *:8080  *:*  users:(("qn",pid=3099,fd=3))
$ vagrant ssh -c 'cat /tmp/qn.log'
2026/06/23 19:51:34 quicknotes listening on :8080 (notes loaded: 4)
```

**From the host (via the `127.0.0.1:18080` port forward):**

```text
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}

$ curl -s http://localhost:18080/notes
[{"id":1,"title":"Welcome to QuickNotes",...},
 {"id":2,"title":"Read app/main.go first",...},
 {"id":3,"title":"DevOps mantra",...},
 {"id":4,"title":"Endpoint cheat-sheet",...}]
```

### 1.2 Design questions

**a) Synced folder type — which and why? Trade-off?**

I used the default **VirtualBox shared folder** — no extra host tooling, and a
live two-way mount so host edits show up in the guest instantly. Trade-off:
it's slow for heavy small-file I/O, where `rsync` (one-way copy) or `nfs`
(faster, but needs a daemon and a Linux/macOS host) would do better. For one
small Go service, simplicity wins.

**b) NAT vs Bridged vs Host-only; why is loopback-bound forwarding safer?**

I use Vagrant's default **NAT** with a forwarded port. NAT hides the guest from
the LAN unless a port is explicitly forwarded, and I bound the forward to
`127.0.0.1`, so `:18080` is reachable only from the host. A **Bridged**
interface would give the VM its own LAN IP, exposing the unauthenticated
service to everyone on the network — needless attack surface for a lab.

**c) Provisioner — which and why?**

The **`shell`** provisioner. Installing one Go tarball is a few imperative
steps, and an inline script handles that with no extra dependencies.
`ansible`/`puppet`/`chef` pay off across many hosts; for a single VM with one
tool to install, they're overkill.

**d) Why pin `1.24.5` instead of `1.24`?**

`go.dev/dl/` only serves full point releases (`go1.24.5...tar.gz`), not a bare
`1.24`. Pinning the exact patch keeps every `vagrant up` reproducible — same
compiler today or in six months. Floating on `1.24` would silently pull
whatever the latest patch is, reintroducing version drift.

---

## Task 2 — Snapshots: Save, Break, Restore

### Commands: save -> break -> verify -> restore -> verify

```bash
$ vagrant snapshot save quicknotes-clean-go124
==> default: Snapshotting the machine as 'quicknotes-clean-go124'...
==> default: Snapshot saved! ...

$ vagrant ssh -c 'sudo rm -rf /usr/local/go /usr/local/bin/go \
    /usr/local/bin/gofmt /etc/profile.d/go.sh'

$ vagrant ssh -c 'go version'
bash: line 1: /usr/local/bin/go: No such file or directory     (exit 127)

$ time vagrant snapshot restore quicknotes-clean-go124

$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

The snapshot captured the **live** machine (RAM included), so the restore
brought the QuickNotes process back with the same PID `3099`, still listening
on `:8080`.

### 6. Restore timing

```text
real 0m21.592s
user 0m0.015s
sys 0m0.000s
```

### 2.2 Design questions

**e) Snapshots are not backups — why?**

A snapshot lives on the **same disk and host** as the VM, so it's useless when
that disk dies, the laptop is lost/stolen, or run `vagrant destroy` — it
goes with the original. It also can't undo corruption that predates it: if data was already bad (or encrypted by ransomware) when snapshotted, restoring just brings the bad state back. A backup is a separate, off-host, retained copy

**f) Copy-on-write — 10 snapshots vs 1?**

Copy-on-write means a snapshot doesn't copy the disk. The current disk is
frozen as a read-only base and new writes go to a delta file, so each snapshot
costs only the blocks that changed since the last one. Ten snapshots ≈ base +
ten small deltas, usually far less than 10× the disk. The cost is on reads,
which must walk the whole delta chain

**g) When is snapshotting an antipattern?**

When the chain gets **long**. Each snapshot adds a delta layer, so long chains
mean slower reads, unbounded disk growth, and fragility — losing one delta
breaks everything after it. Snapshots should be short-lived (take → test →
restore-or-delete), not long-term history or a backup substitute. Hoarding VM
state as a "pet" instead of rebuilding from code ("cattle") is the antipattern
