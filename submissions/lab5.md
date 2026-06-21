# Lab 5 — Virtualization

The `Vagrantfile` lives at the repo root. It boots Ubuntu 24.04, installs Go 1.24.5,
mounts `./app` into the guest, and forwards host `127.0.0.1:18080` to guest `8080`.

## Task 1 — Vagrant up + run QuickNotes inside

### Vagrantfile

```ruby
GO_VERSION = "1.24.5"

Vagrant.configure("2") do |config|
  config.vm.box      = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"
  config.vm.boot_timeout = 600

  config.vm.network "forwarded_port",
    guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/opt/quicknotes"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-lab5"
    vb.cpus   = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    apt-get update
    apt-get install -y curl ca-certificates
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go#{GO_VERSION}"; then
      curl -fsSL "https://go.dev/dl/go#{GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    chmod +x /etc/profile.d/go.sh
    ln -sf /usr/local/go/bin/go /usr/local/bin/go
  SHELL
end
```

### First lines of `vagrant up`

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'bento/ubuntu-24.04'...
==> default: Matching MAC address for NAT networking...
==> default: Setting the name of the VM: quicknotes-lab5
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
    default: 22 (guest) => 2222 (host) (adapter 1)
```

### Build and run QuickNotes inside, then check it

Inside the VM:

```bash
vagrant ssh -c 'go version'
# go version go1.24.5 linux/amd64

vagrant ssh -c 'cd /opt/quicknotes && go build -o /tmp/qn . && nohup /tmp/qn >/tmp/qn.log 2>&1 &'
vagrant ssh -c 'curl -s http://127.0.0.1:8080/health'
# {"notes":4,"status":"ok"}
```

From the host through the port forward:

```bash
curl -s http://127.0.0.1:18080/health
# {"notes":4,"status":"ok"}
```

Same response from inside the guest and from the host, so the forward works.

### Design questions

**a) Which synced-folder type, and the trade-off?**
I used the default VirtualBox shared folder to mount `./app` at `/opt/quicknotes`. It's the
simplest option — it's two-way and mounts automatically, no extra service or manual sync step.
The downside is that VirtualBox shared folders are slower than the native disk (and slower than
rsync) when there are lots of files or heavy build I/O, and they depend on guest additions in the
box. For an app this small that doesn't matter. (rsync is the other reasonable pick — faster
build I/O, but it's one-way host→guest, so edits made inside the VM don't flow back.)

**b) Which network mode, and why is a 127.0.0.1 forward safer than bridged?**
NAT — Vagrant's default. The VM sits behind the host and I expose only what I forward. Binding the
forward to `127.0.0.1` means just the host can reach `:18080`; a bridged adapter would give the VM
its own address on the LAN, so anyone on the same network could hit QuickNotes — which has no auth.
For a course exercise that's the difference between "only me" and "the whole Wi-Fi."

**c) Which provisioner, and why?**
Shell. Installing Go is a short linear script: apt update, download one tarball, unpack to
`/usr/local`, set PATH. Reaching for Ansible/Puppet/Chef here would add a dependency and ceremony
for something a few lines of bash do clearly.

**d) Why pin Go to 1.24.5 instead of 1.24?**
`go.dev/dl` only serves exact versions — there's no moving `1.24` tarball — so I have to name a
patch anyway. Pinning it also means every `vagrant up`, today or in three months, installs the
identical toolchain, which keeps the environment reproducible and makes debugging predictable.

## Task 2 — Snapshots: save, break, restore

```bash
# 1. confirm it's healthy, then snapshot
vagrant ssh -c 'go version'
#   go version go1.24.5 linux/amd64
vagrant snapshot save clean-go-ready
#   ==> default: Snapshotting the machine as 'clean-go-ready'...
#   ==> default: Snapshot saved!

# 2. break it — wipe the Go install
vagrant ssh -c 'sudo rm -rf /usr/local/go /usr/local/bin/go'

# 3. prove it's broken
vagrant ssh -c 'go version'
#   bash: line 1: go: command not found

# 4. restore (timed)
time vagrant snapshot restore clean-go-ready
#   ==> default: Forcing shutdown of VM...
#   ==> default: Restoring the snapshot 'clean-go-ready'...
#   ==> default: Booting VM...
#   ==> default: Machine booted and ready!
#
#   real    0m29.1s
#   user    0m3.9s
#   sys     0m3.2s

# 5. prove recovery
vagrant ssh -c 'go version'
#   go version go1.24.5 linux/amd64
```

Restore took about **29 seconds** — the "30-second rollback" the cattle-vs-pets idea is about.

### Design questions

**e) Why aren't snapshots backups?**
A snapshot sits on the same disk and host as the VM it belongs to. If the laptop dies, the disk
corrupts, or the VM directory is deleted, the snapshot goes with it — it isn't a separate, offsite
copy. It also only rewinds to a moment in time, so it can't protect data created after it was taken.

**f) Copy-on-write — 10 snapshots vs 1?**
VirtualBox snapshots are differencing disks: taking one doesn't copy the whole disk, it just starts
recording the blocks that change afterward. So one snapshot is nearly free at first, and ten cost
roughly the sum of the changes between them — not ten times the full disk. The catch is that a long
chain still grows over time and slows reads, because each read may have to walk down the chain.

**g) When is snapshotting an antipattern?**
When snapshots become a stand-in for reproducible provisioning or real backups — especially long
chains kept around "just in case." They slow disk I/O, get fragile, and hide configuration drift.
The healthier pattern is to rebuild from the Vagrantfile/provisioner (cattle, not pets) and keep
snapshots short-lived: take one, do the risky thing, restore or delete.

## Bonus — VM vs container baseline

Same QuickNotes, measured on the same machine in one session.

| Dimension             |        Vagrant VM | Docker container |
| --------------------- | ----------------: | ---------------: |
| Cold start            | 9.8s halt + 34.6s up | 0.41s |
| Idle RAM              | 180 MiB / 961 MiB | 9 MiB |
| On-disk size          | 2.0 GB | 1.1 GB |
| Process count (guest) | 112 | 2 |

The gap that stands out is RAM and process count: the container runs the single QuickNotes process
in ~9 MiB, while the VM boots a whole Ubuntu — systemd, sshd, cron, dozens of services, ~180 MiB —
just to run the same one binary. Cold start is the other one: under half a second vs a ~35-second
boot. A VM is the right tool when you need a real, isolated OS — a different kernel, system-level
config, or testing that depends on the full machine. A container is the right tool for a stateless
single-process service that should start fast and pack densely. That's exactly why containers took
over stateless microservices in 2014–2020: if the workload is "run one process and forward a port,"
paying for a full guest OS's boot time, memory, and process overhead buys you nothing.
