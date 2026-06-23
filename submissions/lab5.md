# Lab 5 Submission - Virtualization: QuickNotes in a Vagrant VM

---

## Task 1 - Vagrant Up + Run QuickNotes Inside

### 1.1 Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  # Vagrant base box for Ubuntu 22.04 LTS
  config.vm.box     = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"

  # Forward host port 18080 -> guest port 8080, bound to localhost only
  config.vm.network "forwarded_port",
    guest: 8080,
    host:  18080,
    host_ip: "127.0.0.1"

  # Sync the app/ directory into the VM
  config.vm.synced_folder "./app", "/home/vagrant/app"

  # VirtualBox resource caps (Lecture 5: don't over-provision)
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus   = 2
    vb.name   = "quicknotes-vm"
  end

  # Shell provisioner: install Go 1.24.4 on first vagrant up
  config.vm.provision "shell", inline: <<-SHELL
    set -e

    GO_VERSION="1.24.4"
    GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"

    if [ ! -f /usr/local/go/bin/go ]; then
      echo "==> Downloading Go ${GO_VERSION}..."
      curl -fsSL "https://go.dev/dl/${GO_TARBALL}" -o "/tmp/${GO_TARBALL}"

      echo "==> Installing Go to /usr/local..."
      rm -rf /usr/local/go
      tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
    else
      echo "==> Go already installed, skipping download..."
    fi

    echo "==> Adding Go to PATH for all users..."
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.env
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/vagrant/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
    chmod +x /etc/profile.d/go.env

    echo "==> Go installed: $(  /usr/local/go/bin/go version)"
    echo 'PATH=/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' > /etc/environment
  SHELL
end
```

### 1.2 vagrant up log (first 10 lines)

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'ubuntu/jammy64'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'ubuntu/jammy64' version '20241002.0.0' is up to date...
==> default: Setting the name of the VM: quicknotes-vm
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

```

### 1.3 curl outputs from inside the VM

```text
vagrant@quicknotes-vm:~$ curl -s http://localhost:8080/health
{"notes":9,"status":"ok"}
```

### 1.4 curl outputs from the host (via port forward)

```text
$ curl -s http://localhost:18080/health | python3 -m json.tool
{
    "notes": 9,
    "status": "ok"
}

$ curl -s http://localhost:18080/notes | python3 -m json.tool
[
    {
        "id": 1,
        "title": "Welcome to QuickNotes",
        "body": "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.",
        "created_at": "2026-01-15T10:00:00Z"
    },
    {
        "id": 2,
        "title": "Read app/main.go first",
        "body": "Start by understanding the entry point \u2014 env vars, signal handling, graceful shutdown.",
        "created_at": "2026-01-15T10:05:00Z"
    },
    {
        "id": 9,
        "title": "trace me",
        "body": "in flight",
        "created_at": "2026-06-17T03:38:11.742124301Z"
    },
    {
        "id": 6,
        "title": "trace me",
        "body": "in flight",
        "created_at": "2026-06-15T09:11:16.618673131Z"
    },
    {
        "id": 8,
        "title": "trace me",
        "body": "in flight",
        "created_at": "2026-06-17T03:37:40.632009882Z"
    },
    {
        "id": 7,
        "title": "trace me",
        "body": "in flight",
        "created_at": "2026-06-15T09:12:36.564482119Z"
    },
    {
        "id": 3,
        "title": "DevOps mantra",
        "body": "If it hurts, do it more often.",
        "created_at": "2026-01-15T10:10:00Z"
    },
    {
        "id": 5,
        "title": "hello",
        "body": "first POST",
        "created_at": "2026-06-04T22:44:57.201845403Z"
    },
    {
        "id": 4,
        "title": "Endpoint cheat-sheet",
        "body": "GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics",
        "created_at": "2026-01-15T10:15:00Z"
    }
]

```

### 1.5 Design Questions

**a) Synced folders: which type and why?**
VirtualBox shared folders were used (the default). They are the simplest option requiring no extra software on the host or guest, and work well for small source directories like `app/`. The trade-off is performance, VirtualBox shared folders are slower than NFS or rsync for large file trees, because every file operation crosses the hypervisor boundary. For a small Go project like QuickNotes this is not noticeable.

**b) NAT vs Bridged vs Host-only: which mode?**
NAT (the Vagrant default) is used. With NAT, the VM gets a private IP and shares the host's network for outbound traffic. Port forwarding is bound to `127.0.0.1` (localhost only), meaning the QuickNotes port is only accessible from the host machine itself, not from other devices on the same LAN. A Bridged interface would give the VM a real LAN IP, making it accessible to anyone on the network, which is a security risk.

**c) Provisioning options: which method and why?**
The `shell` provisioner was used because it requires no additional tooling on the host, only bash. It is the simplest and most portable option for installing Go from a tarball. Ansible or Chef would be more appropriate for complex multi-step configurations, but for a single tool installation, shell is clear and readable.

**d) Why pin Go to a specific point release (`1.24.4`) instead of `1.24`?**
Pinning to `1.24.4` ensures every `vagrant up` installs the exact same binary. If we specified just `1.24`, a new patch release (e.g. `1.24.5`) could be downloaded next month with subtle behavioural differences, breaking reproducibility.

---
