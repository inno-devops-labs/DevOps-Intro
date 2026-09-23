# Task 1.
## 1.1. Vagrant file
```
GO_INSTALL = <<~SCRIPT
  set -e
  GO_VERSION=1.24.5
  if [ ! -x /usr/local/go/bin/go ]; then
    curl -fsSLO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
  fi
  echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/go.sh
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "cloud-image/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: GO_INSTALL
end
```
## 1.2 Questions
a) **Synced folders.** I picked virtualbox because I'm using windows and it's easy to setup. Other boxes are harder to setup or it's too complex to make them work on windows. The tradeoff is that it's slower with the big amount of files or with large projects. In my case - It wasn't important because the project is quite small. \
b) **NAT vs Bridged vs Host-only.** I'm using default Vagrant network mode - NAT. Binding to 127.0.0.1 means that only host can see the port. In bridged interface, everyone in local network would have access to the port 8080. \
c) **Provisioning options.** I picked shell because it is the simples variant to install Go. Ansible, Puppet, Chef, e.t.c. would be much harder to configure, while providing zero benefit. \
d) **Why pin Go to a specific point release (1.24.5) instead of 1.24?** To make the environment reproducible. Using 1.24 will install latest release, but that basically means that untested version will be installed, which is risky, because it may result in app breaking.
## 1.4

```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ vagrant ssh -c "curl -s http://localhost:8080/health"
{"notes":7,"status":"ok"}

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ curl http://localhost:18080/health
{"notes":7,"status":"ok"}


Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'cloud-image/ubuntu-24.04' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'cloud-image/ubuntu-24.04'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/cloud-image/ubuntu-24.04
==> default: Adding box 'cloud-image/ubuntu-24.04' (v20260911.0.0) for provider: virtualbox (amd64)
    default: Downloading: https://vagrantcloud.com/cloud-image/boxes/ubuntu-24.04/versions/20260911.0.0/providers/virtualbox/amd64/vagrant.box
    default:
==> default: Successfully added box 'cloud-image/ubuntu-24.04' (v20260911.0.0) for 'virtualbox (amd64)'!
==> default: Importing base box 'cloud-image/ubuntu-24.04'...
==> default: Generating MAC address for NAT networking...
==> default: Checking if box 'cloud-image/ubuntu-24.04' version '20260911.0.0' is up to date...
==> default: Setting the name of the VM: quicknotes-lab5
```

```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ vagrant ssh -c "curl -s http://localhost:8080/health"
{"notes":7,"status":"ok"}

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ curl http://localhost:18080/health
{"notes":7,"status":"ok"}
```

# Task 2
## Task 2.1
### Making the snapshot
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ vagrant snapshot save clean-state
==> default: Snapshotting the machine as 'clean-state'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```
### Deleting Go
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ vagrant ssh -c "sudo rm -rf /usr/local/go"
```
### Go was, in fact, deleted
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ vagrant ssh -c "go version"
bash: line 1: go: command not found
```
### Restoring the snapshot and measuring time
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ time vagrant snapshot restore clean-state
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'clean-state'...
==> default: Checking if box 'cloud-image/ubuntu-24.04' version '20260911.0.0' is up to date...
==> default: Resuming suspended VM...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
==> default: Machine booted and ready!
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.

real    0m22.536s
user    0m0.046s
sys     0m0.031s
```
### Go is working
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ vagrant ssh -c "go version"
go version go1.24.5 linux/amd64
```
### Deleting the snapshot
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ vagrant snapshot delete clean-state
==> default: Deleting the snapshot 'clean-state'...
==> default: Snapshot deleted!
```
## Task 2.2
e) **Snapshots are not backups.** Snapshot is basically useles if the VM itself has died. That's because it's stored in the VM storage. \
f) **Copy-on-write.** Taking 10 snapshots instead of 1 doesn't mean that they will weight the same as 10 discs. The total weight will be 1 disc plus what exactly has changed in each snapshot. \
g) **When is snapshotting an antipattern?** When a lot of snapshots are taken in one chain it becomes an antipattern. Each new snapshot saves another state of the disc, the risk of corrupting the chain grows and recovering becomes more confusing and complex. It's better to use snapshots for quick tests and then restore or delete them.

# Bonus task

Here are the measurements and the table below them
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ time vagrant halt
==> default: Attempting graceful shutdown of VM...

real    0m16.223s
user    0m0.000s
sys     0m0.015s

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ time vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Checking if box 'cloud-image/ubuntu-24.04' version '20260911.0.0' is up to date...
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
    default: Warning: Connection aborted. Retrying...
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
    default: The guest additions on this VM do not match the installed version of
    default: VirtualBox! In most cases this is fine, but in rare cases it can
    default: prevent things such as shared folders from working properly. If you see
    default: shared folder errors, please make sure the guest additions within the
    default: virtual machine match the version of VirtualBox you have installed on
    default: your host and reload your VM.
    default:
    default: Guest Additions Version: 6.0.0 r127566
    default: VirtualBox Version: 7.2
==> default: Setting hostname...
==> default: Mounting shared folders...
    default: C:/Users/thebruh/Desktop/DevOpsCourse/DevOps-Intro/app => /home/vagrant/app
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.

real    1m19.395s
user    0m0.000s
sys     0m0.015s

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ vagrant ssh -c "free -h"
               total        used        free      shared  buff/cache   available
Mem:           961Mi       305Mi       593Mi       1.1Mi       205Mi       656Mi
Swap:             0B          0B          0B

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ vagrant ssh -c "ps -A --no-headers | wc -l"
94

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ du -sh ~/VirtualBox\ VMs/quicknotes-lab5
2.3G    /c/Users/thebruh/VirtualBox VMs/quicknotes-lab5
```

```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ time docker start qn
qn

real    0m0.562s
user    0m0.090s
sys     0m0.046s

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ curl -s http://localhost:28080/health
{"notes":7,"status":"ok"}

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ curl -s http://localhost:28080/health
{"notes":7,"status":"ok"}

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ docker stats --no-stream qn
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O     PIDS
f42633e3f495   qn        0.00%     24.37MiB / 15.57GiB   0.15%     2.23kB / 1.02kB   84.2MB / 0B   9

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ docker top qn
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
root                3333                3308                0                   21:41               ?                   00:00:00            sh -c go build -o /tmp/qn . && /tmp/qn
root                3600                3333                0                   21:41               ?                   00:00:00            /tmp/qn

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab5)
$ docker images --format "{{.Size}}" golang:1.24
1.32GB
```

| Dimension              | Vagrant VM | Docker container |
|------------------------|-----------:|-----------------:|
| Cold start             |     79.4 s |           0.56 s |
| Idle RAM               |     305 MB |        24.4 MB   |
| On-disk size           |     2.3 GB |        1.32 GB   |
| Process count (guest)  |         94 |                2 |

## Which numbers surprised me?
Cold start, Docker launched 160x times faster. Also Doker spends much less RAM, weighs two times less and has only 2 processes, instead of 94
## For what workloads is each model the right tool?
Containers are good for trusted services that require quick start and robustness. VMs are needed when full core isolation is wanted, when you want environment that is close to real OS or if you launch untrusted code, that basically guarantees full isolation, even malware wouldn't be able to escape, maybe besides some military-grade spyware that utilizes extremely complicated VM vulnerabilities to escape it
## What does the data say about why containers won the 2014-2020 era for stateless microservices?
Data clearly shows why. Containers start in tenths of seconds, use an order of magnitude less memory and weigh less.