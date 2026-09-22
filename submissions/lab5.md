# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Environment
- Host: macOS on Apple Silicon (`arm64`)
- Vagrant: 2.4.9
- VirtualBox: 7.2.20
- Guest: Ubuntu 24.04 LTS (`bento/ubuntu-24.04`, arm64)
- Go in guest: 1.24.5 linux/arm64

> The lab prerequisite lists VirtualBox 7.1.x. The installed host version was 7.2.20 and the required VM workflow completed successfully.

## Task 1 — Vagrant Up + QuickNotes

### Vagrantfile
The `Vagrantfile` is stored at the repository root.

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes"
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"
  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
  end
  config.vm.provision "shell", inline: <<-SHELL
    set -e
    GO_VERSION="1.24.5"

    ARCH="$(dpkg --print-architecture)"

    case "$ARCH" in
      arm64) GO_ARCH="arm64" ;;
      amd64) GO_ARCH="amd64" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      apt-get update
      apt-get install -y curl
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi
    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    go version
  SHELL
end
```

### First `vagrant up` output
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

The first provisioning attempt had no guest network access while a host VPN was enabled. After disabling the VPN, provisioning was rerun successfully with `vagrant provision`.

```text
go version go1.24.5 linux/arm64
```

### QuickNotes verification
Inside the VM:
```text
2026/09/22 19:41:21 quicknotes listening on :8080 (notes loaded: 6)
```

Guest health check:
```bash
vagrant ssh -c 'curl -s http://localhost:8080/health'
```
```json
{"notes":6,"status":"ok"}
```

Host health check:
```bash
curl -v http://localhost:18080/health
```
```text
* Established connection to localhost (127.0.0.1 port 18080)
< HTTP/1.1 200 OK
{"notes":6,"status":"ok"}
```

### Design questions
**a) Synced folders.** I used `rsync` to copy `./app` to `/home/vagrant/app`. It is simple and avoids depending on VirtualBox shared-folder support. The trade-off is that it is not continuously bidirectional: host changes may require `vagrant rsync`, and guest changes are not automatically synchronized back.

**b) NAT vs Bridged vs Host-only.** The VM uses default NAT with explicit port forwarding. Binding the forwarded port to `127.0.0.1` exposes QuickNotes only to the local host, unlike a bridged interface that could expose the VM to other machines on the surrounding network.

**c) Provisioning.** I used the `shell` provisioner because installing one pinned Go toolchain requires only a small set of Ubuntu shell commands. It keeps setup automatic and reproducible without adding a larger configuration-management tool.

**d) Pinning Go.** Pinning `1.24.5` makes provisioning deterministic. A floating version can change over time, while a point release gives different users and runs the same toolchain.

## Task 2 — Snapshot: Save, Break, Restore

### Save
```bash
vagrant snapshot save quicknotes-working
vagrant snapshot list
```
```text
==> default: Snapshotting the machine as 'quicknotes-working'...
==> default: Snapshot saved!
quicknotes-working
```

### Break and verify
```bash
vagrant ssh -c 'sudo rm -rf /usr/local/go'
vagrant ssh -c '/usr/local/go/bin/go version'
```
```text
bash: line 1: /usr/local/go/bin/go: No such file or directory
```

### Restore and verify
```bash
time vagrant snapshot restore quicknotes-working
```
```text
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'quicknotes-working'...
==> default: Checking if box 'bento/ubuntu-24.04' version '202510.26.0' is up to date...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
==> default: Machine booted and ready!
vagrant snapshot restore quicknotes-working  1,67s user 1,24s system 19% cpu 14,682 total
```

Restore time: **14.682 seconds**.

```bash
vagrant ssh -c 'go version'
```
```text
go version go1.24.5 linux/arm64
```

### Design questions
**e) Snapshots are not backups.** A snapshot depends on the original VM storage and host. If the VM files, host disk, or snapshot chain are lost or corrupted, the snapshot can be lost too. A backup should be stored independently from the original system.

**f) Copy-on-write.** A snapshot initially references unchanged virtual-disk blocks instead of copying the entire disk. Modified blocks are written separately, so ten snapshots are not ten complete disk copies, but their storage grows as more blocks change across the chain.

**g) Snapshot antipattern.** Long-lived snapshot chains are a poor substitute for reproducible infrastructure or backups. They accumulate storage and state and make maintenance and recovery more complicated; disposable environments are usually better rebuilt from version-controlled configuration.