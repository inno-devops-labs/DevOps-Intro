#### Lab 5 Submission

## Task 1 — Vagrant Up + Run QuickNotes Inside

### Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"
  
  config.vm.network "forwarded_port", 
    guest: 8080, 
    host: 18080, 
    host_ip: "127.0.0.1"
  
  config.vm.synced_folder "./app", "/home/vagrant/app"
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y wget curl
    
    wget https://go.dev/dl/go1.24.5.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.24.5.linux-amd64.tar.gz
    echo 'export PATH=/usr/local/go/bin:$PATH' >> /home/vagrant/.bashrc
    
    cd /home/vagrant/app
    /usr/local/go/bin/go build -o /home/vagrant/app/server .
    nohup /home/vagrant/app/server > /home/vagrant/server.log 2>&1 &
    
    echo "Server started on port 8080"
  SHELL
end


###First lines of vagrant up output
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Checking if box 'ubuntu/jammy64' version '20241002.0.0' is up to date...
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.

###curl outputs
From inside the VM:
$ vagrant ssh -c 'curl -s http://localhost:8080/health'
{"status":"ok","notes":4}

From the host (via port forward):
$ curl -s http://localhost:18080/health
{"status":"ok","notes":4}

Design Questions

a) Synced folders:
I used virtualbox synced folder type. It's the default and works without additional dependencies. The trade-off is it's slower than NFS, but for a simple Go application it's sufficient and requires no extra host configuration.

b) NAT vs Bridged vs Host-only:
I'm using NAT (the default network mode). Binding port 18080 to 127.0.0.1 is safer than Bridged because it only exposes the service locally on the host machine, not to the entire network. This prevents other students on the same network from accidentally accessing my VM.

c) Provisioning options:
I used the shell provisioner. It's the simplest approach for installing Go and building the application — no external config files or additional tools required. For a one-time setup like this, Ansible would be overkill.

d) Why pin Go to 1.24.5:
The Vagrantfile installs golang-go from Ubuntu repos, which provides Go 1.24.x. Pinning to 1.24.5 specifically ensures reproducibility — if 1.24 resolves to different patch versions over time, builds could break. 1.24.5 guarantees exactly the same version for everyone.



## Task 2 — Snapshots: Save, Break, Restore

### Commands Run

```bash
# Save snapshot
vagrant snapshot save working

# Break the VM — remove Go
vagrant ssh
sudo rm -rf /usr/local/go
sudo apt remove -y golang-go
exit

# Verify it's broken
vagrant ssh -c 'go version'
# Command 'go' not found

# Restore from snapshot with timing
time vagrant snapshot restore working

# Verify recovery
vagrant ssh -c 'go version'
# go version go1.24.5 linux/amd64

# Verify server is running
curl -s http://localhost:18080/health
# {"status":"ok","notes":4}


Restore Time
real    0m20.016s
user    0m3.634s
sys     0m2.044s

Design Questions
e) Snapshots are not backups:

Snapshots are stored on the same host disk and depend on the original VM disk. If the host disk fails, the snapshot is lost along with the VM. Backups are independent copies stored on separate media or off-site, which survive hardware failures.

f) Copy-on-write:

Copy-on-write means each snapshot only stores changes (deltas) from the previous state, not a full copy of the disk. With 10 snapshots, disk usage grows with each change, but slower than 10 full copies would. With 1 snapshot, disk usage is just the base disk plus one delta file.

g) When is snapshotting an antipattern:

Long snapshot chains (10+) are an antipattern because they degrade VM performance — each read must traverse the chain backwards. They also increase the risk of corruption, and deleting a middle snapshot can be expensive and time-consuming.

