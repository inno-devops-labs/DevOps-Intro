# Lab 5 submission

### vagrant file
```
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  config.vm.hostname = "quicknotes-vm"
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app",
    "/home/vagrant/app",
    type: "rsync"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL

    GO_VERSION="1.24.5"

    apt-get update

    apt-get install -y curl tar

    rm -rf /usr/local/go

    curl -LO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz

    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz

    cat >/etc/profile.d/go.sh <<EOF
export PATH=/usr/local/go/bin:$PATH
EOF

    export PATH=/usr/local/go/bin:$PATH

    go version

  SHELL

end
```

### First 10 lines of `vagrant up`

```
$ vagrant ssh                
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'bento/ubuntu-24.04' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'bento/ubuntu-24.04'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/bento/ubuntu-24.04
==> default: Adding box 'bento/ubuntu-24.04' (v202510.26.0) for provider: virtualbox (amd64)
    default: Downloading: https://vagrantcloud.com/bento/boxes/ubuntu-24.04/versions/202510.26.0/providers/virtualbox/amd64/vagrant.box
==> default: Successfully added box 'bento/ubuntu-24.04' (v202510.26.0) for 'virtualbox (amd64)'!
==> default: Importing base box 'bento/ubuntu-24.04'...
```

```
vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64
```

### From host port:

```
$ curl -s http://localhost:18080/health
{"notes":7,"status":"ok"}
```

### From guest port:

```
$ curl -s http://localhost:8080/health
{"notes":7,"status":"ok"}
```

### By ssh:

```
vagrant ssh -c 'curl -s http://localhost:8080/health'
{"notes":7,"status":"ok"}
```

## Breaking VM

```
vagrant snapshot save snapshot_for_lab
==> default: Snapshotting the machine as 'snapshot_for_lab'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```

### Check

```
vagrant ssh -c 'go version'               
bash: line 1: go: command not found
```

### restore output

```
time vagrant snapshot restore snapshot_for_lab
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'snapshot_for_lab'...
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
vagrant snapshot restore snapshot_for_lab  1,47s user 1,26s system 21% cpu 12,865 total
```

### Verify

```
vagrant ssh -c 'go version'    
go version go1.24.5 linux/amd64
```


## Questions

### a

I choose rsync as the synced folder type to mount host's `.app` directory. It's simple, reliable, helps to avoid some performance and permission issues

Trade-off: no real-live syncronisation

### b
Vagrant uses NAT by default. It allows VM acces external network while remaining isolated from other devices on local network. Binding the port forvaring rule to 127.0.0.1 is safer than using a bridged interface, because the application is only accessible from the local network and other devicec could connect directly to the application, unnecessarily becoming more vulnerable to attack

### c

I used the shell provisioner to install Go. The installation process only required a few commands: downloading the Go tarball, extracting it, and updating the PATH. The shell provisioner is the simplest solution for this task because it is built into Vagrant and does not require additional tooling or configuration. Tools such as Ansible, Puppet, or Chef are more suitable for larger and more complex infrastructure deployments.

### d

Pinning Go to 1.24.5 ensures that every student receives exactly the same compiler version and environment. If only 1.24 were specified, future patch releases could be installed automatically, potentially introducing different behavior, bug fixes, or dependency resolution results.

### e

Snapshot in on the same disk with VM. Disk broken - snapshot lost also. Disk formatted - no more snapshot.

### f

VirtualBox snapshots use a copy-on-write (CoW) mechanism. When a snapshot is created, the existing virtual disk is not duplicated. Instead, unchanged disk blocks are shared, and only new or modified blocks are stored separately after the snapshot is taken.

As a result, taking 10 snapshots does not immediately require 10 times the disk space of a single snapshot. Disk usage grows only as changes accumulate between snapshots. However, many snapshots can still consume significant storage over time if the VM's disk contents change frequently.

### g

Snapshotting becomes an antipattern when snapshots are kept for a long time and form long dependency chains. Each snapshot depends on previous disk states, which increases storage complexity and can reduce VM performance.

Long snapshot chains also make management more difficult and increase the risk that corruption of a parent snapshot affects all dependent snapshots. For long-term protection and recovery, proper backups and reproducible provisioning are preferable to maintaining many snapshots.