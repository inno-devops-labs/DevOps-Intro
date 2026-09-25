# Lab 5 submission

## Task 1

I used Vagrant with VirtualBox to run QuickNotes in a local Ubuntu VM.

The successful VM runs Ubuntu 22.04.5 LTS. The assignment allows Ubuntu 22.04 or 24.04 LTS. I used 22.04 because `bento/ubuntu-24.04` hit a VirtualBox CPU fault during boot on this host, with `VERR_CPUM_RAISE_GP_0` in the VirtualBox log.

The VM uses:

- Ubuntu 22.04.5 LTS
- Go 1.24.5
- 2 vCPUs
- 1024 MB RAM
- NAT networking
- host port `127.0.0.1:18080` forwarded to guest port `8080`
- VirtualBox shared folders
- shell provisioning

## Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.hostname = "quicknotes-lab5"
  config.vm.boot_timeout = 600
  config.ssh.insert_key = false

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1",
    auto_correct: false

  config.vm.synced_folder "./app",
    "/opt/quicknotes/app",
    type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"

    apt-get update
    apt-get install -y curl ca-certificates

    CURRENT=""
    if [ -x /usr/local/go/bin/go ]; then
      CURRENT=$(/usr/local/go/bin/go version | awk '{print $3}')
    fi

    if [ "$CURRENT" != "go${GO_VERSION}" ]; then
      rm -rf /usr/local/go
      curl -fL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm -f /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    install -d -m 0755 /var/lib/quicknotes

    cd /opt/quicknotes/app
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .

    printf '%s\n' \
      '[Unit]' \
      'Description=QuickNotes' \
      'After=network.target' \
      '' \
      '[Service]' \
      'Type=simple' \
      'WorkingDirectory=/opt/quicknotes/app' \
      'Environment=ADDR=:8080' \
      'Environment=DATA_PATH=/var/lib/quicknotes/notes.json' \
      'Environment=SEED_PATH=/opt/quicknotes/app/seed.json' \
      'ExecStart=/usr/local/bin/quicknotes' \
      'Restart=always' \
      'RestartSec=2' \
      '' \
      '[Install]' \
      'WantedBy=multi-user.target' \
      > /etc/systemd/system/quicknotes.service

    systemctl daemon-reload
    systemctl enable quicknotes
    systemctl restart quicknotes
  SHELL
end
```

## First 10 useful lines of `vagrant up --provider=virtualbox`

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'bento/ubuntu-22.04'...
Progress: 10%
Progress: 90%
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'bento/ubuntu-22.04' version '202510.26.0' is up to date...
==> default: Setting the name of the VM: quicknotes-lab5
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
```

## VM status

Command:

```text
vagrant status
```

Output:

```text
default                   running (virtualbox)
```

## Go version inside VM

Command:

```text
vagrant ssh -c "go version"
```

Output:

```text
go version go1.24.5 linux/amd64
```

## Resource check

VirtualBox reported:

```text
cpus=2
memory=1024
```

Inside the VM:

```text
2
Mem:             957         210         229           0         517         584
```

## QuickNotes health inside VM

Command:

```text
vagrant ssh -c "curl -s http://127.0.0.1:8080/health"
```

Output:

```json
{"notes":4,"status":"ok"}
```

## QuickNotes health from Windows host

Command:

```text
curl.exe -s http://127.0.0.1:18080/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

## Design questions

### a) Synced folders

I used VirtualBox shared folders. They are simple with the VirtualBox provider and make the host `app` directory appear inside the VM at `/opt/quicknotes/app`. The trade-off is that shared folders can be slower than a native Linux filesystem for workloads with many small files.

### b) NAT vs Bridged vs Host-only

The VM uses NAT, which is Vagrant's default network mode. The QuickNotes port is forwarded only to `127.0.0.1` on the host. That is safer for this course exercise than a bridged interface because other machines on the physical network cannot connect to the guest service directly.

### c) Provisioning

I used shell provisioning. It is enough for installing one pinned Go version, building the app, and writing one systemd service. A larger tool would add extra complexity for this lab.

### d) Go pinning

Pinning Go to `1.24.5` makes the VM reproducible. A floating `1.24` value could install a different point release later and change compiler or tool behavior without a repository change.

## Task 2

Before saving the snapshot, I checked that the VM was healthy.

```text
go version go1.24.5 linux/amd64
{"notes":4,"status":"ok"}
{"notes":4,"status":"ok"}
```

I halted the VM before taking the snapshot. VirtualBox reported:

```text
VMState="poweroff"
```

## Snapshot save

Command:

```text
vagrant snapshot save clean-lab5
```

Output:

```text
==> default: Snapshotting the machine as 'clean-lab5'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```

Snapshot list:

```text
==> default:
clean-lab5
```

After saving the snapshot, I started the VM with:

```text
vagrant up --no-provision
```

Go and QuickNotes still worked:

```text
go version go1.24.5 linux/amd64
{"notes":4,"status":"ok"}
{"notes":4,"status":"ok"}
```

## Break

Commands:

```text
vagrant ssh -c "sudo rm -f /usr/local/bin/go /usr/local/bin/gofmt"
vagrant ssh -c "sudo mv /usr/local/go /usr/local/go.broken"
```

Verification command:

```text
vagrant ssh -c "if go version; then echo UNEXPECTED_GO_FOUND; else echo EXPECTED_FAILURE_GO_NOT_FOUND; fi"
```

Output:

```text
bash: line 1: go: command not found
EXPECTED_FAILURE_GO_NOT_FOUND
```

## Restore

I halted the broken VM first. VirtualBox reported:

```text
VMState="poweroff"
```

Restore command:

```text
vagrant snapshot restore clean-lab5 --no-provision
```

Restore time:

```text
48.32 seconds
```

Vagrant restored the snapshot and started the VM without provisioning:

```text
==> default: Machine not provisioned because `--no-provision` is specified.
```

## Verify recovery

Go version after restore:

```text
go version go1.24.5 linux/amd64
```

QuickNotes service state after restore:

```text
active
```

Health check inside the VM after restore:

```json
{"notes":4,"status":"ok"}
```

Health check from Windows after restore:

```json
{"notes":4,"status":"ok"}
```

## Design questions

### e) Why snapshots are not backups

Snapshots depend on the original VM storage. If the host disk, VM directory, or VirtualBox files are lost or corrupted, the snapshot can be lost too. A real backup must exist independently from the VM it protects.

### f) Copy-on-write

VirtualBox snapshots store changed disk blocks instead of copying the whole disk every time. Ten snapshots do not immediately mean ten full disk copies. The changed blocks still accumulate, so long snapshot chains can use a lot of space.

### g) Snapshot antipattern

Long snapshot chains are harder to manage, slower to work with, and more fragile. Snapshots are good short-term rollback points for experiments. They should not replace reproducible provisioning or independent backups.

## Bonus

Not attempted.
