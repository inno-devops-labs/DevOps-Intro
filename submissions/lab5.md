# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — QuickNotes VM

### Vagrant configuration

The VM is configured using [`Vagrantfile`](../Vagrantfile) in the repository root.

Configuration:

- Ubuntu 24.04 LTS ARM64
- hostname: `quicknotes-vm`
- 2 vCPUs
- 1024 MB RAM
- host `127.0.0.1:18080` forwarded to guest port `8080`
- host `./app` synced to `/home/vagrant/quicknotes`
- Go 1.24.7 installed automatically during provisioning

The ARM64 Ubuntu box is used because the host machine is an Apple Silicon Mac.

### Initial `vagrant up`

The first lines of the initial VM startup were:

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'net9/ubuntu-24.04-arm64'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'net9/ubuntu-24.04-arm64' version '1.1' is up to date...
==> default: Setting the name of the VM: DevOps-Intro_default_1789459783873_59965
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
```

During the initial setup, the VirtualBox NAT DNS server did not resolve external hostnames correctly on this environment. The provisioning script therefore configures `1.1.1.1` as the DNS server for `eth0` before downloading packages and Go.

### VM verification

The VM configuration was verified with:

```bash
vagrant ssh -c 'hostname && go version && nproc && free -h'
```

Output:

```text
quicknotes-vm
go version go1.24.7 linux/arm64
2
               total        used        free      shared  buff/cache   available
Mem:           951Mi       257Mi       263Mi       936Ki       526Mi       693Mi
Swap:          1.4Gi        12Ki       1.4Gi
```

This confirms that the VM has the expected hostname, Go version, CPU limit, and approximately 1 GB of RAM.

### Running QuickNotes

QuickNotes was built and started inside the VM:

```bash
cd /home/vagrant/quicknotes
go build -o /tmp/qn
/tmp/qn
```

Output:

```text
quicknotes listening on :8080 (notes loaded: 6)
```

The health endpoint was checked from inside the VM:

```bash
vagrant ssh -c 'curl -s http://127.0.0.1:8080/health'
```

Output:

```json
{"notes":6,"status":"ok"}
```

The same service was then accessed from the host through the forwarded port:

```bash
curl -s http://127.0.0.1:18080/health
```

Output:

```json
{"notes":6,"status":"ok"}
```

### Provisioning idempotency

The provisioner was executed again after the initial setup to verify that repeated provisioning does not break the VM:

```bash
vagrant provision
```

The second run completed successfully. Existing packages were detected:

```text
curl is already the newest version (8.5.0-2ubuntu10.13).
ca-certificates is already the newest version (20260601~24.04.1).
0 upgraded, 0 newly installed, 0 to remove and 298 not upgraded.
```

The provisioner also detected the already installed Go version and completed successfully:

```text
go version go1.24.7 linux/arm64
```

Go was verified separately:

```bash
vagrant ssh -c 'go version'
```

Output:

```text
go version go1.24.7 linux/arm64
```

QuickNotes could still be built successfully after reprovisioning:

```bash
vagrant ssh -c 'cd /home/vagrant/quicknotes && go build -o /tmp/qn'
```

The command completed without errors.

### Design questions

#### a. Which synced-folder type did you choose and what is the trade-off?

I used the default VirtualBox shared-folder mechanism. It provides a live shared view of the host `./app` directory inside the VM, so changes made on the host are immediately available in the guest.

The disadvantage is that this mechanism depends on VirtualBox Guest Additions and can have compatibility or performance issues compared with native filesystem access or rsync. For this lab, the convenience of immediate synchronization makes it a suitable choice.

#### b. NAT vs Bridged vs Host-only networking

NAT allows the VM to access external networks through the host without exposing the VM directly to the physical network. Bridged networking gives the VM its own address on the local network, making it behave more like a separate physical machine. Host-only networking creates a private network between the host and the VM and normally does not provide direct Internet access.

Vagrant uses NAT as the default networking mode. This VM uses NAT together with explicit port forwarding.

The forwarded QuickNotes port is bound to `127.0.0.1` on the host. This is safer than exposing the application through a bridged interface because the service is reachable from the host but is not directly exposed to other machines on the local network.

#### c. Which provisioner did you choose and why?

I used the Vagrant shell provisioner. The required setup is relatively small and consists mainly of configuring DNS, installing basic packages, and installing a pinned Go version.

A shell provisioner keeps the configuration simple and transparent and does not require an additional configuration-management tool such as Ansible. For a larger environment with many machines and more complex configuration, a dedicated configuration-management tool could be more appropriate.

#### d. Why pin a Go point release instead of using only `1.24`?

The provisioning script pins Go to `1.24.7`.

Pinning a specific point release improves reproducibility because every clean VM receives exactly the same Go version. If only `1.24` were specified, the installed patch version could change over time and different environments could end up using different Go versions.

---

## Task 2 — Snapshot and Recovery

### Creating a working snapshot

A snapshot of the working VM was created with a meaningful name:

```bash
vagrant snapshot save quicknotes-working
```

The snapshot was verified with:

```bash
vagrant snapshot list
```

Output:

```text
quicknotes-working
```

### Deliberately breaking the VM

To simulate a destructive configuration change, the Go installation and its command symlinks were removed:

```bash
vagrant ssh -c 'sudo rm -rf /usr/local/go && sudo rm -f /usr/local/bin/go /usr/local/bin/gofmt'
```

The broken state was verified:

```bash
vagrant ssh -c 'go version'
```

Output:

```text
bash: line 1: go: command not found
```

QuickNotes could no longer be built:

```bash
vagrant ssh -c 'cd /home/vagrant/quicknotes && go build -o /tmp/qn'
```

Output:

```text
bash: line 1: go: command not found
```

This confirms that the deliberate change successfully broke the development environment.

### Restoring the snapshot

The working snapshot was restored and the restore operation was timed:

```bash
time vagrant snapshot restore quicknotes-working
```

Output:

```text
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'quicknotes-working'...
==> default: Checking if box 'net9/ubuntu-24.04-arm64' version '1.1' is up to date...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
==> default: Machine booted and ready!
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.
vagrant snapshot restore quicknotes-working  0.92s user 0.65s system 14% cpu 11.096 total
```

The complete restore took approximately **11.1 seconds**.

### Verifying recovery

After restoring the snapshot, Go was available again:

```bash
vagrant ssh -c 'go version'
```

Output:

```text
go version go1.24.7 linux/arm64
```

QuickNotes could also be built again:

```bash
vagrant ssh -c 'cd /home/vagrant/quicknotes && go build -o /tmp/qn'
```

The build completed without errors.

After starting QuickNotes, the health endpoint was checked inside the VM:

```bash
vagrant ssh -c 'curl -s http://127.0.0.1:8080/health'
```

Output:

```json
{"notes":6,"status":"ok"}
```

The forwarded endpoint was also checked from the host:

```bash
curl -s http://127.0.0.1:18080/health
```

Output:

```json
{"notes":6,"status":"ok"}
```

The snapshot successfully restored the VM to its previous working state.

### Snapshot design questions

#### e. Why are snapshots not backups?

A snapshot normally depends on the original VM and its virtual disk chain. If the underlying VM files, host storage, or snapshot chain is lost or corrupted, the snapshot can also become unusable.

A proper backup should be an independent copy that can survive the loss of the original VM or storage. Snapshots are therefore useful for short-term rollback but should not replace backups.

#### f. How does copy-on-write affect disk usage with 10 snapshots compared with 1 snapshot?

Snapshots use copy-on-write storage. Instead of creating a complete copy of the virtual disk immediately, the original blocks are preserved and subsequent changed blocks are stored separately.

Therefore, ten snapshots do not necessarily require ten times the full VM disk size. However, as more blocks change between snapshots, additional data and metadata accumulate. Ten snapshots will normally consume more storage than one snapshot and create a longer snapshot chain.

#### g. When does snapshotting become an anti-pattern?

Snapshotting becomes an anti-pattern when snapshots are kept for long periods, when very long snapshot chains are created, or when snapshots are used as a replacement for proper backups.

This is especially problematic for high-write workloads because changed blocks can accumulate quickly. Long chains can increase storage usage, reduce performance, and make recovery more complex. Long-term recovery should instead rely on proper backups, images, and reproducible infrastructure configuration.

---

## Bonus — VM vs Docker

The same QuickNotes application was run both in the Vagrant VM and in a Docker container on the same host.

### B1 — Vagrant VM measurements

#### Cold start

The VM was first stopped and then started again:

```bash
time vagrant halt
time vagrant up
```

The measured VM startup time was:

```text
vagrant up  1.36s user 1.05s system 12% cpu 18.534 total
```

Therefore, the VM cold-start time was approximately **18.534 seconds**.

#### Idle RAM

```bash
vagrant ssh -c 'free -h'
```

Output:

```text
               total        used        free      shared  buff/cache   available
Mem:           951Mi       254Mi       563Mi       948Ki       210Mi       696Mi
Swap:          1.4Gi          0B       1.4Gi
```

The VM used approximately **254 MiB** of RAM while idle.

#### Process count

```bash
vagrant ssh -c 'ps -A --no-headers | wc -l'
```

Output:

```text
108
```

The VM had **108 processes**.

#### On-disk size

The VirtualBox VM directory was measured with:

```bash
du -sh "$HOME/VirtualBox VMs/DevOps-Intro_default_1789459783873_59965"
```

Output:

```text
3.0G	/Users/renatasalikhzianova/VirtualBox VMs/DevOps-Intro_default_1789459783873_59965
```

The VM occupied approximately **3.0 GB** on disk.

### B2 — Docker measurements

The same QuickNotes application was started in a Docker container:

```bash
docker run -d \
  --name quicknotes-lab5 \
  -p 28080:8080 \
  -v "$PWD/app:/src" \
  -w /src \
  golang:1.24 \
  sh -c 'go build -o /tmp/qn && /tmp/qn'
```

The application was verified from the host:

```bash
curl -s http://127.0.0.1:28080/health
```

Output:

```json
{"notes":6,"status":"ok"}
```

#### Cold start

The existing container was stopped and started again:

```bash
docker stop quicknotes-lab5
time docker start quicknotes-lab5
```

Output:

```text
quicknotes-lab5
quicknotes-lab5
docker start quicknotes-lab5  0.01s user 0.01s system 17% cpu 0.097 total
```

The Docker container cold-start time was approximately **0.097 seconds**.

#### Idle RAM

Memory usage was measured with:

```bash
docker stats --no-stream quicknotes-lab5
```

The relevant result was:

```text
MEM USAGE / LIMIT
7.574MiB / 7.652GiB
```

The container used approximately **7.574 MiB** of RAM.

#### Process count

Processes were inspected with:

```bash
docker top quicknotes-lab5
```

The output contained two application process lines:

```text
sh -c go build -o /tmp/qn && /tmp/qn
/tmp/qn
```

Therefore, the Docker process count used for the comparison is **2**.

#### Image size

The Docker image size was checked with:

```bash
docker images golang:1.24 --format '{{.Repository}}:{{.Tag}} {{.Size}}'
```

Output:

```text
golang:1.24 1.33GB
```

The Docker image occupied approximately **1.33 GB**.

### B3 — Comparison

| Metric | Vagrant VM | Docker |
|---|---:|---:|
| Cold start | 18.534 s | 0.097 s |
| Idle RAM | 254 MiB | 7.574 MiB |
| On-disk size | 3.0 GB | 1.33 GB |
| Process count | 108 | 2 |

The biggest difference was startup time: the Docker container started in about 0.1 seconds, while the VM required about 18.5 seconds. Docker also used much less idle memory because containers share the host kernel, while the VM runs a complete guest operating system with its own services and processes. VMs are useful when stronger isolation, a different operating system, or full-system testing is required, while containers are more suitable for lightweight services and fast scaling. Even the full `golang:1.24` development image was smaller than the VM disk in this experiment. The low startup time, lower resource overhead, portable images, and easy orchestration of containers made them especially suitable for the stateless microservice workloads that became common between 2014 and 2020.

---

## Summary

In this lab, I created a reproducible Ubuntu 24.04 VM for QuickNotes using Vagrant and VirtualBox. The VM installs a pinned Go 1.24.7 release automatically, shares the application directory with the host, and exposes QuickNotes through a localhost-bound forwarded port.

I also tested repeated provisioning, deliberately broke the VM, and recovered it using a snapshot. Finally, I compared the VM with a Docker container and observed substantially lower startup time, memory usage, and process overhead for the container.