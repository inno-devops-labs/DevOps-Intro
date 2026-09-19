# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

Student: Arina ([@sonder314](https://github.com/sonder314))

## Environment and implementation

I used Vagrant 2.4.9 with VirtualBox 7.2.6 on an x86-64 Ubuntu host. The
[Vagrantfile](../Vagrantfile) pins `bento/ubuntu-24.04` to version
`202510.26.0`, assigns 2 vCPUs and 1024 MB RAM, and forwards only
`127.0.0.1:18080` to guest port 8080. The accompanying
[provisioning script](../scripts/lab5-provision.sh) installs the checksum-pinned
Go 1.24.5 toolchain, tests and builds QuickNotes, and enables it as a hardened
systemd service. Re-running the provisioner completed successfully and the Go
test result was cached, demonstrating idempotency.

The host uses VirtualBox 7.2 rather than 7.1 because Ubuntu 26.04 ships the
newer kernel-compatible package. This does not change the VM configuration or
the required VirtualBox snapshot workflow.

## Task 1 — Boot and run QuickNotes

The requested [first ten lines of the initial `vagrant up`](evidence/lab5/vagrant-up-first-10.txt)
show the pinned Ubuntu box download. The complete successful provisioning run
is recorded in [vagrant-up.txt](evidence/lab5/vagrant-up.txt).

```text
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64

$ vagrant ssh -c 'curl -fsS http://127.0.0.1:8080/health'
{"notes":4,"status":"ok"}

$ curl -fsS http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
```

These outputs are preserved as [guest-go.txt](evidence/lab5/guest-go.txt),
[guest-health.txt](evidence/lab5/guest-health.txt), and
[host-health.txt](evidence/lab5/host-health.txt). The host request proves that
the loopback-only forward reaches QuickNotes inside the guest.

### Design questions

**a) Synced folders.** I chose `rsync` for `./app` to
`/opt/quicknotes/app`. It avoids coupling the VM to a matching VirtualBox Guest
Additions version and works well for source code. The trade-off is one-way,
event-driven synchronization: host changes require `vagrant rsync` or another
`vagrant up`, and guest edits are not copied back automatically.

**b) Networking.** The first adapter uses Vagrant's default NAT mode, with a
single forwarded application port bound to host loopback. NAT gives the guest
outbound access without placing it directly on the physical LAN. Binding the
forward to `127.0.0.1` prevents other LAN devices from reaching this course VM,
whereas a bridged interface would give the VM its own LAN-visible address.
Host-only networking would isolate host-to-guest traffic but would need an
additional NAT adapter for downloads.

**c) Provisioning.** I used the shell provisioner because installing one pinned
Go archive, building one binary, and writing one systemd unit are small,
transparent tasks. The script is idempotent: it skips the matching Go install,
rebuilds deterministically, replaces the unit definition, and uses
`systemctl enable --now`. Ansible becomes more useful once configuration spans
multiple hosts or roles, which is the focus of Lab 7.

**d) Version pinning.** `1.24` is a moving minor-version target, so two clean
clones could install different patches. Pinning Go 1.24.5 and its SHA-256 digest
makes the toolchain reproducible and verifies the downloaded archive. Patch
releases can also change compiler behavior and security fixes, so the exact
version belongs in the reviewed configuration.

## Task 2 — Snapshot, break, and restore

I used the meaningful snapshot name `quicknotes-clean-lab5`. I then moved the
Go executable out of its expected path, which made `go version` fail with exit
status 127. Restoring the snapshot returned both Go and QuickNotes to the known
working state.

```text
$ vagrant snapshot save quicknotes-clean-lab5
Snapshot saved!

$ vagrant ssh -c 'sudo mv /usr/local/go/bin/go /usr/local/go/bin/go.lab5-broken'

$ vagrant ssh -c 'go version'
bash: line 1: go: command not found
Exit status: 127

$ /usr/bin/time -p vagrant snapshot restore quicknotes-clean-lab5
real 18.37
user 2.65
sys 1.96

$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64

$ curl -fsS http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
```

The complete evidence is in [snapshot-save.txt](evidence/lab5/snapshot-save.txt),
[break-go.txt](evidence/lab5/break-go.txt),
[broken-verification.txt](evidence/lab5/broken-verification.txt),
[snapshot-restore.txt](evidence/lab5/snapshot-restore.txt),
[restored-go.txt](evidence/lab5/restored-go.txt), and
[restored-host-health.txt](evidence/lab5/restored-host-health.txt).

### Snapshot design questions

**e) Snapshots are not backups.** A snapshot depends on the VM's original
virtual disks and the host storage that contains them. It does not protect
against disk loss, deletion of the entire VM directory, host compromise, or a
disaster affecting the same machine; an independent, tested copy is required
for backup.

**f) Copy-on-write.** Each snapshot initially stores metadata and then records
blocks changed after its parent snapshot instead of copying the complete base
disk. Ten snapshots can therefore start cheaply, but their differencing disks
grow with every distinct write and may collectively approach or exceed a full
disk. Reads and restoration also depend on the complete parent chain.

**g) Snapshot antipatterns.** Long-lived, deep snapshot chains are an
antipattern because they accumulate storage, slow I/O and consolidation, and
increase the number of dependent files that can break recovery. Snapshots are
best for short rollback windows around controlled experiments; durable state
should use backups and machines should remain reproducible from configuration.

## Bonus — VM versus container baseline

I measured both models on the same host and during the same session. The VM
measurement was taken after a halt and an unprovisioned cold boot; the container
measurement was taken after `docker stop` and `docker start`.

| Dimension | Vagrant VM | Docker container |
|---|---:|---:|
| Cold start | 33.94 s | 0.18 s |
| Idle RAM | 302 MiB used | 6.234 MiB |
| On-disk size | 3.1 GiB VM directory | 1.32 GB image |
| Process count (guest/container) | 163 | 2 |

The startup gap was the most striking result: the container resumed in 0.18
seconds while the VM needed 33.94 seconds to boot an operating system and become
SSH-ready. The VM also carried a full kernel and user space, reflected in its
RAM, disk, and process counts, while the container shared the host kernel.
VMs remain appropriate when a workload needs a distinct kernel, stronger
machine isolation, or a complete operating-system environment. Containers fit
stateless services that benefit from fast scheduling, high density, and small
operational units. These measurements help explain their adoption for
microservices from 2014–2020, although the 1.32 GB development image should be
replaced by a multi-stage production image for a fair optimized deployment.

Raw measurements: [VM cold start](evidence/lab5/vm-cold-start.txt),
[VM memory](evidence/lab5/vm-memory.txt),
[VM process count](evidence/lab5/vm-process-count.txt),
[VM disk size](evidence/lab5/vm-disk.txt),
[container cold start](evidence/lab5/docker-cold-start.txt),
[container memory](evidence/lab5/docker-memory.txt),
[container processes](evidence/lab5/docker-processes.txt), and
[container image size](evidence/lab5/docker-image-size.txt).

## Completion checklist

- [x] Ubuntu 24.04 VM is reproducibly configured with Go 1.24.5.
- [x] QuickNotes responds inside the guest and through `127.0.0.1:18080`.
- [x] All seven design questions are answered.
- [x] Snapshot save, destructive verification, timed restore, and recovery are recorded.
- [x] VM and container resource measurements and analysis are included.
- [ ] Signed upstream pull request published.
- [ ] Pull request URL submitted through Moodle.
