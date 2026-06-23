# Lab 5 submission

**Host:** Apple Silicon Mac (`arm64`), 24 GB RAM. **Hypervisor:** VirtualBox 7.2 + Vagrant 2.4.9. **Box:** `bento/ubuntu-24.04` (arm64).

---

## Task 1 — Vagrant Up + QuickNotes Inside

### Vagrantfile

Repo root: [`Vagrantfile`](../Vagrantfile) · provisioner: [`scripts/vagrant-provision.sh`](../scripts/vagrant-provision.sh)

```ruby
# frozen_string_literal: true

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-dev"
  config.vm.boot_timeout = 600

  config.vm.network "forwarded_port",
                    guest: 8080, host: 18080, host_ip: "127.0.0.1", id: "quicknotes"

  config.vm.synced_folder "app", "/home/vagrant/quicknotes",
                          type: "rsync", rsync__auto: true, rsync__exclude: [".git/"]

  config.vm.provider "virtualbox" do |vb|
    vb.name = "devops-intro-quicknotes"
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", path: "scripts/vagrant-provision.sh"
end
```

> `generic/ubuntu2404` returned 404 on Vagrant Cloud; replaced with **`bento/ubuntu-24.04`** (arm64 for Apple Silicon).

### First `vagrant up`

First 10 lines: [`vagrant-up-head.txt`](attachments/lab5/vagrant-up-head.txt) · full log: [`vagrant-up-full.txt`](attachments/lab5/vagrant-up-full.txt)

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'bento/ubuntu-24.04'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'bento/ubuntu-24.04' version '202510.26.0' is up to date...
==> default: Setting the name of the VM: devops-intro-quicknotes
...
==> default: Running provisioner: shell...
    default: go version go1.24.5 linux/arm64
```

### Verify

| Check | Output |
|-------|--------|
| `go version` (guest) | `go version go1.24.5 linux/arm64` |
| `curl localhost:8080/health` (guest) | `{"notes":5,"status":"ok"}` |
| `curl 127.0.0.1:18080/health` (host) | `{"notes":5,"status":"ok"}` |

Full log: [`task1-verify.txt`](attachments/lab5/task1-verify.txt) · [`curl-host-health.txt`](attachments/lab5/curl-host-health.txt)

### Design questions (Task 1.2)

**a) Synced folder type — which and why?**

**`rsync`** was chosen. On macOS + VirtualBox (especially Apple Silicon), native `virtualbox` shared folders often break or perform poorly; `nfs` requires extra Mac configuration. `rsync` is reliable: on `vagrant up`/`reload`, code from `./app` is copied to `/home/vagrant/quicknotes`. Trade-off: host changes are not visible in the guest instantly — run `vagrant rsync-auto` or `vagrant rsync` after edits.

**b) NAT vs Bridged vs Host-only?**

**NAT** is used (Vagrant default). Port forward `127.0.0.1:18080 → guest:8080` is reachable only on the host localhost. **Bridged** would give the VM an IP on the LAN — QuickNotes would be visible to others on Wi‑Fi; for a lab VM that is unnecessary attack surface.

**c) Provisioning — which and why?**

**`shell`** provisioner + bash script: one job (download Go tarball, install under `/usr/local/go`). Ansible/Puppet is overkill for a single package; `shell` is transparent, reproducible, and needs no extra deps on the guest.

**d) Why pin Go `1.24.5` instead of `1.24`?**

Minor/patch releases fix compiler bugs and security issues without changing the language version. Bare `1.24` is a moving target; another student might get `1.24.2` vs `1.24.5` and different `go test`/lint behavior. Pinning `1.24.5` keeps provisioning reproducible.

---

## Task 2 — Snapshots: Save, Break, Restore

Full log: [`task2-snapshots.txt`](attachments/lab5/task2-snapshots.txt)

| Step | Command | Result |
|------|---------|--------|
| Save | `vagrant snapshot save lab5-working` | snapshot saved |
| Break | `vagrant ssh -c 'sudo rm -rf /usr/local/go'` | Go removed |
| Verify broken | `go version` | `bash: go: command not found` |
| Restore | `time vagrant snapshot restore lab5-working` | **20.02 s** (`real`) |
| Verify recovered | `go version` | `go version go1.24.5 linux/arm64` |

> After laptop sleep, the first `snapshot restore` hung on SSH (305 s timeout). After `kill VBoxHeadless` + `vagrant up`, a retry restored in **~20 s**. Added `config.vm.boot_timeout = 600`.

### Design questions (Task 2.2)

**e) Snapshots are not backups — why?**

A snapshot lives on the **same disk/hypervisor** as the VM. Disk failure, VBox image corruption, or `vagrant destroy` removes the snapshot with the VM. It is not off-site, not versioned, and not protected from ransomware or deleting `~/VirtualBox VMs/`.

**f) Copy-on-write — 10 snapshots vs 1?**

CoW: the first snapshot is a delta from base; each next one is a delta from the current head. **10 snapshots** = a chain of differencing images; each disk write may propagate through the chain → **disk usage grows faster**, restore is slower. **1 snapshot** = one delta file, simpler and cheaper on disk.

**g) When is snapshotting an antipattern?**

Long **snapshot chains** in prod (months of deltas), using snapshots *instead of* backups, snapshot-before-every-deploy without merge/delete — disk bloat, slow restore, fragile chains. Also an antipattern: keeping a snapshot on a stateful DB VM instead of proper backup/restore testing.

---

## Bonus Task — VM vs Container Baseline

Measurements: [`bonus-vm-idle.txt`](attachments/lab5/bonus-vm-idle.txt) · [`bonus-docker.txt`](attachments/lab5/bonus-docker.txt)

| Dimension | Vagrant VM | Docker container |
|-----------|----------:|-----------------:|
| Cold start | **81.9 s** (`vagrant halt && vagrant up`, no reprovision) | **0.07 s** (`docker stop && docker start`, image already built) |
| Idle RAM | **220 MiB** used (824 MiB total allocated) | **22 MiB** (`docker stats`) |
| On-disk size | **3.5 GB** (`~/VirtualBox VMs/devops-intro-quicknotes`) | **1.33 GB** (`golang:1.24` image) |
| Process count (guest) | **102** (`ps -A`) | **9 PIDs** (`docker stats`) |

### Trade-off analysis

The largest gap is **cold start**: VM ~82 s vs **70 ms** for an already-built container (`docker run` is longer on first pull + `go build`, but still no full OS boot). **102 processes** in the guest vs **9 PIDs** in the container shows why a VM is heavier even at idle: full Ubuntu + systemd. A VM gives real kernel isolation — useful for Lab 7/Ansible where you need a full host. Containers won the 2014–2020 era for **stateless microservices**: one process = one service, seconds to scale out, KB–MB overhead instead of GB. For QuickNotes on one machine Docker is enough; for “boot a real Linux and learn to operate it,” Vagrant is justified.

---

## Install log (for cleanup)

| Item | Method |
|------|--------|
| VirtualBox 7.2.10 | `brew install --cask virtualbox` |
| Vagrant 2.4.9 | `brew install --cask vagrant` |
| Box `bento/ubuntu-24.04` v202510.26.0 (arm64) | `vagrant box add` / `vagrant up` |
| Go 1.24.5 (guest only) | `scripts/vagrant-provision.sh` |
| Docker image `golang:1.24` (bonus) | `docker pull` during bonus measurements |
