# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

The `Vagrantfile` is committed at the repository root: [`../Vagrantfile`](../Vagrantfile).

It uses:

- Ubuntu 24.04 LTS via `bento/ubuntu-24.04`
- Hostname `quicknotes-vm`
- Local-only port forwarding: `127.0.0.1:18080 -> guest:8080`
- `./app` synced into `/srv/quicknotes/app` using rsync
- 2 vCPU and 1024 MB RAM
- Shell provisioning to install Go `1.24.5`, build QuickNotes, and run it as a `systemd` service

### Verification commands

Run from the repository root:

```bash
vagrant up
vagrant ssh -c 'go version'
vagrant ssh -c 'systemctl is-active quicknotes'
vagrant ssh -c 'curl -s http://127.0.0.1:8080/health'
curl -s http://127.0.0.1:18080/health
```

Expected successful outputs:

```text
go version go1.24.5 linux/arm64
active
{"notes":4,"status":"ok"}
{"notes":4,"status":"ok"}
```

### First 10 lines of `vagrant up`

```text
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

### Design questions

**a. Synced folders**

I used `rsync` synced folders. The main benefit is that it is reproducible and does not depend on VirtualBox Guest Additions being perfectly matched inside the guest. The trade-off is that sync is one-way from host to guest, so after changing source files I need `vagrant rsync`, `vagrant rsync-auto`, or `vagrant provision` to push the latest app code into the VM.

**b. NAT vs Bridged vs Host-only**

This VM uses Vagrant's default NAT networking plus a forwarded port. Binding the forwarded port to `127.0.0.1` means only the host machine can reach QuickNotes through `localhost:18080`; it is not exposed to the local LAN. That is safer than a bridged interface for a course lab because bridged mode gives the VM its own network presence and can accidentally expose an unfinished service to classmates, office Wi-Fi, or other devices on the network.

**c. Provisioning options**

I used the `shell` provisioner. For this lab the provisioning task is small and direct: install OS packages, download one pinned Go tarball, build one binary, and write one `systemd` unit. Shell keeps the setup readable without introducing Ansible or another configuration-management dependency before Lab 7.

**d. Why pin Go to `1.24.5` instead of `1.24`?**

Pinning a point release makes the VM reproducible. `1.24` is a moving target that may resolve to different patch releases over time, which can change compiler behavior, security fixes, or module behavior between students. `1.24.5` makes a clean clone today and a clean clone later install the same toolchain.

## Task 2 — Snapshots: Save, Break, Restore

### Commands

```bash
vagrant snapshot save quicknotes-clean
vagrant snapshot list

vagrant ssh -c 'sudo rm -rf /usr/local/go && go version'

time vagrant snapshot restore quicknotes-clean

vagrant ssh -c 'go version'
vagrant ssh -c 'systemctl is-active quicknotes'
curl -s http://127.0.0.1:18080/health
```

The break command removes the Go installation. The verification is `go version`: it should fail after the removal and succeed again after restoring the `quicknotes-clean` snapshot.

### Snapshot command outputs

```text
$ vagrant snapshot save quicknotes-clean
==> default: Snapshotting the machine as 'quicknotes-clean'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.

$ vagrant snapshot list
==> default:
quicknotes-clean

$ vagrant ssh -c 'sudo rm -rf /usr/local/go && go version'
bash: line 1: go: command not found
```

### Restore timing

```text
$ /usr/bin/time -p vagrant snapshot restore quicknotes-clean
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'quicknotes-clean'...
==> default: Checking if box 'bento/ubuntu-24.04' version '202510.26.0' is up to date...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
==> default: Machine booted and ready!
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.
real 12.15
user 0.99
sys 0.78
```

### Recovery verification

```text
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/arm64

$ vagrant ssh -c 'systemctl is-active quicknotes'
active

$ curl -s http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
```

### Design questions

**e. Why snapshots are not backups**

Snapshots are tied to the VM image and the host storage where that image lives. If the laptop disk dies, the VM directory is deleted, or the base VM is corrupted, the snapshot may disappear with it. A backup must be independent, restorable elsewhere, and protected from the same failure domain as the original system.

**f. Copy-on-write**

Copy-on-write means a snapshot initially stores metadata and then records only disk blocks that change after the snapshot. Ten snapshots do not immediately cost ten full VM copies, but each snapshot adds changed blocks and metadata. Long-lived or frequently modified snapshots can grow substantially over time.

**g. When snapshotting is an antipattern**

Snapshotting is an antipattern when it becomes a substitute for automation or backups. Long chains of snapshots make restore behavior slower and more fragile, and they encourage treating the VM like a special pet instead of rebuilding it from code. For repeatable environments, the preferred path is a clean `Vagrantfile` and provisioner, with snapshots used only for short experiments.

## Bonus Task — VM vs Container Resource Baseline

### VM measurement commands

```bash
time vagrant halt
time vagrant up
vagrant ssh -c 'free -h'
vagrant ssh -c 'ps -A --no-headers | wc -l'
du -sh ~/VirtualBox\ VMs/quicknotes-lab5
```

Captured VM outputs:

```text
$ /usr/bin/time -p vagrant halt
==> default: Attempting graceful shutdown of VM...
real 2.46
user 0.58
sys 0.39

$ /usr/bin/time -p vagrant up
real 18.70
user 1.39
sys 1.19

$ vagrant ssh -c 'free -h'
               total        used        free      shared  buff/cache   available
Mem:           824Mi       202Mi       469Mi       4.8Mi       233Mi       621Mi
Swap:          3.7Gi          0B       3.7Gi

$ vagrant ssh -c 'ps -A --no-headers | wc -l'
105

$ du -sh '/Users/shiyan.aleksandr3/VirtualBox VMs/quicknotes-lab5'
3.8G    /Users/shiyan.aleksandr3/VirtualBox VMs/quicknotes-lab5
```

### Docker measurement commands

```bash
docker run -d --name quicknotes-lab5-container -p 28080:8080 -v "$PWD/app:/src" -w /src golang:1.24 go run .

docker stop quicknotes-lab5-container
time docker start quicknotes-lab5-container
docker stats --no-stream quicknotes-lab5-container
docker top quicknotes-lab5-container
docker images golang:1.24 --format '{{.Size}}'
docker rm -f quicknotes-lab5-container
```

Captured Docker outputs:

```text
$ docker run -d --name quicknotes-lab5-container -p 28080:8080 -v "$PWD/app:/src" -w /src golang:1.24 go run .
83e17ec2a6fe4f19cde237dd44a644182fb28aa546e1ea7eb532c6b96bd4120b

$ curl -s http://127.0.0.1:28080/health
{"notes":4,"status":"ok"}

$ docker stop quicknotes-lab5-container
quicknotes-lab5-container

$ /usr/bin/time -p docker start quicknotes-lab5-container
quicknotes-lab5-container
real 0.10
user 0.00
sys 0.00

$ docker stats --no-stream quicknotes-lab5-container
CONTAINER ID   NAME                        CPU %     MEM USAGE / LIMIT     MEM %     NET I/O        BLOCK I/O   PIDS
83e17ec2a6fe   quicknotes-lab5-container   0.00%     30.68MiB / 7.653GiB   0.39%     1.7kB / 574B   0B / 0B     28

$ docker top quicknotes-lab5-container
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
root                2563                2539                0                   12:03               ?                   00:00:00            go run .
root                2659                2563                0                   12:03               ?                   00:00:00            /root/.cache/go-build/cf/cf202ab4b0a028080d0d043a6f70f512f92e12cc628919d443669eb615e489df-d/quicknotes

$ docker images golang:1.24 --format '{{.Size}}'
1.33GB
```

### Comparison table

| Dimension             | Vagrant VM | Docker container |
|-----------------------|-----------:|-----------------:|
| Cold start            | 18.70s     | 0.10s            |
| Idle RAM              | 202Mi      | 30.68MiB         |
| On-disk size          | 3.8G       | 1.33GB           |
| Process count (guest) | 105        | 2                |

### Bonus analysis

The start-time difference surprised me the most: the VM needed 18.70 seconds while the already-created container came back in 0.10 seconds. The VM also carried much more idle operating-system overhead: 202 MiB and 105 processes versus 30.68 MiB and two visible container processes. VMs are still the right tool when I need stronger isolation, a full OS boundary, kernel-level differences, or a target that behaves like an independent server. Containers are the better fit for stateless microservices because they start quickly, use fewer resources, and can be packed densely on shared hosts. These numbers show why containers won so much of the 2014-2020 stateless-service era: they made replacement, scaling, and local-to-CI parity much cheaper.
