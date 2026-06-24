<h1>Task 1</h1>

```vagrant --version```

Vagrant 2.4.9

```vagrant up --provider virtualbox```

Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'ubuntu/jammy64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'ubuntu/jammy64'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/ubuntu/jammy64
==> default: Adding box 'ubuntu/jammy64' (v20241002.0.0) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/ubuntu/boxes/jammy64/versions/20241002.0.0/providers/virtualbox/unknown/vagrant.box
==> default: Successfully added box 'ubuntu/jammy64' (v20241002.0.0) for 'virtualbox'!
==> default: Importing base box 'ubuntu/jammy64'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'ubuntu/jammy64' version '20241002.0.0' is up to date...
==> default: Setting the name of the VM: DevOps-Intro_default_1782309021968_643
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM..

<h2>Questions:</h2>

```a) Synced folders: Vagrant supports nfs, rsync, virtualbox, and smb mount types. Which did you pick and why? What's the trade-off?```

<b>rsync</b> - easy to setup ;)

```b) NAT vs Bridged vs Host-only: which network mode are you using (it's the default, but say which it is)? Why is 127.0.0.1-bound port forwarding safer than a Bridged interface for a course exercise?```

<b> NAT it's default mode for VirtuaBox.</b> 127.0.0.1 == localhost. This is safer for it's study exercise

```c) Provisioning options: Vagrant supports shell, ansible, ansible_local, puppet, chef, … which did you pick for installing Go and why?```

<b>shell-provisioning</b> does't require installation additional tools (Ansible, etc)

```d) Why pin Go to a specific point release (1.24.5) instead of 1.24?```

<b>1.2.4</b> it's major version


<h1>Task 2</h1>

```vagrant snapshot save working-state```

==> default: Snapshotting the machine as 'working-state'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.


```vagrant ssh -c 'go version'``

/usr/local/go/bin/go: No such file or directory


```time vagrant snapshot restore working-state```

real    0m3.404s
user    0m0.519s
sys     0m0.020s

```vagrant ssh -c 'go version'```

go version go1.24.5 linux/amd64

<h2>Questions:</h2>

```e) Snapshots are not backups. Explain why in 2-3 sentences — what failure modes is a snapshot useless for?```

<b>Snapshot</b> - for quick rollback. <b>Backup</b> - for long-term pretection and recovery. Must be regular backups on production version and use snapshots for safe experiments

```f) Copy-on-write: Vagrant snapshots are copy-on-write under VirtualBox. What does that mean for disk usage when you take 10 snapshots vs 1?```

<b>COW</b> - each snapshot only stores cnanges relative to previous state. Singe shapshot takes up signficantly more space as each snapshot stores its own chain of changes, and long chains can lead to performance issues due to the need to traverse all the deltas when reading

```g) When is snapshotting an antipattern? (Hint: long chains.)```

Long chains of snapshots (more than 3-5) become an <b>anti-pattern</b>: they greatly slow down the VM, take up a lot of disk space, and increase the recovery time. Also, snapshots should not be used as a version control system — Git and CI/CD are available for this purpose