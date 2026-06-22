# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
                    guest: 8080, host: 18080,
                    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app",
                          type: "virtualbox",
                          owner: "vagrant", group: "vagrant"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.memory = 1024
    vb.cpus   = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    GO_VERSION="1.24.5"

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      echo ">>> Installing Go ${GO_VERSION}"
      apt-get update -y
      apt-get install -y curl ca-certificates
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
        -o /tmp/go.tgz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
      rm /tmp/go.tgz
      echo 'export PATH=$PATH:/usr/local/go/bin:/home/vagrant/go/bin' \
        > /etc/profile.d/go.sh
    else
      echo ">>> Go ${GO_VERSION} already installed, skipping"
    fi
  SHELL
end
```

### vagrant up output (first 10 lines)

```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'ubuntu/jammy64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'ubuntu/jammy64'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/ubuntu/jammy64
==> default: Adding box 'ubuntu/jammy64' (v20241002.0.0) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/ubuntu/boxes/jammy64/versions/20241002.0.0/providers/virtualbox/unknown/vagrant.box
    default:
==> default: Successfully added box 'ubuntu/jammy64' (v20241002.0.0) for 'virtualbox'!
```

### Verification

**Inside VM:**
```bash
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64
```

**From host (via port forward):**
```bash
$ curl -s http://localhost:18080/health
{"notes":10,"status":"ok"}
```

### Design Questions

**a) Synced folders: Vagrant supports `nfs`, `rsync`, `virtualbox`, and `smb` mount types. Which did you pick and why? What's the trade-off?**

I chose `virtualbox` synced folder type because it works out-of-the-box on Windows without requiring additional software installation.
The trade-off is that VirtualBox shared folders are slower than NFS for large file operations and have issues with file watching (inotify), but for a small project like QuickNotes with a few source files, this performance difference is negligible.
The `virtualbox` type also supports proper ownership settings via `owner` and `group` parameters, which ensures the vagrant user can write to the synced directory.

**b) NAT vs Bridged vs Host-only: which network mode are you using (it's the default, but say which it is)? Why is `127.0.0.1`-bound port forwarding safer than a Bridged interface for a course exercise?**

I'm using NAT (the default Vagrant mode) with port forwarding bound to `127.0.0.1:18080`.
This is safer than Bridged because the service is only accessible from the host machine itself — no one else on the local network can reach it.
In a Bridged setup, the VM would get an IP on the same LAN as the host, making QuickNotes accessible to anyone on the network, which is unnecessary here and could expose the service to unintended access or attacks.
NAT with localhost binding follows the principle of least privilege: the service is only as accessible as it needs to be.

**c) Provisioning options: Vagrant supports `shell`, `ansible`, `ansible_local`, `puppet`, `chef`, … which did you pick for installing Go and why?**

I chose `shell` provisioning because it's the simplest option for a single-task installation (downloading and extracting a tarball).
Ansible/Puppet would be overkill for this lab and would require additional tools on the host machine.
Shell scripts are idempotent when written correctly (checking if Go is already installed before downloading), which means running `vagrant provision` multiple times won't break anything.
The shell provisioner is also the most transparent — anyone reading the Vagrantfile can immediately see what commands are being executed without needing to understand a configuration management framework.

**d) Why pin Go to a specific point release (`1.24.5`) instead of `1.24`?**

Pinning to `1.24.5` ensures reproducibility — if I used `1.24`, the provisioner might install `1.24.6` tomorrow or `1.24.7` next month, potentially introducing different behavior, bugs, or breaking changes. 
By pinning the exact version, any student running `vagrant up` will get the same Go version, making the environment deterministic and debuggable. 
It makes it easier to reproduce bugs and verify that solutions work across different machines.

---

## Task 2 — Snapshots: Save, Break, Restore

### Commands executed

```bash
# 1. Take snapshot
$ vagrant snapshot save clean-quicknotes
==> default: Snapshotting the machine as 'clean-quicknotes'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.

# 2. Verify snapshot exists
$ vagrant snapshot list
==> default:
clean-quicknotes

# 3. Break the VM
$ vagrant ssh
vagrant@quicknotes-vm:~$ sudo rm -rf /usr/local/go
vagrant@quicknotes-vm:~$ go version
Command 'go' not found, but can be installed with:
apt install golang-go  # version 2:1.18~0ubuntu2, or
apt install gccgo-go   # version 2:1.18~0ubuntu2
Ask your administrator to install one of them.

# 4. Restore with timing
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

real    0m19.060s
user    0m0.000s
sys     0m0.000s

# 5. Verify recovery
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64
```

### Design Questions

**e) Snapshots are not backups. Explain why in 2-3 sentences — what failure modes is a snapshot useless for?**

Snapshots are stored on the same physical disk as the VM, so if the disk fails, is corrupted, or files are accidentally deleted, both the VM and all snapshots are lost together.
They also don't protect against logical errors like committing secrets to Git, corrupting application data, or introducing bugs — snapshots capture the exact state at a moment in time, including any mistakes.
Additionally, snapshots are tied to the specific hypervisor and disk format, making them non-portable across different virtualization platforms.

**f) Copy-on-write: Vagrant snapshots are copy-on-write under VirtualBox. What does that mean for disk usage when you take 10 snapshots vs 1?**

Copy-on-write means snapshots don't duplicate the entire disk — they only store the blocks that changed since the snapshot was taken.
Taking 10 snapshots doesn't require 10× the disk space. Instead, each snapshot adds only the changed blocks (delta - difference between blocks).
However, a long chain of snapshots can slow down disk reads because VirtualBox must traverse the entire chain to reconstruct the current state.
For example, if you take snapshot A, then modify 100 MB of data, then take snapshot B, snapshot B only stores those 100 MB of changes. 
But when reading data, VirtualBox must check the current state, then snapshot B, then snapshot A, then the base disk — this chain traversal adds overhead.

**g) When is snapshotting an antipattern? (Hint: long chains.)**

Snapshotting becomes an antipattern when used as a substitute for proper backups or when accumulating dozens of snapshots over time without cleanup.
Long snapshot chains (20+ snapshots) degrade performance because every disk read must traverse the entire chain, and the accumulated delta files can consume significant disk space.
The correct pattern is: snapshot -> experiment -> restore OR delete. 
Snapshots should be transient — used for short-term experiments or pre-deployment safety nets, then deleted once they're no longer needed.
For persistent state preservation or disaster recovery, use actual backups (`vagrant package` or copying `.vdi` files to external storage).

---

## Bonus Task — VM vs Container Resource Baseline

### B.1 & B.2: Measurements

| Dimension | Vagrant VM | Docker container |
|---|---|---|
| Cold start | 28.2 s | 0.17 s |
| Idle RAM | 181 MB | 8.4 MB |
| On-disk size | 2.9 GB | 1.32 GB |
| Process count (guest) | 105 | 2 |

*(Note: the Docker image size is large (~1.32 GB) because the official `golang:1.24` image includes the entire Go toolchain and a full Debian filesystem. If i used `alpine` the size will be reduced to ~50-100 MB).*

### B.3: Analysis

The biggest difference is the cold start time: the VM takes ~28 seconds to boot a full guest OS kernel and systemd, while the container starts in ~0.17 seconds — a 160× speedup.
The RAM usage is equally dramatic: the VM consumes 181 MB for idle system services (sshd, systemd, agetty), while the container uses only 8.4 MB for the application process itself. 
The VM also runs 105 background processes, whereas the container runs exactly 2 processes (the shell wrapper and the Go binary). 
For stateless microservices like QuickNotes, containers are the clear winner because they allow packing 10-20× more instances on the same hardware with near-instant scaling and minimal resource overhead.
However, VMs remain the right tool for multi-tenant environments requiring strict hardware-level isolation, or when running different OS kernels (e.g., Windows on a Linux host). 
Ultimately, containers won the 2014-2020 microservice era because they shifted the isolation boundary from the OS level to the process level, optimizing for density and speed over total isolation.