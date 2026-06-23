# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Objective

Write a `Vagrantfile` that boots an Ubuntu 24.04 LTS VM, installs Go 1.24,
builds and runs QuickNotes inside the VM, and exposes it to the host via port
forwarding. Then demonstrate the snapshot save/break/restore lifecycle.

## Environment

| Component  | Version / value           |
|------------|---------------------------|
| Host OS    | Windows 10                |
| Vagrant    | 2.4.9                     |
| VirtualBox | 7.1.x (provider)          |
| Guest box  | `bento/ubuntu-24.04`      |
| Go (guest) | 1.24.5                    |
| App        | QuickNotes (`./app`)      |

> Note: The `Vagrantfile` was validated with `vagrant validate`
> (`Vagrantfile validated successfully.`). The command outputs marked
> **TODO** below must be filled in by running the listed commands on a host
> with VirtualBox installed, because the machine used to author this report
> did not have the VirtualBox provider available.

## Implementation summary

The `Vagrantfile` at the repo root:

1. Uses the `bento/ubuntu-24.04` box (Ubuntu 24.04 LTS) because it ships
   VirtualBox Guest Additions, which the default `virtualbox` synced-folder
   type needs.
2. Sets the hostname to `quicknotes-vm`.
3. Forwards host `127.0.0.1:18080` → guest `8080` (loopback-only, not exposed
   on the LAN).
4. Syncs `./app` into the guest at `/opt/quicknotes/app`.
5. Caps the VM at **2 vCPU** and **1024 MB RAM**.
6. Provisions with a shell script that installs the pinned Go `1.24.5`, builds
   QuickNotes from the synced source, and runs it as a `systemd` service
   (`quicknotes.service`) on port `8080`. The script is idempotent, so
   `vagrant up --provision` is safe to repeat.

Running QuickNotes as a `systemd` unit (rather than a backgrounded shell
command) means the app comes up automatically on `vagrant up` and after a
reboot, so the host `curl` check works against a clean clone with no manual
SSH step.

## The Vagrantfile

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Lab 5 — QuickNotes in a Vagrant VM.
# Boots an Ubuntu 24.04 LTS VM, installs Go 1.24.x, builds QuickNotes from the
# synced ./app folder, and runs it as a systemd service on guest port 8080.
# The host reaches it on http://127.0.0.1:18080.

GO_VERSION = "1.24.5"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"
  config.vm.synced_folder "./app", "/opt/quicknotes/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.memory = 1024
    vb.cpus   = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    #!/usr/bin/env bash
    set -euo pipefail

    GO_VERSION="#{GO_VERSION}"
    GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y curl

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
      echo "Installing Go ${GO_VERSION}..."
      curl -fsSL "https://go.dev/dl/${GO_TARBALL}" -o "/tmp/${GO_TARBALL}"
      rm -rf /usr/local/go
      tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
    fi

    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh

    install -d /var/lib/quicknotes
    /usr/local/go/bin/go build -C /opt/quicknotes/app -o /usr/local/bin/quicknotes .

    cat > /etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/opt/quicknotes/app/seed.json
WorkingDirectory=/var/lib/quicknotes
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable quicknotes
    systemctl restart quicknotes
  SHELL
end
```

## How to run

```bash
vagrant up                 # boot + provision (downloads box on first run)
vagrant ssh -c 'go version'                       # expect: go1.24.5
vagrant ssh -c 'systemctl is-active quicknotes'   # expect: active
curl -s http://localhost:18080/health             # from the host
```

## Task 1 — Verification

### First 10 lines of `vagrant up`

```text
TODO: paste the first 10 lines of `vagrant up` output here
(box download / boot / provisioning start).
```

### `go version` inside the VM

```text
$ vagrant ssh -c 'go version'
TODO: paste output here (expected: go version go1.24.5 linux/amd64)
```

### `curl /health` from inside the VM

```text
$ vagrant ssh -c 'curl -s http://localhost:8080/health'
TODO: paste output here (expected: {"notes":4,"status":"ok"})
```

### `curl /health` from the host (via port forward)

```text
$ curl -i http://localhost:18080/health
TODO: paste output here (expected: HTTP/1.1 200 OK and {"notes":4,"status":"ok"})
```

### Design questions

**a) Synced folder type.** I use the default **`virtualbox`** shared-folder
type. I picked it because the `bento/ubuntu-24.04` box ships Guest Additions,
so it works out of the box with no extra host tooling. The trade-off:
VirtualBox shared folders have slower I/O than NFS and weaker file-event
support than `rsync`, but for a small Go project that is built once during
provisioning the performance difference is irrelevant, and unlike `rsync` it
does not require `rsync` installed on a Windows host.

**b) Network mode.** The default is **NAT** with port forwarding. NAT gives the
guest outbound internet (needed to download the Go tarball) while keeping it
off the LAN. Binding the forwarded port to `127.0.0.1` is safer than a Bridged
interface because the app is only reachable from the host loopback — nobody
else on the network (e.g. a shared campus Wi-Fi) can hit an unhardened course
app. A Bridged interface would put the VM directly on the LAN with its own IP.

**c) Provisioning option.** I use the **`shell`** provisioner. For a single,
well-understood task (download Go, build one binary, install one service) a
shell script is the simplest, most readable choice and needs no extra tooling
on the host. Ansible/Puppet/Chef would be over-engineering here; Lab 7 will
introduce Ansible against this same VM, which is the right place for it.

**d) Why pin `1.24.5` instead of `1.24`.** Pinning the exact point release makes
the build **reproducible**: every student (and CI) gets byte-for-byte the same
toolchain, so "works on my machine" bugs caused by a newer patch release are
eliminated. `1.24` is a moving target that silently advances as new patches
ship.

## Task 2 — Snapshot lifecycle

Commands run (save → break → verify broken → restore → verify recovered):

```bash
# 1. Snapshot the working VM
vagrant snapshot save clean-quicknotes

# 2. Break it deliberately — wipe the Go install
vagrant ssh -c 'sudo rm -rf /usr/local/go'

# 3. Verify it is broken
vagrant ssh -c '/usr/local/go/bin/go version'   # expect: command/file not found

# 4. Restore from the snapshot (timed)
time vagrant snapshot restore clean-quicknotes

# 5. Verify recovery
vagrant ssh -c 'go version'                      # expect: go1.24.5 again
```

### Restore time output

```text
TODO: paste the `time vagrant snapshot restore clean-quicknotes` output here.
```

### Design questions

**e) Snapshots are not backups.** A snapshot lives on the **same physical
disk** as the VM, so it shares the VM's failure domain: a dead host disk,
deleted VM directory, or a stolen/destroyed laptop takes the snapshot with it.
It also does not protect against logical corruption that predates the snapshot.
Real backups are stored off the machine.

**f) Copy-on-write disk usage.** VirtualBox snapshots are copy-on-write, so a
snapshot does not duplicate the base disk — it only stores the **blocks that
change** after the snapshot is taken. Ten snapshots therefore cost roughly the
sum of the deltas between them, not ten full disk copies; if little changes,
ten snapshots can be much smaller than one full clone.

**g) When snapshotting is an antipattern.** Long snapshot chains: every disk
read has to walk the chain of deltas, which degrades performance, and the chain
grows fragile and large over time. Snapshots should be used transiently — take,
restore, then **delete** — not as a permanent layered history or a substitute
for proper image rebuilds.

## Bonus — VM vs container resource baseline

> TODO: collect these numbers on the same hardware in one session. The Docker
> baseline uses:
> `docker run -d -p 28080:8080 -v "$PWD/app:/src" -w /src golang:1.24 sh -c 'go build -o /tmp/qn && /tmp/qn'`

| Dimension              | Vagrant VM | Docker container |
|------------------------|-----------:|-----------------:|
| Cold start             |       TODO |             TODO |
| Idle RAM               |       TODO |             TODO |
| On-disk size           |       TODO |             TODO |
| Process count (guest)  |       TODO |             TODO |

Trade-off analysis (write 4–5 sentences after collecting the numbers): TODO.

## Notes

- `.vagrant/` is git-ignored (already in the repo `.gitignore`); only the
  `Vagrantfile` and this report are committed.
- This lab feeds Lab 7: the Ansible playbook there will target this VM.
