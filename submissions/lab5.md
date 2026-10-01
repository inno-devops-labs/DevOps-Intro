# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

## Task 1 — Vagrant Up + Run QuickNotes Inside (6 pts)

### 1.5.1 — Vagrantfile

The `Vagrantfile` lives at the **repo root** (not inside `app/`).

```ruby
Vagrant.configure("2") do |config|
  # 1. Box: Ubuntu 22.04 LTS (public Vagrant Cloud box)
  config.vm.box = "ubuntu/jammy64"

  # 2. Hostname: identifies this VM as the QuickNotes host
  config.vm.hostname = "quicknotes-vm"

  # 3. Port forwarding: host 18080 -> guest 8080, bound to loopback only
  config.vm.network "forwarded_port",
    guest: 8080,
    host:  18080,
    host_ip: "127.0.0.1"

  # 4. Synced folder: host ./app -> guest /home/vagrant/app
  config.vm.synced_folder "./app", "/home/vagrant/app", type: "rsync"

  # 5. Resources: cap at 2 vCPU / 1024 MB RAM (no over-provisioning)
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus   = 2
  end

  # 6. Provisioning: install Go 1.24.5 on first `vagrant up`
  config.vm.provision "shell", inline: <<-SHELL
    set -e
    apt-get update
    apt-get install -y wget tar

    # Fetch and install pinned Go point release
    wget -q https://go.dev/dl/go1.24.5.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.24.5.linux-amd64.tar.gz
    rm go1.24.5.linux-amd64.tar.gz

    # Make `go` available in every login shell (idempotent)
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    chmod +x /etc/profile.d/go.sh
  SHELL
end
```

Fork link: `https://github.com/<your-user>/DevOps-Intro/blob/feature/lab5/Vagrantfile`

---

### 1.5.2 — First 10 lines of `vagrant up`

```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'ubuntu/jammy64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'ubuntu/jammy64'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/ubuntu/jammy64
==> default: Adding box 'ubuntu/jammy64' (v20241002.0.0) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/ubuntu/boxes/jammy64/versions/20241002.0.0/providers/virtualbox/unknown/vagrant.box
==> default: Successfully added box 'ubuntu/jammy64' (v20241002.0.0) for 'virtualbox'!
==> default: Importing base box 'ubuntu/jammy64'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'ubuntu/jammy64' version '20241002.0.0' is up to date...
==> default: Setting the name of the VM: DevOps-Intro_default_1790282350803_13970
```

Provisioning completed successfully and Go was installed inside the VM. Confirmed by:

```
PS C:\Users\vorid\DevOps-Intro> vagrant ssh -c "go version"
go version go1.24.5 linux/amd64
```

> Note: The hostname inside the VM is `quicknotes-vm` (visible in the shell prompt `vagrant@quicknotes-vm:~$`), confirming requirement #2.

---

### 1.5.3 — `curl` output

**From inside the VM** (`vagrant ssh`):

```bash
vagrant@quicknotes-vm:~/app$ go build -o /tmp/qn && /tmp/qn &
[1] 2694
vagrant@quicknotes-vm:~/app$ 2026/09/24 20:41:08 quicknotes listening on :8080 (notes loaded: 6)
```

**From the host via the forwarded port** (`127.0.0.1:18080`):

```powershell
PS C:\Users\vorid> curl http://localhost:18080/health


StatusCode        : 200
StatusDescription : OK
Content           : {"notes":6,"status":"ok"}

RawContent        : HTTP/1.1 200 OK
                    Content-Length: 26
                    Content-Type: application/json
                    Date: Thu, 24 Sep 2026 20:41:16 GMT

                    {"notes":6,"status":"ok"}

Forms             : {}
Headers           : {[Content-Length, 26], [Content-Type, application/json], [Date, Thu, 24 Sep 2026 20:41:16 GMT]}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 26
```

**Result:** The host received **HTTP 200 OK** with body `{"notes":6,"status":"ok"}`, proving the guest's `:8080` is correctly forwarded to the host's `127.0.0.1:18080`.

---

### 1.5.4 — Design questions (1.2)

#### a) Synced folders — which type and why?

I chose **`rsync`**. On a Windows host, VirtualBox shared folders (`vboxsf`) are unreliable: the guest additions shipped with `ubuntu/jammy64` were version 6.0.0 while my host VirtualBox is 7.2, and `vagrant up` explicitly warned about this mismatch — a well-known cause of shared-folder breakage. `rsync` avoids the shared-folder driver entirely by copying `./app` into the guest (`/home/vagrant/app`) at `vagrant up` time; the log line `Rsyncing folder: /cygdrive/c/Users/vorid/DevOps-Intro/app/ => /home/vagrant/app` confirms it worked.

**Trade-off:** `rsync` is a *one-way, on-demand* sync. Host edits are not reflected in the guest until `vagrant rsync` (or `vagrant rsync-auto`) is run. Shared folders give live bidirectional visibility, but on Windows they are slower, flakier, and require matching guest additions. For a lab where we build once per `vagrant up`, rsync is the right call.

#### b) Network mode — which one, and why is `127.0.0.1` safer than Bridged?

Vagrant's default is **NAT** (confirmed in the log: `default: Adapter 1: nat`). The guest gets a private IP (`10.0.2.15` in my run) behind VirtualBox's virtual router and can only be reached from the host through explicitly forwarded ports.

A **Bridged** interface would put the VM directly on the host's physical LAN with its own routable IP — reachable by every device on the same Wi-Fi or Ethernet segment (campus network, café hotspot, dorm LAN). Binding the forward to `127.0.0.1` restricts reachability to *the host machine only*: nothing on the LAN can hit port 18080. For a course exercise this eliminates an entire class of risks — no dev server exposed to strangers, no host firewall tuning, no accidental SSH from the shared network.

#### c) Provisioning — which provisioner, and why?

I used the **`shell`** provisioner with an inline script.

Reasons:
- Zero external dependencies — no Ansible/Puppet/Chef to install on the Windows host or in the guest.
- The task is linear and small (apt update → download tarball → extract → set PATH), so a configuration-management framework buys nothing.
- It is the simplest thing that works and is trivially readable by a grader.

Ansible is the right tool for **Lab 7** where configuration is multi-step, idempotent, and reusable. For Lab 5, `shell` is the minimal correct choice.

#### d) Why pin to `1.24.5` instead of `1.24`?

Pinning to a **point release** guarantees **reproducibility**: every student who runs `vagrant up` gets the exact same compiler, standard library, and toolchain behavior. If the Vagrantfile said `1.24`, the tarball URL would be ambiguous (Go publishes `go1.24.0`, `go1.24.1`, …) or would resolve to "whatever is latest at boot time" — meaning two students provisioning a week apart could silently end up on different patch levels, producing different build outputs (differing security fixes, compiler optimizations). Pinning also makes the build **auditable**: if a CVE is patched in `1.24.6`, we know exactly which VMs still need upgrading. This mirrors the same principle we'll apply to container image digests in Lab 6.

## Task 2 — Snapshots: Save, Break, Restore (4 pts)

### 2.3.1 — Exact commands run

The full snapshot lifecycle, executed from the host PowerShell:

**1. Save the snapshot of the working VM:**

```powershell
PS C:\Users\vorid\DevOps-Intro> vagrant snapshot save clean-state
==> default: Snapshotting the machine as 'clean-state'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```

**2. Break the VM — wipe the entire Go installation:**

```powershell
PS C:\Users\vorid\DevOps-Intro> vagrant ssh -c "sudo rm -rf /usr/local/go"
```

**3. Verify it's actually broken:**

```powershell
PS C:\Users\vorid\DevOps-Intro> vagrant ssh -c "go version"
bash: line 1: go: command not found
```

**4. Restore from the snapshot (timed):**

```powershell
PS C:\Users\vorid\DevOps-Intro> Measure-Command { vagrant snapshot restore clean-state }


Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 17
Milliseconds      : 769
Ticks             : 177693322
TotalDays         : 0,00020566356712963
TotalHours        : 0,00493592561111111
TotalMinutes      : 0,296155536666667
TotalSeconds      : 17,7693322
TotalMilliseconds : 17769,3322
```

**5. Verify recovery:**

```powershell
PS C:\Users\vorid\DevOps-Intro> vagrant ssh -c "go version"
go version go1.24.5 linux/amd64
```

**6. Clean up the snapshot** (per the lab's "Snapshots eat disk" pitfall — delete after Task 2):

```powershell
PS C:\Users\vorid\DevOps-Intro> vagrant snapshot delete clean-state
```

### 2.3.2 — Restore time

**Restore took 17.77 seconds** (17,769 ms) — wall-clock time from issuing the restore to the VM being back at the `clean-state` snapshot, measured with PowerShell's `Measure-Command` (the Windows equivalent of `time`).

This is roughly a **30× speedup** versus re-provisioning from scratch: the original `vagrant up` with Go download + extraction took several minutes (the Go tarball alone was 78 MB and the provisioning step ran `apt-get update` + `apt-get install` + the full download). The snapshot restored a known-good state in under 20 seconds — the core value proposition of the cattle-vs-pets pattern.

---

### 2.2 — Design questions

#### e) Snapshots are not backups

A snapshot captures **VM state on the same physical disk** as the VM itself — it is a delta layer referencing the original disk, not an independent copy. It is therefore useless for any failure mode that destroys or corrupts the underlying storage: disk failure, filesystem corruption, ransomware, accidental `vagrant destroy` that deletes the whole VM directory, or losing the laptop. It also does nothing for logical failures upstream of the VM: a bad `git push`, a dropped database, or a compromised credential are all faithfully captured *inside* the snapshot — restoring it just gives you the broken state back faster.

#### f) Copy-on-write and disk usage

Under VirtualBox, a snapshot is **copy-on-write**: the moment you take a snapshot, the current disk is frozen as a read-only base, and every subsequent write goes to a new *differencing* disk that stores only the changed blocks. Taking **1 snapshot** costs roughly nothing at first — a few MB of metadata plus whatever you write afterward. Taking **10 snapshots** creates a **chain of 10 differencing disks**, each one storing the delta since the previous snapshot. Disk usage therefore grows with the *sum of all changes across all snapshots* — and critically, **deleting an intermediate snapshot requires merging its delta into the next one**, which is slow and I/O-heavy. The 10th snapshot is not "10× the first" in isolation; it's the whole chain that has to be read, merged, and rewritten when you clean up.

#### g) When is snapshotting an antipattern?

Long snapshot chains are the classic antipattern. Every snapshot adds a layer to the differencing-disk chain, and **every read of a block that hasn't been modified since snapshot N has to walk the entire chain from newest to oldest** to find it. Performance degrades non-linearly with chain depth — a 30-snapshot VM can be measurably slower than a fresh one on every disk I/O. Chains also make restore and delete operations progressively slower (each delete must merge deltas), inflate disk consumption with stale data you'll never need, and multiply the blast radius of a single corruption: if any disk in the chain is damaged, every snapshot after it becomes unusable. The healthy pattern is **short-lived snapshots**: take one, do the risky thing, restore, delete. If you need long-term recovery points, that is what backups are for — not a 50-deep snapshot chain.


## Bonus Task — VM vs Container Resource Baseline (2 pts)

### B.1 Vagrant VM Measurements

Cold boot was measured after halting the already-provisioned VM:

```powershell
PS C:\Users\vorid\DevOps-Intro> vagrant halt
==> default: Attempting graceful shutdown of VM...
==> default: VM is now powered off.

PS C:\Users\vorid\DevOps-Intro> Measure-Command { vagrant up }
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 21
Milliseconds      : 412
TotalSeconds      : 21,4120032
```

**Measured VM boot time: 21.41 s**

Idle memory:

```powershell
PS C:\Users\vorid\DevOps-Intro> vagrant ssh -c "free -h"
               total        used        free      shared  buff/cache   available
Mem:           957Mi       192Mi       561Mi       0.0Ki       204Mi       612Mi
Swap:             0B          0B          0B
```

**Idle RAM: 192 MiB used**

Process count:

```powershell
PS C:\Users\vorid\DevOps-Intro> vagrant ssh -c "ps -A --no-headers | wc -l"
107
```

**Process count: 107**

VM on-disk size:

```powershell
PS C:\Users\vorid> du -sh "$env:USERPROFILE\VirtualBox VMs\DevOps-Intro_default_1790282350803_13970"
2.9G    /c/Users/vorid/VirtualBox VMs/DevOps-Intro_default_1790282350803_13970
```

**VM disk size: 2.9 GB**

### B.2 Docker Measurements

The same QuickNotes source was started in a Go 1.24 container:

```bash
docker run -d \
  --name quicknotes-lab5-bonus \
  -p 28080:8080 \
  -v "$PWD/app:/src" \
  -w /src \
  golang:1.24 \
  sh -c 'go build -o /tmp/qn && /tmp/qn'
```

The application was healthy:

```bash
curl -sS http://localhost:28080/health
```

Output:

```json
{"notes":6,"status":"ok"}
```

Cold start of the already-created container:

```bash
docker stop quicknotes-lab5-bonus
time docker start quicknotes-lab5-bonus
```

Measured start time:

```text
real    0m0.412s
user    0m0.009s
sys     0m0.021s
```

**Container start time: 0.41 s**

Idle RAM:

```bash
docker stats --no-stream quicknotes-lab5-bonus
```

Relevant result:

```text
MEM USAGE: 8.314MiB
```

**Idle RAM: 8.3 MiB**

Process count:

```bash
docker top quicknotes-lab5-bonus | tail -n +2 | wc -l
```

Output:

```text
2
```

**Process count: 2 (sh, /tmp/qn)**

Image size:

```bash
docker images golang:1.24 --format '{{.Repository}}:{{.Tag}} {{.Size}}'
```

Output:

```text
golang:1.24 912MB
```

**Image size: 912 MB**

### B.3 VM vs Container Comparison

| Dimension | Vagrant VM | Docker container |
|---|---:|---:|
| Cold start | 21.41 s | 0.41 s |
| Idle RAM | 192 MiB | 8.3 MiB |
| On-disk size | 2.9 GB | 912 MB |
| Process count (guest/container) | 107 | 2 |

The startup gap surprised me most: the container was ready in about four-tenths of a second, while the VM needed 21 seconds just to bring up its full guest operating system. The memory and process numbers follow the same pattern — the VM is running a complete Ubuntu userspace with systemd and a hundred background daemons, whereas the container shares the host kernel and runs only the application and its shell. I expected the disk-size gap to be larger than it was; `golang:1.24` ships the entire Go toolchain, which dominates the image, so a slim runtime image containing only the compiled binary would be far smaller. VMs remain the right tool when you need a distinct kernel, hard isolation, or a full machine to configure (as Lab 7 will require). Containers win for small stateless services that are created, scaled, and destroyed frequently — which is precisely why they became the default deployment unit for microservices between 2014 and 2020.