# Lab 5 Submission
## Task 1
### Vagrantfile
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"
  config.vm.synced_folder "./app", "/home/vagrant/app", type: "virtualbox"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    echo "Downloading Go 1.24.0"
    apt-get update
    wget -q https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/vagrant/.profile
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/vagrant/.bashrc
    echo "Done"
  SHELL
end
```

### Vagrant up output
```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'ubuntu/jammy64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'ubuntu/jammy64'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/ubuntu/jammy64
==> default: Adding box 'ubuntu/jammy64' (v20241002.0.0) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/ubuntu/boxes/jammy64/versions/20241002.0.0/providers/virtualbox/unknown/vagrant.box
    default: 
==> default: Successfully added box 'ubuntu/jammy64' (v20241002.0.0) for 'virtualbox'!
```
### Verification inside the VM
```
vagrant ssh -c 'go version'
go version go1.24.0 linux/amd64
```
### Curl outputs from the host 
```
{"notes":6,"status":"ok"}
```
### Design Questions
**a) Synced folders:** 
```Text
I chose the virtualbox type (built-in shared folders). Type 2 hypervisors are designed for developer laptops. The virtualbox type works out-of-the-box on hosts, providing seamless access to the code without complex network configuration.
```
**b) Network mode:** 
```Text
We are using the NAT with port forwarding mode. NAT gives the VM internet access to download packages, and forwarding to 127.0.0.1 allows the host to reach QuickNotes. If we used Bridged mode, the VM would get an IP on the local network, and anyone on the same Wi-Fi could connect to it, which is insecure for a course lab environment.
```
**c) Provisioning options:** 
```Text
I used the shell provisioner. An inline shell script allows describing the entire configuration declaratively directly inside the Vagrantfile. It turns setup from "GUI clicking" into code that can be committed to Git.
```
**d) Pinned version:** 
```Text
The Go version is strictly pinned to 1.24.5 to ensure 100% reproducibility. Version pinning guarantees that a student running vagrant up a month from now will get an absolutely identical virtual machine.
```
## Task 2 

### Take Snapshot:
```Plaintext
vagrant snapshot save clean-go-install

==> default: Snapshotting the machine as 'clean-go-install'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```
### Break the VM:
```Plaintext
vagrant ssh -c 'sudo rm -rf /usr/local/go'
```
### Verify it's broken:
```Plaintext
vagrant ssh -c 'go version'

bash: line 1: go: command not found
```
### Restore & Time Measurement:
```Plaintext
time vagrant snapshot restore clean-go-install

real    0m26.950s
```
### Verify Recovery:
```Plaintext
vagrant ssh -c 'go version'

go version go1.24.0 linux/amd64
```
### Design Questions
**e) Snapshots are not backups:** 
```Text
Snapshots live on the same disk and share the same failure domain. In the event of a physical disk hardware failure, both the base VM image file and all its snapshots will be irretrievably lost.
```
**f) Copy-on-write:** 
```Text
The Copy-on-write mechanism means a snapshot does not duplicate the entire disk, but only writes the changed blocks (delta). If you take 10 snapshots, they will take up very little space initially, but every disk read will traverse the entire snapshot chain, which will catastrophically degrade disk I/O performance.
```
**g) When is snapshotting an antipattern:** 
```Text
Running a VM on a long chain of snapshots is an antipattern. The correct approach is to use snapshots transiently: take a snapshot, perform the risky action, verify it, and then explicitly delete it, committing the changes back to the base disk.
```
## Bonus Task
| Dimension | Vagrant VM (Ubuntu 22.04) | Docker container (golang:1.24) |
|---|---|---|
| **Cold start** | ~ 43.76 s | ~ 10.82 s |
| **Idle RAM** | 162 MiB | ~ 6.45 MiB |
| **On-disk size** | 3.03 GB | 894 MB |
| **Process count** | 103 | 2 |

**Questions:**
```Text
The most surprising numbers are the massive differences in RAM consumption, process count, and on-disk size. 

A virtual machine emulates a complete computer with its own OS kernel, so it boots dozens of system daemons, which requires gigabytes of disk space and tens of seconds to start. A container, on the other hand, shares the host kernel and runs only the application process itself, starting significantly faster. 
Virtual machines are the right tool for strong, hardware-level isolation and running full operating systems. Containers are ideal for stateless microservices, CI jobs, and local development environments. 

The baseline numbers in the table clearly explain why containers won the microservices era (2014-2020). The ability to run thousands of isolated applications on a single server with fast startup times and near-zero memory overhead made cloud architectures incredibly dense and cost-effective.
```