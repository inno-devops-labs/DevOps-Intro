# Task 1 — Vagrant Up + Run QuickNotes Inside

## Vagrantfile

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"
  config.vm.boot_timeout = 600

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/opt/quicknotes"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"

    apt-get update
    apt-get install -y curl ca-certificates build-essential

    if ! /usr/local/go/bin/go version | grep "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi

    cat >/etc/profile.d/go.sh <<'EOF'
export PATH=/usr/local/go/bin:$PATH
EOF

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
  SHELL
end
```

## First `vagrant up` output

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'bento/ubuntu-24.04'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'bento/ubuntu-24.04' version '202510.26.0' is up to date...
==> default: Setting the name of the VM: quicknotes-lab5
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
```

## Curl verification

### Inside the VM

Command:

```bash
vagrant ssh -c "curl -s http://127.0.0.1:8080/health"
```

Output:

```json
{"notes":7,"status":"ok"}
```

### From the host via port forwarding

Command:

```bash
curl -s http://127.0.0.1:18080/health
```

Output:

```json
{"notes":7,"status":"ok"}
```

## Design questions

### a) Synced folders: which did you pick and why? What is the trade-off?

I used the default VirtualBox synced folder to mount the host `./app` directory into the guest at `/opt/quicknotes`. I picked it because it is simple, works automatically with the VirtualBox provider, and does not require a separate file sync command after every edit. The trade-off is that VirtualBox shared folders can be slower than native disk or rsync for large projects, but for this small QuickNotes app the simplicity is more valuable.

### b) NAT vs Bridged vs Host-only: which network mode are you using? Why is `127.0.0.1`-bound port forwarding safer than Bridged?

This VM uses Vagrant's default NAT networking with an explicit forwarded port from host `127.0.0.1:18080` to guest `8080`. NAT keeps the VM behind the host instead of placing it directly on the local network like a bridged adapter would. Binding the forwarded port to `127.0.0.1` is safer for a course exercise because only the local host can reach QuickNotes; other machines on the same Wi-Fi or LAN cannot connect to it.

### c) Provisioning options: which did you pick for installing Go and why?

I used the Vagrant shell provisioner to install Go. Shell provisioning is enough here because the setup is small: update packages, install basic tools, download the Go tarball, extract it to `/usr/local`, and add it to `PATH`. It is simple, readable, and reproducible for another student running `vagrant up` from a clean clone.

### d) Why pin Go to a specific point release like `1.24.5` instead of `1.24`?

Pinning Go to `1.24.5` makes the VM reproducible because every run installs the same toolchain version. If I only specify `1.24`, the actual patch version could change later, and a future patch release might change behavior, compiler output, warnings, or dependency compatibility. A specific point release makes debugging easier because the environment is stable.

# Task 2 — Snapshots: Save, Break, Restore

## Snapshot save

Command:

```bash
vagrant ssh -c "go version"
vagrant snapshot save quicknotes-clean
vagrant snapshot list
```

Output:

```text
go version go1.24.5 linux/amd64

==> default: Snapshotting the machine as 'quicknotes-clean'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
==> default:
quicknotes-clean
```

## Break the VM

Command:

```bash
vagrant ssh -c "sudo mv /usr/local/go /usr/local/go.broken"
vagrant ssh -c "go version"
```

Output:

```text
bash: line 1: go: command not found
```

## Restore snapshot

Command:

```bash
time vagrant snapshot restore quicknotes-clean
```

Output:

```text
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'quicknotes-clean'...
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

real    0m30.557s
user    0m0.046s
sys     0m0.075s

```

## Verify recovery

Command:

```bash
vagrant ssh -c "go version"
```

Output:

```text
go version go1.24.5 linux/amd64
```

## Design questions

### e) Snapshots are not backups. Why?

Snapshots are not backups because they usually depend on the original VM disk and local host storage. If the laptop disk is corrupted, the VM directory is deleted, or the VirtualBox VM is lost, the snapshot can be lost with it. A real backup should be stored separately and should survive host or disk failure.

### f) Copy-on-write: what does that mean for disk usage when you take 10 snapshots vs 1?

Copy-on-write means the snapshot does not immediately copy the entire VM disk. Instead, VirtualBox keeps the original disk state and stores only the blocks that change after the snapshot. This makes one snapshot cheap at first, but long chains of 10 snapshots can still consume a lot of disk over time as more blocks change.

### g) When is snapshotting an antipattern?

Snapshotting is an antipattern when snapshots become a replacement for reproducible provisioning or real backups. Long snapshot chains can make VMs harder to manage, slower, and more fragile. For infrastructure, it is usually better to rebuild from code using tools like Vagrant, shell provisioning, or Ansible instead of depending on many manual VM snapshots.

# Bonus — VM vs Docker Container Resource Baseline

## Comparison table

| Dimension             |    Vagrant VM |                         Docker container |
| --------------------- | ------------: | ---------------------------------------: |
| Cold start            |      1m38.33s |                                   0.568s |
| Idle RAM              | 299Mi / 961Mi |                                 7.188MiB |
| On-disk size          |          1.8G | 120B container size, 1.09GB virtual size |
| Process count (guest) |           158 |                                        2 |

## Questions

The most surprising result was the cold start difference: the Docker container started in less than one second, while the VM needed more than one minute. Vagrant is the better tool when I need a full Linux machine, stronger isolation, OS-level configuration, provisioning, and realistic system/network testing. Docker is the better tool for lightweight application workloads, fast local development, and stateless services that need to start and stop quickly. The data shows why containers became dominant for stateless microservices in the 2014–2020 era: they use much less memory, start much faster, and run only the application process instead of a full guest operating system. For QuickNotes, Docker was more efficient, while Vagrant was more useful for reproducing a complete machine environment.
