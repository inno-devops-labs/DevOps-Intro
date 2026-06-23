# Lab 5 Submission

## Task 1

### Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"
  config.vm.box_check_update = false
  config.vm.hostname = "quicknotes-lab5"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app", type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", privileged: true, inline: <<-'SHELL'
    set -euxo pipefail

    GO_VERSION="1.24.5"
    GO_ROOT="/usr/local/go"

    apt-get update
    apt-get install -y ca-certificates curl tar

    guest_arch="$(dpkg --print-architecture)"
    case "$guest_arch" in
      amd64)
        go_arch="amd64"
        go_sha256="10ad9e86233e74c0f6590fe5426895de6bf388964210eac34a6d83f38918ecdc"
        ;;
      arm64)
        go_arch="arm64"
        go_sha256="0df02e6aeb3d3c06c95ff201d575907c736d6c62cfa4b6934c11203f1d600ffa"
        ;;
      *)
        echo "Unsupported guest architecture: $guest_arch" >&2
        exit 1
        ;;
    esac

    archive="go${GO_VERSION}.linux-${go_arch}.tar.gz"
    url="https://go.dev/dl/${archive}"
    tmp_archive="/tmp/${archive}"

    installed_version=""
    if [ -x "${GO_ROOT}/bin/go" ]; then
      installed_version="$(${GO_ROOT}/bin/go version | awk '{print $3}')"
    fi

    if [ "$installed_version" != "go${GO_VERSION}" ]; then
      rm -rf "${GO_ROOT}"
      curl -fsSL "${url}" -o "${tmp_archive}"
      echo "${go_sha256}  ${tmp_archive}" | sha256sum --check --status
      tar -C /usr/local -xzf "${tmp_archive}"
      rm -f "${tmp_archive}"
    fi

    ln -sf "${GO_ROOT}/bin/go" /usr/local/bin/go
    ln -sf "${GO_ROOT}/bin/gofmt" /usr/local/bin/gofmt

    cat >/etc/profile.d/go.sh <<'EOF'
export PATH=/usr/local/go/bin:$PATH
EOF
  SHELL
end
```

### First 10 lines of `vagrant up`

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'bento/ubuntu-24.04' could not be found. Attempting to find and install...
  default: Box Provider: virtualbox
  default: Box Version: 202510.26.0
==> default: Loading metadata for box 'bento/ubuntu-24.04'
  default: URL: https://vagrantcloud.com/api/v2/vagrant/bento/ubuntu-24.04
==> default: Adding box 'bento/ubuntu-24.04' (v202510.26.0) for provider: virtualbox (arm64)
  default: Downloading: https://vagrantcloud.com/bento/boxes/ubuntu-24.04/versions/202510.26.0/providers/virtualbox/arm64/vagrant.box
Progress: 0% (Rate: 0*/s, Estimated time remaining: --:--:--)
Progress: 100% (Rate: 2/s, Estimated time remaining: --:--:--)
```

### `go version` inside the VM

```text
go version go1.24.5 linux/arm64
```

### `curl` output inside the VM

```text
{"notes":7,"status":"ok"}

HTTP_STATUS=200
```

### `curl` output from the host via port forwarding

```text
{"notes":7,"status":"ok"}

HTTP_STATUS=200
```

### Design answers

#### a) Synced folders

I used the `virtualbox` synced folder type. It is the simplest option here because it works with the VirtualBox provider directly, does not require extra host-side setup, and keeps the `app/` directory mounted live in both directions during development. The trade-off is file system performance: VirtualBox shared folders are usually slower than NFS for heavy I/O workloads, and less predictable than `rsync` for large trees, but for this small Go project they are the most practical choice.

#### b) NAT vs Bridged vs Host-only

I am using Vagrant's default NAT networking mode together with an explicit forwarded port from `127.0.0.1:18080` on the host to `8080` in the guest. Binding the forwarded port to `127.0.0.1` is safer than using a Bridged interface because only processes on the local host can reach the service; the VM does not appear as another machine on the LAN. For a course exercise, that reduces accidental exposure to other devices on the same network and avoids unnecessary attack surface.

#### c) Provisioning choice

I used the `shell` provisioner. For a single VM and one focused task, which is installing a pinned Go toolchain from the upstream tarball, shell is the smallest and most transparent solution. Tools such as Ansible, Puppet, or Chef would also work, but they add extra moving parts and setup cost that are not justified for one short, reproducible bootstrap step.

#### d) Why pin `1.24.5` instead of `1.24`

Pinning `1.24.5` makes the environment reproducible because every student gets the exact same compiler build, patches, and behavior. A floating `1.24` reference can silently resolve to different point releases over time, which can change bug fixes, security patches, or module resolution behavior and make results differ between machines or between submission dates.

## Task 2

### Exact commands run

```bash
vagrant snapshot save task2-go-1-24-5-working
vagrant ssh -c "sudo rm -rf /usr/local/go /usr/local/bin/go /usr/local/bin/gofmt"
vagrant ssh -c 'go version'
time vagrant snapshot restore task2-go-1-24-5-working
vagrant ssh -c 'go version'
```

### Snapshot save output

```text
==> default: Snapshotting the machine as 'task2-go-1-24-5-working'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```

### Broken state verification

```text
bash: line 1: go: command not found
```

### Restore time output

```text
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'task2-go-1-24-5-working'...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
  default: SSH address: 127.0.0.1:2222
  default: SSH username: vagrant
  default: SSH auth method: private key
==> default: Machine booted and ready!
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.
vagrant snapshot restore task2-go-1-24-5-working  1.31s user 0.76s system 16% cpu 12.770 total
```

### Recovery verification

```text
go version go1.24.5 linux/arm64
```

### Design answers

#### e) Why snapshots are not backups

Snapshots are tied to the same underlying VM disk chain and usually to the same host storage, so they do not protect you from host disk failure, accidental deletion of the VM files, or corruption of the entire VirtualBox VM directory. They are also a poor answer to broader disaster scenarios such as losing the laptop or damaging the base image metadata, because the snapshot disappears with the machine state it depends on.

#### f) Copy-on-write and disk usage

With copy-on-write snapshots, taking a snapshot does not duplicate the entire disk immediately. Instead, each snapshot preserves a point-in-time base and only stores blocks that change afterward. That means 10 snapshots do not cost 10 full VM disks up front, but they still accumulate extra delta files over time, and long-lived or heavily changed VMs can consume substantial disk space.

#### g) When snapshotting becomes an antipattern

Snapshotting becomes an antipattern when you build long chains of snapshots and start depending on them as a workflow instead of keeping environments reproducible from code. Long chains increase storage overhead, slow management operations, make recovery history harder to reason about, and create fragile stateful systems where nobody is sure which snapshot is the real source of truth.

## Bonus Task

### Comparison table

| Dimension | Vagrant VM | Docker container |
| --- | ---: | ---: |
| Cold start | 19.662 s | 0.172 s |
| Idle RAM | 214 MiB used of 824 MiB | 7.77 MiB |
| On-disk size | 3.3G | 1.32GB |
| Process count (guest) | 105 | 2 |

### Measurement notes

VM measurements came from `time vagrant up`, `vagrant ssh -c 'free -h'`, `vagrant ssh -c 'ps -A --no-headers | wc -l'`, and `du -sh "$HOME/VirtualBox VMs/quicknotes-lab5"`. Docker measurements came from `docker stop lab5-qn-bonus && time docker start lab5-qn-bonus`, `docker stats --no-stream`, `docker top lab5-qn-bonus`, and `docker images golang:1.24 --format 'IMAGE={{.Repository}}:{{.Tag}} SIZE={{.Size}}'`.

### Analysis

The biggest (but expectable) surprise was the gap in startup latency and background overhead: the container restarted in 0.172 seconds, while the VM took 19.662 seconds to boot, and the container used only 7.77 MiB of RAM versus 214 MiB already consumed inside the guest OS. The VM is the right tool when you need stronger OS-level isolation, a full init/system environment, or realistic testing of machine-level provisioning and configuration management. The container is the right tool for fast, repeatable packaging of a single stateless service where host-kernel sharing is acceptable and startup speed matters. These measurements show why containers dominated the 2014-2020 stateless microservice wave: they are dramatically cheaper to start, smaller to distribute, and lighter to run, so dense scheduling and rapid rollout are much easier than with full virtual machines.