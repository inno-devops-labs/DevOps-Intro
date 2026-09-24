# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  # Ubuntu 24.04 LTS
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes"

  # Host 127.0.0.1:18080 -> guest :8080
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  # Sync the QuickNotes application into the VM
  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  # VM resource limits
  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 1024
  end

  # Install a pinned Go version
  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"
    ARCH="$(dpkg --print-architecture)"

    case "$ARCH" in
      amd64|arm64)
        ;;
      *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
    esac

    apt-get update
    apt-get install -y curl ca-certificates

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm -f /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    go version
  SHELL
end
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

### Go version inside the VM

```bash
vagrant ssh -c 'go version'
```

```text
go version go1.24.5 linux/arm64
```

### QuickNotes health check inside the VM

```bash
vagrant ssh -c 'curl -s http://localhost:8080/health'
```

```json
{"notes":7,"status":"ok"}
```

### QuickNotes health check from the host

```bash
curl -s http://localhost:18080/health
```

```json
{"notes":7,"status":"ok"}
```

### Design questions

#### a) Synced folders

I used the `rsync` synced-folder type to synchronize the host `./app` directory with `/home/vagrant/app` in the guest. It is simple and avoids relying on VirtualBox shared-folder support inside the guest. The trade-off is that rsync synchronization is not inherently bidirectional or continuously updated, so host-side changes may require another sync.

#### b) NAT vs Bridged vs Host-only

The VM uses Vagrant's default NAT networking with port forwarding. Binding the forwarded host port to `127.0.0.1` makes QuickNotes reachable only from the host machine. This is safer for a course exercise than a Bridged interface because a bridged VM can appear as a separate machine on the physical network and expose its services to other hosts on that network.

#### c) Provisioning options

I used the `shell` provisioner to install Go. The required setup is small and consists mainly of installing dependencies and downloading a pinned Go archive, so a shell provisioner is sufficient and keeps the Vagrant configuration simple. More advanced configuration-management tools such as Ansible would add unnecessary complexity for this task.

#### d) Why pin Go to `1.24.5`?

Pinning Go to the specific `1.24.5` point release makes provisioning reproducible. Using only `1.24` could result in different machines receiving different patch releases over time, potentially changing behavior or build results.

---

## Task 2 — Snapshots: Save, Break, Restore

### Save a working snapshot

```bash
vagrant snapshot save lab5-clean
```

```text
==> default: Snapshotting the machine as 'lab5-clean'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```

Snapshot verification:

```bash
vagrant snapshot list
```

```text
==> default:
lab5-clean
```

### Break the VM

I deliberately removed the Go installation:

```bash
vagrant ssh -c 'sudo rm -rf /usr/local/go'
```

I verified that Go was no longer available:

```bash
vagrant ssh -c 'go version'
```

```text
bash: line 1: go: command not found
```

### Restore the snapshot

```bash
time vagrant snapshot restore lab5-clean
```

```text
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'lab5-clean'...
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
vagrant snapshot restore lab5-clean  1.03s user 0.73s system 15% cpu 11.138 total
```

Restore time: **11.138 seconds**.

### Verify recovery

```bash
vagrant ssh -c 'go version'
```

```text
go version go1.24.5 linux/arm64
```

QuickNotes was also available again:

```bash
curl -s http://localhost:18080/health
```

```json
{"notes":7,"status":"ok"}
```

### Design questions

#### e) Why are snapshots not backups?

A snapshot depends on the underlying VM storage and host infrastructure, so it does not protect against failures such as loss or corruption of the host disk or deletion of the entire VM. A real backup should be stored independently so that data can still be recovered when the original VM and its storage are unavailable.

#### f) Copy-on-write

With copy-on-write snapshots, unchanged virtual disk blocks are shared rather than copied into a complete new disk image for every snapshot. Each snapshot primarily stores blocks that change after the snapshot point, so ten snapshots do not normally consume ten times the full VM disk size. However, disk usage continues to grow as more blocks change across the snapshot chain.

#### g) When is snapshotting an antipattern?

Snapshotting becomes an antipattern when long snapshot chains are kept for extended periods or treated as a replacement for proper backups and reproducible provisioning. Long chains consume increasing disk space, add dependencies between snapshot states, and can make management and recovery more complicated.

---

## Bonus — VM vs Container Resource Baseline

### Measurements

| Dimension | Vagrant VM | Docker container |
|---|---:|---:|
| Cold start | 18.790 s | 0.119 s |
| Idle RAM | 259 MiB used | 7.578 MiB |
| On-disk size | 3.6 GB | 1.32 GB |
| Process count (guest) | 99 | 2 |



### Comparison

The most surprising numbers were the cold-start time and idle memory usage: the Vagrant VM took 18.790 seconds to start and used 259 MiB of RAM, while the Docker container started in only 0.119 seconds and used 7.578 MiB. The process-count difference was also significant, with 99 processes in the VM compared with only 2 processes reported by `docker top` for the container. VMs are the better fit when a workload requires a complete independent operating system, stronger isolation, or OS-level configuration, while containers are well suited to lightweight, stateless application services. For stateless microservices, the measured container startup time, memory usage, and process count demonstrate the lower runtime overhead of the container model. These results help explain why containers became attractive during the 2014–2020 era for stateless microservices: they could start much faster and run with substantially fewer resources than a full VM.
