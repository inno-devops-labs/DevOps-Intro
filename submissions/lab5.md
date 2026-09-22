# Lab 5 submission

## Task 1: Vagrant Up + Run QuickNotes Inside

### Vagrantfile

[`Vagrantfile`](../Vagrantfile)

### `vagrant up` (first 10 lines)

```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'bento/ubuntu-24.04' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: 202510.26.0
==> default: Loading metadata for box 'bento/ubuntu-24.04'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/bento/ubuntu-24.04
==> default: Adding box 'bento/ubuntu-24.04' (v202510.26.0) for provider: virtualbox (arm64)
    default: Downloading: https://vagrantcloud.com/bento/boxes/ubuntu-24.04/versions/202510.26.0/providers/virtualbox/arm64/vagrant.box
==> default: Successfully added box 'bento/ubuntu-24.04' (v202510.26.0) for 'virtualbox (arm64)'!
==> default: Importing base box 'bento/ubuntu-24.04'...
```

### curl

```
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/arm64
```

Inside the VM:

```
$ vagrant ssh -c 'curl -s http://localhost:8080/health'
{"notes":6,"status":"ok"}
```

From the host, through the port forward:

```
$ curl -s http://localhost:18080/health
{"notes":6,"status":"ok"}
```

### Design questions

**a) Which synced folder type, and the trade-off?**

The `virtualbox` type (VirtualBox shared folders), which is the default for this provider. It needs nothing extra on the host: no NFS server and exports, no rsync daemon, no SMB credentials. It is also live and two-way, so an edit on the host is visible in the guest immediately, which suits a small source tree that only gets read at build time. The trade-off is performance and semantics: shared folders are noticeably slower than the guest's own disk under heavy I/O, file-change events do not cross the boundary, and permissions and symlinks behave differently from a native filesystem. `nfs` is faster but needs a host daemon and root on macOS and does not work on Windows. `rsync` gives native disk speed in the guest but is one-way and only stays current if `vagrant rsync-auto` is running. `smb` exists mainly for Windows hosts.

**b) Which network mode, and why is a `127.0.0.1` port forward safer than Bridged?**

NAT, the default, shown as `Adapter 1: nat` in the `vagrant up` output. With NAT the VM has no address on the physical network at all: nothing outside the laptop can reach it, and the only way in is a port forward that I opened explicitly. Binding that forward to `127.0.0.1` also matters, because without `host_ip` Vagrant binds it on all host interfaces, which would expose it on whatever Wi-Fi the laptop joins. Bridged mode would put the VM on the local network with its own IP, so a service with no authentication that accepts `POST` and `DELETE`, plus an SSH server with well-known Vagrant defaults, would be reachable by everyone on a campus network.

**c) Which provisioner, and why?**

`shell`. The job is to download one tarball and unpack it, and the shell provisioner is built into Vagrant and needs nothing installed on either side. `ansible` would require Ansible on every student's host, `ansible_local` would install Ansible and Python inside the guest and add minutes to every fresh boot, and Puppet and Chef bring agents and a whole configuration model for a single package. The script is idempotent through its version check, so `vagrant provision` is safe to re-run. Lab 7 introduces Ansible for the actual deployment, where declarative configuration management earns its weight.

**d) Why pin `1.24.5` instead of `1.24`?**

`1.24` names a series of releases, not one toolchain. Point releases change the compiler, the runtime and the standard library, sometimes in ways a program can observe, so "install Go 1.24" would produce different binaries for students who ran `vagrant up` on different days, which breaks requirement 7 and brings back "works on my VM" bugs. Pinning the exact version makes an upgrade a deliberate, reviewable change to the Vagrantfile, and it is also what lets the provisioner decide reliably that the correct version is already installed.

---

## Task 2: Snapshots, Save, Break, Restore

### Commands

Save:

```
$ vagrant snapshot save clean-go-1.24.5
==> default: Snapshotting the machine as 'clean-go-1.24.5'...
==> default: Snapshot saved!

$ vagrant snapshot list
clean-go-1.24.5
```

Break:

```
$ vagrant ssh -c 'sudo rm -rf /usr/local/go'
```

Verify broken:

```
$ vagrant ssh -c 'go version'
bash: line 1: go: command not found
```

Restore:

```
$ time vagrant snapshot restore --no-provision clean-go-1.24.5
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'clean-go-1.24.5'...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Machine booted and ready!
==> default: Machine not provisioned because `--no-provision` is specified.
vagrant snapshot restore --no-provision clean-go-1.24.5  1.19s user 0.94s system 10% cpu 20.129 total
```

Verify recovered:

```
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/arm64
```

**Restore time: 20.1 s.**

### Design questions

**e) Why snapshots are not backups**

A snapshot lives on the same disk, in the same VM directory, as the machine it protects, and usually as a differencing image that depends on the base disk. Anything that takes out that location takes the snapshots with it: a failed or stolen laptop, a corrupted base image, or simply `vagrant destroy`, which deletes the snapshots along with the VM. A backup is an independent copy in a separate failure domain, and a snapshot is neither independent nor separate.

**f) Copy-on-write: 10 snapshots vs 1**

Taking a snapshot freezes the current disk image and starts a new differencing image that receives all later writes. So 10 snapshots are not 10 copies of the disk: each one costs only the blocks that changed since the previous one, and disk usage grows with the amount of change, not the number of snapshots. Two caveats. A snapshot of a running VM, like the one here, also stores the machine's RAM, roughly the size of the allocated memory each time. And the space never comes back until snapshots are deleted and merged.

**g) When snapshotting is an antipattern**

When it turns into a long chain. Every read may have to walk through a stack of differencing images, so I/O degrades as the chain grows; deleting a snapshot in the middle forces a merge that is slow and risky; and corruption anywhere in the chain breaks everything after it. The deeper problem is that a VM kept alive for months with twenty snapshots becomes a pet whose state nobody can reproduce from code. The healthy pattern is to rebuild from the Vagrantfile, take a snapshot only right before a risky change, and delete it afterwards.

---

## Bonus Task: VM vs Container Resource Baseline

| Dimension | Vagrant VM | Docker container |
|---|---:|---:|
| Cold start | 18.6 s | 0.09 s |
| Idle RAM | 236 MiB | 7.6 MiB |
| On-disk size | 3.0 GB (includes the Task 2 snapshot) | 1.33 GB |
| Process count (guest) | 105 | 2 |

The disk column surprised me: the container image is not small at all, because `golang:1.24` carries the whole compiler toolchain to build the binary on start, and a runtime-only image would be a fraction of that size. The RAM gap is huge in the other direction: the VM runs a full operating system with 105 processes to serve the same six notes that the container serves with 2 processes in under 8 MiB, because the container shares the host kernel instead of booting its own. A VM is the right tool when a workload needs its own kernel, a hard isolation boundary around untrusted code, or a full machine to configure, like the Ansible target in Lab 7. A container is the right tool for many small stateless services, where density and start-up time matter most. That is why containers won the 2014 to 2020 era: an instance that starts in a tenth of a second and costs a few megabytes can be scaled out and replaced as easily as restarting a process, which is exactly what microservices needed.
