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
<!-- paste first 10 lines after vagrant up -->
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
<!-- paste go version + in-guest curl output -->
```

**From host (port forward):**

```bash
curl -s http://127.0.0.1:18080/health
```

```text
<!-- paste host curl output -->
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
<!-- paste go version failure -->
```

**Restore timing:**

```text
<!-- paste time vagrant snapshot restore output -->
```

**Recovery verification:**

```text
<!-- paste go version after restore -->
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

| Dimension | Vagrant VM | Docker container |
|-----------|----------:|-----------------:|
| Cold start | _TODO_ | _TODO_ |
| Idle RAM | _TODO_ | _TODO_ |
| On-disk size | _TODO_ | _TODO_ |
| Process count (guest) | _TODO_ | _TODO_ |

**Trade-off analysis (4–5 sentences):**

_TODO after measurements._

---

## Lab 5 completion checklist

### Task 1 (6 pts)

- [ ] `Vagrantfile` at repo root meets all requirements
- [ ] `vagrant up` + Go 1.24.x inside VM
- [ ] `curl http://127.0.0.1:18080/health` from host → 200
- [ ] Design questions a–d answered
- [ ] `vagrant up` log + curl outputs pasted

### Task 2 (4 pts)

- [ ] Snapshot save → break → restore demonstrated
- [ ] Restore `time` output captured
- [ ] Design questions e–g answered

### Bonus (2 pts)

- [ ] Comparison table with real numbers
- [ ] Written trade-off analysis

### Submission

- [ ] Course PR opened (`feature/lab5` → `inno-devops-labs/main`)
- [ ] Fork PR opened (`feature/lab5-fork` → `selysecr332/main`)
- [ ] Both URLs on Moodle
