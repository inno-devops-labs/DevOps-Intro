# Lab 5 — QuickNotes in a Vagrant VM

**Setup:** MacBook Air (Apple Silicon, arm64), VirtualBox 7.2.20, Vagrant 2.4.9, Docker 29.2.1.

Because my Mac is ARM, the VM must be ARM too. `bento/ubuntu-24.04` has an arm64 VirtualBox box, and the provisioner downloads the matching Go (`amd64` or `arm64`), so the same `Vagrantfile` also works on Intel laptops.

## Task 1 — Vagrant up + QuickNotes

**Vagrantfile:** [`Vagrantfile`](../Vagrantfile) in the repo root.

- Box: `bento/ubuntu-24.04` (Ubuntu 24.04 LTS), version pinned
- Hostname: `quicknotes-vm`
- Port forward: `127.0.0.1:18080` → guest `8080`
- Synced folder: `./app` → `/home/vagrant/app` (rsync)
- Resources: 2 vCPU, 1024 MB RAM
- Provisioning: shell script installs Go **1.24.13** and checks its SHA256; it skips the install if Go is already there

**First 10 lines of `vagrant up`:**

```text
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

End of provisioning:

```text
==> default: Running provisioner: install-go (shell)...
    default: /tmp/go1.24.13.linux-arm64.tar.gz: OK
    default: go version go1.24.13 linux/arm64
```

**curl from inside the VM:**

```console
$ vagrant ssh -c 'cd ~/app && go build -o /tmp/qn . && (setsid nohup /tmp/qn > /tmp/qn.log 2>&1 &); sleep 2; curl -s http://localhost:8080/health'
{"notes":4,"status":"ok"}
```

**curl from the host (through the port forward):**

```console
$ curl -s -i http://localhost:18080/health
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 26

{"notes":4,"status":"ok"}
```

### Design questions

**a) Synced folder.** I used **rsync**. It doesn't need VirtualBox Guest Additions, which are still new on ARM Macs, and the app builds from the VM's own disk, so it's fast. The trade-off is that it only copies one way (host → VM) and only on `vagrant up`/`reload`. After I edit code I have to run `vagrant rsync`. `virtualbox` shared folders are live and two-way but slower and need Guest Additions. `nfs` is fast but needs sudo on the host.

**b) Network mode.** **NAT**, the default (`vagrant up` prints `Adapter 1: nat`). With the port bound to `127.0.0.1`, only my own laptop can open QuickNotes. With **Bridged**, the VM would get its own IP on the Wi-Fi network, and anyone on the university network could reach the app and its SSH.

**c) Provisioner.** **shell**. Installing Go is just download → check → extract, which is a few lines of bash. It needs no extra tools on the host, while `ansible` would need Ansible installed first. Ansible makes more sense in Lab 7, where there is more to configure.

**d) Why pin 1.24.13, not 1.24.** "1.24" changes over time (1.24.0 … 1.24.13), so two people could get different Go versions and different bugs. An exact version gives everyone the same result, lets me check the file's SHA256, and makes an upgrade a visible commit.

## Task 2 — Snapshots

```console
# 1. save
$ vagrant snapshot save clean-go-1.24.13
==> default: Snapshot saved!
$ vagrant snapshot list
clean-go-1.24.13

# 2-3. break + prove it's broken
$ vagrant ssh -c 'sudo rm -rf /usr/local/go; go version; echo "exit code: $?"'
bash: line 1: go: command not found
exit code: 127

# 4. restore (timed; --no-provision so the provisioner can't reinstall Go)
$ time vagrant snapshot restore --no-provision clean-go-1.24.13
==> default: Restoring the snapshot 'clean-go-1.24.13'...
==> default: Resuming suspended VM...
==> default: Machine booted and ready!
vagrant snapshot restore --no-provision clean-go-1.24.13  1.06s user 0.72s system 14% cpu 12.088 total

# 5. verify
$ vagrant ssh -c 'go version'
go version go1.24.13 linux/arm64
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

**Restore time: 12.1 seconds.** QuickNotes was running again without me restarting it, because the snapshot was taken while the VM was on and saved its memory too.

### Design questions

**e) Snapshots are not backups.** A snapshot is stored on the same disk as the VM, and it needs the original disk to work. If the laptop's disk dies, the laptop is lost, or I run `vagrant destroy`, the snapshot is gone too. A real backup is a separate copy in a different place.

**f) Copy-on-write.** A snapshot doesn't copy the whole disk. It freezes the current disk, and new changes go into a new small file. So 10 snapshots don't take 10× the space, only the space of what changed between them. They can still grow big if the VM writes a lot, and live snapshots also save the RAM.

**g) When it's an antipattern.** Long chains of snapshots make the disk slower (reads go through many layers), use more space, and if one layer breaks, all later ones break. It's also bad when a snapshot becomes the only way to get a "good" VM. The VM should be rebuilt from the `Vagrantfile`, and snapshots should only be kept for short experiments.

## Bonus — VM vs Container

Same laptop, same session, same QuickNotes code.

```console
# VM
$ time vagrant halt        → 2.55 s
$ time vagrant up          → 18.39 s
$ vagrant ssh -c 'free -h'           → used 205Mi (of 824Mi)
$ vagrant ssh -c 'ps -A --no-headers | wc -l'   → 104
$ du -sh ~/VirtualBox\ VMs/quicknotes-vm        → 2.7G

# Container (golang:1.24, port 28080)
$ time docker start qn-docker        → 0.09 s
$ docker stats --no-stream           → MEM 9.566MiB
$ docker top qn-docker               → 2 processes (sh, /tmp/qn)
$ docker images golang:1.24          → 1.33GB
```

| Dimension             | Vagrant VM | Docker container |
|-----------------------|-----------:|-----------------:|
| Cold start            |     18.4 s |           0.09 s |
| Idle RAM              |    205 MiB |          9.6 MiB |
| On-disk size          |     2.7 GB |          1.33 GB |
| Process count (guest) |        104 |                2 |

The container used about 20× less RAM, and started in under a second instead of 18 seconds. That surprised me most. The VM runs a full Ubuntu with 104 processes just to serve one Go app, while the container runs only the app and shares the host's kernel. Disk size was closer than I expected, because `golang:1.24` includes the whole Go toolchain. A small image with only the binary would be much smaller. VMs are better when you need a different OS or kernel, strong isolation, or a full machine to configure (like Lab 7). Containers are better for small stateless services that are started, scaled and replaced often. That's why they won for microservices: many copies are cheap and start instantly.
