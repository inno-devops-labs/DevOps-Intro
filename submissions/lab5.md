# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

**Student:** SophiiaSultanova  
**GitHub:** [@fsstilerr](https://github.com/fsstilerr)  
**Host architecture:** Apple Silicon (`arm64`)  
**Vagrant:** 2.4.9  
**VirtualBox:** 7.1.18r173720  
**Docker:** 29.2.1  

---

## Task 1 — Vagrant Up + Run QuickNotes Inside

The final Vagrant configuration is stored at the repository root:

[Vagrantfile](../Vagrantfile)

It satisfies the lab requirements:

- Ubuntu 24.04 LTS public Bento box
- hostname: `quicknotes-vm`
- host `127.0.0.1:18080` → guest `8080`
- host `./app` synced to `/home/vagrant/quicknotes`
- 2 vCPU
- 1024 MB configured RAM
- Go pinned to `1.24.5`
- reproducible shell provisioning
- QuickNotes built and managed by `systemd`

Because the host is Apple Silicon, the provisioner detects the guest architecture and installs the ARM64 Go archive. On an x86_64 host it uses the amd64 archive instead.

### First 10 lines of `vagrant up`

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'bento/ubuntu-24.04' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: 202510.26.0
==> default: Loading metadata for box 'bento/ubuntu-24.04'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/bento/ubuntu-24.04
==> default: Adding box 'bento/ubuntu-24.04' (v202510.26.0) for provider: virtualbox (arm64)
    default: Downloading: https://vagrantcloud.com/bento/boxes/ubuntu-24.04/versions/202510.26.0/providers/virtualbox/arm64/vagrant.box
==> default: Successfully added box 'bento/ubuntu-24.04' (v202510.26.0) for 'virtualbox (arm64)'!
==> default: Importing base box 'bento/ubuntu-24.04'...
```

### Verification

```text
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/arm64
```

```text
$ vagrant ssh -c 'hostname'
quicknotes-vm
```

```text
$ vagrant ssh -c 'uname -m'
aarch64
```

```text
$ vagrant ssh -c 'nproc'
2
```

Guest memory:

```text
              total        used        free      shared  buff/cache   available
Mem:           823Mi       238Mi       270Mi       4.8Mi       414Mi       585Mi
Swap:          3.7Gi       524Ki       3.7Gi
```

QuickNotes service:

```text
● quicknotes.service - QuickNotes
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; preset: enabled)
     Active: active (running)
   Main PID: 8344 (quicknotes)
     Memory: 1.0M (peak: 1.3M)
```

Health check from inside the VM:

```text
$ vagrant ssh -c 'curl -s http://127.0.0.1:8080/health'
{"notes":9,"status":"ok"}
```

Health check from the host through the forwarded port:

```text
$ curl -i http://127.0.0.1:18080/health
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 26

{"notes":9,"status":"ok"}
```

### Design questions

#### a) Synced folders

I used Vagrant's `rsync` synced-folder type for `./app`.

This is a good fit for macOS on Apple Silicon because it does not depend on matching VirtualBox Guest Additions versions. It is also simple and predictable for a source-code directory.

The trade-off is that `rsync` is not a fully live bidirectional filesystem mount. Changes from the host must be synchronized again by Vagrant/rsync, while VirtualBox shared folders can provide more transparent live access when Guest Additions are compatible.

#### b) NAT vs Bridged vs Host-only

The VM uses Vagrant's default **NAT** networking mode plus explicit port forwarding.

Only guest port `8080` is forwarded to `127.0.0.1:18080` on the host. Binding the host side to `127.0.0.1` means the service is reachable only from the local machine.

A Bridged interface would place the VM directly on the local network and could expose the service to other devices on the LAN. For a course exercise, NAT plus loopback-only forwarding reduces unnecessary network exposure.

#### c) Provisioning option

I used the built-in **shell provisioner**.

The task only requires installing one pinned Go toolchain, building QuickNotes, and configuring a small systemd service. Shell provisioning keeps the setup self-contained and requires no extra configuration-management runtime such as Ansible, Puppet, or Chef.

For a larger infrastructure estate I would prefer a higher-level configuration-management tool, but for one reproducible VM this would add unnecessary complexity.

#### d) Why pin Go to `1.24.5` instead of `1.24`?

Pinning the exact point release makes the VM reproducible: every student gets the same compiler and standard-library patch level.

A floating `1.24` reference could resolve to a different patch release later. Patch releases can include compiler changes, bug fixes, and security fixes that may change build or runtime behavior.

---

## Task 2 — Snapshots: Save, Break, Restore

### Snapshot save

```bash
vagrant snapshot save lab5-working
vagrant snapshot list
vagrant ssh -c 'go version'
```

Output:

```text
==> default: Snapshotting the machine as 'lab5-working'...
==> default: Snapshot saved!

lab5-working

go version go1.24.5 linux/arm64
```

### Deliberately break the VM

I removed the installed Go toolchain:

```bash
vagrant ssh -c 'sudo rm -rf /usr/local/go /usr/local/bin/go /usr/local/bin/gofmt'
```

Verification:

```text
go command is missing
bash: line 1: go: command not found
go version FAILED as expected
```

### Restore

```bash
time vagrant snapshot restore lab5-working
```

Measured restore time:

```text
vagrant snapshot restore lab5-working  0.99s user 0.71s system 13% cpu 12.643 total
```

So the observed wall-clock restore time was **12.643 seconds**.

### Verify recovery

```text
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/arm64
```

```text
$ vagrant ssh -c 'systemctl is-active quicknotes'
active
```

```text
$ vagrant ssh -c 'curl -s http://127.0.0.1:8080/health'
{"notes":9,"status":"ok"}
```

```text
$ curl -s http://127.0.0.1:18080/health
{"notes":9,"status":"ok"}
```

### Design questions

#### e) Why snapshots are not backups

A snapshot normally depends on the VM's existing disk image and the host storage that contains it. If the host disk is lost, corrupted, deleted, or otherwise unavailable, the snapshots can disappear with the VM.

A backup should be independently stored and designed for recovery from failures that destroy the original machine or storage.

#### f) Copy-on-write

With copy-on-write snapshots, unchanged disk blocks are shared and new writes are stored as deltas instead of copying the entire virtual disk for every snapshot.

Therefore ten snapshots do not necessarily consume ten times the full VM disk size. However, every snapshot can accumulate changed blocks and metadata, so a long sequence still grows disk usage over time.

#### g) When snapshotting becomes an antipattern

Snapshots become an antipattern when long chains are treated as permanent version history or as a replacement for reproducible infrastructure and backups.

Long chains consume storage, add operational complexity, and make lifecycle management and recovery harder. For disposable development environments, it is usually better to rebuild the VM from the Vagrantfile and provisioning code instead of keeping many historical snapshots.

---

## Bonus — VM vs Container Resource Baseline

The same QuickNotes application was measured in the Vagrant VM and in a Docker container.

### Vagrant VM

The first cold-boot measurement was distorted by a remote box-metadata timeout, so I disabled the unnecessary update check for the already pinned box and repeated the measurement.

Final cold-boot result:

```text
vagrant up  1.37s user 1.09s system 12% cpu 19.387 total
```

Idle guest memory:

```text
Mem: 823Mi total, 266Mi used, 394Mi free, 557Mi available
```

Process count:

```text
115
```

VM disk footprint:

```text
3.6G    /Users/sophiyasultanova/VirtualBox VMs/quicknotes-lab5
```

### Docker container

Cold start:

```text
docker start quicknotes-lab5-docker  0.01s user 0.01s system 13% cpu 0.108 total
```

Idle memory:

```text
7.801MiB / 3.827GiB
```

`docker top` showed two processes:

```text
sh -c go build -o /tmp/qn && /tmp/qn
/tmp/qn
```

Image size:

```text
1.33GB
```

Health check:

```text
{"notes":9,"status":"ok"}
```

### Comparison

| Dimension | Vagrant VM | Docker container |
|---|---:|---:|
| Cold start | **19.387 s** | **0.108 s** |
| Idle RAM | **266 MiB used** | **7.801 MiB** |
| On-disk size | **3.6 GB** | **1.33 GB image** |
| Process count | **115** | **2** |

The biggest difference was startup time and idle memory: the container started in about a tenth of a second and used only a few MiB, while the VM needed roughly 19 seconds and hundreds of MiB of guest memory. The VM also ran a complete guest operating system, which explains its 115 processes compared with only two visible processes in the container. The Docker image in this experiment was still fairly large because the fallback `golang:1.24` development image includes a complete Go toolchain; a multi-stage production image from Lab 6 should be much smaller. VMs remain useful when a separate kernel, full operating-system isolation, or OS-level testing is required, while containers are a better fit for lightweight stateless services. These measurements help explain why containers became attractive for microservices: they have much lower startup and runtime overhead while still packaging application dependencies consistently.

---

## Result

- Task 1: completed
- Task 2: completed
- Bonus: completed with measurements from the local machine
