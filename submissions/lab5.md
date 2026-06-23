# Lab 5 Submission

## Task 1. Run QuickNotes Inside a Vagrant VM

### Vagrantfile

The Vagrantfile is located at the repository root and satisfies all requirements:

- Ubuntu LTS box
- Hostname configured
- Port forwarding `127.0.0.1:18080 -> guest:8080`
- Synced `app/` directory
- 2 vCPU
- 1024 MB RAM
- Go 1.24.5 installed during provisioning
- Reproducible environment

See:

```text
Vagrantfile
```

### First 10 Lines of `vagrant up`

Source file:

```text
submissions/src/lab05/vagrant_up.txt
```

Output:

```text
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'ubuntu/jammy64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'ubuntu/jammy64'
    default: URL: https://vagrantcloud.com/api/v2/vagrant/ubuntu/jammy64
==> default: Adding box 'ubuntu/jammy64' (v20241002.0.0) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/ubuntu/boxes/jammy64/versions/20241002.0.0/providers/virtualbox/unknown/vagrant.box
```

### Go Version Inside VM

Source file:

```text
submissions/src/lab05/go_version.txt
```

Command:

```bash
vagrant ssh -c "go version"
```

Output:

```text
go version go1.24.5 linux/amd64
```

### QuickNotes Reachable From Guest

Source file:

```text
submissions/src/lab05/curl_guest_health.txt
```

Command:

```bash
vagrant ssh -c "curl -s http://localhost:8080/health"
```

Output:

```json
{"notes":5,"status":"ok"}
```

### QuickNotes Reachable From Host Through Port Forwarding

Source file:

```text
submissions/src/lab05/curl_host_health.txt
```

Command:

```powershell
curl.exe -s http://localhost:18080/health
```

Output:

```json
{"notes":5,"status":"ok"}
```

---

### Question a. Synced Folders

I used the default VirtualBox shared folder mechanism. The main advantage is simplicity because it works immediately after `vagrant up` and does not require additional host software. The downside is lower file synchronization performance compared to NFS or rsync, especially for projects with many small files.

### Question b. NAT vs Bridged vs Host-only

The VM uses NAT networking with explicit port forwarding. NAT is safer because the VM is not directly exposed to the local network. Only port `18080` on `127.0.0.1` is forwarded to the guest. A bridged adapter would expose the VM as a separate machine on the network, increasing the attack surface unnecessarily for a course exercise.

### Question c. Provisioning Choice

I used a shell provisioner. The shell provisioner is the simplest option for this lab because only a few installation commands are required. Tools such as Ansible, Puppet, or Chef are more appropriate for larger infrastructure deployments.

### Question d. Why Pin Go 1.24.5?

Using a specific version guarantees reproducibility. If only `1.24` is specified, a future patch release could change behavior, fix bugs, or introduce regressions. Pinning `1.24.5` ensures every student receives exactly the same toolchain.

---

## Task 2. Snapshots: Save, Break, Restore

### Create Snapshot

Source file:

```text
submissions/src/lab05/snapshot_save.txt
```

Command:

```bash
vagrant snapshot save quicknotes-clean
```

Output:

```text
==> default: Snapshotting the machine as 'quicknotes-clean'...
==> default: Snapshot saved!
```

### Break the VM

Command:

```bash
vagrant ssh -c "sudo rm -rf /usr/local/go /usr/local/bin/go /usr/local/bin/gofmt"
```

### Verify Failure

Source file:

```text
submissions/src/lab05/go_version_broken.txt
```

Command:

```bash
vagrant ssh -c "go version"
```

Output:

```text
bash: line 1: go: command not found
```

### Restore Snapshot

Source files:

```text
submissions/src/lab05/snapshot_restore.txt
submissions/src/lab05/snapshot_restore_time.txt
```

Command:

```bash
vagrant snapshot restore quicknotes-clean --no-provision
```

Restore duration:

```text
19.60 seconds
```

### Verify Recovery

Source file:

```text
submissions/src/lab05/go_version_restored.txt
```

Command:

```bash
vagrant ssh -c "go version"
```

Output:

```text
go version go1.24.5 linux/amd64
```

Source file:

```text
submissions/src/lab05/curl_host_after_restore.txt
```

Command:

```powershell
curl.exe -s http://localhost:18080/health
```

Output:

```json
{"notes":5,"status":"ok"}
```

---

### Question e. Why Snapshots Are Not Backups

Snapshots depend on the original virtual disk. If the host disk fails or the VM files become corrupted, snapshots are lost together with the VM. Backups are independent copies stored separately and protect against hardware failure.

### Question f. Copy-on-Write

Copy-on-write means a snapshot initially stores only differences from the base disk. Taking many snapshots consumes little space at first, but storage usage grows as more blocks are modified over time.

### Question g. When Snapshotting Becomes an Antipattern

Long snapshot chains make management difficult and increase storage consumption. Restoring old snapshots can become confusing because dependencies between snapshots accumulate. For long-term recovery, proper backups and infrastructure automation are preferable.

---

# Bonus Task. VM vs Container Resource Baseline

## VM Measurements

### Cold Shutdown Time

Source:

```text
submissions/src/lab05/vm_halt_time.txt
```

Result:

```text
10.49 seconds
```

### Cold Boot Time

Source:

```text
submissions/src/lab05/vm_boot_time.txt
```

Result:

```text
28.72 seconds
```

### Idle Memory

Source:

```text
submissions/src/lab05/vm_free_h.txt
```

Output:

```text
Mem: 957Mi total, 176Mi used, 633Mi available
```

### Process Count

Source:

```text
submissions/src/lab05/vm_process_count.txt
```

Output:

```text
106
```

### VM Disk Size

```text
3.73 GB
```

## Docker Measurements

### Container Startup

Source:

```text
submissions/src/lab05/docker_start_time.txt
```

Result:

```text
0.236 seconds
```

### Container Stop Time

Source:

```text
submissions/src/lab05/docker_stop_time.txt
```

Result:

```text
1.338 seconds
```

### Health Check

Source:

```text
submissions/src/lab05/docker_health.txt
```

Output:

```json
{"notes":5,"status":"ok"}
```

### Memory Usage

Source:

```text
submissions/src/lab05/docker_stats.txt
```

Output:

```text
7.914 MiB
```

### Process Count

Source:

```text
submissions/src/lab05/docker_top.txt
```

Output:

```text
2 processes
```

### Image Size

Source:

```text
submissions/src/lab05/docker_image_size.txt
```

Output:

```text
1.32 GB
```

---

## VM vs Container Comparison

| Dimension | Vagrant VM | Docker Container |
|------------|------------:|-----------------:|
| Cold start | 28.72 s | 0.236 s |
| Idle RAM | 176 MiB | 7.91 MiB |
| On-disk size | 3.73 GB | 1.32 GB |
| Process count | 106 | 2 |

### Analysis

The most surprising result was the difference in startup time. The Docker container started almost instantly, while the VM required nearly half a minute to boot. The memory difference was also significant. The VM consumed hundreds of megabytes because it runs a complete operating system, while the container only runs the application process.

Virtual machines are useful when strong isolation or different operating systems are required. Containers are better for stateless services, rapid deployment, and efficient resource utilization. These measurements help explain why containers became dominant for microservices. They start faster, consume less memory, and allow higher service density on the same hardware.
