# Lab 5 submission

Author: Telman Nuruzov (`Telman3000`)
Branch: `feature/lab5`
Fork: https://github.com/Telman3000/DevOps-Intro
Host: Windows 10 + VirtualBox **7.2.18** + Vagrant **2.4.9**

Course PR: https://github.com/inno-devops-labs/DevOps-Intro/pull/1622

---

## Task 1 — Vagrant up + QuickNotes inside

### Vagrantfile

Root `Vagrantfile` (also in the PR):

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Lab 5 — QuickNotes in a Vagrant VM
# Repo-root Vagrantfile: Ubuntu 24.04, Go 1.24.x, port 18080→8080, 2 vCPU / 1024 MB

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04" # Ubuntu 24.04 LTS (public box)
  config.vm.hostname = "quicknotes-vm"

  # Host-only binding: reachable from this machine, not the LAN
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1",
    auto_correct: true

  # VirtualBox shared folder (default on Windows; no extra host packages)
  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  # Shell provisioner: install pinned Go 1.24.5 (idempotent)
  config.vm.provision "shell", path: "scripts/lab5-provision.sh", privileged: true
end
```

Provisioning script: `scripts/lab5-provision.sh` installs **Go 1.24.5** from `go.dev` into `/usr/local/go`.

### First lines of `vagrant up`

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'bento/ubuntu-24.04' could not be found. Attempting to find and install...
==> default: Loading metadata for box 'bento/ubuntu-24.04'
==> default: Adding box 'bento/ubuntu-24.04' (v202510.26.0) for provider: virtualbox (amd64)
==> default: Successfully added box 'bento/ubuntu-24.04' (v202510.26.0) for 'virtualbox (amd64)'!
==> default: Importing base box 'bento/ubuntu-24.04'...
==> default: Matching MAC address for NAT networking...
==> default: Setting the name of the VM: quicknotes-lab5
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
==> default: Booting VM...
==> default: Machine booted and ready!
...
    default: Installing Go 1.24.5...
    default: go version go1.24.5 linux/amd64
    default: Go 1.24.5 provision complete.
```

(Full log also in `submissions/lab5-vagrant-up.txt`.)

### Verify

**Inside VM**

```text
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64

$ hostname
quicknotes-vm

$ curl -s http://127.0.0.1:8080/health   # after go build + run
{"notes":7,"status":"ok"}
```

**From host (port forward `127.0.0.1:18080` → guest `:8080`)**

```text
$ curl -s http://127.0.0.1:18080/health
{"notes":7,"status":"ok"}
```

Artifacts: `lab5-artifacts/go-version.txt`, `curl-guest-health.txt`, `curl-host-health.txt`.

### Design questions (1.2)

**a) Synced folders — which type and why?**  
I used the default **VirtualBox shared folder** (`config.vm.synced_folder` without an explicit type). On Windows this is the path of least friction: no NFS daemon, no `rsync` binary on the host, no SMB credentials. Trade-off: VirtualBox shared folders are slower for heavy `go build` I/O than NFS/rsync (I built in `/tmp` inside the guest for speed), and symlink behavior needs care — but for a course VM that only needs `app/` source visible, convenience beats peak throughput.

**b) NAT vs Bridged vs Host-only?**  
The VM uses Vagrant’s default **NAT** adapter, plus a **forwarded port bound to `127.0.0.1`**. Bridged would put the guest on the LAN with its own IP — any roommate/network peer could hit `:8080`. Binding the forward to localhost keeps QuickNotes reachable only from this host’s loopback, which is the right blast radius for a homework service.

**c) Why shell provisioner?**  
I used the **shell** provisioner (`scripts/lab5-provision.sh`). Installing one pinned Go tarball is a short, idempotent bash script; bringing Ansible/Chef/Puppet for a single download would be ceremony without benefit in Lab 5 (Ansible arrives properly in Lab 7 against this same VM).

**d) Why pin `1.24.5` instead of `1.24`?**  
`1.24` is a moving channel (point releases keep landing). Pinning **1.24.5** makes `vagrant up` on a clean clone download bit-identical toolchain bits today and next month, so toolchain drift cannot silently change `go test` / compile behavior between students or between grading runs.

---

## Task 2 — Snapshots: save → break → restore

### Commands + evidence

```text
# 1) Save clean state (QuickNotes working, Go installed)
vagrant snapshot save clean-working
# => Snapshot saved!
vagrant snapshot list
# => clean-working

# 2) Break: wipe the Go toolchain
vagrant ssh -c "sudo rm -rf /usr/local/go"
vagrant ssh -c "go version"
# => bash: go: command not found
#    ls: cannot access '/usr/local/go/bin/go': No such file or directory

# 3) Restore (timed with Measure-Command ≈ `time`)
vagrant snapshot restore clean-working --no-provision
# TotalSeconds ≈ 24.5 s

# 4) Verify recovery
vagrant ssh -c "go version"
# => go version go1.24.5 linux/amd64
```

**Restore wall-clock:** **~24.5 seconds** (`TotalSeconds = 24.521`).

Artifacts: `lab5-artifacts/snapshot-save.txt`, `break-verify.txt`, `snapshot-restore.txt`, `snapshot-restore-time.txt`, `restore-verify.txt`.

### Design questions (2.2)

**e) Snapshots are not backups.**  
A snapshot lives on the **same disk / same host** as the running VM. Disk failure, ransomware encrypting `VirtualBox VMs/`, or accidentally `vagrant destroy` plus deleting the VM folder take the snapshots with them. Snapshots also do not protect against logic bugs you re-introduce after restore — they are a fast undo for local experiments, not an off-site recovery plan.

**f) Copy-on-write disk usage.**  
VirtualBox snapshots are **copy-on-write**: the base disk stays; each snapshot stores only blocks that diverge after the snap. Ten snapshots of a mostly-idle VM cost far less than 10× full clones, but every write after a snap grows the delta chain — long chains still accumulate gigabytes and slow I/O.

**g) When is snapshotting an antipattern?**  
Long snapshot chains (“save before every experiment, never delete”) become slow to traverse, hard to reason about, and disk-heavy. Treating a golden snapshot as a substitute for **reproducible provisioning** (`Vagrantfile` + scripts) also creates pets: nobody knows how to rebuild the box from scratch. Prefer few named snaps + destroy/recreate from code.

---

## Bonus — VM vs Docker resource baseline

Measured on the same Windows host in one session.

| Dimension | Vagrant VM | Docker container |
|-----------|-----------:|-----------------:|
| Cold start | **~85.9 s** (`vagrant halt` then `vagrant up`, already provisioned) | **~0.26 s** (`docker stop` then `docker start`) |
| Idle RAM | **~334 MiB used** / 961 MiB guest (`free -h`; available ~627 MiB) | **~24.2 MiB** (`docker stats --no-stream`) |
| On-disk size | **~3.31 GB** (`VirtualBox VMs/quicknotes-lab5`, incl. disk + snapshots) | **~1.32 GB** (`golang:1.24` image) |
| Process count (guest) | **143** (`ps -A --no-headers \| wc -l`) | **2** in `docker top` (`sh -c …` + `/tmp/qn`); stats **PIDS=9** |

Docker run used (as suggested in the lab):

```bash
docker run -d -p 28080:8080 -v "$PWD/app:/src" -w /src golang:1.24 \
  sh -c 'go build -o /tmp/qn && /tmp/qn'
```

Host check: `curl http://127.0.0.1:28080/health` → `{"notes":7,"status":"ok"}`.

### Trade-off analysis

The cold-start gap (~86 s vs ~0.26 s) and idle RAM (~334 MiB vs ~24 MiB) surprised me even knowing the theory — a full Ubuntu userspace is expensive when the workload is a tiny Go binary. VMs win when you need a **kernel boundary**, real systemd/networking experiments, or a durable “machine” for Ansible (Lab 7); containers win for **stateless microservices** where density, second-scale restarts, and thin images matter. The 2014–2020 container wave makes sense from this table alone: packing dozens of services per host became feasible once you stopped shipping a guest kernel and init per app, cutting both RAM and boot time by orders of magnitude while keeping a good-enough isolation story for many SaaS workloads.

Artifacts: `lab5-artifacts/vm-*.txt`, `docker-*.txt`.
