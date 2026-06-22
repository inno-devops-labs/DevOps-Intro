# Lab 5 Submission

## Task 1 - Vagrant Up + Run QuickNotes Inside

### Vagrantfile

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
    guest: 8080,
    host: 18080,
    host_ip: "127.0.0.1"

  config.vm.synced_folder "./app", "/opt/quicknotes/app",
    type: "virtualbox",
    owner: "vagrant",
    group: "vagrant"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    GO_VERSION="1.24.5"

    apt-get update
    apt-get install -y curl ca-certificates tar build-essential

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
      tar -C /usr/local -xzf /tmp/go.tar.gz
    fi

    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    install -d -o vagrant -g vagrant /var/lib/quicknotes

    cd /opt/quicknotes/app
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .

    cat >/etc/systemd/system/quicknotes.service <<'UNIT'
[Unit]
Description=QuickNotes API
After=network.target

[Service]
User=vagrant
Group=vagrant
WorkingDirectory=/opt/quicknotes/app
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/opt/quicknotes/app/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable quicknotes
    systemctl restart quicknotes
  SHELL
end
```

### First 10 lines of `vagrant up`

```text
mostafa@aorus-AORUS-15-BSF:~/git_repos/DevOps-Intro$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'ubuntu/jammy64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'ubuntu/jammy64'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/ubuntu/jammy64
==> default: Adding box 'ubuntu/jammy64' (v20241002.0.0) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/ubuntu/boxes/jammy64/versions/20241002.0.0/providers/virtualbox/unknown/vagrant.box
==> default: Successfully added box 'ubuntu/jammy64' (v20241002.0.0) for 'virtualbox'!
```

### Verification output

Go version inside the VM:

```bash
vagrant ssh -c 'go version'
```

```text
go version go1.24.5 linux/amd64
```

QuickNotes service status inside the VM:

```bash
vagrant ssh -c 'systemctl status quicknotes --no-pager'
```

```text
quicknotes.service - QuickNotes API
Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; vendor preset: enabled)
Active: active (running) since Mon 2026-06-22 19:44:47 UTC
Main PID: 4412 (quicknotes)
```

Health check from inside the VM:

```bash
vagrant ssh -c 'curl -s http://localhost:8080/health'
```

```json
{"notes":4,"status":"ok"}
```

Health check from the host through the forwarded port:

```bash
curl -s http://localhost:18080/health
```

```json
{"notes":4,"status":"ok"}
```

### Design questions

#### a) Synced folders

I used the VirtualBox synced folder type to mount the host `./app` directory into the guest at `/opt/quicknotes/app`. This is simple for a VirtualBox-based lab because file changes on the host are visible inside the VM without a manual sync step. The trade-off is that it depends on VirtualBox Guest Additions and can have portability or performance differences compared with `rsync`, while `rsync` is often more predictable but is mainly one-way from host to guest unless extra setup is added.

#### b) NAT vs Bridged vs Host-only

The VM uses NAT networking, which is Vagrant's default network mode, plus a forwarded port from host `127.0.0.1:18080` to guest `8080`. Binding the forwarded port to `127.0.0.1` makes QuickNotes reachable only from my host machine. This is safer than using a bridged interface because the VM is not directly exposed as a separate machine on the local network.

#### c) Provisioning options

I used the shell provisioner to install Go, build QuickNotes, and create the systemd service. Shell provisioning is enough for this lab because the setup is small, explicit, and easy to reproduce during `vagrant up`. Tools such as Ansible are better for larger configuration management tasks and will be used later in the course.

#### d) Why pin Go to a specific point release (`1.24.5`) instead of `1.24`?

Pinning Go to `1.24.5` makes the VM more reproducible. If the provisioner only requested `1.24`, two students could run the same lab at different times and receive different patch releases. A specific point release keeps the build environment stable and makes validation output easier to compare.
