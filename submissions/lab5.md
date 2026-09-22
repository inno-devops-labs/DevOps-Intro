# Lab 5 — Virtualization with Vagrant

## Goal

Run QuickNotes inside an Ubuntu 24.04 LTS Vagrant VM, configure reproducible Go provisioning, verify host-to-guest networking, and demonstrate VM recovery using snapshots.

## Task 1 — QuickNotes in a Vagrant VM

### Vagrantfile configuration

The VM is configured with:

- Ubuntu 24.04 LTS public box: `bento/ubuntu-24.04`
- hostname: `quicknotes-vm`
- VirtualBox provider
- 2 vCPUs
- 1024 MB RAM
- host `127.0.0.1:18080` forwarded to guest `8080`
- synced folder `./app` mounted at `/vagrant/app`
- Go `1.24.5`
- shell provisioning
- ARM64 Go binary for Apple Silicon

The Go version is pinned to `1.24.5` for reproducibility. The provisioning script checks the installed Go binary and does not reinstall it when the required version is already present.

### Go verification

Command:

```bash
vagrant ssh -c 'go version'
Result:

go version go1.24.5 linux/arm64

### QuickNotes verification inside the VM

QuickNotes was built and started inside the VM from the synced application directory.

Command:

vagrant ssh -c 'curl -s http://localhost:8080/health'

Result:

{"notes":6,"status":"ok"}

### QuickNotes verification from the host

Command:

curl -s http://localhost:18080/health

Result:

{"notes":6,"status":"ok"}

This confirms that QuickNotes is running on guest port `8080` and is accessible from the host through forwarded port `18080`.

### Design questions

#### a) Synced folder type and trade-off

The Vagrantfile uses a VirtualBox shared folder:

config.vm.synced_folder "./app", "/vagrant/app"

This provides simple live access to the application source from the VM. The main trade-off is that VirtualBox shared folders can have lower filesystem performance than alternatives such as rsync, especially for workloads with many small file operations.

#### b) NAT vs Bridged vs Host-only

The VM uses VirtualBox NAT networking with port forwarding.

NAT allows the VM to access external networks without placing the VM directly on the local LAN.

The forwarded port is bound to `127.0.0.1`, so QuickNotes is accessible from the host machine but is not directly exposed to other machines on the local network.

Bridged networking would place the VM directly on the LAN, while host-only networking would provide an isolated host-to-VM network.

#### c) Provisioning method and why

A shell provisioner was used because the VM setup is small and only requires installation of one pinned Go toolchain.

Shell provisioning is built into Vagrant and does not require an additional configuration-management tool.

The provisioning script is idempotent because it checks the installed Go version before downloading and installing it.

#### d) Why pin Go to 1.24.5 instead of 1.24

Go `1.24.5` is pinned to make the environment reproducible.

Using only `1.24` could result in a different patch release being installed later. Pinning the exact patch version ensures that repeated provisioning uses the same Go toolchain.

## Task 2 — Vagrant Snapshots

### Creating the snapshot

A clean snapshot named `lab5-clean` was created:

vagrant snapshot save lab5-clean

### Deliberately breaking the VM

The Go installation was deliberately removed:

vagrant ssh -c 'sudo rm -rf /usr/local/go'

Verification:

vagrant ssh -c 'go version'

Result:

bash: line 1: go: command not found

This confirmed that the VM was deliberately broken.

### Restoring the snapshot

The clean snapshot was restored using:

time vagrant snapshot restore lab5-clean

Measured restore time:

11.191 seconds

### Verification after restore

Go was restored successfully:

go version go1.24.5 linux/arm64

QuickNotes was then started from the synced application directory and verified inside the restored VM:

{"notes":6,"status":"ok"}

The host-side forwarded endpoint also returned:

{"notes":6,"status":"ok"}

### e) Why a snapshot is not a backup

A VM snapshot depends on the VM's virtual disk and the host storage containing the VM. It is useful for quickly returning to an earlier local VM state, but it is not an independent disaster-recovery copy.

If the host disk or VM storage is lost or corrupted, the snapshot can also be lost. Proper backups should therefore be stored independently from the original VM storage.

### f) Copy-on-write and snapshot storage

Snapshots use differencing or copy-on-write storage rather than immediately making a complete copy of the virtual disk.

The original disk remains the base, while changed blocks are stored separately. Therefore, multiple snapshots do not necessarily consume multiple complete copies of the disk.

However, additional snapshots and accumulated changes increase storage usage and can add I/O overhead.

### g) When snapshotting becomes an antipattern

Snapshotting becomes an antipattern when snapshots are used as a replacement for source-controlled infrastructure, reproducible provisioning, or real backups.

Long snapshot chains can increase storage usage and operational complexity.

For infrastructure that can be rebuilt from a Vagrantfile and application source, snapshots are best used as short-term recovery points rather than long-term infrastructure versioning.

## Idempotency Verification

The provisioning script was executed more than once:

vagrant provision

The repeated provisioning completed successfully and reported:

go version go1.24.5 linux/arm64

The installed Go version was already correct, so the provisioning logic did not reinstall the toolchain.

## Verification Summary

| Check | Result |
|---|---|
| Vagrantfile validation | Passed |
| Ubuntu 24.04 VM | Passed |
| ARM64 architecture | Passed |
| 2 vCPUs | Configured |
| 1024 MB RAM | Configured |
| Host port `18080` | Passed |
| Guest port `8080` | Passed |
| Synced `./app` folder | Passed |
| Go `1.24.5` | Passed |
| QuickNotes inside VM | Passed |
| QuickNotes from host | Passed |
| Provisioning idempotency | Passed |
| Snapshot creation | Passed |
| Deliberate VM break | Passed |
| Snapshot restore | Passed |
| Restore time | 11.191 seconds |
| Go after restore | Passed |
| QuickNotes after restore | Passed |

## Conclusion

QuickNotes was successfully deployed inside an ARM64 Ubuntu 24.04 Vagrant VM.

The VM uses:

- 2 vCPUs
- 1024 MB RAM
- a synced application directory
- localhost-only port forwarding from host port `18080` to guest port `8080`
- Go `1.24.5`

The Go provisioning was verified to be reproducible and idempotent.

QuickNotes responded successfully both inside the VM and from the host machine.

A Vagrant snapshot was used to recover the VM after deliberately removing Go. The snapshot restored the Go toolchain successfully, with a measured restore time of `11.191` seconds.

## Bonus Task — VM vs Container Resource Baseline

### B.1 — Vagrant VM baseline

The Vagrant VM was measured while running idle.

Results:

- Cold boot: `28.140 seconds`
- Idle RAM: `237 MiB used` out of `824 MiB`
- Process count: `105`
- On-disk VM size: `3.2 GB`

The VM was halted and started again with `vagrant up --no-provision` so that the measurement represented boot time rather than the first provisioning.

### B.2 — Docker container baseline

The same QuickNotes application was run in a `golang:1.24` Docker container using the application source from the repository.

The container was verified with:

`{"notes":6,"status":"ok"}`

Results:

- Cold start: `0.081 seconds`
- Idle RAM: `10.45 MiB`
- Process count: `2`
- Docker image size: `1.33 GB`

The Docker container exposed QuickNotes on host port `28080` and returned HTTP `200 OK` from `/health`.

### B.3 — Comparison

| Dimension | Vagrant VM | Docker container |
|---|---:|---:|
| Cold start | 28.140 s | 0.081 s |
| Idle RAM | 237 MiB | 10.45 MiB |
| On-disk size | 3.2 GB | 1.33 GB image |
| Process count (guest) | 105 | 2 |

The cold-start and process-count differences were the most noticeable results: the VM required 28.140 seconds to boot and had 105 processes, while the container started in 0.081 seconds and had only 2 processes. The container also used substantially less idle RAM because it shared the host kernel instead of running a complete guest operating system. A VM is useful when stronger isolation, a separate operating-system environment, or different kernel requirements are important. Containers are well suited to lightweight, portable, stateless services where fast startup and efficient resource usage are important. These measurements help explain why containers became widely adopted for stateless microservices during the 2014–2020 period: they provided fast startup, low overhead, and efficient packaging compared with running a separate VM for each service.
