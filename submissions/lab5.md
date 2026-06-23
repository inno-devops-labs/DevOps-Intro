# Lab 5 Submission - Virtualization: QuickNotes in a Vagrant VM

---

## Task 1 - Vagrant Up + Run QuickNotes Inside

### 1.1 Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  # Vagrant base box for Ubuntu 22.04 LTS
  config.vm.box     = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"

  # Forward host port 18080 -> guest port 8080, bound to localhost only
  config.vm.network "forwarded_port",
    guest: 8080,
    host:  18080,
    host_ip: "127.0.0.1"

  # Sync the app/ directory into the VM
  config.vm.synced_folder "./app", "/home/vagrant/app"

  # VirtualBox resource caps (Lecture 5: don't over-provision)
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus   = 2
    vb.name   = "quicknotes-vm"
  end

  # Shell provisioner: install Go 1.24.4 on first vagrant up
  config.vm.provision "shell", inline: <<-SHELL
    set -e

    GO_VERSION="1.24.4"
    GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"

    if [ ! -f /usr/local/go/bin/go ]; then
      echo "==> Downloading Go ${GO_VERSION}..."
      curl -fsSL "https://go.dev/dl/${GO_TARBALL}" -o "/tmp/${GO_TARBALL}"

      echo "==> Installing Go to /usr/local..."
      rm -rf /usr/local/go
      tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
    else
      echo "==> Go already installed, skipping download..."
    fi

    echo "==> Adding Go to PATH for all users..."
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.env
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/vagrant/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
    chmod +x /etc/profile.d/go.env

    echo "==> Go installed: $(  /usr/local/go/bin/go version)"
    echo 'PATH=/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' > /etc/environment
  SHELL
end
```

### 1.2 vagrant up log (first 10 lines)

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'ubuntu/jammy64'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'ubuntu/jammy64' version '20241002.0.0' is up to date...
==> default: Setting the name of the VM: quicknotes-vm
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222

```

### 1.3 curl outputs from inside the VM

```text
vagrant@quicknotes-vm:~$ curl -s http://localhost:8080/health
{"notes":9,"status":"ok"}
```

### 1.4 curl outputs from the host (via port forward)

```text
$ curl -s http://localhost:18080/health | python3 -m json.tool
{
    "notes": 9,
    "status": "ok"
}

$ curl -s http://localhost:18080/notes | python3 -m json.tool
[
    {
        "id": 1,
        "title": "Welcome to QuickNotes",
        "body": "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.",
        "created_at": "2026-01-15T10:00:00Z"
    },
    {
        "id": 2,
        "title": "Read app/main.go first",
        "body": "Start by understanding the entry point \u2014 env vars, signal handling, graceful shutdown.",
        "created_at": "2026-01-15T10:05:00Z"
    },
    {
        "id": 9,
        "title": "trace me",
        "body": "in flight",
        "created_at": "2026-06-17T03:38:11.742124301Z"
    },
    {
        "id": 6,
        "title": "trace me",
        "body": "in flight",
        "created_at": "2026-06-15T09:11:16.618673131Z"
    },
    {
        "id": 8,
        "title": "trace me",
        "body": "in flight",
        "created_at": "2026-06-17T03:37:40.632009882Z"
    },
    {
        "id": 7,
        "title": "trace me",
        "body": "in flight",
        "created_at": "2026-06-15T09:12:36.564482119Z"
    },
    {
        "id": 3,
        "title": "DevOps mantra",
        "body": "If it hurts, do it more often.",
        "created_at": "2026-01-15T10:10:00Z"
    },
    {
        "id": 5,
        "title": "hello",
        "body": "first POST",
        "created_at": "2026-06-04T22:44:57.201845403Z"
    },
    {
        "id": 4,
        "title": "Endpoint cheat-sheet",
        "body": "GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics",
        "created_at": "2026-01-15T10:15:00Z"
    }
]

```

### 1.5 Design Questions

**a) Synced folders: which type and why?**
VirtualBox shared folders were used (the default). They are the simplest option requiring no extra software on the host or guest, and work well for small source directories like `app/`. The trade-off is performance, VirtualBox shared folders are slower than NFS or rsync for large file trees, because every file operation crosses the hypervisor boundary. For a small Go project like QuickNotes this is not noticeable.

**b) NAT vs Bridged vs Host-only: which mode?**
NAT (the Vagrant default) is used. With NAT, the VM gets a private IP and shares the host's network for outbound traffic. Port forwarding is bound to `127.0.0.1` (localhost only), meaning the QuickNotes port is only accessible from the host machine itself, not from other devices on the same LAN. A Bridged interface would give the VM a real LAN IP, making it accessible to anyone on the network, which is a security risk.

**c) Provisioning options: which method and why?**
The `shell` provisioner was used because it requires no additional tooling on the host, only bash. It is the simplest and most portable option for installing Go from a tarball. Ansible or Chef would be more appropriate for complex multi-step configurations, but for a single tool installation, shell is clear and readable.

**d) Why pin Go to a specific point release (`1.24.4`) instead of `1.24`?**
Pinning to `1.24.4` ensures every `vagrant up` installs the exact same binary. If we specified just `1.24`, a new patch release (e.g. `1.24.5`) could be downloaded next month with subtle behavioural differences, breaking reproducibility.

---

## Task 2 — Snapshots: Save, Break, Restore

### 2.1 Commands

```text
$ vagrant snapshot save clean-quicknotes
==> default: Snapshotting the machine as 'clean-quicknotes'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.

$ vagrant ssh -c 'sudo rm -rf /usr/local/go'
$ vagrant ssh -c '/usr/local/go/bin/go version'
bash: line 1: /usr/local/go/bin/go: No such file or directory

$ time vagrant snapshot restore clean-quicknotes
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'clean-quicknotes'...
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

real    0m26.571s
user    0m3.054s
sys 0m2.494s


$ vagrant ssh -c '/usr/local/go/bin/go version'
go version go1.24.4 linux/amd64

```

### 2.2 Restore time

```text
real    0m26.571s
user    0m3.054s
sys 0m2.494s
```

### 2.3 Design Questions

**e) Snapshots are not backups: why?**
A snapshot is stored on the same physical disk as the VM it protects. If the disk fails (hardware fault, accidental deletion, RAID failure), both the VM and all its snapshots are lost simultaneously. A backup, by contrast, lives on a separate medium or location. Snapshots also do not protect against logical corruption, if a bug corrupts data before the snapshot is taken, restoring the snapshot restores the corrupted state.

**f) Copy-on-write: what does it mean for disk usage with 10 snapshots?**
Copy-on-write means a snapshot does not copy the entire disk at creation time. Instead, it records only the blocks that change after the snapshot is taken. With 1 snapshot, disk overhead is small, only changed blocks are stored. With 10 snapshots, each layer stores its delta from the previous one, forming a chain. Disk usage grows with each snapshot proportional to how much data changed between them. Reading any block may require traversing the entire chain, degrading performance significantly.

**g) When is snapshotting an antipattern?**
Running a VM on a long chain of snapshots is an antipattern. Each read may require traversing multiple copy-on-write layers to find the original block, causing severe I/O performance degradation. Snapshots are meant to be transient, take one before a risky operation, restore or delete it after. Treating snapshots as a version history system leads to slow VMs and unpredictable disk growth.

---

## Bonus Task — VM vs Container Resource Baseline

### Comparison Table

| Dimension | Vagrant VM | Docker container |
|-----------|----------:|----------------:|
| Cold start | 40s | 0.27s |
| Idle RAM | 170 MiB | 6.5 MiB |
| On-disk size | 2.5 GB | 1.32 GB |
| Process count (guest) | 105 | 2 |

### Analysis

The most striking number is cold start time, 40 seconds for the VM vs 0.27 seconds for the container, a 148× difference. This is because the VM must boot an entire Linux kernel, initialize hardware emulation, and start dozens of system services before the application can run. The container reuses the host kernel and starts almost instantly.

RAM usage tells the same story: the VM consumes 170 MiB just for the OS overhead (systemd, sshd, udev, and 105 processes), while the container uses only 6.5 MiB for the application itself with 2 processes. For stateless microservices that need to scale horizontally, this density advantage explains why containers won the 2014-2020 era, you can run 25+ container instances in the RAM one VM would consume idle.

The VM's 2.5 GB disk footprint vs the container's 1.32 GB reflects the full OS installation vs just the Go toolchain image. The VM model is the right choice when strong hardware-level isolation is required (multi-tenant clouds, full OS customization) or when the workload needs its own kernel. Containers are the right tool for stateless, short-lived, high-density workloads like microservices and CI jobs.
