## Task 2 - Snapshots: Save, Break, Restore

### Initial working state

Before taking the snapshot, I confirmed that the VM was running and that QuickNotes worked correctly.

Commands:

```powershell
vagrant status
vagrant ssh -c "go version"
vagrant ssh -c "curl -s http://localhost:8080/health"
curl.exe -s http://localhost:18080/health
```

Output:

```text
Current machine states:

default                   running (virtualbox)

The VM is running.
go version go1.24.5 linux/amd64
{"notes":6,"status":"ok"}
{"notes":6,"status":"ok"}
```

This shows that the VM was running, Go 1.24.5 was installed inside the guest, QuickNotes responded inside the VM on port 8080, and the host could reach it through the forwarded port 18080.

---

### Snapshot save

I saved a clean working snapshot named `quicknotes-clean`.

Command:

```powershell
vagrant snapshot save quicknotes-clean
```

Output:

```text
==> default: Snapshotting the machine as 'quicknotes-clean'...
==> default: Snapshot saved! You can restore the snapshot at any time by
==> default: using `vagrant snapshot restore`. You can delete it using
==> default: `vagrant snapshot delete`.
```

I then listed the snapshots to confirm it was created.

Command:

```powershell
vagrant snapshot list
```

Output:

```text
==> default:
quicknotes-clean
```

---

### Break the VM deliberately

To break the VM, I removed the Go installation and the Go binaries from the guest.

Command:

```powershell
vagrant ssh -c "sudo rm -rf /usr/local/go /usr/local/bin/go /usr/local/bin/gofmt"
```

I verified that the VM was broken by checking the Go version again.

Command:

```powershell
vagrant ssh -c "go version"
```

Output:

```text
bash: line 1: go: command not found
```

This proves that the VM was deliberately broken because the Go toolchain was no longer available.

---

### Restore from snapshot

I restored the VM from the `quicknotes-clean` snapshot and measured the restore time using PowerShell's `Measure-Command`.

Command:

```powershell
$restoreTime = Measure-Command { vagrant snapshot restore quicknotes-clean }
$restoreTime
```

Output:

```text
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 18
Milliseconds      : 74
Ticks             : 180741974
TotalDays         : 0.000209192099537037
TotalHours        : 0.00502061038888889
TotalMinutes      : 0.301236623333333
TotalSeconds      : 18.0741974
TotalMilliseconds : 18074.1974
```

The restore took approximately **18.07 seconds**.

---

### Verify recovery

After restoring the snapshot, I verified that Go was available again and that QuickNotes was still reachable both inside the VM and from the host.

Commands:

```powershell
vagrant ssh -c "go version"
vagrant ssh -c "curl -s http://localhost:8080/health"
curl.exe -s http://localhost:18080/health
```

Output:

```text
go version go1.24.5 linux/amd64
{"notes":6,"status":"ok"}
{"notes":6,"status":"ok"}
```

This confirms that restoring the snapshot successfully recovered the VM to the previous working state.

---

### Design questions

#### e) Snapshots are not backups

Snapshots are not backups because they usually depend on the original VM disk and are often stored on the same host. If the host disk fails, the VM directory is deleted, or the snapshot chain becomes corrupted, the snapshot may be lost together with the VM. A real backup should be independent from the original machine and restorable somewhere else.

#### f) Copy-on-write

Copy-on-write means that taking a snapshot does not immediately create a full duplicate of the VM disk. Instead, VirtualBox keeps the original disk state and stores only the blocks that change after the snapshot. This means that 10 snapshots may initially use much less space than 10 full VM copies, but disk usage grows as more changes are made across the snapshot chain.

#### g) When is snapshotting an antipattern?

Snapshotting becomes an antipattern when it replaces proper automation, provisioning, or backups. Long chains of snapshots can become fragile, consume increasing disk space, and make the VM harder to reason about. For long-term infrastructure, it is better to rebuild the environment from code using tools such as Vagrant provisioning or Ansible rather than relying on a pile of old VM states.
