# Lab 5 - Virtualization: QuickNotes in a Vagrant VM

## Task 1 - Vagrant Up + Run QuickNotes Inside

### Vagrantfile

The final VM uses the public `generic/ubuntu2204` Vagrant Cloud box. This is Ubuntu 22.04 LTS, which is allowed by the lab requirement. It was used because it booted successfully with this Windows + VirtualBox host; the Vagrantfile itself keeps the rest of the setup reproducible.

```ruby
# frozen_string_literal: true

GO_VERSION = "1.24.5"
APP_GUEST_PATH = "/opt/quicknotes/app"

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.vm.boot_timeout = 900
  config.vm.hostname = "quicknotes-vm"

  config.vm.network "forwarded_port",
                    guest: 8080,
                    host: 18080,
                    host_ip: "127.0.0.1",
                    auto_correct: false

  config.vm.synced_folder "./app",
                          APP_GUEST_PATH,
                          type: "virtualbox",
                          owner: "vagrant",
                          group: "vagrant",
                          SharedFoldersEnableSymlinksCreate: false,
                          mount_options: ["dmode=775", "fmode=664"]

  config.vm.provider "virtualbox" do |vb|
    vb.name = "quicknotes-lab5"
    vb.cpus = 2
    vb.memory = 1024
  end

  config.vm.provision "shell",
                      privileged: true,
                      env: {
                        "APP_DIR" => APP_GUEST_PATH,
                        "GO_VERSION" => GO_VERSION
                      },
                      inline: <<-'SHELL'
    set -euxo pipefail
    export DEBIAN_FRONTEND=noninteractive

    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl build-essential

    case "$(dpkg --print-architecture)" in
      amd64) GO_ARCH="amd64" ;;
      arm64) GO_ARCH="arm64" ;;
      *) echo "unsupported CPU architecture"; exit 1 ;;
    esac

    if ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION} "; then
      rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tgz
      tar -C /usr/local -xzf /tmp/go.tgz
      rm -f /tmp/go.tgz
    fi

    cat >/etc/profile.d/go.sh <<'EOF'
export PATH=/usr/local/go/bin:$PATH
EOF

    install -d -o vagrant -g vagrant /var/lib/quicknotes

    cd "${APP_DIR}"
    /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .

    cat >/etc/systemd/system/quicknotes.service <<EOF
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
User=vagrant
Group=vagrant
WorkingDirectory=${APP_DIR}
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=${APP_DIR}/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now quicknotes.service
    systemctl --no-pager --full status quicknotes.service
  SHELL
end
```

### `vagrant up` evidence

First `vagrant up` lines:

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'generic/ubuntu2204' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'generic/ubuntu2204'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/generic/ubuntu2204
==> default: Adding box 'generic/ubuntu2204' (v4.3.12) for provider: virtualbox (amd64)
    default: Downloading: https://vagrantcloud.com/generic/boxes/ubuntu2204/versions/4.3.12/providers/virtualbox/amd64/vagrant.box
    default: Calculating and comparing box checksum...
==> default: Successfully added box 'generic/ubuntu2204' (v4.3.12) for 'virtualbox (amd64)'!
```

Provisioning and service excerpt:

```text
==> default: Machine booted and ready!
==> default: Mounting shared folders...
    default: C:/GitProjects/DevOps-Intro/app => /opt/quicknotes/app
==> default: Running provisioner: shell...
    default: ++ curl -fsSL https://go.dev/dl/go1.24.5.linux-amd64.tar.gz -o /tmp/go.tgz
    default: ++ /usr/local/go/bin/go build -o /usr/local/bin/quicknotes .
    default: ++ systemctl enable --now quicknotes.service
    default: Created symlink /etc/systemd/system/multi-user.target.wants/quicknotes.service -> /etc/systemd/system/quicknotes.service.
    default: Active: active (running) since Wed 2026-06-17 11:14:20 UTC
```

Validation:

```text
$ vagrant validate
Vagrantfile validated successfully.
```

Go version inside the VM:

```text
$ vagrant ssh -c 'go version'
go version go1.24.5 linux/amd64
```

QuickNotes health from inside the VM:

```text
$ vagrant ssh -c 'curl -s http://localhost:8080/health'
{"notes":4,"status":"ok"}
```

QuickNotes health from the host through the forwarded port:

```text
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

Service status:

```text
$ vagrant ssh -c 'systemctl --no-pager --full status quicknotes.service | sed -n "1,8p"'
quicknotes.service - QuickNotes API
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; vendor preset: enabled)
     Active: active (running) since Wed 2026-06-17 11:14:20 UTC; 29s ago
   Main PID: 10088 (quicknotes)
      Tasks: 7 (limit: 1012)
     Memory: 1.6M
        CPU: 24ms
```

### Design questions

a) I used the `virtualbox` synced-folder type. For this Windows + VirtualBox setup it avoids an extra host-side `rsync` dependency and gives immediate bidirectional edits between the host `app/` directory and `/opt/quicknotes/app` in the VM. The trade-off is that VirtualBox shared folders depend on Guest Additions compatibility and can be slower than native filesystem access or one-way `rsync` for large trees.

b) The VM uses NAT, which is Vagrant's default VirtualBox network mode. The only host exposure is a forwarded port bound to `127.0.0.1:18080`, so only the local machine can reach QuickNotes. That is safer than a bridged interface for a course exercise because bridged networking puts the VM directly on the LAN, where classmates, campus devices, or other local network clients could reach the service if firewalling is wrong.

c) I used the shell provisioner. Installing one pinned Go toolchain, building one binary, and writing one systemd unit is simple enough that shell is the least moving part; Ansible would be useful later, but Lab 7 is where the course starts targeting this VM with Ansible.

d) Pinning `1.24.5` instead of only `1.24` makes the build reproducible. A floating minor alias can move to a new patch release with different compiler behavior, security fixes, or cache contents, while a point release lets every student and CI run use the same toolchain.

## Task 2 - Snapshots: Save, Break, Restore

### Commands run

```bash
vagrant snapshot save quicknotes-clean
vagrant snapshot list
vagrant ssh -c 'sudo mv /usr/local/go /usr/local/go.broken'
vagrant ssh -c 'go version'
time vagrant snapshot restore quicknotes-clean
vagrant ssh -c 'go version'
vagrant ssh -c 'curl -s http://localhost:8080/health'
curl -s http://localhost:18080/health
```

### Output

```text
==> default: Snapshotting the machine as 'quicknotes-clean'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.

quicknotes-clean

bash: line 1: go: command not found

RESTORE_SECONDS=19.523

go version go1.24.5 linux/amd64
{"notes":4,"status":"ok"}
{"notes":4,"status":"ok"}
```

The deliberate break was moving `/usr/local/go` out of the way. That made `go version` fail with `command not found`, proving the VM was broken. Restoring `quicknotes-clean` recovered both the Go toolchain and the running QuickNotes service.

### Snapshot design questions

e) Snapshots are not backups because they usually live on the same host and storage pool as the VM. If the laptop disk dies, the VM directory is deleted, ransomware encrypts the host, or the VirtualBox metadata is corrupted, the snapshot is lost with the VM. A backup must be independent, recoverable elsewhere, and protected from the same failure domain.

f) Copy-on-write means the snapshot initially stores metadata and only keeps blocks that change after the snapshot point. Ten snapshots do not immediately cost ten full VM disks, but disk usage grows as the VM writes new blocks and as each snapshot chain keeps older versions alive. Long chains can become surprisingly large even if each individual snapshot looked cheap when created.

g) Snapshotting is an antipattern when snapshots become long-lived operational state. Long chains make restore behavior harder to reason about, can hurt performance, and encourage pet-server habits instead of rebuilding from code and configuration. For production-like systems, backups, image builds, configuration management, and disposable rebuilds are safer than keeping many old snapshots around.

## Bonus Task

Not claimed. I attempted the VM cold-boot measurement after the required tasks with `vagrant halt` followed by a timed `vagrant up`, but on this host the VM powered on without presenting an SSH banner, so the cold-boot number was not reliable. I restored the verified `quicknotes-clean` snapshot afterward and confirmed the VM was healthy again. The usable post-restore idle VM numbers were `957Mi` total RAM with `190Mi` used, `124` guest processes, and a `6.21 GiB` VirtualBox VM directory, but I am not submitting the bonus comparison table because the required cold-boot and Docker side-by-side baseline was not completed cleanly.
