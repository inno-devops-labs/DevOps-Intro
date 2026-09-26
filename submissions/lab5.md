# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Environment

- Host OS: Ubuntu 24.04.4 LTS, x86_64, kernel `7.0.0-34-generic`.
- Vagrant: `2.4.9`.
- VirtualBox: `7.1.18r173720`.
- Docker: `29.6.1`.
- rsync: `3.2.7`.
- VM box: `bento/ubuntu-24.04` version `202510.26.0` (amd64).
- Guest OS: Ubuntu 24.04.3 LTS; Go: `go1.24.5 linux/amd64` (official archive SHA256 checked).

## Task 1 — Vagrant Up and QuickNotes

### 1.1 Vagrantfile

The root [Vagrantfile](../Vagrantfile) configures a two vCPU, 1024 MB Ubuntu 24.04 VM named `quicknotes-vm`. It syncs `./app` to `/opt/quicknotes` with rsync, builds QuickNotes, and enables a systemd service. The service stores writable notes in `/var/lib/quicknotes`, separate from the synced source. The forwarded port is `127.0.0.1:18080` on the host to port 8080 in the guest.

### 1.2 Provisioning and `vagrant up`

`vagrant up --provider=virtualbox` completed successfully. The first ten meaningful lines of the captured output were:

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

Provisioning reported `/tmp/go1.24.5.linux-amd64.tar.gz: OK`, created the systemd service, and received `{"notes":4,"status":"ok"}`. `vagrant status` reported `default running (virtualbox)`.

### 1.3 Guest verification

`vagrant ssh -c 'hostname'` returned `quicknotes-vm`; `vagrant ssh -c 'nproc'` returned `2`. The service was `active (running)` and listening on port 8080. The synced application was present at `/opt/quicknotes`.

```text
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64

$ vagrant ssh -c 'curl -i http://localhost:8080/health'
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 26

{"notes":4,"status":"ok"}
```

### 1.4 Host verification

`ss -tlnp` on the host showed a listener at `127.0.0.1:18080`. The host request through the forwarded port returned:

```text
$ curl -i http://127.0.0.1:18080/health
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 26

{"notes":4,"status":"ok"}

$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:18080/health
200
```

### 1.5 Design questions

#### a) Synced folders

I chose rsync in the Vagrantfile because it is simple, reliable for a small source tree, and does not depend on matching VirtualBox Guest Additions for shared folders. The host source is authoritative. It is not a live bidirectional mount: after changing files on the host, I must run `vagrant rsync` (or trigger another sync) to update the guest.

#### b) NAT, bridged, and host-only networking

The VM uses Vagrant's default NAT network with one explicit forwarded port: `127.0.0.1:18080` to guest port 8080. Binding to loopback allows the host to access the service without putting the guest directly on the local network. A bridged adapter would give the VM broader LAN presence. Host-only networking could also isolate the guest, but an explicit loopback forward is enough for this exercise.

#### c) Provisioning

I used shell provisioning because this bootstrap installs one pinned toolchain, builds one service, and needs no extra configuration-management dependency. The shell script checks the installed Go version, so a later `vagrant provision` does not download Go again when it is already correct. Ansible can take over configuration management in Lab 7.

#### d) Go point release

`1.24` identifies a series whose latest patch can change. Pinning `1.24.5` gives students the same toolchain during rebuilds and makes behavior and troubleshooting more predictable.

## Task 2 — Snapshots

### 2.1 Save working snapshot

Before saving, `vagrant status` showed `running (virtualbox)`, `go version` returned `go1.24.5 linux/amd64`, and host `/health` returned `{"notes":4,"status":"ok"}`.

```text
$ vagrant snapshot save lab5-working
==> default: Snapshotting the machine as 'lab5-working'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.

$ vagrant snapshot list
lab5-working
```

### 2.2 Deliberate break

I deleted the Go installation **inside the guest VM**. This did not touch the host.

```text
$ vagrant ssh -c 'sudo rm -rf /usr/local/go'
$ vagrant ssh -c 'go version'
bash: line 1: go: command not found
exit code: 127
$ vagrant ssh -c 'test -d /usr/local/go'
exit code: 1
```

### 2.3 Restore and timing

```text
$ /usr/bin/time -p vagrant snapshot restore lab5-working
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'lab5-working'...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Machine booted and ready!
real 13.01
user 1.61
sys 1.23
```

The wall-clock restore command took **13.01 seconds**.

### 2.4 Verify recovery and repeat provisioning

`vagrant status` again reported `running (virtualbox)`. The following checks succeeded both after restore and after a second `vagrant provision`:

```text
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64

$ vagrant ssh -c 'curl -i http://localhost:8080/health'
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 26

{"notes":4,"status":"ok"}

$ curl -i http://127.0.0.1:18080/health
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 26

{"notes":4,"status":"ok"}
```

The second `vagrant provision` completed without downloading Go again and the host health check returned HTTP `200`.

### Snapshot design questions

#### e) Why snapshots are not backups

A snapshot depends on the VM disk chain and host storage that contain it. It cannot recover the VM after loss of the host disk, corruption or deletion of the VM files, or loss of the machine holding both the base image and snapshots. An independent backup must live separately.

#### f) Copy-on-write

A snapshot initially references existing disk blocks and stores later changes separately. Ten snapshots therefore do not immediately require ten complete copies of the VM disk. Changed blocks and metadata accumulate as the chain grows.

#### g) Snapshot antipattern

Long snapshot chains consume increasing storage and make management and restores more complex. They are a poor substitute for reproducible provisioning and independent backups.

## Bonus — VM vs Docker

Both measurements were made on this host during this lab session, using the same `./app` source. The VM and container were already created before their cold-start measurements.

### B.1 VM measurements

I ran `/usr/bin/time -p vagrant halt` followed by `/usr/bin/time -p vagrant up`. The latter performed a normal boot and rsync but did not rerun provisioning:

```text
$ /usr/bin/time -p vagrant up
real 23.63
user 2.46
sys 1.88
```

After boot, `vagrant ssh -c 'free -h'` showed `Mem: 961Mi total, 301Mi used, 577Mi free, 223Mi buff/cache, 659Mi available`. I use the **used** field, not the configured 1024 MB allocation, as idle RAM in the table. `vagrant ssh -c 'ps -A --no-headers | wc -l'` returned `164`. `VBoxManage showvminfo quicknotes-lab5 --machinereadable` identified the VM configuration under `/home/alex/VirtualBox VMs/quicknotes-lab5`; `du -sh` on that actual directory returned `2.7G` (`2825338658` bytes). That directory includes the VM disk and snapshot files. Host `/health` returned HTTP `200` after boot.

### B.2 Docker measurements

The existing `lab5-quicknotes` container used the same `./app` bind-mounted to `/src`, the `golang:1.24` image, and `go build -o /tmp/qn && /tmp/qn`. Its published port was `127.0.0.1:28080` to guest port 8080. It returned `HTTP/1.1 200 OK` and `{"notes":8,"status":"ok"}` from `/health`.

After `docker stop lab5-quicknotes`, I measured `/usr/bin/time -p docker start lab5-quicknotes`:

```text
real 0.35
user 0.06
sys 0.03
```

The first immediate curl received `Recv failure: Connection reset by peer`; a later health check returned HTTP `200`. Thus `0.35 s` is the Docker **start command** time, not a measured time to HTTP readiness. `docker stats --no-stream lab5-quicknotes` reported `6.648MiB / 15.32GiB` memory use. `docker top lab5-quicknotes` showed two process rows (shell and `/tmp/qn`). `docker inspect` identified `golang:1.24`; `docker images` reported that image's size as `894MB`.

### B.3 Comparison

| Dimension | Vagrant VM | Docker container |
|---|---:|---:|
| Cold start command | 23.63 s (`vagrant up`) | 0.35 s (`docker start`) |
| Idle RAM | 301 MiB (`free -h` used) | 6.648 MiB (`docker stats`) |
| On-disk size | 2.7 G (VM directory, including snapshot) | 894 MB (`golang:1.24` image) |
| Process count | 164 (`ps -A`) | 2 (`docker top`) |

### B.4 Analysis

The biggest observed differences were the start-command time and reported memory use; the container was much lighter on this host. A full VM is appropriate when the workload needs its own kernel, operating-system configuration, or strong environment separation, as this lab's provisioning and snapshot exercise did. A container is appropriate for a stateless service that can share the host kernel and be rebuilt from an image. These measurements help explain the appeal of containers for stateless microservices during 2014–2020: on this machine they start quickly and account for far fewer processes and less memory. The disk figures cover different scopes (a VM directory with a snapshot versus one image), and one host cannot establish universal performance results.
