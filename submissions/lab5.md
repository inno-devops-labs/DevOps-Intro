# Lab 5 Solution


## Task 1

### 1. Vagrantfile
```Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e

    GO_VERSION="1.24.5"

    if ! command -v go >/dev/null 2>&1 || [ "$(go version)" != "go version go${GO_VERSION} linux/amd64" ]; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
        -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi

    if ! grep -q '/usr/local/go/bin' /etc/profile.d/go.sh 2>/dev/null; then
      cat > /etc/profile.d/go.sh <<'EOF'
export PATH=/usr/local/go/bin:$PATH
EOF
    fi
  SHELL
end
```


### 2. First 10 ```vargant up``` output strings

```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Checking if box 'ubuntu/jammy64' version '20241002.0.0' is up to date...
==> default: Clearing any previously set forwarded ports...
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
    default: Warning: Connection reset. Retrying...
==> default: Machine booted and ready!
```


### 3. Design Questions
#### a) Synced folders

I used VirtualBox shared folders:

```config.vm.synced_folder "./app", "/home/vagrant/app"```

This is simple because the host app directory is available inside the VM. The trade-off is that shared folders can have worse filesystem performance than approaches such as rsync

#### b) NAT vs Bridged vs Host-only

The VM uses the default NAT networking mode. Port forwarding exposes guest port 8080 through host port 18080, but binds the host side to 127.0.0.1. Binding to 127.0.0.1 means the service is accessible from the local host. A bridged interface would place the VM directly on the surrounding network and would expose another network interface.

#### c) Provisioning options

I used the Vagrant shell provisioner because installing Go requires only a small number of commands. The provisioner downloads the pinned Go archive, extracts it into /usr/local, and configures the PATH.

#### d) Why pin Go to 1.24.5?

A specific point release makes the environment reproducible. So we can reproduce environment on other machine exactly.


### 4. Verification
![img.png](img.png)
![img_1.png](img_1.png)
![img_2.png](img_2.png)



## Task 2

### 1. Save
```vagrant snapshot save lab5-clean```
```
==> default: Snapshotting the machine as 'lab5-clean'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using vagrant snapshot restore. You can delete it using
==> default: vagrant snapshot delete.
```

### 2. Break
```vagrant ssh -c "sudo rm -rf /usr/local/go"```

### 3. Verification
```vagrant ssh -c "go version"```
```
bash: line 1: go: command not found
```

### 4. Restore
```Measure-Command { vagrant snapshot restore lab5-clean }```
```
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 36
Milliseconds      : 98
Ticks             : 360988780
TotalDays         : 0,000417811087962963
TotalHours        : 0,0100274661111111
TotalMinutes      : 0,601647966666667
TotalSeconds      : 36,098878
TotalMilliseconds : 36098,878
```

### 5. Verification
```vagrant ssh -c "go version"```
```
go version go1.24.5 linux/amd64
```

### 6. TotalSeconds: 36,098878

### 7. Design Questions
#### e) Snapshots are not backups

A snapshot depends on the VM storage and virtualization system. If the host disk or the snapshot storage is lost or corrupted, the snapshot may also be lost. A snapshot also does not replace independent backups of important data.

#### f) Copy-on-write

One snapshot does not necessarily duplicate the entire disk immediately, but multiple snapshots can accumulate additional changed blocks.

#### g) When is snapshotting an antipattern?

Snapshotting can become an antipattern when a long chain of snapshots is used instead of maintaining reproducibility and proper backups. Long chains increase storage usage and operational complexity and can make lifecycle management harder.


## Bonus Task

| Dimension              | Vagrant VM | Docker container |
|------------------------|-----------:|-----------------:|
| Cold start             |     13.4 s |            0.4 s |
| Idle RAM               |   180  MiB |          7.1 MiB |
| On-disk size           |     2.0 GB |           885 MB |
| Process count (guest)  |        103 |                2 |


### What figures surprised you?
I was most surprised by the incredible speed and the reduction in the number of processes, especially when compared to Vagrant. These are truly very significant changes.
### For which workloads is each model a suitable tool?
A virtual machine is best suited for tasks where you need to fully deploy a separate operating system or perform operations on the kernel.
A container, on the other hand, is needed for more down‑to‑earth tasks, such as deploying an API, running several simple processes simultaneously, and testing individual microservices.
### What do the data say about why containers emerged as the winner in the 2014–2020 era for stateless microservices?
Containers won precisely because of their ease of use and speed in small processes. Many tasks that were previously assigned to VMs have now shifted to containers, as VM resources for them have simply become redundant.
