# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

The submitted [`Vagrantfile`](../Vagrantfile) uses the public `bento/ubuntu-24.04` box.

### Evidence

`vagrant up` (first 10 lines):

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Checking if box 'bento/ubuntu-24.04' version '202510.26.0' is up to date...
==> default: Clearing any previously set forwarded ports...
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
```

Go version inside the VM:

```text
go version go1.24.5 linux/amd64
```

Health endpoint inside the VM:

```text
{"notes":4,"status":"ok"}
```

Health endpoint from the host through the port forward:

```text
{"notes":4,"status":"ok"}
```

### Design answers

**a) Synced folders.** I chose the `virtualbox` synced-folder type and mounted the host's `app/` directory at `/opt/quicknotes/app` in the guest. It is simple for a Windows host and needs no separate NFS or SMB server configuration. The trade-off is that file I/O can be slower than a native filesystem, especially for projects with many small files.

**b) Networking.** The VM uses Vagrant's default NAT network and a forwarded port. Binding the host side to `127.0.0.1` makes QuickNotes available only from this computer; a bridged adapter would put the VM directly on the local network and could expose the course application to other devices.

**c) Provisioning.** I chose Vagrant's `shell` provisioner. The setup is short: it installs the exact Go archive, builds QuickNotes, and configures a systemd service, without adding the overhead of a configuration-management tool for one VM.

**d) Go version.** `1.24.5` identifies one immutable release with a fixed set of fixes and behaviour. A version such as `1.24` could resolve differently over time, so builds would be less reproducible.

## Task 2 — Snapshots: Save, Break, Restore

### Commands and evidence

```bash
vagrant snapshot save quicknotes-clean
vagrant ssh -c "sudo rm -rf /usr/local/go"
vagrant ssh -c "go version"
# bash: line 1: go: command not found

# VirtualBox 7.1 could not resume a live snapshot after Hyper-V was disabled,
# so a clean disk-only snapshot was saved after a verified shutdown.
vagrant halt
vagrant snapshot save quicknotes-disk-clean
vagrant up
vagrant ssh -c "sudo rm -rf /usr/local/go"
vagrant ssh -c "go version"
# bash: line 1: go: command not found
powershell -NoProfile -Command "Measure-Command { vagrant snapshot restore quicknotes-disk-clean }"
vagrant ssh -c "go version"
# go version go1.24.5 linux/amd64
```

Restore timing:

```text
Seconds           : 48
Milliseconds      : 403
TotalSeconds      : 48.4038065
```

### Design answers

**e) Snapshots are not backups.** A snapshot depends on the original VM disk and the local VirtualBox files. It does not protect against loss of the host disk, corruption of the base disk, or a lost laptop, and it is not an off-machine copy of the data.

**f) Copy-on-write.** A new snapshot initially records only the disk blocks that later change, rather than immediately duplicating the whole virtual disk. Ten snapshots can therefore start small, but every changed block must be kept in the snapshot chain, so storage consumption grows over time.

**g) When snapshotting is an antipattern.** Long snapshot chains make disk usage, performance, and recovery more fragile and harder to reason about. For long-lived environments, reproducible provisioning and real backups are preferable; short snapshots are useful only for temporary experiments and rollback points.

## Bonus — VM vs Container Resource Baseline

| Dimension | Vagrant VM | Docker container |
|---|---:|---:|
| Cold start | 75.809 s | 0.282 s |
| Idle RAM | 313 MiB used | 6.383 MiB |
| On-disk size | 3.35 GB | 1.32 GB |
| Process count (guest) | 149 | 2 |

The cold-start difference was the most surprising result: the VM took 75.809 seconds, whereas the container started in 0.282 seconds. The VM also kept 149 guest processes and used 313 MiB RAM at idle, while the QuickNotes container had two processes and used 6.383 MiB. A VM is the better model when a complete operating system, strong isolation, or different kernel behaviour is needed; a container is well suited to stateless application services that can share the host kernel. The VM directory is also larger than the Docker image in this measurement, although the VM directory includes VirtualBox snapshot data. These measurements explain why containers became popular for stateless microservices: they start rapidly and add far less per-service operating-system overhead.
