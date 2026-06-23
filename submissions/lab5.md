# Lab 5

## Task 1
```
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"

  config.vm.hostname = "quicknotes-vm"
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", create: true

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus   = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e
    apt-get update && apt-get install -y curl
    GO_VERSION=1.24.5
    case "$(uname -m)" in
      x86_64)  GOARCH=amd64 ;;
      aarch64) GOARCH=arm64 ;;
      *) echo "unsupported arch $(uname -m)"; exit 1 ;;
    esac
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz" -o /tmp/go.tgz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
    fi
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
  SHELL
end
```

```
vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'bento/ubuntu-24.04'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'bento/ubuntu-24.04' version '202510.26.0' is up to date...
==> default: Setting the name of the VM: DevOps-Intro_default_1782077425063_37425
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
```


```
vagrant ssh -c 'go version'

go version go1.24.5 linux/arm64
```

```
vagrant@quicknotes-vm:~$ cd app/
vagrant@quicknotes-vm:~/app$ ls
data    handlers.go       main.go   quicknotes  seed.json  store_test.go
go.mod  handlers_test.go  Makefile  README.md   store.go
vagrant@quicknotes-vm:~/app$ go build -o /tmp/qn && /tmp/qn
2026/06/21 21:37:55 quicknotes listening on :8080 (notes loaded: 7)

# local
curl -s http://localhost:18080/health
{"notes":7,"status":"ok"}

# vagrant ssh
vagrant@quicknotes-vm:~$ curl -s http://localhost:8080/health
{"notes":7,"status":"ok"}
```

### Design Questions

**a) Synced folders — which type and why? What is the trade-off?**

I used the **default VirtualBox shared folder** (`config.vm.synced_folder "./app", "/home/vagrant/app"`). I did not set a type, so Vagrant uses the VirtualBox driver automatically. The good side is that it needs no extra setup: no NFS server, no rsync on the host, no SMB credentials. It also syncs in both directions in real time, so when I edit a file on the host, the change is visible inside the VM at once. The trade-off is performance: VirtualBox shared folders are slower than NFS for projects with many files, and they need the VirtualBox Guest Additions in the box. For a small Go app like QuickNotes this is not a problem, but for a large codebase NFS or rsync would build faster.

**b) NAT vs Bridged vs Host-only — which mode, and why is 127.0.0.1 port forwarding safer than Bridged?**

I use the **default NAT mode** (the boot output shows `Adapter 1: nat`). The VM sits behind a private NAT network, and I reach the app through a forwarded port. I bound the forward to `127.0.0.1` with `host_ip: "127.0.0.1"`, so port 18080 is open **only on my own machine**. A Bridged interface would put the VM directly on the physical network with its own IP, so other people on the same Wi-Fi or LAN could connect to QuickNotes. For a course exercise that runs an app with no real security, that is a risk I do not want. Loopback-bound forwarding keeps the app reachable for me and invisible to everyone else.

**c) Provisioning — which provisioner and why?**

I used the **shell provisioner**. The job is small and simple: update apt, install curl, download the Go tarball for the right CPU architecture, unpack it to `/usr/local`, and add Go to the PATH. A few lines of bash do this clearly, with no extra tools to install. Ansible, Puppet, or Chef would be overkill here — they add a dependency and a learning cost for a task that is just "download and extract one tarball". I would reach for Ansible only when the setup grows bigger (many packages, services, config files), which is exactly what Lab 7 will do.

**d) Why pin Go to a specific point release (1.24.5) instead of 1.24?**

I pinned `GO_VERSION=1.24.5`. The label `1.24` is a moving target — it points to whatever the latest patch is at download time, so two students running `vagrant up` on different days could get different builds (1.24.3, 1.24.5, …). Pinning the exact point release makes the VM **reproducible**: everyone gets the same compiler, so a build that works for me works the same for the grader. It also matches the URL format `go1.24.5.linux-arm64.tar.gz`, which needs a full version number anyway. When I want a newer Go later, I bump one line on purpose instead of it changing silently.

## Task 2

### Snapshot lifecycle: save → break → verify → restore → verify

I broke the VM by **deleting the Go installation** (`/usr/local/go`). This is a safe, guest-only break: it does not touch the synced folder or the host. `go version` failing is a clear proof that the VM is broken, and the snapshot restore brings Go back.

> ⚠️ I deliberately did **not** use `rm -rf /`. Because Vagrant mounts the host project into the guest (the explicit `./app` mount and the default `/vagrant` mount), `rm -rf /` would delete the real files on the host through the shared folder, not only inside the VM.

**1. Take a snapshot of the working VM:**

```bash
vagrant snapshot save clean-go-quicknotes
==> default: Snapshotting the machine as 'clean-go-quicknotes'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```

**2. Break the VM (wipe the Go install):**

```bash
vagrant ssh -c 'sudo rm -rf /usr/local/go'
```

**3. Verify it is broken:**

```bash
vagrant ssh -c '/usr/local/go/bin/go version'
bash: line 1: /usr/local/go/bin/go: No such file or directory

vagrant ssh -c 'cd /home/vagrant/app && /usr/local/go/bin/go build -o /tmp/qn'

bash: line 1: /usr/local/go/bin/go: No such file or directory
```

**4. Restore from the snapshot (and time it):**

```bash
time vagrant snapshot restore clean-go-quicknotes

==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'clean-go-quicknotes'...
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
vagrant snapshot restore clean-go-quicknotes  0.97s user 0.78s system 14% cpu 11.942 total
```

**5. Verify recovery:**

```bash
vagrant ssh -c '/usr/local/go/bin/go version'
go version go1.24.5 linux/arm64

# QuickNotes builds and serves again
curl -s http://localhost:18080/health
{"notes":7,"status":"ok"}
```

The restore took **~12 seconds** — much faster than re-provisioning the VM from scratch, which proves the "cattle, not pets" idea: instead of fixing a broken machine by hand, you roll it back to a known-good state in seconds.

### Design Questions

**e) Snapshots are not backups. Why? What failure modes is a snapshot useless for?**

A snapshot lives on the **same disk and the same host** as the VM it captures. If that disk dies, the laptop is stolen, or the VirtualBox VM folder is deleted, the snapshot disappears together with the VM — so it protects nothing against hardware loss. It is also useless against anything that changed *before* the snapshot was taken: if data was already corrupted or a file was deleted earlier, the snapshot just preserves that bad state. A real backup is a separate copy on separate storage (another disk, another machine, cloud), kept independently of the original.

**f) Copy-on-write: what does it mean for disk usage when you take 10 snapshots vs 1?**

Copy-on-write means a snapshot does not copy the whole disk. It freezes the current disk image and writes only the **changes** after that point into a new differencing file. So a fresh snapshot costs almost nothing, and 10 snapshots do not use 10× the disk — each one only stores the blocks that changed since the previous one. The total size grows with **how much you change**, not with the number of snapshots. If you barely touch the VM, 10 snapshots can still be small; if you rewrite a lot of data between each, they grow.

**g) When is snapshotting an antipattern? (long chains)**

Long snapshot chains are the antipattern. Every snapshot adds another differencing layer on top of the previous one, and the VM has to read through the whole chain to find the current block — so a long chain makes disk I/O slower and the VM heavier over time. The chain also becomes fragile: if one link in the middle is damaged, the snapshots after it can break. Snapshots are meant to be short-lived "save points" you create, use, and delete quickly (like before Task 2's break). Keeping dozens of them as if they were version history or backups is the wrong use — that is what Git and real backups are for.

## Bonus — VM vs Container Resource Baseline

Both baselines were measured on the **same Mac in the same session**, so the numbers are comparable. The container runs the same QuickNotes app, built from the same `./app` source.

### B.1: Vagrant VM (idle)

```bash
# Cold-boot time (boot only — VM already provisioned)
vagrant halt
time vagrant up
vagrant up  1.52s user 1.39s system 10% cpu 27.416 total

# Idle RAM inside the guest
vagrant ssh -c 'free -h'
total        used        free      shared  buff/cache   available
Mem:           824Mi       225Mi       440Mi       4.8Mi       239Mi       598Mi
Swap:          3.7Gi          0B       3.7Gi

# Process count inside the guest
vagrant ssh -c 'ps -A --no-headers | wc -l'
103

# On-disk size of the VM image
du -sh ~/VirtualBox\ VMs/DevOps-Intro_default_*/
3.4G    .../DevOps-Intro_default_1782077425063_37425/
```

### B.2: Docker container (same QuickNotes)

```bash
docker run -d --name qn-bonus -p 28080:8080 -v "$PWD/app:/src" -w /src golang:1.24 \
  sh -c 'go build -o /tmp/qn && /tmp/qn'
curl -s http://localhost:28080/health
# {"notes":4,"status":"ok"}

# Cold start
docker stop qn-bonus
time docker start qn-bonus
docker start qn-bonus  0.03s user 0.02s system 40% cpu 0.129 total

# Idle RAM
docker stats --no-stream qn-bonus
NAME       CPU %   MEM USAGE / LIMIT     MEM %   PIDS
qn-bonus   0.00%   7.543MiB / 11.67GiB   0.06%   8

# Process count
docker top qn-bonus | tail -n +2 | wc -l
2

# On-disk size of the image
docker images golang:1.24 --format '{{.Size}}'
1.33GB
```

### B.3: Comparison

| Dimension              | Vagrant VM | Docker container |
|------------------------|-----------:|-----------------:|
| Cold start             |    ~27.4 s |          ~0.13 s |
| Idle RAM (used)        |     225 MB |          7.5 MB  |
| On-disk size           |      3.4 GB |          1.33 GB |
| Process count (guest)  |        103 |                2 |

**Analysis.**
The number that surprised me most was the cold start: the VM needs **~27 seconds** to boot a full Linux kernel, systemd, and all its background services, while the container starts in **~0.13 seconds** — about 200× faster — because it shares the host kernel and only has to start one process. The process count explains the rest: the VM runs **103 processes** (systemd, sshd, cron, journald, …) just to exist and holds a whole guest of RAM, so it sits at **225 MB used**, while the container runs essentially the app alone (**2 processes**) and touches only **7.5 MB**. On disk the gap is smaller than expected — **3.4 GB vs 1.33 GB** — but only because I used the fat `golang:1.24` image, which ships the whole Go toolchain; a real production build (multi-stage, a tiny base like `distroless` or `alpine`) would shrink the container to tens of MB and widen the gap a lot. The VM is the right tool when you need **strong isolation, your own kernel, or a faithful copy of a real server** — which is exactly why Lab 7 deploys QuickNotes to this VM with Ansible. The container is the right tool for **stateless microservices** that must start fast and pack many to a host. This is why containers won the 2014–2020 microservice era: for a small stateless service, paying ~27 s of boot and a guest's worth of RAM and processes per instance is pure overhead, while a container gives near-instant start and an order-of-magnitude better density on the same hardware.
