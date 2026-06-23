# Lab 5 Submission

## Task 1: Vagrant Up + Run QuickNotes Inside

### Vagrantfile

The [`Vagrantfile`](../Vagrantfile) in the repo root.

Pasted here for reference:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box      = "bento/ubuntu-24.04"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest: 8080, host: 18080, host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/home/vagrant/app"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "quicknotes-vm"
    vb.cpus   = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e
    GO_VERSION="1.24.5"
    GO_BIN="/usr/local/go/bin/go"

    if "${GO_BIN}" version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      echo "==> Go ${GO_VERSION} already installed — skipping download"
    else
      echo "==> Installing Go ${GO_VERSION}"
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf /tmp/go.tar.gz
      rm /tmp/go.tar.gz
    fi

    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh

    echo "==> $( ${GO_BIN} version )"
  SHELL
end
```

### First 10 lines of `vagrant up` output

```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'bento/ubuntu-24.04' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'bento/ubuntu-24.04'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/bento/ubuntu-24.04
==> default: Adding box 'bento/ubuntu-24.04' (v202510.26.0) for provider: virtualbox (amd64)
    default: Downloading: https://vagrantcloud.com/bento/boxes/ubuntu-24.04/versions/202510.26.0/providers/virtualbox/amd64/vagrant.box
    default:
==> default: Successfully added box 'bento/ubuntu-24.04' (v202510.26.0) for 'virtualbox (amd64)'!
```

### `curl` output — from inside the VM

```bash
vagrant ssh -c 'cd /home/vagrant/app && /usr/local/go/bin/go build -o /tmp/qn . && /tmp/qn &'
sleep 3
vagrant ssh -c 'curl -s http://localhost:8080/health'
```

```
{"notes":13,"status":"ok"}
```

### `curl` output — from the host (via port forward)

```bash
curl.exe -s http://localhost:18080/health
```

```
{"notes":13,"status":"ok"}
```

### Design questions

**a) **Synced folders:** Vagrant supports `nfs`, `rsync`, `virtualbox`, and `smb` mount types. Which did you pick and why? What's the trade-off?**

I used the default VirtualBox shared folder type (no explicit `type:` needed; Vagrant picks it automatically when the provider is VirtualBox). The host is Windows, which rules out NFS (requires an NFS server daemon, not available natively on Windows) and makes rsync require extra tooling (rsync is not in PATH on a plain Windows install, only available via WSL2 or Cygwin). SMB works on Windows but needs manual guest-side `cifs-utils` installation and credential handling. VirtualBox shared folders are built into the VirtualBox Guest Additions already present in the `bento/ubuntu-24.04` box, so they work out of the box with zero extra steps.

Trade-off: VirtualBox shared folders have noticeably higher I/O latency than NFS or rsync because every file operation crosses the VirtualBox host/guest boundary synchronously. For a Go build (`go build`), this matters because the compiler reads many small files; building inside the VM from the shared mount is slower than building from a native ext4 path. For this lab the bottleneck is the network download of the Go tarball, not I/O, so the trade-off is acceptable.

**b) **NAT vs Bridged vs Host-only:** which network mode are you using (it's the default, but say which it is)? Why is `127.0.0.1`-bound port forwarding safer than a Bridged interface for a course exercise?**

Vagrant's default network mode is **NAT**. The VM receives a private IP (typically in the `10.0.2.0/24` range) behind a NAT device managed by VirtualBox; the host reaches the guest only via configured port forwards.

Binding the forward to `127.0.0.1` (loopback) is safer than a Bridged interface for a course exercise because:
- **Bridged** puts the VM directly on the LAN with its own DHCP-assigned IP, making the service visible to every machine on the same network segment — classmates, campus Wi-Fi, etc. That turns a development service into a publicly reachable endpoint with no authentication.
- **NAT + 127.0.0.1 port forward** means only the local developer's machine can reach port 18080; the binding is not exposed to the LAN at all, eliminating accidental exposure.

**c) **Provisioning options:** Vagrant supports `shell`, `ansible`, `ansible_local`, `puppet`, `chef`, … which did you pick for installing Go and why?**

I used the **shell provisioner** (`config.vm.provision "shell"`). It requires no additional software on the host beyond Vagrant itself. The Go installation script is 10 lines of standard POSIX shell that any DevOps practitioner can read and audit at a glance.

Ansible (`ansible_local`) would be cleaner for a multi-role setup but adds the complexity of installing Ansible inside the VM before it can provision itself. Lab 7 will target this VM with Ansible from the host — using shell here keeps the separation clear: Vagrant brings up a clean OS, Ansible configures the application.

**d) **Why pin Go to a specific point release** (`1.24.5`) instead of `1.24`?**

There is no `go1.24.linux-amd64.tar.gz` — the Go distribution only publishes specific point releases (e.g. `go1.24.5`). Using a vague label like `1.24` in the provisioner script would require a resolver step (querying the Go download API, parsing JSON, picking the "latest" in the series), this adds complexity and a network dependency on that resolver at provision time.

More importantly, idempotency breaks without a fixed version: if the provisioner runs today and installs `1.24.4`, then the upstream "latest 1.24" advances to `1.24.5`, a second `vagrant provision` would detect a mismatch and re-download which wastes bandwidth and time. Pinning to `1.24.5` means the idempotency guard (`grep -q "go1.24.5"`) is deterministic. It also ensures every student gets the exact same binary regardless of when they run `vagrant up`, which is essential for reproducible course infrastructure.

---

## Task 2: Snapshots — Save, Break, Restore

### Commands and outputs

#### 1. Take a snapshot:
```bash
vagrant snapshot save clean-go-install
```
```bash
==> default: Snapshotting the machine as 'clean-go-install'...
==> default: Snapshot saved!
```
#### 2. Break the VM (Wipe Go):
```bash
vagrant ssh -c 'sudo rm -rf /usr/local/go'
```
(Completed with no output)

#### 3. Verify it's broken:
```bash
vagrant ssh -c 'go version'
```

```bash
Exit code 127
vagrant : bash: line 1: go: command not found
At line:1 char:106
+ ... SCodeProjects\DevOps-Intro"; vagrant ssh -c 'go version' 2>&1; Write- ...
+                                  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (bash: line 1: go: command not found:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
Exit code: 127
```


#### 4. Time the restore:

```powershell
Measure-Command { vagrant snapshot restore clean-go-install }
```
```
==> default: Forcing shutdown of VM...
==> default: Restoring the snapshot 'clean-go-install'...

Progress: 0%
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

Restore time: 23.549s
```

#### 5. Verify recovery:
```bash
vagrant ssh -c '/usr/local/go/bin/go version'
```
```bash
go version go1.24.5 linux/amd64
```

### Design questions

**e) Snapshots are not backups. Explain why in 2-3 sentences — what failure modes is a snapshot useless for?**

A snapshot is stored on the same physical disk as the VM, so a disk failure destroys both simultaneously. Snapshots also can't protect against logical corruption that predates the snapshot and restoring brings back the already-broken state. They are host-local with no off-site copy, offering no protection against fire, theft, or ransomware.

**f) Copy-on-write: Vagrant snapshots are copy-on-write under VirtualBox. What does that mean for disk usage when you take 10 snapshots vs 1?**

After the first snapshot the base VMDK becomes immutable; each subsequent snapshot adds a differencing image recording only changed blocks. With 1 snapshot the diff is near-empty. With 10, disk usage grows by the cumulative delta of all 10 states (potentially several GB), and restore time lengthens as VirtualBox must replay the entire diff chain.

**g) When is snapshotting an antipattern?**

Long snapshot chains degrade I/O performance because VirtualBox reads through every level of the diff chain on each disk access, and migration becomes difficult since all ancestor diffs must travel with the VM. In production, VMs should be cattle — destroyed and rebuilt from a versioned base image (Packer/cloud AMI) rather than kept alive through accumulated snapshots.