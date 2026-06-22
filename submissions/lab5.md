# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + VirtualBox + Vagrant

---

## Task 1 — Vagrant up + QuickNotes inside

### Vagrantfile

See repo root: [`Vagrantfile`](../Vagrantfile)  
Provisioner: [`vagrant/provision-go.sh`](../vagrant/provision-go.sh)

### 1.1 `vagrant up` (first 10 lines)

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Checking if box 'ubuntu/jammy64' version '20241002.0.0' is up to date...
==> default: Clearing any previously set forwarded ports...
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 8080 (guest) => 18080 (host) (adapter 1)
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
```

### 1.2 Verify Go + QuickNotes

**Inside VM:**

```bash
vagrant ssh -c 'go version'
vagrant ssh -c 'cd /home/vagrant/quicknotes/app && go build -o /tmp/qn && ADDR=:8080 /tmp/qn &'
sleep 3
vagrant ssh -c 'curl -s http://localhost:8080/health'
```

```text
$ vagrant ssh -c "go version"
go version go1.24.5 linux/amd64

$ vagrant ssh -c "cd /home/vagrant/quicknotes/app && go build -o /tmp/qn"
$ vagrant ssh -c "nohup env ADDR=:8080 /tmp/qn > /tmp/qn.log 2>&1 &"

$ vagrant ssh -c "curl -s http://localhost:8080/health"
{"notes":9,"status":"ok"}
```

**From host (port forward):**

```powershell
Invoke-RestMethod http://127.0.0.1:18080/health
```

```text
notes status
----- ------
    9 ok
```

### 1.3 Design questions (Task 1)

**a) Synced folders — which type and why?**

`virtualbox` (VirtualBox shared folders). On Windows it works out of the box with no extra host packages (unlike `nfs` on Linux-only, or `rsync` which needs rsync on the host). Trade-off: shared folders are convenient for live editing but slower than `rsync` for large trees and can have permission quirks — acceptable for a small Go app in a course VM.

**b) NAT vs Bridged vs Host-only?**

Default **NAT**. The guest gets outbound internet via the host’s NAT adapter; inbound is only what we explicitly forward (`127.0.0.1:18080` → guest `:8080`). **Safer than Bridged** for a lab: Bridged puts the VM on the LAN with its own IP reachable by other machines on the network; binding the forward to `127.0.0.1` keeps QuickNotes reachable only from this laptop.

**c) Provisioning — which tool and why?**

**Shell** provisioner (`vagrant/provision-go.sh`). Smallest dependency surface for Lab 5: installs a pinned Go tarball with plain bash. Ansible/Puppet/Chef add agent/tooling overhead better saved for Lab 7; shell is idempotent and easy to code-review in the PR.

**d) Why pin Go to `1.24.5` instead of `1.24`?**

`go.mod` requires 1.24; a **point release** (`1.24.5`) fixes bugs and security issues while staying on the same language version. `1.24` alone is ambiguous (which patch?). Pinning the tarball URL makes `vagrant up` reproducible for every student and matches CI/toolchain expectations.

---

## Task 2 — Snapshots: save, break, restore

### 2.1 Commands

```bash
# 1. Save working state
vagrant snapshot save clean-quicknotes

# 2. Break VM (example: remove Go)
vagrant ssh -c 'sudo rm -rf /usr/local/go'

# 3. Verify broken
vagrant ssh -c 'go version'

# 4. Restore
time vagrant snapshot restore clean-quicknotes

# 5. Verify recovery
vagrant ssh -c 'go version'
```

**Break verification (broken):**

```text
$ vagrant ssh -c "go version"
bash: line 1: go: command not found
```

**Restore timing:**

```text
$ Measure-Command { vagrant snapshot restore clean-quicknotes }

TotalSeconds      : 26.1888969
TotalMilliseconds : 26188.8969
```

**Recovery verification:**

```text
$ vagrant ssh -c "go version"
go version go1.24.5 linux/amd64
```

### 2.2 Design questions (Task 2)

**e) Snapshots are not backups — why?**

Snapshots only roll back disk state on **this** host/VM; they don’t protect against disk failure, accidental `vagrant destroy`, or corruption of the snapshot chain itself. They also don’t copy data off-machine — if the laptop dies, snapshots die with it.

**f) Copy-on-write — 10 snapshots vs 1?**

CoW means new snapshots store **deltas** against the parent, not full copies. One snapshot is cheap; **many** snapshots accumulate divergent blocks and grow total disk usage — each snapshot holds changes since its parent, so long chains use more space and slow I/O.

**g) When is snapshotting an antipattern?**

When snapshots become a **long-lived dependency** instead of ephemeral cattle: deep chains, never deleted, used as “backup” for months, or as a substitute for config management. Production pets with 20 snapshots are harder to reason about than reprovisioning from a `Vagrantfile`/image.

---

## Bonus — VM vs container baseline (optional)

**Measurement session:** Windows 11, same laptop, 2026-06-19. VM: `quicknotes-lab5` (1 vCPU cap / 1024 MB RAM). Docker: `golang:1.24` running QuickNotes on port 28080.

| Dimension | Vagrant VM | Docker container |
|-----------|----------:|-----------------:|
| Cold start | ~127 s (`vagrant halt` → `vagrant up --no-provision`, SSH ready) | 0.32 s (`docker stop` → `docker start`) |
| Idle RAM | 172 MiB used (`free -h` in guest) | 22.81 MiB (`docker stats --no-stream`) |
| On-disk size | 2.97 GB (`~/VirtualBox VMs/quicknotes-lab5`) | 1.32 GB (`golang:1.24` image) |
| Process count (guest) | 107 (`ps -A --no-headers \| wc -l`) | 5 (`ps` inside container) |

**Trade-off analysis (4–5 sentences):**

The gap in cold start (~127 s vs under 1 s) and idle RAM (172 MiB vs ~23 MiB) was the biggest surprise — the container runs only QuickNotes plus a thin runtime, while the VM boots a full Ubuntu userspace with systemd, sshd, and background services. Process count (107 vs 5) shows the same story: a VM is a pet with an entire OS to babysit; a container is cattle scoped to one workload. VMs are the right tool when you need kernel isolation, a specific OS image, or legacy apps that expect a full machine (this lab’s VirtualBox + Ansible path in Lab 7). Containers won the 2014–2020 microservices era because stateless services could be packed densely, restarted in seconds, and patched by replacing images — Heartbleed-style incidents pushed teams away from long-lived pets toward reproducible, disposable units. For QuickNotes alone, Docker is far cheaper; for teaching full-machine DevOps (snapshots, SSH, provisioning), the VM cost is intentional.

---

## Lab 5 completion checklist

### Task 1 (6 pts)

- [x] `Vagrantfile` at repo root meets all requirements
- [x] `vagrant up` + Go 1.24.x inside VM
- [x] `curl http://127.0.0.1:18080/health` from host → 200
- [x] Design questions a–d answered
- [x] `vagrant up` log + curl outputs pasted

### Task 2 (4 pts)

- [x] Snapshot save → break → restore demonstrated
- [x] Restore `time` output captured
- [x] Design questions e–g answered

### Bonus (2 pts)

- [x] Comparison table with real numbers
- [x] Written trade-off analysis

### Submission

- [x] Course PR opened (`feature/lab5` → `inno-devops-labs/main`)  
  **https://github.com/inno-devops-labs/DevOps-Intro/pull/1146**  
  ![Course PR](../screenshots/lab_5/check1.png)
- [x] Fork PR opened (`feature/lab5-fork` → `selysecr332/main`)  
  **https://github.com/selysecr332/DevOps-Intro/pull/6**  
  ![Fork PR](../screenshots/lab_5/check_5.png)

