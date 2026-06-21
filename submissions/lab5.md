# Lab 5 Submission

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # 1. Box: Ubuntu 22.04 LTS
  config.vm.box = "ubuntu/jammy64"

  # 2. Hostname
  config.vm.hostname = "quicknotes-vm"

  # 3. Boot timeout
  config.vm.boot_timeout = 600

  # 4. Port forwarding: host 18080 -> guest 8080
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  # 5. Synced folder
  config.vm.synced_folder "./app", "/opt/quicknotes/app"

  # 6. Resources
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  # 7. Provision: install Go 1.24.5
  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    GO_VERSION=1.24.5
    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tgz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tgz
    fi
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    /usr/local/go/bin/go version
  SHELL
end
```

### Verification
```bash
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64

$ curl -s http://localhost:18080/health
{"notes":7,"status":"ok"}
```
### Design Questions
```text

a) Synced folders: which did you pick and why?

I used the default VirtualBox shared folders because they work on Windows without requiring additional tools like rsync. The trade-off is that VirtualBox shared folders are slower than NFS, but they are simpler to set up.

b) Network mode: which are you using and why?

By default, Vagrant uses NAT networking. Port forwarding is bound to 127.0.0.1, which means the service is only accessible from the host machine. This is safer than using a bridged interface, which would expose the VM to the local network.

c) Provisioning: which did you pick and why?

I used the shell provisioner because it is simple, works without external dependencies, and reliably installs Go with a specific version.

d) Why pin Go to 1.24.5 instead of 1.24?

Pinning a specific point release (1.24.5) ensures reproducibility. 1.24 could resolve to different minor versions on different days, potentially introducing inconsistencies.
```

## Task 2 — Snapshots

### Commands

```bash
$ vagrant snapshot save working-state
==> default: Snapshotting the machine as 'working-state'...
==> default: Snapshot saved!

$ vagrant ssh -c 'sudo rm -f /usr/local/go/bin/go'
$ vagrant ssh -c 'go version'
bash: go: command not found

$ Measure-Command { vagrant snapshot restore working-state }

Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 39
Milliseconds      : 363
Ticks             : 393633499
TotalDays         : 0,000455594327546296
TotalHours        : 0,0109342638611111
TotalMinutes      : 0,656055831666667
TotalSeconds      : 39,3633499
TotalMilliseconds : 39363,3499

$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64
```

### Restore time
```text
~39 seconds
```

### Verification after restore
```bash
$ vagrant ssh -c 'cd /opt/quicknotes/app && go run .'
2026/06/21 21:56:15 quicknotes listening on :8080 (notes loaded: 7)

$ curl.exe -s http://localhost:18080/health
{"notes":7,"status":"ok"}
```

### Design Questions
e) Snapshots are not backups. Why?

Snapshots are stored on the same physical disk as the VM. If the host disk fails, both the VM and all its snapshots are lost. Backups are stored separately and protect against hardware failure.

f) Copy-on-write: what does it mean for disk usage?

Each snapshot stores only the changes (deltas) from the previous state. Ten snapshots take more disk space than one because each snapshot retains its own set of changes.

g) When is snapshotting an antipattern?

Long chains of snapshots (more than 3) degrade performance because the VM has to traverse the chain to read data. They also consume significant disk space and are not suitable for production environments.

## Bonus Task — VM vs Container Resource Baseline

### Measurements

| Dimension              | Vagrant VM | Docker container |
|------------------------|-----------:|-----------------:|
| Cold start             |     13.64s |             2.78s |
| Idle RAM               |    166 MiB |          117.5 MiB |
| On-disk size           |   2.37 GB |            903 MB |
| Process count (guest)  |       104 |                2 |

*Note: Docker image size shown is for the `golang:1.24` base image; multiple sizes appear due to other images on the system.*

### Analysis

The data clearly shows why containers won the 2014–2020 era for stateless microservices. The Docker container starts **~5× faster** than the VM, uses **~30% less RAM**, and has **~2.6× smaller on-disk footprint**. The VM also runs **52× more processes**, reflecting the full OS overhead of a virtualized system.

These numbers highlight the key architectural difference: VMs virtualize **hardware**, while containers share the **host kernel**. For stateless workloads that need rapid scaling and resource efficiency, containers are the superior choice. However, for **stateful workloads** that require strong isolation, dedicated resources, or legacy OS support, VMs remain the right tool.

This explains industry trends: containers power modern microservices (Kubernetes, serverless), while VMs continue to host databases, legacy enterprise applications, and multi-tenant workloads where isolation is critical.