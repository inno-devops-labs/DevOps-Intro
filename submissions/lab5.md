# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

> **Environment:** 
> My machine is running Apple Silicon M4. 
> I downloaded the last version of virtual box that is 7.2.1. I choose arm64 ubunto image :`cloudicio/ubuntu-server` 24.04. Everything else follows the lab as written.


---
What I have done?

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile



```ruby
GO_VERSION = "1.24.13"

Vagrant.configure("2") do |config|

  config.vm.box = "cloudicio/ubuntu-server"
  config.vm.box_version = "24.04.1"
  config.vm.hostname = "quicknotes-vm"
  config.vm.network "forwarded_port",
    guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
    vb.gui = false
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    export DEBIAN_FRONTEND=noninteractive

    command -v curl >/dev/null 2>&1 || { apt-get update && apt-get install -y curl; }

    
    ARCH="$(dpkg --print-architecture)"          
    cd /tmp
    curl -fsSLO "https://go.dev/dl/go#{GO_VERSION}.linux-${ARCH}.tar.gz"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "go#{GO_VERSION}.linux-${ARCH}.tar.gz"
    ln -sf /usr/local/go/bin/go    /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
    go version

    
    install -d -o vagrant -g vagrant /opt/quicknotes
    cp -r /home/vagrant/app/. /opt/quicknotes/
    rm -rf /opt/quicknotes/data                 
    chown -R vagrant:vagrant /opt/quicknotes
    cd /opt/quicknotes
    CGO_ENABLED=0 go build -o /usr/local/bin/quicknotes .

    cat >/etc/systemd/system/quicknotes.service <<'UNIT'

[Unit]
Description=QuickNotes API
After=network.target

[Service]
Environment=ADDR=:8080
Environment=DATA_PATH=/opt/quicknotes/data/notes.json
Environment=SEED_PATH=/opt/quicknotes/seed.json
WorkingDirectory=/opt/quicknotes
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
User=vagrant

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now quicknotes
    systemctl restart quicknotes  
    sleep 2
    curl -fsS http://127.0.0.1:8080/health && echo
  SHELL
end

```

### `vagrant up` — first 10 lines (box download / provisioning)

```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'cloudicio/ubuntu-server' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: 24.04.1
==> default: Loading metadata for box 'cloudicio/ubuntu-server'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/cloudicio/ubuntu-server
==> default: Adding box 'cloudicio/ubuntu-server' (v24.04.1) for provider: virtualbox (arm64)
    default: Downloading: https://vagrantcloud.com/cloudicio/boxes/ubuntu-server/versions/24.04.1/providers/virtualbox/arm64/vagrant.box
    default: Calculating and comparing box checksum...
==> default: Successfully added box 'cloudicio/ubuntu-server' (v24.04.1) for 'virtualbox (arm64)'!
```

### Proof QuickNotes runs — curl from INSIDE the VM and from the HOST

Inside the guest (service is started by the provisioner):

```text
$ vagrant ssh -c 'go version'
$ vagrant ssh -c 'curl -s http://127.0.0.1:8080/health'

go version go1.24.13 linux/arm64
{"notes":4,"status":"ok"}
```

From the host, through the `127.0.0.1:18080 -> 8080` port forward:

```text
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

### Design questions

**a) Synced folder type — which and why; trade-off.**
I used **`rsync`**, a one-way host→guest copy performed at `up` /
`reload` / `provision`. 

I picked it because it needs no guest additions —
VirtualBox's shared folders depend on guest additions that are
unreliable on arm64. Rsync behaves the same way on every provider.

The trade-off is that it is **not live or
bidirectional**: edits I make on the host don't appear in the guest until the
next `vagrant rsync` , and files created in the
guest never propagate back. 



**b) Network mode; why loopback-bound forwarding beats bridged.**
The VM uses **NAT**. I expose the app only via
the port forward bound to `127.0.0.1:18080`. NAT keeps the guest hidden behind the
host — only ports I explicitly forward are reachable.

A **Bridged** interface would give the VM its own IP
on the physical network, exposing *every* guest port to the whole LAN. 

So, here is just a following minimize-exposure principle.

**c) Provisioner — which and why.**
**`shell`**. Because installing one pinned Go and wiring a systemd unit is a few
imperative steps. A shell provisioner does it with zero extra tooling and is
fully transparent.

**d) Why pin `1.24.13` instead of `1.24`.**
`1.24` is a floating version. It resolves to whatever the newest `1.24.x`
happens to be at download time. Keeping `1.24` might leads to unreproducible/unpredicatble behaviour. Pinning the exact  `1.24.13` version  makes
`vagrant up` deterministic.

---

## Task 2 — Snapshots: Save, Break, Restore

What I have done?

### 1) Save snapshot

```
vagrant snapshot save clean-go-1.24.13

==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```

### 2) Break it intenationally and verify it

```
vagrant ssh -c 'sudo rm -rf /usr/local/go /usr/local/bin/go /usr/local/bin/gofmt'
vagrant ssh -c 'go version' 

bash: line 1: go: command not found
exit=127

```


### 3) Restore and verify it

```
time vagrant snapshot restore clean-go-1.24.13

vagrant snapshot restore clean-go-1.24.13  1.05s user 0.70s system 14% cpu 11.963 total
```

```
vagrant ssh -c 'go version'
go version go1.24.13 linux/arm64
```





### Design questions

**e) Why snapshots are not backups.**
A snapshot lives on the same disk and host as the VM, so it dies with any
failure that takes out the host: disk failure, filesystem
corruption, `vagrant destroy`. It
also only captures a point-in-time of this one VM, so it useless for recovering
data you deleted before taking it. Snapshot is a fast local
rollback.

A backup is an **independent copy**. 

**f) Copy-on-write — disk cost of 10 snapshots vs 1.**
VirtualBox snapshots are copy-on-write: the base disk is frozen and only
blocks that change after the snapshot is written to a new differencing file.
Unchanged blocks stay shared with the base. So 10 snapshots do not cost 10×
the disk — each one only consumes the size of the changes since the previous
one. 

**g) When snapshotting is an antipattern.**
Each live snapshot adds a differencing layer the hypervisor
must walk on every read, so 
one corrupted link breaks everything downstream of it. Snapshots are for
short-lived save point before something risky, not a substitute for backups.

A `Vagrantfile` you can simply re-`up` beats a tower of snapshots.

---

## Bonus Task — VM vs Container Resource Baseline
Here I measured a performance between docker container that I will us ein lab 6 and vagrant vm. 



| Dimension              | Vagrant VM | Docker container |
|------------------------|-----------:|-----------------:|
| Cold start             | ~18.6 s | ~0.09 s |
| Idle RAM               | 245 MiB used (of 1024 MB) | 3.18 MiB |
| On-disk size           | 6.0 GB | 21.7 MB |
| Process count (guest)  | 104 | 1 |

**Analysis.**
The container cold-starts in ~0.09 s while the VM takes ~18.6 s — about 200×
slower — because the VM boots a full guest kernel + systemd + services,
whereas the container just resumes one already-resident process on the host
kernel. 

The gaps in idle RAM (3.18 MiB vs 245 MiB) and on-disk size
(21.7 MB vs 6.0 GB) are even bigger, for the same reason: the VM ships
and runs an entire OS with many processes, while the distroless container is a
single static binary running as exactly one process in this case.

The number that surprised me most is on-disk size — a 6 GB VM image versus a 22 MB image. I will have to clean my disk after these labs :)


Conclusion: the VM is the right tool when you need full kernel isolation, a
different kernel/OS, or to mimic a real server. The container wins when you want
to pack many lightweight, stateless instances and start/stop them
instantly. 
That flexibility with near-zero cold start is exactly why containers took
over stateless microservices in the 2014–2020 era: the same hardware runs far
more isolated workloads, and autoscaling/redeploys measured in milliseconds
become practical.
