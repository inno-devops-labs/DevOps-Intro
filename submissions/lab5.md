# Lab 5 Submission

Host used for the run: Ubuntu 24.04.3 LTS x86_64 cloud server with nested KVM enabled. The committed `Vagrantfile` also keeps an Apple Silicon branch for ARM64 hosts.

## Task 1 - Vagrant Up + Run QuickNotes Inside

`Vagrantfile` is committed at the repository root. The important settings are:

```ruby
GO_VERSION = "1.24.5"

config.vm.box = "bento/ubuntu-24.04"
config.vm.box_version = "202510.26.0"
config.vm.box_architecture = "amd64"
config.vm.hostname = "quicknotes-vm"

config.vm.network "forwarded_port",
                  guest: 8080,
                  host: 18080,
                  host_ip: "127.0.0.1",
                  auto_correct: false

config.vm.synced_folder "./app",
                        "/opt/quicknotes/app",
                        type: "rsync",
                        rsync__exclude: [".git/", "data/"]

config.vm.provider "virtualbox" do |vb|
  vb.name = "quicknotes-lab5"
  vb.cpus = 2
  vb.memory = 1024
  vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
end
```

First lines from `vagrant up --provider=virtualbox`:

```text
Vagrantfile validated successfully.
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'bento/ubuntu-24.04'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'bento/ubuntu-24.04' version '202510.26.0' is up to date...
==> default: Setting the name of the VM: quicknotes-lab5
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
```

Verification:

```text
$ vagrant status --machine-readable
default,state,running
default,state-human-short,running

$ vagrant ssh -c "go version"
go version go1.24.5 linux/amd64

$ vagrant ssh -c "curl -s http://localhost:8080/health"
{"notes":4,"status":"ok"}

$ curl -s http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}

$ vagrant ssh -c "systemctl --no-pager --full status quicknotes.service | sed -n '1,12p'"
quicknotes.service - QuickNotes API
Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; preset: enabled)
Active: active (running)
Main PID: 3047 (quicknotes)
Memory: 1.2M
quicknotes listening on 0.0.0.0:8080 (notes loaded: 4)
```

### Design answers

a) I used `rsync` for the synced folder. It works reliably both on Linux and macOS hosts, avoids depending on matching VirtualBox Guest Additions, and is good enough for a source tree that only needs to be copied into the VM. The trade-off is that it is one-way and changes need `vagrant rsync` or another `vagrant up`/reload to resync.

b) The VM uses VirtualBox NAT with explicit port forwarding. Binding the forwarded port to `127.0.0.1` is safer than a bridged interface because the service is only reachable from the host, not from the whole network where the lab machine happens to run.

c) I used the shell provisioner. For this lab it is the smallest reproducible option: install pinned Go, build QuickNotes, and write one systemd unit. Ansible would be useful later in Lab 7, but here it would add another dependency without improving the result.

d) I pinned Go to `1.24.5` instead of `1.24` so that a clean `vagrant up` installs the same toolchain every time. A moving minor selector can change patch versions, compiler behavior, or standard-library fixes without a repository change.

## Task 2 - Snapshots: Save, Break, Restore

Commands and evidence:

```text
$ vagrant snapshot save quicknotes-clean
==> default: Snapshotting the machine as 'quicknotes-clean'...
==> default: Snapshot saved!

$ vagrant snapshot list
quicknotes-clean

$ vagrant ssh -c "sudo mv /usr/local/go /usr/local/go.broken && go version" || true
bash: line 1: go: command not found

$ vagrant ssh -c "go version" || true
bash: line 1: go: command not found

$ /usr/bin/time -p vagrant snapshot restore quicknotes-clean
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'quicknotes-clean'...
==> default: Machine booted and ready!
real 36.78
user 4.18
sys 4.55

$ vagrant ssh -c "go version"
go version go1.24.5 linux/amd64

$ curl -s http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
```

### Snapshot design answers

e) Snapshots are not backups because they usually live on the same host and storage stack as the VM. If the host disk dies, the VM directory is deleted, or the provider account is lost, the snapshot disappears with the VM.

f) Copy-on-write means a snapshot initially stores metadata and then records changed blocks after the snapshot point. Ten snapshots do not immediately use 10x disk, but long chains can accumulate many changed blocks and become expensive.

g) Snapshotting is an antipattern when it becomes a long-term release or backup strategy. Long snapshot chains slow down operations, make state harder to reason about, and hide the fact that the environment should be reproducible from code.

## Bonus - VM vs Container Resource Baseline

### VM measurements

```text
$ vagrant ssh -c "free -h"
Mem: 961Mi total, 299Mi used, 662Mi available
Swap: 2.9Gi total, 12Ki used

$ vagrant ssh -c "ps -A --no-headers | wc -l"
138

$ du -sh "/root/VirtualBox VMs/quicknotes-lab5"
2.7G

$ VBoxManage showvminfo quicknotes-lab5 --machinereadable
memory=1024
cpuexecutioncap=50
cpus=2
VMState="running"

$ /usr/bin/time -p vagrant halt
real 54.73

$ /usr/bin/time -p vagrant up --provider=virtualbox
real 217.63
```

### Docker measurements

Container command:

```bash
docker run -d --name qn-lab5 -p 28080:8080 \
  -v /root/devops-lab5/app:/src -w /src golang:1.24 \
  sh -c "CGO_ENABLED=0 GOTOOLCHAIN=local GOMAXPROCS=1 go build -p=1 -o /tmp/qn && /tmp/qn"
```

Evidence:

```text
$ curl -s http://127.0.0.1:28080/health
{"notes":4,"status":"ok"}

$ docker stats --no-stream qn-lab5
MEM USAGE / LIMIT: 55.95MiB / 3.824GiB
PIDS: 8

$ docker top qn-lab5
sh -c CGO_ENABLED=0 GOTOOLCHAIN=local GOMAXPROCS=1 go build -p=1 -o /tmp/qn && /tmp/qn
/tmp/qn

$ docker images golang:1.24 --format "{{.Repository}}:{{.Tag}} {{.Size}}"
golang:1.24 1.32GB

$ /usr/bin/time -p docker stop qn-lab5
real 10.20

$ /usr/bin/time -p docker start qn-lab5
real 0.19

$ docker stats --no-stream qn-lab5
MEM USAGE / LIMIT: 5.973MiB / 3.824GiB
PIDS: 8
```

| Dimension | Vagrant VM | Docker container |
|-----------|-----------:|-----------------:|
| Cold start | 217.63 s | 0.19 s |
| Idle RAM | 299 MiB used | 5.97-55.95 MiB used |
| On-disk size | 2.7 GiB VM folder | 1.32 GiB image |
| Process count | 138 guest processes | 2 app processes / 8 PIDs |

The cold-start gap was the least surprising number: the VM boots a full OS, while Docker restarts one isolated process tree. The RAM and process-count gap show why containers became the default for stateless microservices: they share the host kernel and do not carry a whole guest OS per service. The VM is still the better model when I need kernel isolation, a different OS image, or a long-lived machine boundary. For QuickNotes, the container is the right operational unit; the VM is useful here because Lab 7 will target it like a small server.
