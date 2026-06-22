# Lab 5 Submission

## Task 1 - Vagrant Up + Run QuickNotes Inside

### Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/opt/quicknotes/app",
    type: "virtualbox",
    owner: "vagrant",
    group: "vagrant"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"

    apt-get update
    apt-get install -y curl ca-certificates tar build-essential

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    install -d -o vagrant -g vagrant /var/lib/quicknotes

    cd /opt/quicknotes/app
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .

    cat >/etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes API
After=network.target

[Service]
User=vagrant
Group=vagrant
WorkingDirectory=/opt/quicknotes/app
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/opt/quicknotes/app/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable quicknotes
    systemctl restart quicknotes
  SHELL
end
```

### First 10 lines of `vagrant up`

```text
mostafa@aorus-AORUS-15-BSF:~/git_repos/DevOps-Intro$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'ubuntu/jammy64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'ubuntu/jammy64'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/ubuntu/jammy64
==> default: Adding box 'ubuntu/jammy64' (v20241002.0.0) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/ubuntu/boxes/jammy64/versions/20241002.0.0/providers/virtualbox/unknown/vagrant.box
==> default: Successfully added box 'ubuntu/jammy64' (v20241002.0.0) for 'virtualbox'!
```

### Verification output

Go version inside the VM:

```bash
vagrant ssh -c 'go version'
```

```text
go version go1.24.5 linux/amd64
```

QuickNotes service status inside the VM:

```bash
vagrant ssh -c 'systemctl status quicknotes --no-pager'
```

```text
quicknotes.service - QuickNotes API
Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; vendor preset: enabled)
Active: active (running) since Mon 2026-06-22 19:44:47 UTC
Main PID: 4412 (quicknotes)
```

Health check from inside the VM:

```bash
vagrant ssh -c 'curl -s http://localhost:8080/health'
```

```json
{"notes":4,"status":"ok"}
```

Health check from the host through the forwarded port:

```bash
curl -s http://localhost:18080/health
```

```json
{"notes":4,"status":"ok"}
```

### Design questions

#### a) Synced folders

I used the VirtualBox synced folder type to mount the host `./app` directory into the guest at `/opt/quicknotes/app`. This is simple for a VirtualBox-based lab because file changes on the host are visible inside the VM without a manual sync step. The trade-off is that it depends on VirtualBox Guest Additions and can have portability or performance differences compared with `rsync`, while `rsync` is often more predictable but is mainly one-way from host to guest unless extra setup is added.

#### b) NAT vs Bridged vs Host-only

The VM uses NAT networking, which is Vagrant's default network mode, plus a forwarded port from host `127.0.0.1:18080` to guest `8080`. Binding the forwarded port to `127.0.0.1` makes QuickNotes reachable only from my host machine. This is safer than using a bridged interface because the VM is not directly exposed as a separate machine on the local network.

#### c) Provisioning options

I used the shell provisioner to install Go, build QuickNotes, and create the systemd service. Shell provisioning is enough for this lab because the setup is small, explicit, and easy to reproduce during `vagrant up`. Tools such as Ansible are better for larger configuration management tasks and will be used later in the course.

#### d) Why pin Go to a specific point release (`1.24.5`) instead of `1.24`?

Pinning Go to `1.24.5` makes the VM more reproducible. If the provisioner only requested `1.24`, two students could run the same lab at different times and receive different patch releases. A specific point release keeps the build environment stable and makes validation output easier to compare.

## Task 2 - Snapshots: Save, Break, Restore

### Commands and output

Initial host health check before taking the snapshot:

```bash
curl -s http://localhost:18080/health
```

```json
{"notes":4,"status":"ok"}
```

Snapshot save:

```bash
vagrant snapshot save quicknotes-clean
```

```text
==> default: Snapshotting the machine as 'quicknotes-clean'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```

Snapshot list:

```bash
vagrant snapshot list
```

```text
==> default:
quicknotes-clean
```

Deliberately breaking the VM by removing the Go installation and Go command links:

```bash
vagrant ssh -c 'sudo rm -rf /usr/local/go /usr/local/bin/go /usr/local/bin/gofmt'
```

Verification that the VM is broken:

```bash
vagrant ssh -c 'go version'
```

```text
bash: line 1: go: command not found
```

Timed restore from the snapshot:

```bash
time vagrant snapshot restore quicknotes-clean
```

```text
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'quicknotes-clean'...
==> default: Checking if box 'ubuntu/jammy64' version '20241002.0.0' is up to date...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
==> default: Machine booted and ready!
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.

real    0m20.208s
user    0m2.349s
sys     0m1.848s
```

Verification after restore:

```bash
vagrant ssh -c 'go version'
```

```text
go version go1.24.5 linux/amd64
```

Health check from inside the VM after restore:

```bash
vagrant ssh -c 'curl -s http://localhost:8080/health'
```

```json
{"notes":4,"status":"ok"}
```

Health check from the host after restore:

```bash
curl -s http://localhost:18080/health
```

```json
{"notes":4,"status":"ok"}
```

### Design questions

#### e) Snapshots are not backups

Snapshots are not backups because they usually depend on the same VM storage and host machine as the original VM. If the host disk fails, the VM directory is deleted, or the snapshot chain is corrupted, the snapshot may be lost with the VM. A real backup should be stored separately and should still be usable after failure of the original host or storage.

#### f) Copy-on-write

Copy-on-write means VirtualBox does not immediately duplicate the full VM disk when a snapshot is created. Instead, it keeps the original disk state and stores only the disk blocks that change after the snapshot. Ten snapshots can use much less space than ten full VM copies at first, but disk usage grows as more changes are made across the snapshot chain.

#### g) When is snapshotting an antipattern?

Snapshotting is an antipattern when long chains of snapshots become a substitute for reproducible provisioning and configuration management. Long snapshot chains can consume increasing disk space, slow down VM operations, and make recovery more fragile. For infrastructure work, it is usually better to rebuild a machine from code than to preserve one manually changed VM forever.

## Bonus Task - VM vs Container Resource Baseline

### Vagrant VM measurements

Cold boot:

```bash
time vagrant halt
time vagrant up
```

```text
real    0m8.304s
user    0m1.464s
sys     0m0.932s

real    0m26.550s
user    0m3.506s
sys     0m2.995s
```

Idle RAM:

```bash
vagrant ssh -c 'free -h'
```

```text
               total        used        free      shared  buff/cache   available
Mem:           957Mi       176Mi       578Mi       0.0Ki       202Mi       634Mi
Swap:             0B          0B          0B
```

Process count:

```bash
vagrant ssh -c 'ps -A --no-headers | wc -l'
```

```text
107
```

Disk size:

```bash
du -sh ~/VirtualBox\ VMs/quicknotes-lab5
```

```text
3.5G    /home/mostafa/VirtualBox VMs/quicknotes-lab5
```

### Docker container measurements

Container start command:

```bash
docker run -d --name qn-lab5-bonus -p 28080:8080 \
  -v "$PWD/app:/src" \
  -w /src \
  golang:1.24 \
  sh -c 'go build -o /tmp/qn && DATA_PATH=/tmp/notes.json SEED_PATH=/src/seed.json /tmp/qn'
```

Health check:

```bash
curl -s http://localhost:28080/health
```

```json
{"notes":4,"status":"ok"}
```

Cold start:

```bash
docker stop qn-lab5-bonus
time docker start qn-lab5-bonus
```

```text
qn-lab5-bonus

real    0m0.216s
user    0m0.016s
sys     0m0.008s
```

Idle RAM:

```bash
docker stats qn-lab5-bonus --no-stream
```

```text
CONTAINER ID   NAME            CPU %     MEM USAGE / LIMIT     MEM %     NET I/O         BLOCK I/O   PIDS
4f077f5d760a   qn-lab5-bonus   0.00%     6.742MiB / 15.31GiB   0.04%     4.52kB / 126B   0B / 0B     8
```

Process count:

```bash
docker top qn-lab5-bonus | tail -n +2 | wc -l
```

```text
2
```

On-disk image size:

```bash
docker images golang:1.24 --format '{{.Size}}'
```

```text
894MB
```

### Comparison

| Dimension             | Vagrant VM | Docker container |
|-----------------------|-----------:|-----------------:|
| Cold start            |    26.550s |           0.216s |
| Idle RAM              |      176Mi |         6.742MiB |
| On-disk size          |       3.5G |            894MB |
| Process count (guest) |        107 |                2 |

The biggest surprise was the startup-time difference: the Docker container restarted in less than a second, while the VM needed about 26.5 seconds to boot. The RAM and process-count numbers also show the cost of a full guest operating system, because the VM runs Ubuntu and system services while the container only runs the shell wrapper and QuickNotes process. A VM is the right tool when I need strong isolation, a full OS environment, kernel-level differences, or a server-like target for configuration management. A container is the better tool for stateless microservices because it starts quickly, consumes fewer resources, and packages the application runtime without booting a separate operating system. These measurements help explain why containers became popular from 2014 to 2020 for stateless services: teams could run and scale many lightweight application instances faster and cheaper than full VMs.
