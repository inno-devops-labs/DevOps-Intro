# Lab 5 Submission — Virtualization

## Task 1 — Vagrant Up + QuickNotes

### Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./app", "/opt/quicknotes", type: "rsync"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e

    GO_VERSION="1.24.5"

    apt-get update
    apt-get install -y curl ca-certificates

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSLo /tmp/go.tar.gz \
        "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go

    cd /opt/quicknotes
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes

    cat > /etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes
After=network.target

[Service]
ExecStart=/usr/local/bin/quicknotes
Environment=ADDR=:8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now quicknotes
  SHELL
end
```

The VM uses Ubuntu 22.04 LTS, 2 vCPUs, 1024 MB RAM, NAT networking, and forwards `127.0.0.1:18080` to guest port `8080`.

### First 10 lines of `vagrant up`

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'ubuntu/jammy64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'ubuntu/jammy64'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/ubuntu/jammy64
==> default: Adding box 'ubuntu/jammy64' (v20241002.0.0) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/ubuntu/boxes/jammy64/versions/20241002.0.0/providers/virtualbox/unknown/vagrant.box
==> default: Box download is resuming from prior download progress
==> default: Successfully added box 'ubuntu/jammy64' (v20241002.0.0) for 'virtualbox'!
```

### Verification

```text
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64
```

Inside the VM:

```text
$ vagrant ssh -c 'curl -s http://localhost:8080/health'
{"notes":0,"status":"ok"}
```

From the host through port forwarding:

```text
$ curl -s http://localhost:18080/health
{"notes":0,"status":"ok"}
```

### Design questions

#### a) Synced folders

I used `rsync`. It is simple and does not depend on matching VirtualBox Guest Additions. The trade-off is that changes must be synchronized instead of appearing automatically as with a continuously mounted shared folder.

#### b) NAT vs Bridged vs Host-only

I used Vagrant's default NAT networking with port forwarding. Binding the forwarded port to `127.0.0.1` means QuickNotes is reachable only from the host. A bridged VM would appear directly on the LAN and could be reachable by other machines.

#### c) Provisioning

I used the shell provisioner because the setup is small: install Go, build QuickNotes, create the systemd service, and start it. A larger configuration-management tool would add unnecessary complexity here.

#### d) Why pin Go to 1.24.5?

Pinning an exact point release makes provisioning reproducible. Using only `1.24` could result in different patch versions being installed at different times.

---

## Task 2 — Snapshot, Break, Restore

### Save snapshot

```text
$ vagrant snapshot save clean-quicknotes
==> default: Snapshotting the machine as 'clean-quicknotes'...
==> default: Snapshot saved!
```

```text
$ vagrant snapshot list
==> default:
clean-quicknotes
```

### Break the VM

I deliberately removed the Go installation:

```bash
vagrant ssh -c 'sudo rm -rf /usr/local/go'
```

Verification:

```text
$ vagrant ssh -c 'go version'
bash: line 1: go: command not found
```

### Restore snapshot

```text
$ time vagrant snapshot restore clean-quicknotes

==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'clean-quicknotes'...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Machine booted and ready!

real    0m14.651s
user    0m1.830s
sys     0m1.503s
```

### Verify recovery

```text
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64
```

```text
$ vagrant ssh -c 'curl -s http://localhost:8080/health'
{"notes":0,"status":"ok"}
```

```text
$ curl -s http://localhost:18080/health
{"notes":0,"status":"ok"}
```

The snapshot successfully restored the deleted Go installation and returned the VM to a working state.

### Design questions

#### e) Why are snapshots not backups?

Snapshots usually remain on the same storage as the VM. If that storage fails or the VM files are lost, the snapshots can be lost as well.

#### f) Copy-on-write

A snapshot does not immediately duplicate the whole virtual disk. The existing disk state is preserved and only changed blocks are stored afterward. Multiple snapshots therefore consume space mainly as changes accumulate rather than each requiring a full disk copy.

#### g) When is snapshotting an antipattern?

Long snapshot chains are an antipattern because they consume increasing disk space and create a more complex dependency chain. Snapshots should normally be temporary: create, use or restore, then delete them.
