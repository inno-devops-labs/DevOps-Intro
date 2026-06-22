# Lab 5 submission
### Vagrant file
[Link](../Vagrantfile)

### `vagrant up` log
```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'ubuntu/jammy64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: 20241002.0.0
==> default: Loading metadata for box 'ubuntu/jammy64'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/ubuntu/jammy64
==> default: Adding box 'ubuntu/jammy64' (v20241002.0.0) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/ubuntu/boxes/jammy64/versions/20241002.0.0/providers/virtualbox/unknown/vagrant.box
==> default: Successfully added box 'ubuntu/jammy64' (v20241002.0.0) for 'virtualbox'!
==> default: Importing base box 'ubuntu/jammy64'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'ubuntu/jammy64' version '20241002.0.0' is up to date...
==> default: Setting the name of the VM: DevOps-Intro_default_1782161451346_70730
...
==> default: Running provisioner: shell...
    default: Running: inline script
    default: Installing Go 1.24.5...
    default:   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
    default:                                  Dload  Upload   Total   Spent    Left  Speed
100    75  100    75    0     0     91      0 --:--:-- --:--:-- --:--:--    91
100 74.9M  100 74.9M    0     0  17.2M      0  0:00:04  0:00:04 --:--:-- 29.0M
    default: Installed Go 1.24.5.
```

### Verification
```sh
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64
```
From guest:
```sh
$ curl -s http://localhost:8080/health
{"notes":8,"status":"ok"}
```
From host:
```sh
$ curl -s http://localhost:18080/health                      
{"notes":8,"status":"ok"}
```
Via ssh:
```sh
vagrant ssh -c 'curl -s http://localhost:8080/health' 
{"notes":8,"status":"ok"}
```

### Snapshots
1) Save
```sh
$ vagrant snapshot save state1
==> default: Snapshotting the machine as 'state1'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```
2) Break
```sh
$ vagrant ssh -c 'sudo rm -rf /usr/local/go'
```
3) Verify
```sh
$ vagrant ssh -c 'go version'               
bash: line 1: go: command not found
```
4) Restore
```sh
$ time vagrant snapshot restore state1
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'state1'...
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
vagrant snapshot restore state1  0.80s user 0.23s system 9% cpu 10.325 total
```
5) Verify
```sh
$ vagrant ssh -c 'go version'    
go version go1.24.5 linux/amd64
```

### Design questions
**a)** I chose the **rsync** mount type because it is highly reliable, universally supported across different host operating systems, and doesn't require guest additions to be installed. The trade-off is that rsync is strictly one-way (host to guest) and does not sync changes automatically in real-time unless `vagrant rsync-auto` is running.\
**b)** By default, Vagrant uses **NAT** mode for the primary interface to allow the VM to access the internet. Binding the forwarded port to `127.0.0.1` is safer than a Bridged interface because it isolates the VM's network traffic to the host machine (`localhost`), preventing anyone else on the local Wi-Fi or physical network from accessing the unfinished or insecure course application.\
**c)** I picked the **shell** provisioner because it allows executing standard Bash commands directly, making it the simplest and most lightweight option for basic tasks like downloading and unpacking an archive. It eliminates the need to install heavy external configuration management tools like Ansible or Puppet inside the VM or on the host.\
**d)** Pinning Go to a exact point release (`1.24.5`) ensures build reproducibility and prevents breaking changes or unexpected bugs if a newer patch version is released later. It guarantees that everyone running `vagrant up` gets the exact same environment with identical dependency behavior and security patches.\
**e)** Snapshots are not backups because they rely on the parent disk and reside on the same physical hardware and storage system. If the host machine suffers a drive failure, or if the base virtual disk file (`.vdi`) becomes corrupted, the entire snapshot chain is lost instantly. Backups must be independent, isolated copies of data stored on a separate medium to survive hardware disasters.\
**f)** Under copy-on-write, taking a snapshot creates a new delta file that only stores subsequent changes, meaning taking 10 snapshots initially consumes almost no extra disk space compared to taking just 1. However, as the VM runs over time, modifying or deleting files forces data to be duplicated across these snapshot layers, which eventually causes disk usage to bloat significantly.\
**g)** Snapshotting becomes an antipattern when you maintain long, deeply nested snapshot chains over an extended period. This severely degrades VM disk I/O performance because VirtualBox has to traverse multiple delta layers to read a single file, while also increasing the risk of the entire VM breaking if any single snapshot in the chain gets corrupted.
