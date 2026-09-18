# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside

### 1.1 Vagrantfile

The final `Vagrantfile` is stored at the repository root:

```ruby
Vagrant.configure("2") do |config|
  # Ubuntu 22.04 LTS public Vagrant box
  config.vm.box = "ubuntu/jammy64"

  # Identify the VM clearly
  config.vm.hostname = "quicknotes-vm"

  # Host 127.0.0.1:18080 -> Guest :8080
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  # Sync only the application directory into the VM
  config.vm.synced_folder "./app",
    "/home/vagrant/app",
    type: "rsync"

  # VirtualBox resource limits
  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  # Install a pinned Go 1.24.x release automatically
  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"

    apt-get update
    apt-get install -y curl ca-certificates

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
        -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm -f /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    go version
  SHELL
end
```

The final VM uses Ubuntu 22.04 LTS (`ubuntu/jammy64`), which is one of the Ubuntu LTS versions allowed by the lab. The VM is limited to 2 vCPUs and 1024 MB RAM, syncs `./app` to `/home/vagrant/app`, and forwards only `127.0.0.1:18080` on the host to port `8080` in the guest.

`.vagrant/` is excluded through `.gitignore`.

### First 10 lines of `vagrant up`

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

The first attempted Ubuntu 24.04 Bento box did not complete boot/SSH successfully on this host, so the final reproducible configuration was switched to the allowed public Ubuntu 22.04 LTS box `ubuntu/jammy64`. The final `vagrant up` completed provisioning and installed Go successfully:

```text
default: ++ curl -fsSL https://go.dev/dl/go1.24.5.linux-amd64.tar.gz -o /tmp/go.tar.gz
default: ++ tar -C /usr/local -xzf /tmp/go.tar.gz
default: ++ ln -sf /usr/local/go/bin/go /usr/local/bin/go
default: ++ go version
default: go version go1.24.5 linux/amd64
```

### 1.2 Design Questions

#### a) Synced folders

I chose the `rsync` synced-folder type. It is simple and reliable on Linux and does not depend on matching VirtualBox Guest Additions for application file sharing. The trade-off is that it is not a fully transparent bidirectional filesystem mount: when host files change, an explicit `vagrant rsync` or `vagrant rsync-auto` may be needed to synchronize the changes into the guest.

#### b) NAT vs Bridged vs Host-only

The VM uses Vagrant's default NAT networking mode together with port forwarding. Binding the forwarded port to `127.0.0.1` means QuickNotes is reachable only from the host machine, while a bridged interface would give the VM an address on the local network and could expose the service to other devices. For a course exercise, localhost-only forwarding reduces unnecessary network exposure while still allowing the host to reach the guest application.

#### c) Provisioning options

I used Vagrant's `shell` provisioner to install Go. The provisioning task is small and deterministic, so a shell script is easier to read and maintain than introducing Ansible, Puppet, or Chef only to install one pinned toolchain. It also runs automatically during `vagrant up`, so no manual SSH installation is required.

#### d) Why pin Go to `1.24.5`?

Pinning Go to the exact point release `1.24.5` makes the environment reproducible. If the configuration only specified `1.24`, different students or future runs could receive different patch releases with different bug fixes or toolchain behavior. A point release ensures the same compiler and standard-library version are used every time.

### 1.4 Verification

Go inside the VM:

```bash
vagrant ssh -c 'go version'
```

Output:

```text
go version go1.24.5 linux/amd64
```

Health check from inside the VM:

```bash
vagrant ssh -c 'curl -sS http://localhost:8080/health'
```

Output:

```json
{"notes":8,"status":"ok"}
```

Health check from the host through the forwarded port:

```bash
curl -sS http://localhost:18080/health
```

Output:

```json
{"notes":8,"status":"ok"}
```

This verifies that `127.0.0.1:18080` on the host is successfully forwarded to QuickNotes on guest port `8080`.

---

## Task 2 — Snapshots: Save, Break, Restore

### 2.1 Snapshot Lifecycle

A snapshot of the healthy VM was saved with a meaningful name:

```bash
vagrant snapshot save quicknotes-clean
```

Output:

```text
==> default: Snapshotting the machine as 'quicknotes-clean'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```

The snapshot was listed successfully:

```bash
vagrant snapshot list
```

Output:

```text
quicknotes-clean
```

#### Deliberately break the VM

The Go installation was removed inside the guest:

```bash
vagrant ssh -c 'sudo rm -rf /usr/local/go'
```

The breakage was verified:

```bash
vagrant ssh -c 'go version'
```

Output:

```text
bash: line 1: go: command not found
```

#### Restore the snapshot

The snapshot was restored while measuring the operation:

```bash
time vagrant snapshot restore quicknotes-clean
```

Output:

```text
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'quicknotes-clean'...
==> default: Checking if box 'ubuntu/jammy64' version '20241002.0.0' is up to date...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
==> default: Machine booted and ready!
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.

real    0m19.672s
user    0m3.784s
sys     0m4.363s
```

Recovery was verified:

```bash
vagrant ssh -c 'go version'
```

Output:

```text
go version go1.24.5 linux/amd64
```

QuickNotes was also healthy again inside the guest:

```bash
vagrant ssh -c 'curl -sS http://localhost:8080/health'
```

```json
{"notes":8,"status":"ok"}
```

and from the host:

```bash
curl -sS http://localhost:18080/health
```

```json
{"notes":8,"status":"ok"}
```

### 2.2 Design Questions

#### e) Why are snapshots not backups?

A snapshot depends on the VM's underlying virtual disk and the storage that contains it. If the host disk is lost, the base virtual disk is corrupted, or the VM storage is deleted, the snapshot may be unusable as well. A real backup is an independent copy that can survive loss of the original VM and storage.

#### f) Copy-on-write

VirtualBox snapshots use copy-on-write differencing disks. A snapshot does not duplicate the entire virtual disk; after the snapshot, changed blocks are written to a new differencing disk while unchanged blocks continue to reference the previous disk state. Therefore, ten snapshots normally use more disk space than one snapshot, but they do not automatically consume ten complete copies of the VM disk; the actual growth depends on how much data changes between snapshots.

#### g) When is snapshotting an antipattern?

Snapshotting becomes an antipattern when long chains of snapshots are kept for extended periods or treated as permanent backups. Long chains consume increasing disk space, introduce dependencies between differencing disks, and make storage management and recovery more complex. Snapshots are most useful as short-lived rollback points around controlled changes.

---

## Bonus Task — VM vs Container Resource Baseline

### B.1 Vagrant VM Measurements

Cold boot was measured after halting the existing provisioned VM:

```bash
time vagrant halt
time vagrant up
```

Measured VM boot time:

```text
real    0m33.548s
user    0m5.664s
sys     0m7.177s
```

Idle memory:

```bash
vagrant ssh -c 'free -h'
```

Output:

```text
               total        used        free      shared  buff/cache   available
Mem:           957Mi       180Mi       578Mi       0.0Ki       198Mi       629Mi
Swap:             0B          0B          0B
```

Process count:

```bash
vagrant ssh -c 'ps -A --no-headers | wc -l'
```

Output:

```text
110
```

VM on-disk size:

```bash
du -sh "/home/kriss/VirtualBox VMs/quicknotes-lab5"
```

Output:

```text
3.0G    /home/kriss/VirtualBox VMs/quicknotes-lab5
```

### B.2 Docker Measurements

The same QuickNotes source was started in a Go 1.24 container:

```bash
docker run -d \
  --name quicknotes-lab5-bonus \
  -p 28080:8080 \
  -v "$PWD/app:/src" \
  -w /src \
  golang:1.24 \
  sh -c 'go build -o /tmp/qn && /tmp/qn'
```

The application was healthy:

```bash
curl -sS http://localhost:28080/health
```

Output:

```json
{"notes":8,"status":"ok"}
```

Cold start of the already-created container:

```bash
docker stop quicknotes-lab5-bonus
time docker start quicknotes-lab5-bonus
```

Measured start time:

```text
real    0m0.556s
user    0m0.014s
sys     0m0.028s
```

Idle RAM:

```bash
docker stats --no-stream quicknotes-lab5-bonus
```

Relevant result:

```text
MEM USAGE: 7.078MiB
```

Process count:

```bash
docker top quicknotes-lab5-bonus | tail -n +2 | wc -l
```

Output:

```text
2
```

Image size:

```bash
docker images golang:1.24 --format '{{.Repository}}:{{.Tag}} {{.Size}}'
```

Output:

```text
golang:1.24 894MB
```

### B.3 VM vs Container Comparison

| Dimension | Vagrant VM | Docker container |
|---|---:|---:|
| Cold start | 33.548 s | 0.556 s |
| Idle RAM | 180 MiB | 7.078 MiB |
| On-disk size | 3.0 GB | 894 MB |
| Process count (guest/container) | 110 | 2 |

The largest difference was startup time: the container started in well under one second, while the VM required more than 33 seconds to boot its full guest operating system. The memory and process counts show the same pattern, because the VM runs an entire Linux userspace and kernel environment while the container shares the host kernel and runs only the application-related processes. VMs are still useful when strong isolation, a separate guest OS, or a complete machine-level environment is required. Containers are a better fit for lightweight, stateless services that need fast startup and high density. These measurements help explain why containers became dominant for stateless microservices during the 2014–2020 period: they provide much lower startup and runtime overhead while retaining reproducible application packaging.
