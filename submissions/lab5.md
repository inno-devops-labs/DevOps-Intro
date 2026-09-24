# Lab 5 - Virtualization: QuickNotes in a Vagrant VM

## Environment

- Host: MacBook Air, Apple M3 (arm64), macOS
- VirtualBox 7.2.20 (the lab asks for 7.1.x; 7.2 worked with Vagrant)
- Vagrant 2.4.9
- Box: `net9/ubuntu-24.04-arm64` v1.1 (Ubuntu 24.04 LTS, arm64, VirtualBox provider)
- Go: 1.24.5 (linux/arm64), installed by the shell provisioner

## Task 1 - Vagrant Up + Run QuickNotes Inside

### Vagrantfile

The file is at the repo root: https://github.com/Kulichcom/DevOps-Intro/blob/feature/lab5/Vagrantfile

Summary of what it does:
- Box `net9/ubuntu-24.04-arm64` on Apple Silicon, `bento/ubuntu-24.04` on Intel hosts
- Hostname `quicknotes-vm`
- 2 vCPU, 1024 MB RAM
- `./app` synced to `/home/vagrant/app` with `rsync`
- Shell provisioner installs Go 1.24.5 (idempotent, picks amd64 or arm64 automatically)
- Host `127.0.0.1:18080` to guest `8080` (see the note below)

Note about port forwarding: on my Mac, Vagrant's own port check reported a false "port already in use" error, even for free ports (I tested 18080, 18081, and later the SSH port 2250). A direct connection test said the port was refused (free), and Vagrant's own `is_port_open?` function returned `true`, so the problem is inside Vagrant's check on my machine. I therefore set the same forward with a VirtualBox NAT rule in the Vagrantfile: `vb.customize ["modifyvm", :id, "--natpf1", "quicknotes,tcp,127.0.0.1,18080,,8080"]`.

Check that the rule exists:
```
$ VBoxManage showvminfo quicknotes-vm --machinereadable | grep -i forwarding
Forwarding(0)="quicknotes,tcp,127.0.0.1,18080,,8080"
Forwarding(1)="ssh,tcp,127.0.0.1,2250,,22"
```

### First 10 lines of `vagrant up`

```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'net9/ubuntu-24.04-arm64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'net9/ubuntu-24.04-arm64'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/net9/ubuntu-24.04-arm64
==> default: Adding box 'net9/ubuntu-24.04-arm64' (v1.1) for provider: virtualbox (arm64)
    default: Downloading: https://vagrantcloud.com/net9/boxes/ubuntu-24.04-arm64/versions/1.1/providers/virtualbox/arm64/vagrant.box
==> default: Successfully added box 'net9/ubuntu-24.04-arm64' (v1.1) for 'virtualbox (arm64)'!
==> default: Importing base box 'net9/ubuntu-24.04-arm64'...
```

The provisioner ended with: `go version go1.24.5 linux/arm64`

### Building and running QuickNotes

```
$ vagrant ssh -c 'cd ~/app && go build -o /tmp/qn'
$ vagrant ssh -c 'cd ~/app && setsid nohup /tmp/qn >/tmp/qn.log 2>&1 </dev/null & sleep 1'
$ vagrant ssh -c 'cat /tmp/qn.log'
2026/09/24 20:35:18 quicknotes listening on :8080 (notes loaded: 6)
```

### curl outputs

From inside the VM:
```
$ vagrant ssh -c 'curl -s localhost:8080/health'
{"notes":6,"status":"ok"}
```

From the host (through the port forward):
```
$ curl -s http://localhost:18080/health
{"notes":6,"status":"ok"}
```

### Design questions

**a) Synced folders.** I used `rsync`. It copies `./app` into the guest's own disk, so it does not depend on Guest Additions (the box has Guest Additions 7.1.2, but VirtualBox is 7.2, and VirtualBox warned about the mismatch), builds run at native disk speed, and macOS already ships rsync. Trade-off: it is one-way (host to guest) and not live, so I run `vagrant rsync` after editing code on the host. The `virtualbox` type is live and two-way but needs matching Guest Additions and has slower file I/O; `nfs` is fast but needs host setup and privileges; `smb` is mostly for Windows hosts.

**b) Network mode.** I am using NAT (the VirtualBox default) with port forwarding. Binding the forward to `127.0.0.1` means only my own machine can reach the app. A Bridged interface would give the VM its own IP on the LAN, so anyone on the same network could reach a dev service that has no authentication and is not hardened. Host-only would also keep it private, but it needs an extra network adapter and setup.

**c) Provisioning.** I used `shell`. It needs no extra tools on the host, the whole setup is one readable block in the Vagrantfile, and installing one tarball does not justify a configuration-management tool. `ansible` needs Ansible on the host (hard on Windows). `ansible_local` adds an install step inside the VM. Ansible is better for the app deployment, which is Lab 7.

**d) Pinning the point release.** `1.24.5` is an exact, immutable artifact, so every student and every rebuild gets identical bytes. `1.24` is ambiguous (it points to the first release, 1.24.0), and floating to "latest 1.24.x" would silently change behavior and security fixes between runs, breaking reproducibility.

## Task 2 - Snapshots: Save, Break, Restore

### Commands and output

```
$ vagrant snapshot save clean-go-ready
==> default: Snapshotting the machine as 'clean-go-ready'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.

$ vagrant ssh -c 'sudo rm -rf /usr/local/go /usr/local/bin/go'

$ vagrant ssh -c 'go version'
bash: line 1: go: command not found

$ time vagrant snapshot restore --no-start clean-go-ready
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'clean-go-ready'...
vagrant snapshot restore --no-start clean-go-ready  0.57s user 0.28s system 40% cpu 2.077 total

$ VBoxManage startvm quicknotes-vm --type headless
Waiting for VM "quicknotes-vm" to power on...
VM "quicknotes-vm" has been successfully started.

$ vagrant ssh -c 'go version'
go version go1.24.5 linux/arm64

$ vagrant snapshot delete clean-go-ready
==> default: Deleting the snapshot 'clean-go-ready'...
==> default: Snapshot deleted!
```

### Restore time

`time vagrant snapshot restore --no-start clean-go-ready` took **2.077 seconds** total. This is the restore only. I started the VM separately with VirtualBox, and I waited about 40 seconds before connecting.

Why `--no-start` and a manual start: a normal restore starts the VM afterwards, and there Vagrant's port check failed with the same false "port already in use" error (on the SSH port 2250). Starting the VM with `VBoxManage startvm` avoids that check.

### Design questions

**e) Snapshots are not backups.** A snapshot lives on the same disk and host as the VM, so it dies with them: disk failure, host loss, theft, or `vagrant destroy` (which deletes the snapshots too) all remove both. It also depends on the parent disk, so corruption of the base image can ruin every snapshot. A backup must be a separate copy, on separate storage.

**f) Copy-on-write.** After a snapshot, changes are written to a new differencing disk and the old data stays untouched. So a snapshot is small at first and only grows with the blocks changed since it was taken. 10 snapshots do not cost 10x the disk, but the total grows with every change made across the chain, and older data can never be freed until snapshots are deleted or merged.

**g) When it is an antipattern.** Long chains: each level adds a differencing disk, reads may walk the whole chain (slower I/O), disk usage keeps growing, and deleting or merging in the middle is slow and risky. Snapshots should be short-lived checkpoints before a risky change, not a long-term version history. Rebuild from code instead (cattle, not pets).