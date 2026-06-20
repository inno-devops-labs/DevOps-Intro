# Lab 5 - Submission

## Task 1 - Vagrant Up + Run QuickNotes Inside

### Vagrantfile

```
GO_VERSION = "1.24.5"

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"          # Ubuntu 22.04 LTS
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail

    if ! command -v go >/dev/null 2>&1 || ! go version | grep -q "go#{GO_VERSION}"; then
      curl -fsSL "https://go.dev/dl/go#{GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi

    if ! grep -q '/usr/local/go/bin' /etc/profile.d/go.sh 2>/dev/null; then
      echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
      chmod +x /etc/profile.d/go.sh
    fi
  SHELL
end
```

### First 10 lines of vagrant up output

```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Checking if box 'ubuntu/jammy64' version '20241002.0.0' is up to date...
==> default: Clearing any previously set forwarded ports...
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
```

### curl from inside the VM

```
$ vagrant ssh -c 'curl -s http://localhost:8080/health'
{"notes":4,"status":"ok"}
```

### curl from the host (via port forward)

```
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

### Design questions

**a) Synced folders: which type, and why?**

rsync. Faster build I/O than VirtualBox shared folders, no NFS/SMB service needed. Trade-off: sync is one-way, host to guest only.

**b) NAT vs Bridged vs Host-only: which mode, and why is 127.0.0.1-bound port forwarding safer?**

NAT (the default). Binding the forwarded port to 127.0.0.1 keeps it reachable only from the host itself; a Bridged interface would expose it to the whole LAN.

**c) Provisioning options: which did you pick, and why?**

shell. Installing one Go tarball is a single linear script; a tool like Ansible would be overkill.

**d) Why pin Go to 1.24.5 instead of 1.24?**

go.dev/dl has no moving "1.24" alias, only exact tarballs. Pinning also keeps the toolchain identical for every student.

## Task 2 - Snapshots: Save, Break, Restore

### Commands run

```
$ vagrant snapshot save clean-go-installed
==> default: Snapshotting the machine as 'clean-go-installed'...
==> default: Snapshot saved!

$ vagrant ssh -c 'sudo rm -rf /usr/local/go'

$ vagrant ssh -c 'go version'
bash: line 1: go: command not found

$ time vagrant snapshot restore clean-go-installed
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'clean-go-installed'...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Machine booted and ready!

$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64
```

### Restore time

```
real    0m27.546s
user    0m4.655s
sys     0m3.436s
```

### Design questions

**e) Why are snapshots not backups?**

Snapshot and VM share one disk, so a disk or host failure loses both. Restoring also discards any data created after the snapshot.

**f) Copy-on-write: 10 snapshots vs 1**

Snapshots are differencing disks holding only changed blocks. 10 snapshots cost roughly the sum of actual changes between them, not 10x the full disk.

**g) When is snapshotting an antipattern?**

Long snapshot chains: each extra layer slows disk reads and is harder to reason about. Snapshots should be short-lived and deleted after use.

## Bonus Task - VM vs Container Resource Baseline

| Dimension             |            Vagrant VM | Docker container |
| --------------------- | --------------------: | ---------------: |
| Cold start            | 11.2s halt + 32.8s up |            0.35s |
| Idle RAM              |          168 MiB used |          8.4 MiB |
| On-disk size          |                2.2 GB |          1.32 GB |
| Process count (guest) |                   105 |                2 |

Idle RAM and process count were the most surprising: the container uses about 20x less RAM and runs 2 processes versus 105 in the VM, for the identical app. VMs fit workloads needing a different OS or kernel-level isolation; containers fit stateless, single-process services. This is why containers won for stateless microservices in 2014-2020: paying for a full guest OS's boot time, RAM, and process overhead has no benefit when the workload is just "run one process, forward a port."
