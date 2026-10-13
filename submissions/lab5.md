# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Environment

The lab was completed on an Apple Silicon macOS host using:

- Host architecture: `arm64`
- Vagrant: `2.4.9`
- Provider: Parallels with `vagrant-parallels`
- Guest OS: Ubuntu 24.04.2 LTS
- Guest architecture: `aarch64`
- Go: `1.24.5`
- VM hostname: `quicknotes-vm`
- Guest application port: `8080`
- Host forwarded port: `127.0.0.1:18080`

The course instructions primarily reference VirtualBox, but the VM was run with the Parallels Vagrant provider because the host is an Apple Silicon Mac with Parallels already installed.

The `Vagrantfile` remains at the repository root:

[Vagrantfile](../Vagrantfile)

---

# Task 1 — Vagrant Up and QuickNotes

## 1. VM configuration

The Vagrant environment creates an Ubuntu 24.04 LTS VM with:

- hostname identifying the QuickNotes VM;
- maximum 2 vCPU;
- 1024 MB RAM;
- host `127.0.0.1:18080` forwarded to guest port `8080`;
- host `./app` synchronized into `/opt/quicknotes`;
- Go `1.24.5` installed automatically by a shell provisioner.

The resulting architecture is:

```text
macOS host
ARM64
│
├── ./app
│     │
│     │ rsync
│     ▼
│   Ubuntu VM
│   /opt/quicknotes
│
└── 127.0.0.1:18080
          │
          │ Vagrant port forwarding
          ▼
      guest :8080
          │
          ▼
      QuickNotes
```

---

## 2. Vagrant startup and provisioning

The VM was started using:

```bash
vagrant up --provider=parallels --provision
```

Relevant beginning of the successful run:

```text
Bringing machine 'default' up with 'parallels' provider...
==> default: Checking if box 'gutehall/ubuntu24-04' version '2025.02.20' is up to date...
==> default: Running provisioner: shell...
    default: Running: inline script
    default: ++ GO_VERSION=1.24.5
    default: ++ case "$(uname -m)" in
    default: +++ uname -m
    default: ++ GO_ARCH=arm64
    default: ++ apt-get update
    default: Hit:1 http://ports.ubuntu.com/ubuntu-ports noble InRelease
```

The provisioner detected the ARM64 architecture and verified the installed Go version:

```text
GO_ARCH=arm64
go version go1.24.5 linux/arm64
```

---

## 3. VM verification

Command:

```bash
vagrant status
```

Output:

```text
default                   running (parallels)
```

System properties were checked with:

```bash
vagrant ssh -c '
uname -m
cat /etc/os-release | head -n 6
hostname
go version
'
```

Output:

```text
aarch64

PRETTY_NAME="Ubuntu 24.04.2 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.2 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu

quicknotes-vm

go version go1.24.5 linux/arm64
```

This confirms that the VM is Ubuntu 24.04 LTS on ARM64 and that the required Go 1.24.x toolchain is installed.

---

## 4. Synced application directory

The synchronized application directory was checked with:

```bash
vagrant ssh -c '
ls -la /opt/quicknotes
cat /opt/quicknotes/go.mod
'
```

Relevant output:

```text
.golangci.yml
go.mod
handlers.go
handlers_test.go
main.go
Makefile
README.md
seed.json
store.go
store_test.go
```

The module definition was:

```text
module quicknotes

go 1.24
```

Therefore the host application directory was successfully synchronized into:

```text
/opt/quicknotes
```

inside the guest.

---

## 5. Port forwarding

Command:

```bash
vagrant port
```

Output:

```text
22 (guest) => 22022 (host)
8080 (guest) => 18080 (host)
```

The application path therefore is:

```text
Host
127.0.0.1:18080
       │
       │ port forwarding
       ▼
Guest
*:8080
       │
       ▼
QuickNotes
```

The application port is bound only through host loopback for the forwarded host endpoint, so the course service is not intentionally exposed to the external LAN.

---

## 6. Building and starting QuickNotes

QuickNotes was built inside the VM:

```bash
vagrant ssh -c '
cd /opt/quicknotes
go build -o /tmp/qn
'
```

The resulting executable was approximately:

```text
7.8M /tmp/qn
```

It was started in the guest and its socket was verified:

```text
quicknotes listening on :8080 (notes loaded: 6)
```

Listener:

```text
LISTEN 0 4096 *:8080 *:* users:(("qn",pid=11547,fd=3))
```

---

## 7. Health check from inside the VM

Command:

```bash
vagrant ssh -c \
  'curl -sS http://127.0.0.1:8080/health'
```

Output:

```json
{"notes":6,"status":"ok"}
```

This verifies that QuickNotes itself was healthy inside the guest.

---

## 8. Health check from the host

Command:

```bash
curl -sS http://127.0.0.1:18080/health
```

Output:

```json
{"notes":6,"status":"ok"}
```

This proves the complete host-to-guest path:

```text
curl on macOS
      │
      ▼
127.0.0.1:18080
      │
      ▼
Vagrant / Parallels port forwarding
      │
      ▼
Ubuntu guest :8080
      │
      ▼
QuickNotes
      │
      ▼
HTTP 200
```

---

# Task 1 — Design Questions

## a) Which synced-folder type did I choose and why?

I used the `rsync` synced-folder type.

`rsync` copies the contents of the host `./app` directory into the guest filesystem. I selected it because it is relatively provider-independent and does not require provider-specific shared-folder drivers such as VirtualBox Guest Additions or Parallels shared-folder support.

The main trade-off is that `rsync` is not the same as a continuously shared filesystem. Changes made on the host are not necessarily reflected in the guest immediately. After changing source files, synchronization may need to be triggered again with:

```bash
vagrant rsync
```

A native shared-folder implementation provides a more immediate view of host files, while `rsync` is simple and portable but requires explicit synchronization.

---

## b) Which network mode is used, and why is loopback-bound port forwarding safer than bridged networking?

The VM uses the provider's default NAT-style networking together with an explicit forwarded port.

Conceptually:

```text
Guest VM
   │
   ▼
virtual NAT
   │
   ▼
Host
   │
   ▼
external network
```

The application is made available to the host through:

```text
127.0.0.1:18080 → guest:8080
```

Binding the forwarded host port to `127.0.0.1` means that the service is intended to be reachable only from the local host.

A bridged VM behaves more like a separate physical machine on the local network and can obtain its own LAN address. Depending on network and firewall configuration, other machines could then communicate directly with it.

For a course exercise, exposing only the required loopback port follows the principle of reducing unnecessary network exposure.

---

## c) Which provisioning method did I choose and why?

I used Vagrant's `shell` provisioner.

The required provisioning task is small:

1. detect guest CPU architecture;
2. update package metadata;
3. install basic dependencies;
4. install a pinned Go release;
5. configure the Go executable in `PATH`.

A shell provisioner is appropriate for a simple single-host bootstrap procedure because it adds very little complexity.

Tools such as Ansible, Puppet or Chef become more useful when configuration grows, multiple hosts need to be managed, state must be modeled more systematically, or reusable configuration roles are required.

For this VM bootstrap, a shell script is sufficient and easy to understand.

---

## d) Why pin Go to `1.24.5` instead of `1.24`?

A point release such as:

```text
1.24.5
```

identifies one specific Go toolchain version.

A less specific version such as:

```text
1.24
```

can allow different machines or executions to receive different patch releases over time.

Pinning the exact version improves reproducibility because two students provisioning the environment at different times are much more likely to receive the same compiler and standard-library implementation.

This reduces the number of environmental variables when troubleshooting builds or tests.

---

# Task 2 — Snapshot: Save, Break, Restore

## 1. Verify the clean state

Before creating the snapshot, Go was verified:

```bash
vagrant ssh -c '
which go
go version
ls -ld /usr/local/go
'
```

Output:

```text
/usr/local/go/bin/go
go version go1.24.5 linux/arm64
drwxr-xr-x 10 root root ... /usr/local/go
```

The VM was therefore in a known working state.

---

## 2. Save the snapshot

Command:

```bash
vagrant snapshot save lab5-clean
```

Output:

```text
==> default: Snapshotting the machine as 'lab5-clean'...
==> default: Snapshot saved!
```

The snapshot was verified:

```bash
vagrant snapshot list
```

Output:

```text
lab5-clean
```

The state at this point was:

```text
Ubuntu 24.04
├── Go 1.24.5
├── QuickNotes
├── /opt/quicknotes
└── working configuration
        │
        ▼
   snapshot: lab5-clean
```

---

## 3. Deliberately break the VM

The Go installation was deliberately removed:

```bash
vagrant ssh -c '
sudo rm -rf /usr/local/go
'
```

This was intentionally destructive and removed the installed Go toolchain.

---

## 4. Verify the broken state

Command:

```bash
vagrant ssh -c '
go version
'
```

Output:

```text
bash: line 3: go: command not found
```

Additional verification:

```text
ls: cannot access '/usr/local/go': No such file or directory
bash: /usr/local/bin/go: No such file or directory
bash: go: command not found
```

This proves that the VM state was actually modified after the snapshot.

Interestingly, the already compiled and already running QuickNotes process continued to answer:

```bash
curl -sS http://127.0.0.1:18080/health
```

Output:

```json
{"notes":6,"status":"ok"}
```

This demonstrates an important distinction between a build-time toolchain and a runtime executable.

The Go compiler/toolchain had been removed, but the already-built native QuickNotes executable did not require the Go compiler to continue running.

---

## 5. Restore the snapshot

The snapshot restore was timed using:

```bash
time vagrant snapshot restore lab5-clean
```

Output:

```text
==> default: Restoring the snapshot 'lab5-clean'...
vagrant snapshot restore lab5-clean  0.50s user 0.20s system 29% cpu 2.356 total
```

Measured wall-clock restore time:

```text
2.356 seconds
```

---

## 6. Verify recovery

The VM returned to the running state:

```text
default                   running (parallels)
```

Go was checked again:

```bash
vagrant ssh -c '
which go
go version
ls -ld /usr/local/go
'
```

Output:

```text
/usr/local/go/bin/go
go version go1.24.5 linux/arm64
drwxr-xr-x 10 root root ... /usr/local/go
```

Therefore the deleted Go installation was successfully restored from the snapshot.

The listening QuickNotes process was also present again:

```text
LISTEN 0 4096 *:8080 *:* users:(("qn",pid=11547,fd=3))
```

Finally, the application was verified from the host:

```bash
curl -sS http://127.0.0.1:18080/health
```

Output:

```json
{"notes":6,"status":"ok"}
```

The complete lifecycle was therefore:

```text
WORKING VM
    │
    ▼
snapshot save lab5-clean
    │
    ▼
delete /usr/local/go
    │
    ▼
go version fails
    │
    ▼
snapshot restore
    │
    ▼
Go 1.24.5 restored
    │
    ▼
QuickNotes healthy
```

---

# Task 2 — Design Questions

## e) Why are snapshots not backups?

A snapshot is primarily a point-in-time rollback mechanism and usually remains dependent on the original VM storage and its underlying infrastructure.

If the host disk fails, the VM directory is lost, the storage becomes corrupted, or the machine containing both the original disk and its snapshots is destroyed, the snapshot may be lost together with the VM.

A backup should provide an independent copy, ideally stored in a different failure domain, so that data can still be recovered after loss of the original storage.

In short:

```text
Snapshot → fast rollback

Backup → recovery after loss of the original system/data
```

---

## f) What does copy-on-write mean for snapshot disk usage?

The laboratory asks about the VirtualBox copy-on-write snapshot model.

With copy-on-write, creating a snapshot does not normally produce another complete copy of the entire virtual disk.

Instead, the existing disk state becomes the base and subsequent changed blocks are written into additional differencing storage.

Conceptually:

```text
Base virtual disk
████████████████████████

        │ snapshot

Snapshot changes
        ███
           ██

        │ another snapshot

New changes
              ████
```

Therefore ten snapshots do not automatically consume ten times the full VM disk size.

However, each snapshot can accumulate changed blocks, metadata and additional differencing state, so disk usage continues to grow as more data changes between snapshots.

The exact implementation in this lab was Parallels rather than VirtualBox, but the answer above describes the copy-on-write model specifically requested by the task.

---

## g) When is snapshotting an antipattern?

Snapshots become an antipattern when they are treated as permanent version history or backups and are allowed to form long dependency chains.

For example:

```text
Base
 ↓
Snapshot 1
 ↓
Snapshot 2
 ↓
Snapshot 3
 ↓
...
 ↓
Snapshot 20
```

Long chains increase storage consumption and operational complexity. Depending on the hypervisor, they may also reduce I/O performance and make consolidation, deletion and recovery more complicated.

Snapshots are most useful as temporary rollback points before controlled experiments, upgrades or risky configuration changes.

They should not replace proper backups, reproducible provisioning or configuration management.

---

# Result

## Task 1

- Ubuntu 24.04 LTS VM: ✅
- ARM64 guest on Apple Silicon: ✅
- QuickNotes-specific hostname: ✅
- Go `1.24.5`: ✅
- Go installed automatically through provisioning: ✅
- `./app` synchronized into the guest: ✅
- Resource limits configured: ✅
- Guest `8080` forwarded to host `127.0.0.1:18080`: ✅
- `/health` reachable inside the VM: ✅
- `/health` reachable from the host: ✅
- Design questions a-d answered: ✅

## Task 2

- Clean snapshot created: ✅
- VM deliberately broken: ✅
- Broken state demonstrated: ✅
- Snapshot restored: ✅
- Recovery verified: ✅
- Restore time measured: **2.356 s**
- Design questions e-g answered: ✅