# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

The submitted configuration is [`Vagrantfile`](../Vagrantfile), with an idempotent [shell provisioner](../provision/lab5-provision.sh) and [systemd unit](../provision/lab5-quicknotes.service). I ran it on Windows 11 with Vagrant 2.4.9 and VirtualBox 7.0.20. The box is pinned to `bento/ubuntu-24.04` version `202508.03.0` for `amd64`; the provisioner downloads Go 1.24.13 and verifies its SHA-256. `.vagrant/` is already excluded by the repository's `.gitignore`.

## Task 1 — Boot, provision, and reach QuickNotes

The opening 10 lines of the first `vagrant up --provider=virtualbox` output, with terminal progress control characters removed, were:

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'bento/ubuntu-24.04' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: 202508.03.0
==> default: Loading metadata for box 'bento/ubuntu-24.04'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/bento/ubuntu-24.04
==> default: Adding box 'bento/ubuntu-24.04' (v202508.03.0) for provider: virtualbox (amd64)
    default: Downloading: https://vagrantcloud.com/bento/boxes/ubuntu-24.04/versions/202508.03.0/providers/virtualbox/amd64/vagrant.box
Progress: 100% (Rate: 2/s, Estimated time remaining: --:--:--)
Progress: 9% (Rate: 7955k/s, Estimated time remaining: 0:01:47)
```

The first boot stalled before SSH and exceeded Vagrant's five minute timeout. I halted only this new VM and ran `vagrant up` again; the same pinned box then booted, mounted `./app`, and completed provisioning. The provisioner finished with `/tmp/go-1.24.13.linux-amd64.tar.gz: OK` and `{"notes":4,"status":"ok"}`. A second `vagrant provision` completed successfully, leaving Go 1.24.13 and the service healthy; no reinstall of Go was needed.

```text
vagrant ssh -c 'go version && curl -sS http://127.0.0.1:8080/health && systemctl is-active quicknotes'
go version go1.24.13 linux/amd64
{"notes":4,"status":"ok"}
active

curl.exe -sS -i http://127.0.0.1:18080/health
HTTP/1.1 200 OK
Content-Type: application/json
{"notes":4,"status":"ok"}
```

VirtualBox reported one NAT adapter, `127.0.0.1:18080 → guest:8080`, 2 vCPU, and 1024 MB RAM. QuickNotes runs under systemd as the `vagrant` user with persistent data at `/var/lib/quicknotes/notes.json` inside the guest.

### Design answers

**a) Synced folder.** I chose a VirtualBox shared folder for `./app` because it provides immediate two-way updates from the Windows host without requiring a Windows `rsync` installation. Its drawbacks are dependence on compatible Guest Additions, slower file I/O than a native guest disk, and host/guest permission differences. Vagrant warned that this box's Guest Additions are 7.1.12 while the installed VirtualBox is 7.0, but the mount worked in the actual run.

**b) Network.** The VM uses VirtualBox's default NAT mode. Loopback-bound port forwarding exposes only the one course API port to the host itself; a bridged adapter would give the VM an address reachable by other machines on the local network and widen the exposure of an unprotected lab service.

**c) Provisioning.** A shell provisioner installs the pinned Go tarball, builds the synced source, and enables a systemd service. A file provisioner uploads the unit file. This small setup is readable and works on the first `vagrant up`; it was rerun to test idempotency. Lab 7 can introduce Ansible without making this VM dependent on Ansible for its initial boot.

**d) Point release.** Pinning `1.24.13`, rather than a moving `1.24` selector, makes the compiler and standard library predictable across students and rebuilds. The tarball SHA-256 check also detects a corrupted or substituted download. A later security update becomes an explicit reviewed change to the version and checksum.

## Task 2 — Save, break, restore

I saved the running, healthy VM and deliberately removed the Go executable from **inside this VM**. The host source files were not changed.

```text
vagrant snapshot save quicknotes-clean-go12413
==> default: Snapshot saved!

vagrant ssh -c 'sudo rm -- /usr/local/go/bin/go'
vagrant ssh -c 'go version'
bash: line 1: go: command not found
exit code: 1

vagrant snapshot restore quicknotes-clean-go12413
==> default: Restoring the snapshot 'quicknotes-clean-go12413'...
==> default: Machine booted and ready!
restore_exit=0 elapsed_seconds=48.7

vagrant ssh -c 'go version && systemctl is-active quicknotes && curl -sS http://127.0.0.1:8080/health'
go version go1.24.13 linux/amd64
active
{"notes":4,"status":"ok"}
```

`vagrant snapshot list` still shows `quicknotes-clean-go12413`, so the clean recovery point remains available. The restore took 48.7 seconds on this host, above the 30 second target. The VM's `/health` endpoint also returned HTTP 200 from the Windows host after restore.

**e) Snapshot versus backup.** A snapshot normally remains on the same host and storage as its VM, so disk failure, loss of the laptop, or deletion of the VM can destroy both the working state and the snapshot. It also does not protect data outside the VM disk, such as this project's host-side shared `app/` folder; an independent off-host backup is still needed.

**f) Copy-on-write.** VirtualBox freezes the parent disk and puts later writes into a new differencing image. Ten snapshots do not copy the entire base disk ten times, but each snapshot adds metadata and changed blocks (and may include saved memory), so disk use grows with the amount of writing and the number of recovery points.

**g) Antipattern.** A long snapshot chain makes reads and merges depend on multiple differencing images, increases disk use, and complicates recovery. Snapshots are useful for a short experiment or rollback point, but persistent environments should be rebuilt from provisioning code and backed up separately.

## Bonus — VM and container resource baseline

Both measurements were taken on this Windows host in the same session while QuickNotes was idle. The VM cold boot was measured from `vagrant up --no-provision` after `vagrant halt`; the container start was measured from `docker start` after `docker compose stop quicknotes`.

| Dimension | Vagrant VM | Docker container |
|---|---:|---:|
| Cold start | 104.71 s | 0.73 s |
| Idle RAM | 330 MiB used of 961 MiB guest RAM (`free -h`) | 2.383 MiB (`docker stats --no-stream`) |
| On-disk size | 3.07 GiB VM folder, including the snapshot | 15.7 MB runtime image |
| Process count | 148 guest processes | 1 process (`docker top`) |

The VM's boot time and process count were much larger than the container's. A VM is appropriate when a separate kernel, full OS, or stronger machine boundary is needed; the container fits a small, stateless API that can share the host kernel. The data explains why containers became attractive for stateless services: startup and per-service storage and memory are much smaller. The comparison has limits: the VM folder includes a snapshot, the container image excludes Docker Engine and its shared kernel, and `docker start` returns before the Compose healthcheck changes to `healthy`; both endpoints were checked after startup.
