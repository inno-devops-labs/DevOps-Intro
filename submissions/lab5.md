# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

**Author:** Kolpakova Valeriia — v.kolpakova@innopolis.university

**One deviation from the Prerequisites:** they ask for VirtualBox 7.1.x, and I ran **7.2.20**
on an Apple Silicon (M1 Pro) host. VirtualBox 7.1 is the release that first supported macOS
ARM64 as a *host*, and 7.2.20 is the current build of that line; the box Vagrant selected is
`bento/ubuntu-24.04` for `virtualbox (arm64)`. Everything else follows the brief.

---

## Task 1 — Vagrant Up + Run QuickNotes Inside

### `Vagrantfile` (repo root)

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes"

  # Bound to the loopback address, so the guest's 8080 is reachable at
  # 127.0.0.1:18080 on this machine and nowhere else on the network.
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # Only app/ is shared: the VM has no reason to see .git or submissions/.
  config.vm.synced_folder "./app", "/srv/quicknotes"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 1024
  end

  # Installs a pinned Go from the upstream tarball. Re-running `vagrant provision`
  # is a no-op once the right version is in place.
  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    GO_VERSION=1.24.13
    ARCH="$(dpkg --print-architecture)"

    if [ "$(/usr/local/go/bin/go version 2>/dev/null | awk '{print $3}')" = "go${GO_VERSION}" ]; then
      echo "go${GO_VERSION} already installed, nothing to do"
      exit 0
    fi

    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm -f /tmp/go.tar.gz

    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    chmod +x /etc/profile.d/go.sh

    /usr/local/go/bin/go version
  SHELL
end
```

The architecture is read from `dpkg --print-architecture` rather than hardcoded, so the same
file provisions correctly whether the box is arm64 or amd64.

### First lines of `vagrant up`

```console
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'bento/ubuntu-24.04' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'bento/ubuntu-24.04'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/bento/ubuntu-24.04
==> default: Adding box 'bento/ubuntu-24.04' (v202510.26.0) for provider: virtualbox (arm64)
    default: Downloading: https://vagrantcloud.com/bento/boxes/ubuntu-24.04/versions/202510.26.0/providers/virtualbox/arm64/vagrant.box
==> default: Successfully added box 'bento/ubuntu-24.04' (v202510.26.0) for 'virtualbox (arm64)'!
==> default: Importing base box 'bento/ubuntu-24.04'...
```

and the tail, showing both mounts and the provisioner:

```console
==> default: Mounting shared folders...
    default: /.../DevOps-Intro => /vagrant
    default: /.../DevOps-Intro/app => /srv/quicknotes
==> default: Running provisioner: shell...
    default: Running: inline script
    default: go version go1.24.13 linux/arm64
```

### Verification (1.4)

```console
$ vagrant ssh -c 'go version'
go version go1.24.13 linux/arm64
```

**From inside the VM:**

```console
$ vagrant ssh -c 'cd /srv/quicknotes && go build -o /tmp/qn . && (setsid nohup /tmp/qn &) ; sleep 3; curl -s http://localhost:8080/health'
2026/09/25 01:56:01 quicknotes listening on :8080 (notes loaded: 4)
{"notes":4,"status":"ok"}
```

**From the host, through the port forward:**

```console
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

And the forward really is loopback-only, not exposed to the network:

```console
$ lsof -nP -iTCP:18080 -sTCP:LISTEN
COMMAND    PID   USER   FD   TYPE  NODE NAME
VBoxHeadl 6822 ivozhs   12u  IPv4   TCP 127.0.0.1:18080 (LISTEN)
```

Re-provisioning is a no-op, so the script is idempotent:

```console
$ vagrant provision
==> default: Running provisioner: shell...
    default: go1.24.13 already installed, nothing to do
```

### 1.2 — Design questions

**a) Synced folders: `nfs`, `rsync`, `virtualbox`, `smb` — which, and what's the trade-off?**

I used the default, **VirtualBox shared folders** (`vboxsf`). It needs no configuration beyond
one line, no daemon on the host, and the Guest Additions that make it work already ship in the
bento box — the mount just appeared in the `vagrant up` output above, and `go build` compiled
straight out of it.

The trade-off is performance and fidelity. `vboxsf` is slow on workloads that touch thousands
of small files, and it does not propagate inotify events, so file-watchers inside the guest
often miss host edits. `rsync` is the fastest for guest-side reads because the files are
genuinely local, but it is one-way and one-shot — you need `vagrant rsync-auto` running to keep
it fresh, and guest-side changes never come back. `nfs` beats vboxsf substantially on large
trees but requires an NFS server on the host and `sudo` to edit `/etc/exports`. `smb` is the
Windows-host equivalent and wants credentials.

For QuickNotes — a handful of `.go` files compiled inside the VM — vboxsf's performance ceiling
is never reached, so the cheapest option is also the right one. On a Node project with
`node_modules` I would have reached for `rsync` instead.

**b) NAT vs Bridged vs Host-only — which, and why is loopback-bound forwarding safer than Bridged?**

I'm on **NAT**, Vagrant's default. The guest sits behind a virtual NAT: outbound traffic works,
and inbound arrives only through ports I forward explicitly.

Bridged would put the VM directly onto the physical LAN with its own DHCP address. Everything
listening in the guest would then be reachable by every other host on that network — university
wifi, a coffee shop, a shared flat — with no host firewall between them and a box that ships
the well-known `vagrant`/`vagrant` credentials and a published insecure SSH key. That is a
genuinely bad combination for a machine that exists to be thrown away and rebuilt.

Binding the forward to `127.0.0.1` narrows the exposure twice over: exactly one port, and only
to processes on this laptop. The `lsof` output above confirms it is `127.0.0.1:18080`, not
`0.0.0.0:18080` — which is the difference between "my machine can reach it" and "the network
can reach it".

**c) Provisioning: `shell`, `ansible`, `ansible_local`, `puppet`, `chef` — which and why?**

**`shell`.** The entire task is "put one pinned tarball in `/usr/local` and add it to PATH" —
about eight lines of bash. Every other option would first have to install itself (Ansible on
the host for `ansible`, inside the guest for `ansible_local`, an agent or agentless bootstrap
for Puppet/Chef) in order to express the same eight lines. That is more moving parts than the
problem has complexity, and more things to break on a clean clone, which requirement 7 cares
about.

There is also a course-level reason: Lab 7 deploys to this same VM *via Ansible*. Introducing
Ansible here would duplicate that lab and blur what each one teaches.

The honest cost is that shell is imperative, not declarative — nothing makes it idempotent for
free. That is my responsibility, which is why the script checks the installed version first and
exits early, and why I verified the no-op above.

**d) Why pin Go to a point release (`1.24.13`) instead of `1.24`?**

Because `1.24` is not a version, it is a moving pointer: it resolves to whatever the newest
patch happens to be at download time. Two students running `vagrant up` a week apart would get
different toolchains from an identical `Vagrantfile`, and the same student rebuilding next month
would silently drift — which is precisely what requirement 7 ("another student running
`vagrant up` from a clean clone produces the same working state") rules out. A point release
makes the result deterministic.

The cost is that pinning freezes security patches too: you now own an upgrade cadence instead
of getting fixes by accident. Lab 6 made that concrete — Trivy found 19 HIGH stdlib CVEs in
binaries built with this exact Go 1.24.13, all fixed only in 1.25.8+. Pinning buys
reproducibility, not safety, and those are different things.

---

## Task 2 — Snapshots: Save, Break, Restore

### 2.1 — The exact commands

**Save:**

```console
$ vagrant snapshot save clean-go-1.24.13
==> default: Snapshotting the machine as 'clean-go-1.24.13'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`.

$ vagrant snapshot list
clean-go-1.24.13
```

**Break** — wipe the Go installation and the PATH entry that finds it:

```console
$ vagrant ssh -c 'sudo rm -rf /usr/local/go /etc/profile.d/go.sh'
```

**Verify it's broken:**

```console
$ vagrant ssh -c 'go version'
bash: line 1: go: command not found
```

**Restore, timed:**

```console
$ time vagrant snapshot restore clean-go-1.24.13
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'clean-go-1.24.13'...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Machine booted and ready!

vagrant snapshot restore clean-go-1.24.13  1.38s user 1.01s system 18% cpu  13.075 total
```

**Verify recovery:**

```console
$ vagrant ssh -c 'go version'
go version go1.24.13 linux/arm64

$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

**Restore time: 13.075 s** to go from a destroyed toolchain back to a working machine.

One detail worth noting: the snapshot was taken while the VM was *running*, so VirtualBox
captured RAM as well as disk. The restore therefore brought back not just the Go installation
but the running QuickNotes process — the `curl` above answered immediately, with no restart.
That is a resumed machine, not a rebooted one.

### 2.2 — Design questions

**e) Snapshots are not backups. Why?**

Because a snapshot lives on the same disk, in the same VM directory, under the same hypervisor
as the thing it is supposed to protect — it shares every failure domain with its original. It
is useless for host disk failure or filesystem corruption (both die together), for
`vagrant destroy` or deleting the VM folder (the snapshots go with it), for ransomware
encrypting the host, and for the laptop being lost or stolen. It is also useless against slow
logical corruption, because by the time anyone notices, the damage is inside the snapshot too.

A backup is off-host, independently restorable, and retained across time. A snapshot is a fast
undo button for a change you are about to make on purpose — it protects you from your next
command, not from losing the machine.

**f) Copy-on-write: 10 snapshots vs 1?**

Taking a snapshot costs almost nothing up front. VirtualBox freezes the current disk image as
read-only and directs all subsequent writes into a new differencing image, so what consumes
space is not the snapshot itself but *the writes that happen after it*. Ten snapshots of an
idle VM occupy roughly what one does; my VM directory sits at 3.0 GB with one snapshot, and
would barely move if I took nine more right now without touching the guest.

The subtlety is that each snapshot *pins* the blocks it references. Data that would normally be
freed stays alive as long as some snapshot still needs it, so a VM that writes heavily between
snapshots can occupy far more than its nominal disk size. Deleting a snapshot is not free
either — it merges differencing images, which is I/O-heavy and slower the longer the chain.

**g) When is snapshotting an antipattern?**

When it replaces reproducible provisioning. Every snapshot in a chain is another differencing
layer that reads must traverse, so a long chain measurably degrades guest I/O, and each delete
means a bigger, riskier merge.

The deeper problem is conceptual. A machine described as "base box plus fourteen snapshots
taken over three months" is a pet: nobody can rebuild it from source, and what each layer
actually changed lives only in someone's memory. That is exactly the state Lecture 5's
cattle-not-pets framing warns against. The right move is to put the change in the
`Vagrantfile`'s provisioner and rebuild, so the machine's definition stays in git where it can
be read, reviewed and reproduced — and to keep snapshots for what they are good at: a
throwaway safety net around one risky experiment.

---

## Bonus Task — VM vs Container Resource Baseline

Both measured on the same machine (M1 Pro, 8 GB available to the hypervisor) in the same
session. The container runs the Lab 6 image, `quicknotes:lab6`, serving the same application.

| Dimension | Vagrant VM | Docker container |
|---|---:|---:|
| Cold start | **19.997 s** | **0.121 s** |
| Idle RAM | **236 MiB** (of 824 MiB) | **2.93 MiB** |
| On-disk size | **3.0 GB** | **13.1 MB** |
| Process count (guest) | **105** | **1** |

Raw evidence:

```console
# VM
$ time vagrant up                                  ->  19.997 total
$ vagrant ssh -c 'free -h'                         ->  Mem: 824Mi total, 236Mi used
$ vagrant ssh -c 'ps -A --no-headers | wc -l'      ->  105
$ du -sh ~/VirtualBox\ VMs/DevOps-Intro_default_*  ->  3.0G

# Container
$ time docker start qn-bonus                       ->  0.121 total
$ docker stats --no-stream                         ->  2.93MiB / 7.654GiB
$ docker top qn-bonus                              ->  1 line: 65532 /app/quicknotes
$ docker images quicknotes:lab6                    ->  13.1MB
```

**What surprised me** was the process count, more than the headline ratios. 105 against 1 is
the whole story in one number: the VM is running a complete Linux — systemd, journald, cron,
snapd, an SSH daemon, udev — none of which QuickNotes asked for, all of which must boot, hold
RAM, and be patched. The 165× gap in start time and the 80× gap in memory are downstream of
that one fact, not separate findings. The 229× disk difference I half-expected, but it is worth
saying that 3.0 GB buys a real kernel and the ability to run anything, while 13.1 MB buys one
static binary and nothing else.

**Each model is right for different work.** The container wins decisively for stateless
services that scale horizontally: if starting an instance costs 0.12 s and 3 MB, you can run
hundreds per host and treat them as disposable. The VM earns its overhead when you need a real
kernel — different kernel version or OS from the host, kernel modules, strict isolation between
tenants, or emulating a full production host for configuration management, which is exactly
what Lab 7 will do with Ansible against this machine.

**Why containers won 2014-2020 for stateless microservices** is visible right in the table: the
architecture they displaced was paying a ~20-second, ~236 MB, ~3 GB tax per service *for a copy
of an operating system that the service never used*. Once tooling made it practical to ship
just the process and its dependencies, that tax became optional — and for a stateless HTTP
service with no kernel requirements of its own, optional means gone.
