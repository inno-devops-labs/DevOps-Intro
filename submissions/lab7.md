# Lab 7 - Configuration Management: Deploy QuickNotes via Ansible

## Task 1 - Idempotent Deploy to the Lab 5 VM

### Setup

- Host: MacBook Air (Apple Silicon), Ansible 10.7.0 (ansible-core 2.17.14, Python 3.12)
- Target: Lab 5 Vagrant VM `quicknotes-vm` (Ubuntu 24.04 arm64, VirtualBox), recreated with `vagrant up` from the Lab 5 Vagrantfile
- Port forward: host `127.0.0.1:18080` -> guest `8080`
- The binary is built as a static Linux ARM64 executable, because the VM runs on ARM:

```bash
cd app
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o ../ansible/files/quicknotes .
```

### Files

- Playbook: [ansible/playbook.yaml](../ansible/playbook.yaml)
- Inventory: [ansible/inventory.ini](../ansible/inventory.ini) (values from `vagrant ssh-config`)
- Unit template: [ansible/templates/quicknotes.service.j2](../ansible/templates/quicknotes.service.j2)
- Shipped files: [ansible/files/quicknotes](../ansible/files/quicknotes), [ansible/files/seed.json](../ansible/files/seed.json)

### First run

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] *******************************************************

TASK [Create quicknotes group] *************************************************
changed: [quicknotes-vm]

TASK [Create quicknotes system user] *******************************************
changed: [quicknotes-vm]

TASK [Ensure data directory exists] ********************************************
changed: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
changed: [quicknotes-vm]

TASK [Copy seed data] **********************************************************
changed: [quicknotes-vm]

TASK [Render systemd unit] *****************************************************
changed: [quicknotes-vm]

TASK [Run pending handlers before starting the service] ************************

RUNNING HANDLER [reload systemd] ***********************************************
ok: [quicknotes-vm]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [quicknotes-vm]

TASK [Enable and start QuickNotes] *********************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=9    changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Service status

```text
$ vagrant ssh -c "systemctl status quicknotes --no-pager"
● quicknotes.service - QuickNotes service
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-10-01 17:05:19 UTC; 15s ago
   Main PID: 2411 (quicknotes)
     CGroup: /system.slice/quicknotes.service
             └─2411 /usr/local/bin/quicknotes
```

### Verification from the host

```text
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}

$ curl -s http://localhost:18080/notes
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]
```

`/notes` returns the 4 seeded notes, not `[]`, so `seed.json` reached the VM and `SEED_PATH` points to the right file.

### Design questions

**a) `command:` vs dedicated modules**

`command:` just runs a program. Ansible doesn't know what the program does, so it can't check whether the work is already done. It runs every time and reports `changed` every time. Dedicated modules (`apt`, `file`, `copy`, `systemd`) describe a desired state: they first check the current state and only act if it's different. So the modules are idempotent and `command:` is not (unless you add `creates:` / `changed_when:` by hand).

It matters because: re-running the playbook is safe, `changed` in the recap shows real changes, handlers only fire on real changes, and `--check` can predict what will happen.

**b) `notify:` and handlers**

A handler fires when a task that notifies it reports `changed`. It runs at the end of the play (or earlier at `meta: flush_handlers`), and only once, even if several tasks notified it. In this playbook, a new binary or a new unit file restarts the service.

It does not fire when the notifying task reports `ok` (nothing changed), when the task fails (the play stops for that host), or when the `notify:` name doesn't exactly match the handler name.

This is the right default because a restart causes a short downtime. We only want it when something actually changed, and only once per run, not once per changed file.

**c) Variable hierarchy - top 3 places for this lab**

1. **Play `vars:`** (used here) - all values in one file next to the tasks. Simple and clear for one playbook and one VM.
2. **`group_vars/quicknotes.yml`** - values per group of hosts, for example a different `listen_addr` for dev and prod. The playbook stays the same, only the inventory data changes. This is the next step if the project grows.
3. **Extra vars (`-e listen_addr=:9090`)** - highest precedence, good for a one-time override from the command line without editing files.

(If the deploy became a role, the base values would go into role `defaults/`, the lowest precedence, so anything above can override them.)

**d) `gather_facts`**

Not needed. The playbook doesn't use any facts: no OS-specific conditions, no IP addresses, no hardware info. All paths and values are fixed variables. So it's set to `false`.

Turning it off skips the `setup` module, which runs on every host at the start of every play and collects a lot of system information (OS, CPUs, memory, network, disks). That saves one extra remote task per host, usually around 1-2 seconds per run here, and much more with many hosts.

## Task 2 - Prove Idempotency + Selective Re-run

### 2.1.1 Second run - no changes

Same playbook, nothing edited:

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] *******************************************************

TASK [Create quicknotes group] *************************************************
ok: [quicknotes-vm]

TASK [Create quicknotes system user] *******************************************
ok: [quicknotes-vm]

TASK [Ensure data directory exists] ********************************************
ok: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
ok: [quicknotes-vm]

TASK [Copy seed data] **********************************************************
ok: [quicknotes-vm]

TASK [Render systemd unit] *****************************************************
ok: [quicknotes-vm]

TASK [Run pending handlers before starting the service] ************************

TASK [Enable and start QuickNotes] *********************************************
ok: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`changed=0`, and no handlers ran, so the service was not restarted.

### 2.1.2 One variable changed - selective change

Changed `listen_addr` from `":8080"` to `":9090"` in `playbook.yaml`:

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] *******************************************************

TASK [Create quicknotes group] *************************************************
ok: [quicknotes-vm]

TASK [Create quicknotes system user] *******************************************
ok: [quicknotes-vm]

TASK [Ensure data directory exists] ********************************************
ok: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
ok: [quicknotes-vm]

TASK [Copy seed data] **********************************************************
ok: [quicknotes-vm]

TASK [Render systemd unit] *****************************************************
changed: [quicknotes-vm]

TASK [Run pending handlers before starting the service] ************************

RUNNING HANDLER [reload systemd] ***********************************************
ok: [quicknotes-vm]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [quicknotes-vm]

TASK [Enable and start QuickNotes] *********************************************
ok: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=9    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

- Only the `template` task changed.
- The `restart quicknotes` handler fired (plus `reload systemd`, so systemd re-reads the unit).
- All other tasks are `ok`.
- `changed=2` = the template change + the restart done by the handler.

### 2.1.3 `--check --diff` preview

Third change: `listen_addr` from `":9090"` back to `":8080"`, previewed before applying:

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff

TASK [Render systemd unit] *****************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/iliakulichenko/.ansible/tmp/ansible-local-40174nbhian1c/tmpwfm3mar_/quicknotes.service.j2
@@ -9,7 +9,7 @@
 User=quicknotes
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment="ADDR=:9090"
+Environment="ADDR=:8080"
 Environment="DATA_PATH=/var/lib/quicknotes/notes.json"
 Environment="SEED_PATH=/var/lib/quicknotes/seed.json"
 ExecStart=/usr/local/bin/quicknotes

changed: [quicknotes-vm]

RUNNING HANDLER [reload systemd] ***********************************************
ok: [quicknotes-vm]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=9    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Exactly one line in the unit file would change. Nothing was applied in check mode; after that, a normal run applied it, and `curl http://localhost:18080/health` worked again.

### Design questions

**e) Why does the second run report `changed=0`?**

Every module compares the desired state with the real state on the VM and only acts if they differ:

- `file` uses `stat` on the path: does it exist, is it a directory, and do owner, group, and mode match? All matched, so `ok`.
- `template` renders the template on the control node, calculates its checksum (SHA1), and compares it with the checksum of the file on the VM. It also checks owner, group, and mode. Same checksum and same attributes, so nothing is copied.
- `copy` does the same checksum comparison for the binary and the seed.
- `user` / `group` check the existing accounts, and `systemd` checks whether the unit is already enabled and active.

Since nothing differed, no task changed anything, so no handler was notified.

**f) What if `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` replaced `template:`?**

- **The unit file would be broken.** `>` replaces the whole file with that one line, so `[Unit]`, `[Service]`, `ExecStart=`, `User=` are all gone. That's not a valid unit, so after a reload the service can't start - the deploy itself takes the app down.
- **Not idempotent.** `shell:` runs every time and always reports `changed`. The recap can't tell real changes from no changes anymore, and `changed=0` is impossible.
- **Handlers break too.** With `notify:`, the service restarts on every run, even when nothing changed (needless downtime). Without `notify:`, a real change is written but never applied.
- **No control over the file.** Owner and mode depend on the shell's umask, and quoting or special characters (`$`, `"`) in values can break the command or the content.
- **No preview.** In `--check` mode, `shell:` tasks are skipped, and `--diff` shows nothing, so you can't see what would happen before a deploy.

**g) What does `--check --diff` catch that plain `--check` misses?**

Plain `--check` only says *that* a task would change, not *what* would change. For example, `changed=1` on the template looks correct for a planned port change. But the diff shows the real content: maybe a typo rendered `ADDR=:80800`, a wrong `SEED_PATH`, or a variable with higher precedence (for example in `group_vars`) overrode the value you edited. `--check` would show "1 change, as expected", while `--diff` shows the change is wrong.

It also catches configuration drift: if someone edited the file on the server by hand, the diff shows those lines being removed, so you know about it before the deploy silently overwrites them.
