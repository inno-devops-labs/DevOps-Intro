# lab 5 submission

# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

Environment:
* Host System: Windows 10
* Git: 2.54.0.windows.1
* VirtualBox: 7.2.6
* Vagrant: 2.4.9
* VPN: enabled (required to access Vagrant Cloud from Russia)

---

## Task 1 — Vagrant up + run QuickNotes inside

### 1.1 Requirements implementation

| Requirement     | Implementation                        |
| --------------- | ------------------------------------- |
| Ubuntu LTS      | `bento/ubuntu-24.04`                  |
| Hostname        | `quicknotes-vm`                       |
| Port forwarding | `127.0.0.1:18080 -> 8080`             |
| Shared folder   | `./app -> /opt/quicknotes/app`        |
| CPU             | 2                                     |
| RAM             | 1024 MB                               |
| Go installation | Go 1.24.5                             |
| Reproducibility | Fixed Ubuntu box and fixed Go version |

### 1.3-1.4 Launch and Verification

First 10 lines of vagrant up:
```text
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

Check Go version:
```bash
vagrant@quicknotes-vm:~$ go version
go version go1.24.5 linux/amd64
```

Check mounted application directory:
```bash
vagrant@quicknotes-vm:~$ ls /opt/quicknotes/app
go.mod  
handlers.go  
handlers_test.go  
main.go  
Makefile  
README.md  
seed.json  
store.go  
store_test.go
```

Run QuickNotes:
```bash
vagrant@quicknotes-vm:~$ cd /opt/quicknotes/app
vagrant@quicknotes-vm:/opt/quicknotes/app$ go run .
2026/06/21 17:54:06 quicknotes listening on :8080 (notes loaded: 4)
```

Check from host machine:
```powershell
curl.exe http://localhost:18080/health
{"notes":4,"status":"ok"}
```

Check from inside the VM:
```bash
vagrant@quicknotes-vm:/opt/quicknotes/app$ curl http://localhost:8080/health
{"notes":4,"status":"ok"}
```

## 1.2 Design questions

### a) Synced folders: Vagrant supports nfs, rsync, virtualbox, and smb mount types. Which did you pick and why? What's the trade-off?

I used the default **VirtualBox shared folder** implementation (`config.vm.synced_folder`). 
It does not require any additional configuration on the host machine and works out of the box with VirtualBox Guest Additions. 
It also provides live synchronization between the host `./app` directory and the guest `/opt/quicknotes/app` directory.
The trade-off is that VirtualBox shared folders may have lower performance for intensive file operations
and can sometimes have permission or symbolic link limitations. Alternatives such as NFS 
provide better performance but require additional host configuration, especially on Windows.

### b) NAT vs Bridged vs Host-only: which network mode are you using (it's the default, but say which it is)? Why is 127.0.0.1-bound port forwarding safer than a Bridged interface for a course exercise?

The virtual machine uses the default **NAT** networking mode with port forwarding.
Using `127.0.0.1`-bound port forwarding is safer than a Bridged interface because 
the QuickNotes application is accessible only from the local host machine. 
Other devices on the local network cannot directly access the service.
With a Bridged interface, the VM would obtain its own IP address on the local network 
and could become accessible to other devices, which is unnecessary and less secure for a laboratory exercise.

### c) Provisioning options: Vagrant supports shell, ansible, ansible_local, puppet, chef, … which did you pick for installing Go and why?

I used the **shell provisioner**.
The shell provisioner is sufficient for this task because only a single dependency (Go) needs to be installed. 
It is simple, lightweight, and does not require installing additional configuration management tools.
More advanced provisioners such as Ansible, Puppet, 
or Chef are useful for larger infrastructures but would unnecessarily complicate this laboratory work.

### d) Why pin Go to a specific point release (1.24.5) instead of 1.24?

I pinned Go to the exact version **1.24.5** to ensure reproducibility.
Using a generic version such as `1.24` may result in different patch versions being installed over time. 
Pinning the exact version guarantees that every `vagrant up` 
installs the same Go release and produces identical results regardless of when the laboratory is executed.

### Result

QuickNotes successfully runs inside the Ubuntu VM 
and is accessible from the Windows host through NAT port forwarding.

The screenshot below demonstrates:
- Successful response from `curl http://localhost:8080/health`
- Successful response from `curl.exe http://localhost:18080/health` on the Windows host

![Task 1 verification](proof1.png)