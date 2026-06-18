	# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

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
    apt-get install -y wget curl golang-go
    
    cd /home/vagrant/app
    go build -o /home/vagrant/app/server .
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

