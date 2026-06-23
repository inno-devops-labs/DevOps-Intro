# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

The Vagrantfile is located in the root of the repository.

### Verification from Host Machine

curl -s http://localhost:18080/health
{"notes":6,"status":"ok"}

### Verification from Inside the VM

vagrant ssh -c 'curl -s http://localhost:8080/health'
{"notes":6,"status":"ok"}

### Go Version Output

vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64

### First Few Lines of vagrant up Output

Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'ubuntu/jammy64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'ubuntu/jammy64'
    default: URL: https://vagrantcloud.com/ubuntu/jammy64
==> default: Adding box 'ubuntu/jammy64' (v20241002.0.0) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/ubuntu/boxes/jammy64/versions/20241002.0.0/providers/virtualbox/unknown/vagrant.box
==> default: Successfully added box 'ubuntu/jammy64' (v20241002.0.0) for 'virtualbox'!
==> default: Importing base box 'ubuntu/jammy64'...

### Answers to Design Questions

a) Synced folders:

I chose the virtualbox mount type because it works out of the box without requiring any additional setup. Unlike rsync, it does not require manual synchronization, and NFS is more difficult to configure on Windows. For a small project with just a few files, this is the most practical choice.

b) Network mode:

I am using NAT with port forwarding bound to 127.0.0.1. This is safer than using a Bridged adapter because the VM does not get its own IP address on the local network, the port forwarding is restricted to localhost only, and the VM remains isolated from other devices on the network. This is the standard approach for development environments.

c) Provisioning:

I used the shell provisioner because it is the simplest way to install Go on a single VM. It does not require installing Ansible, Puppet, or any other configuration management tools. For a small lab assignment, this approach is completely sufficient.

d) Why pin Go to version 1.24.5:

Pinning to a specific patch version ensures reproducibility. Using go1.24 without a patch number could resolve to different versions over time (1.24.5, 1.24.6, etc.), which might introduce unexpected differences. For educational purposes, it is important that all students work with exactly the same version.

## Task 2 — Snapshots

### Commands and Output

vagrant snapshot save working
==> default: Snapshotting the machine as 'working'...
==> default: Snapshot saved!

vagrant ssh -c 'sudo rm -rf /usr/local/go'

vagrant ssh -c 'go version'
bash: line 1: go: command not found

time vagrant snapshot restore working
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'working'...
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

real    0m16.153s
user    0m1.420s
sys     0m0.748s

vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64

curl -s http://localhost:18080/health
{"notes":6,"status":"ok"}

### Snapshot Restore Time

Real: 0m16.153s
User: 0m1.420s
Sys: 0m0.748s

### Answers to Design Questions

e) Snapshots are not backups:

Snapshots are not backups because they depend on the parent disk and only store changes. They are useless if the physical disk becomes corrupted, if the base box image is lost, or if there is hardware failure. Backups can be restored on a different system, while snapshots cannot.

f) Copy-on-write:

Copy-on-write means that when a snapshot is created, only the changes are saved rather than making a full copy of the entire disk. With 10 snapshots, the total disk usage will grow more slowly compared to having 10 full copies, but performance will decrease because the system has to check the entire snapshot chain when reading data.

g) When is snapshotting an antipattern:

Long snapshot chains (more than 3-5) are an antipattern for production environments because they significantly reduce I/O performance, increase the risk of corruption during failures, complicate disk space management, and make rollback operations more difficult.
