# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-vm"
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e
    GO_VERSION="1.24.5"

    if go version 2>/dev/null | grep -q "$GO_VERSION"; then
      echo "Go $GO_VERSION already installed"
      exit 0
    fi

    apt-get update -qq
    apt-get install -y -qq curl gcc > /dev/null

    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz

    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
  SHELL
end
```

### First 10 lines of `vagrant up` output

```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'ubuntu/jammy64'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'ubuntu/jammy64' version '20250615.0.0' is up to date...
==> default: Setting the name of the VM...
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
```

### curl output from inside the VM

```
vagrant@quicknotes-vm:~$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

### curl output from the host (via port forward)

```
PS> curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

### Design Questions

**a) Synced folders — which type and why?**

I used `virtualbox` shared folders. They work out of the box on any host OS without extra software — unlike `rsync` (requires rsync binary on Windows) or `nfs` (not supported on Windows without plugins). The trade-off is performance: VirtualBox shared folders have slower I/O than NFS or rsync, but for a small Go project this is negligible. Rsync is one-directional (host → guest) so changes inside the VM are not synced back, while VirtualBox mounts are bidirectional.

**b) NAT vs Bridged vs Host-only — which mode and why `127.0.0.1`?**

The default mode is NAT. The VM gets a private IP behind VirtualBox's NAT engine and reaches the internet through the host. Port forwarding with `host_ip: "127.0.0.1"` means the forwarded port is only accessible from localhost — not from other machines on the network. A Bridged interface would place the VM directly on the physical network, exposing the unprotected dev server to anyone on the LAN or Wi-Fi, which is unnecessary and risky for a course exercise.

**c) Provisioning method — which and why?**

I used the `shell` provisioner with an inline script. For a single task (install Go), shell is the simplest and most portable option — no extra tools needed on the host. Ansible would add a dependency and complexity that is not justified for downloading and extracting one tarball. The script is idempotent: it checks whether the correct Go version is already installed before doing anything.

**d) Why pin Go to `1.24.5` instead of `1.24`?**

`go.dev/dl` only hosts specific point releases (e.g. `go1.24.5.linux-amd64.tar.gz`), not a generic `go1.24` tarball. Pinning ensures every student gets the exact same binary, making builds reproducible. If a new patch version (e.g. 1.24.6) introduced a behavior change or regression, an unpinned install could break the build on some machines but not others.

---

## Task 2 — Snapshots: Save, Break, Restore

### Commands

```bash
# 1. Save a snapshot of the working VM
vagrant snapshot save working-state

# 2. Break the VM — delete the Go installation
vagrant ssh -c 'sudo rm -rf /usr/local/go'

# 3. Verify it's broken
vagrant ssh -c 'go version'
# bash: go: command not found

# 4. Restore the snapshot
vagrant snapshot restore working-state

# 5. Verify recovery
vagrant ssh -c 'go version'
# go version go1.24.5 linux/amd64
```

### Restore time

```
$ time vagrant snapshot restore working-state
==> default: Restoring the snapshot 'working-state'...
==> default: Checking if box 'ubuntu/jammy64' version '20250615.0.0' is up to date...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Waiting for machine to boot...
==> default: Machine booted and ready!
==> default: Machine already provisioned.

real    0m24.318s
user    0m3.112s
sys     0m1.245s
```

### Design Questions

**e) Snapshots are not backups — why?**

Snapshots live on the same disk as the VM image. If the host drive fails, both the base image and all snapshots are lost together. Snapshots also do not protect against hypervisor bugs or corruption of the VirtualBox metadata. A real backup is an independent copy stored on a separate medium, ideally off-site.

**f) Copy-on-write and 10 snapshots vs 1**

With copy-on-write, taking a snapshot does not duplicate the entire disk. It only records the difference (delta) from that point forward. Ten snapshots therefore use much less space than 10 full copies — but each snapshot still accumulates its own delta. Over time, a long chain of snapshots can consume significant disk space as deltas stack up, and read performance degrades because VirtualBox must traverse the chain to resolve each block.

**g) When is snapshotting an antipattern?**

Long snapshot chains are an antipattern. Each new snapshot adds a layer that the hypervisor must walk through on every disk read, degrading I/O performance. They also create a false sense of safety — the chain is fragile, and deleting a middle snapshot requires merging deltas, which is slow and risky. In production, immutable infrastructure (rebuild from code) is preferred over mutable state managed via snapshots.

---

## Bonus Task — VM vs Container Resource Baseline

### Comparison Table

| Dimension             | Vagrant VM   | Docker container |
|-----------------------|-------------:|-----------------:|
| Cold start            |       38.2 s |            1.8 s |
| Idle RAM              |      412 MiB |           18 MiB |
| On-disk size          |      2.1 GiB |          820 MiB |
| Process count (guest) |          112 |                3 |

### Commands used

**VM:**

```bash
time vagrant halt; time vagrant up       # cold boot
vagrant ssh -c 'free -h'                 # idle RAM
vagrant ssh -c 'ps -A --no-headers | wc -l'  # process count
du -sh ~/VirtualBox\ VMs/quicknotes-vm   # disk size
```

**Docker:**

```bash
docker run -d -p 28080:8080 -v "$PWD/app:/src" -w /src golang:1.24 \
  sh -c 'go build -o /tmp/qn && /tmp/qn'
docker stop <id>; time docker start <id>  # cold start
docker stats --no-stream                  # idle RAM
docker top <id>                           # process count
docker images --format '{{.Size}}' golang:1.24  # disk size
```

### Analysis

The biggest gap is in cold start time: the VM takes ~38 seconds to boot a full Linux kernel and init system, while the container starts in under 2 seconds because it reuses the host kernel. Idle RAM is also dramatically different — the VM runs over 100 processes (systemd, journald, cron, sshd, etc.) consuming ~400 MiB, while the container runs only the Go binary with minimal overhead. On-disk size reflects the same pattern: the VM image includes a full OS install, while the container image only ships the Go toolchain and dependencies. These numbers explain why containers dominated the 2014–2020 era for stateless microservices — fast startup, low resource overhead, and high density per host are exactly what horizontal scaling demands. VMs remain the right choice when you need full OS isolation, different kernels, or hardware-level security boundaries (e.g. multi-tenant cloud).
