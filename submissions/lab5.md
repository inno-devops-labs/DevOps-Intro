# Lab 5 — Virtualization: QuickNotes in a Vagrant VM

![difficulty](https://img.shields.io/badge/difficulty-intermediate-yellow)
![topic](https://img.shields.io/badge/topic-Virtualization-blue)
![points](https://img.shields.io/badge/points-10%2B2-orange)
![tech](https://img.shields.io/badge/tech-Vagrant%20%2B%20VirtualBox-informational)

> **Goal:** Write a `Vagrantfile` that boots an Ubuntu VM, builds and runs QuickNotes inside, and exposes it to the host. Snapshot/restore the VM lifecycle. Compare VM vs container resource cost (Bonus).
> **Deliverable:** A PR from `feature/lab5` to the course repo with your `Vagrantfile` + `submissions/lab5.md`. Submit the PR link via Moodle.

---

## Overview

By the end of this lab you have:
- A `Vagrantfile` at the **repo root** that boots a Ubuntu 24.04 VM, provisions it with Go 1.24, syncs `app/` in, and forwards a host port to the guest
- A running QuickNotes inside the VM, reachable from your host
- A "clean" snapshot you can roll back to in 30 seconds
- *(Bonus)* A side-by-side resource comparison: VM vs Docker container

This lab feeds Lab 7 directly — your Ansible playbook there will target this VM.

---

## Project State

**Starting point:** QuickNotes runs locally (Lab 1). Lab 3 CI passes.

**After this lab:** Your fork ships a `Vagrantfile`; you have a running VM serving QuickNotes; you've taken, broken, and restored a snapshot.

---

## Prerequisites

- Laptop with hardware virtualization enabled (Windows: Hyper-V off, VirtualBox on)
- Install VirtualBox **7.1.x**, Vagrant **2.4.x**
- ≥ 8 GB RAM on the host

---

## Task 1 — Vagrant Up + Run QuickNotes Inside (6 pts)

### 1.1: Requirements your `Vagrantfile` must meet

Your `Vagrantfile` (at the repo root, **not inside `app/`**) MUST:

1. **Box:** use Ubuntu 22.04 or 24.04 LTS from a public Vagrant box source
2. **Hostname:** set the VM's hostname to something identifying QuickNotes
3. **Port forwarding:** map host port **18080** → guest port **8080**, bound to `127.0.0.1` (not exposed publicly)
4. **Synced folder:** mount the host's `./app` directory into the guest (anywhere reasonable; rsync or VirtualBox shared folders are both fine)
5. **Resources:** cap the VM at **2 vCPU** and **1024 MB RAM** (over-provisioning is an antipattern from Lecture 5)
6. **Provisioning:** install **Go 1.24.x** inside the VM as part of `vagrant up` — student does not have to SSH in to install Go
7. **Reproducible:** another student running `vagrant up` from a clean clone produces the same working state

### 1.2: Design questions — answer in your submission

- a) **Synced folders:** Vagrant supports `nfs`, `rsync`, `virtualbox`, and `smb` mount types. Which did you pick and why? What's the trade-off?
- b) **NAT vs Bridged vs Host-only:** which network mode are you using (it's the default, but say which it is)? Why is `127.0.0.1`-bound port forwarding safer than a Bridged interface for a course exercise?
- c) **Provisioning options:** Vagrant supports `shell`, `ansible`, `ansible_local`, `puppet`, `chef`, … which did you pick for installing Go and why?
- d) **Why pin Go to a specific point release** (`1.24.5`) instead of `1.24`?

### 1.3: Where to start

- 📖 [Vagrant — Getting started](https://developer.hashicorp.com/vagrant/tutorials/getting-started)
- 📖 [Vagrantfile reference](https://developer.hashicorp.com/vagrant/docs/vagrantfile)
- 📖 [Vagrant — Networking](https://developer.hashicorp.com/vagrant/docs/networking)
- 📖 [Vagrant — Synced folders](https://developer.hashicorp.com/vagrant/docs/synced-folders)
- 📖 [Vagrant — Shell provisioner](https://developer.hashicorp.com/vagrant/docs/provisioning/shell)
- 📖 [Public Vagrant boxes catalog](https://portal.cloud.hashicorp.com/vagrant/discover) (search "ubuntu")

> 💡 **Hint:** the upstream Go tarball at `https://go.dev/dl/go<X.Y.Z>.linux-amd64.tar.gz` is the simplest way to install a specific Go version on Ubuntu — extract to `/usr/local`, add to PATH.

### 1.4: Verify

After `vagrant up`:

```bash
vagrant ssh -c 'go version'                # should print go1.24.x
vagrant ssh -c 'cd /path/to/synced/app && go build -o /tmp/qn && /tmp/qn &' &
sleep 3
curl -s http://localhost:18080/health      # from your host
```

You should see `{"notes":4,"status":"ok"}` or similar from the host hitting the guest.

### 1.5: Document

In `submissions/lab5.md`:
- Your `Vagrantfile` (paste it; or a link to it in your fork)
- First 10 lines of `vagrant up` output (box download / provisioning)
- `curl` outputs from inside the VM AND from the host (via port forward)
- Written answers to all 4 design questions in 1.2

---

## Task 2 — Snapshots: Save, Break, Restore (4 pts)

Vagrant exposes snapshot operations under `vagrant snapshot save|restore|delete|list`. You'll use them to prove the cattle-vs-pets pattern from Lecture 5.

### 2.1: Required actions

1. **Take a snapshot** of the working VM, give it a meaningful name
2. **Break the VM** deliberately — pick a way that's actually destructive (rm a system binary, corrupt a config, wipe the Go install, etc.)
3. **Verify it's broken** with a command that proves it (e.g. `go version` failing)
4. **Restore** from the snapshot
5. **Verify recovery** (the broken thing works again)
6. **Time the restore** with `time vagrant snapshot restore <name>`

### 2.2: Design questions

- e) **Snapshots are not backups.** Explain why in 2-3 sentences — what failure modes is a snapshot useless for?
- f) **Copy-on-write:** Vagrant snapshots are copy-on-write under VirtualBox. What does that mean for disk usage when you take 10 snapshots vs 1?
- g) **When is snapshotting an antipattern?** (Hint: long chains.)

### 2.3: Document

In `submissions/lab5.md`:
- The exact commands you ran (save → break → verify → restore → verify)
- The `time` output of the restore
- Written answers to questions e, f, g

---

## Bonus Task — VM vs Container Resource Baseline (2 pts)

### B.1: Measure the Vagrant VM (idle)

While the VM from Task 1 is up and idle, capture:
- **Cold-boot time** — `time vagrant halt && time vagrant up` (the *boot*, not the *first-ever* provisioning)
- **Idle RAM** — `vagrant ssh -c 'free -h'`
- **Process count** — `vagrant ssh -c 'ps -A --no-headers | wc -l'`
- **Disk size of the VM image** — `du -sh ~/VirtualBox\ VMs/<name>` or equivalent

### B.2: Measure a Docker container running the same QuickNotes

Use your Lab 6 image if you've done Lab 6, or build with:

```bash
docker run -d -p 28080:8080 -v "$PWD/app:/src" -w /src golang:1.24 \
  sh -c 'go build -o /tmp/qn && /tmp/qn'
```

Capture the same four numbers:
- Cold start (`docker stop && time docker start`)
- Idle RAM (`docker stats --no-stream`)
- Process count (`docker top <id>` lines)
- On-disk size (`docker images --format '{{.Size}}'`)

### B.3: Present the comparison

In `submissions/lab5.md`, build the following table from your real numbers:

| Dimension              | Vagrant VM | Docker container |
|------------------------|-----------:|-----------------:|
| Cold start             |          ? |                ? |
| Idle RAM               |          ? |                ? |
| On-disk size           |          ? |                ? |
| Process count (guest)  |          ? |                ? |

Then write 4-5 sentences:
- Which numbers surprised you?
- For what workloads is each model the right tool?
- What does the data say about why containers won the 2014-2020 era for stateless microservices?

---

## How to Submit

1. `Vagrantfile` at the repo root in your fork (with `.vagrant/` in `.gitignore`)
2. `submissions/lab5.md` covers all attempted tasks
3. PR from `feature/lab5` → course repo's `main`
4. Submit the PR URL via Moodle

---

## Acceptance Criteria

### Task 1 (6 pts)
- ✅ `Vagrantfile` boots a clean Ubuntu LTS VM with Go 1.24 installed
- ✅ Port forward `127.0.0.1:18080 → guest:8080` works
- ✅ `curl :18080/health` from the host returns 200
- ✅ All 4 design questions answered in writing

### Task 2 (4 pts)
- ✅ Snapshot taken; VM deliberately broken; restored successfully
- ✅ Restore time captured
- ✅ Design questions e, f, g answered

### Bonus Task (2 pts)
- ✅ Four-row comparison table with real numbers from your hardware
- ✅ Written trade-off analysis (4-5 sentences)

---

## Rubric

| Task | Points | Criteria |
|------|-------:|----------|
| **Task 1** — Vagrantfile + QuickNotes inside | **6** | Boots clean, port forward works, design questions answered |
| **Task 2** — Snapshot lifecycle | **4** | Save → break → restore demonstrated; design questions answered |
| **Bonus** — VM vs container baseline | **2** | Comparison table + trade-off analysis from your real measurements |
| **Total** | **10 + 2 bonus** | |

---

## Common Pitfalls

- 🪤 **VirtualBox kernel modules missing on Ubuntu host** — `sudo apt install virtualbox-dkms` + `sudo modprobe vboxdrv`. On Windows make sure Hyper-V is *disabled*
- 🪤 **`vagrant up` hangs on "Waiting for SSH"** — first boot on slow disks is slow; give it 5 minutes before assuming it's stuck
- 🪤 **rsync sync requires `rsync` on the host** — install it if missing
- 🪤 **Snapshots eat disk** — they're copy-on-write but accumulate; delete after Task 2
- 🪤 **`vagrant destroy` while you have uncommitted work in the VM** — sync changes out *first*
- 🪤 **Committed `.vagrant/`** — that directory is per-machine state, not source. `.gitignore` it
- 🪤 **Used `vb.cpus = 16` on a 4-core laptop** — Lecture 5 warned about over-subscription; honor the requirement of ≤ 2 vCPU

---

## Guidelines

- One `Vagrantfile` line per concept — the file is small Ruby DSL; readability matters
- The provisioner runs on **first** `vagrant up`; afterwards use `vagrant provision` to re-run it. Test idempotency before submitting
- Lab 7 will deploy QuickNotes to this VM via Ansible — keep it healthy
- For the bonus, run baselines on the **same** hardware in the same session — comparing two different days is meaningless

---

## Resources

- 📖 [Vagrant docs](https://developer.hashicorp.com/vagrant/docs)
- 📖 [VirtualBox 7.1 User Manual](https://www.virtualbox.org/manual/UserManual.html)
- 📕 *Modern Operating Systems* — Andrew Tanenbaum — Chapter 7 (Virtualization)
- 📖 [Brendan Gregg — *Containers vs VMs* (USENIX talk PDF)](https://www.brendangregg.com/Slides/UMCloud2016_container_performance.pdf)
- 📝 [Cloudflare on Heartbleed (2014)](https://blog.cloudflare.com/answering-the-critical-question-can-you-get-private-ssl-keys-using-heartbleed/) — why "cattle, not pets" matters
- 🛠️ `vagrant`, `VBoxManage` CLI
