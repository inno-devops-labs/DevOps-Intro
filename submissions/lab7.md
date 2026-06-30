# Lab 7 Submission - Configuration Management: Deploy QuickNotes via Ansible

---

## Task 1 - Idempotent Deploy to the Lab 5 VM

### 1.1 Layout

```text
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── quicknotes          (static linux/amd64 binary, CGO_ENABLED=0)
│   └── seed.json           (initial notes, shipped for SEED_PATH)
└── templates/
    └── quicknotes.service.j2
```

### 1.2 inventory.ini

```ini
[quicknotes_vm]
qn-vm-1 ansible_host=127.0.0.1 ansible_port=2222

[quicknotes_vm:vars]
ansible_user=vagrant
ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa
```

The host/port/key were taken directly from `vagrant ssh-config` (HostName `127.0.0.1`, Port `2222`, User `vagrant`, the generated `private_key`).

### 1.3 playbook.yaml

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes_vm
  become: true
  gather_facts: false

  vars:
    app_user: quicknotes
    app_group: quicknotes
    data_dir: /var/lib/quicknotes
    binary_path: /usr/local/bin/quicknotes
    listen_addr: ":8080"
    data_path: "{{ data_dir }}/notes.json"
    seed_path: "{{ data_dir }}/seed.json"

  tasks:
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: "{{ app_user }}"
        system: true
        shell: /usr/sbin/nologin
        home: "{{ data_dir }}"
        create_home: false

    - name: Ensure data directory exists
      ansible.builtin.file:
        path: "{{ data_dir }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: "0750"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ binary_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart quicknotes

    - name: Copy seed data
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ seed_path }}"
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: "0640"

    - name: Render systemd unit from template
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: Restart quicknotes

    - name: Reload systemd, enable and start quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: started
        enabled: true
        daemon_reload: true

  handlers:
    - name: Restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
        daemon_reload: true
```

### 1.4 templates/quicknotes.service.j2

```jinja
# {{ ansible_managed }}
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ app_user }}
Group={{ app_group }}
WorkingDirectory={{ data_dir }}
ExecStart={{ binary_path }}
Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ data_path }}
Environment=SEED_PATH={{ seed_path }}
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

Every value in the unit (`User`, `WorkingDirectory`, `ExecStart`, and all three `Environment=` lines) is rendered from a playbook variable, so changing a variable changes the deployed unit. The binary's env contract is `ADDR` (default `:8080`), `DATA_PATH` (default `data/notes.json`), `SEED_PATH` (default `seed.json`); since the defaults are relative, `WorkingDirectory` is set to the data dir and absolute paths are passed explicitly.

### 1.5 Build + connectivity

```text
$ ( cd app && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o ../ansible/files/quicknotes . )
$ file ansible/files/quicknotes
ansible/files/quicknotes: ELF 64-bit LSB executable, x86-64, statically linked, ...

$ ansible -i ansible/inventory.ini quicknotes_vm -m ping
qn-vm-1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 1.6 First-run PLAY RECAP

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] ********************************************************

TASK [Create quicknotes system user] *******************************************
changed: [qn-vm-1]
TASK [Ensure data directory exists] ********************************************
changed: [qn-vm-1]
TASK [Copy QuickNotes binary] **************************************************
changed: [qn-vm-1]
TASK [Copy seed data] **********************************************************
changed: [qn-vm-1]
TASK [Render systemd unit from template] ***************************************
changed: [qn-vm-1]
TASK [Reload systemd, enable and start quicknotes] *****************************
changed: [qn-vm-1]
RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [qn-vm-1]

PLAY RECAP *********************************************************************
qn-vm-1  : ok=7  changed=7  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

### 1.7 Service reachable

```text
$ ansible -i ansible/inventory.ini quicknotes_vm -b -m shell -a "systemctl is-active quicknotes"
qn-vm-1 | CHANGED | rc=0 >>
active

$ curl -s http://localhost:18080/health ; echo
{"notes":4,"status":"ok"}
```

The Vagrantfile forwards host `127.0.0.1:18080` -> guest `:8080`, and the service listens on `ADDR=:8080`, so the health endpoint is reachable from the host.

### 1.8 Design Questions

**a) `command:` vs the dedicated modules (`apt`, `file`, `copy`, `systemd`) - which is idempotent and why does it matter?**
`command:`/`shell:` just execute a process on the target. They have no concept of desired vs. current state, so they run every time and report `changed` on every run (unless you hand-write `creates:`/`changed_when:`). The dedicated modules are declarative: they inspect the current state (does the user exist? does the file's checksum/owner/mode already match? is the service running?) and only act on the delta, reporting `changed` accurately. The dedicated modules are idempotent; `command`/`shell` are not by default. It matters because (1) re-running after a partial failure is safe, (2) accurate `changed` status is what drives handlers, wrong status means needless restarts or missed ones, and (3) `--check`/`--diff` only work meaningfully with state-aware modules.

**b) `notify:` and handlers - when does a handler fire, when does it not, why is that the right default?**
A handler fires only when a task that notifies it reports `changed=true`. It does not fire when the task is `ok` (state already correct), skipped, or failed. Handlers are de-duplicated and run once, at the end of the play, even if notified by several tasks. This is the right default because the goal of config management is convergence: you only want to restart/reload a service when one of its actual inputs (the binary or the unit file here) changed. On an unchanged re-run nothing is notified, so the service is not bounced - no needless downtime.

**c) Variable hierarchy — top 3 places you'd put a variable for this lab, and why.**
Ansible has ~22 precedence levels; the three I'd actually use here, lowest-to-highest precedence:
1. **`defaults/main.yaml`** (if this were a role) — structural constants like `data_dir`, `binary_path`. Lowest precedence so anyone can override them without editing the role.
2. **`group_vars/quicknotes_vm`** - per-environment values such as `listen_addr` (`:8080` in dev, `:80` in prod). This is where environment variation belongs so the same playbook serves multiple inventories.
3. **playbook `vars:`** (what I used) - convenient for a single play/single host, and higher precedence than defaults/group_vars. For the Task 2 tweak I could also use **`-e listen_addr=:9090`** (extra-vars, highest precedence) to override for one run without editing any file.
For this small single-host lab I kept everything in playbook `vars:`; if it grew to multiple environments I'd push `listen_addr` down into `group_vars` and the constants into `defaults`.

**d) `gather_facts: true` is the default - do you need it here? What does turning it off save?**
No. The playbook references no facts (no `ansible_distribution`, `ansible_default_ipv4`, etc.), every value is a static var or module parameter. So I set `gather_facts: false`. Turning it off skips the implicit `setup` module that runs against the target at the start of every play, saving the fact-gathering round-trip (a few seconds here, and it scales with host count and latency). Trade-off: if I later needed OS-conditional logic I'd re-enable it or use a narrow `gather_subset`.

---

## Task 2 - Prove Idempotency + Selective Re-run

### 2.1 Second run = zero changes

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
...
TASK [Render systemd unit from template] ***************************************
ok: [qn-vm-1]
TASK [Reload systemd, enable and start quicknotes] *****************************
ok: [qn-vm-1]

PLAY RECAP *********************************************************************
qn-vm-1  : ok=6  changed=0  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

No `RUNNING HANDLER` line - nothing changed, so the handler was never notified.

### 2.2 Variable tweak = selective change

Changed `listen_addr` from `:8080` to `:9090` in `playbook.yaml`, then re-ran.

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
...
TASK [Copy QuickNotes binary] **************************************************
ok: [qn-vm-1]
TASK [Copy seed data] **********************************************************
ok: [qn-vm-1]
TASK [Render systemd unit from template] ***************************************
changed: [qn-vm-1]
TASK [Reload systemd, enable and start quicknotes] *****************************
ok: [qn-vm-1]
RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [qn-vm-1]

PLAY RECAP *********************************************************************
qn-vm-1  : ok=7  changed=2  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

Only the `template` task changed (the rendered unit differed), which notified the handler, every other task stayed `ok`. `changed=2` = the template task + the handler.

### 2.3 `--check --diff` preview

Made a third variable change and ran with `--check --diff`.

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
...
TASK [Render systemd unit from template] ***************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after:  .../tmp/.../quicknotes.service.j2
@@ -10,7 +10,7 @@
 WorkingDirectory=/var/lib/quicknotes
 ExecStart=/usr/local/bin/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:8080
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
changed: [qn-vm-1]

PLAY RECAP *********************************************************************
qn-vm-1  : ok=7  changed=2  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

`--check` ran the play without writing anything; `--diff` printed the exact line-level change to the unit file (`ADDR=:9090` -> `:8080`) — the preview a human reviews before a real deploy.

### 2.4 Design Questions

**e) Why does the second run report `changed=0`? What does `file`/`template` check?**
Each module compares desired state to actual state and only writes on a difference. `copy` computes the checksum of the source file and compares it to the destination's checksum, plus owner/group/mode; identical - no change. `template` renders the Jinja2 to a temporary file, checksums the rendered output, and compares it (and metadata) to the existing destination; it only replaces the file if the rendered bytes differ. `file` checks the path's existence, type, owner, group, and mode. On an unchanged second run all of these already match, so every task reports `ok`, `changed=0`, and no handler is notified.

**f) What if you used `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` instead of `template:`? Trace the failure modes.**
- **Not idempotent:** `shell` runs unconditionally and reports `changed` every run, so the restart handler fires on *every* run - needless restarts/downtime.
- **No content comparison:** `>` truncates and rewrites the file every time even when the contents are identical; there's no checksum check.
- **Non-atomic write:** a redirect writes in place; an interruption can leave a half-written unit file. `template` writes to a temp file and atomically renames it.
- **No `--check`/`--diff`:** you can't dry-run or preview the change.
- **No managed owner/mode**, and **quoting/escaping hell** for multi-line unit content, colons, and env values, fragile and easy to corrupt. You'd also be doing variable substitution in the shell instead of Jinja2.

**g) `--check` is dry-run, `--diff` shows changes - what bug do you catch with `--check --diff` that plain `--check` misses?**
Plain `--check` only tells you a task *would* change something (`changed=1`); it doesn't show *what*. `--diff` shows the line-level content. The bug you catch: a template that would change in a way you didn't intend, e.g. a variable rendering to the wrong value (`ADDR=:9090` when you meant `:8080`), an accidental owner/mode/whitespace drift, or a template that rewrites the whole file every run (trailing-newline diff). With plain `--check` you'd see `changed=1` and assume it's benign; `--diff` reveals the exact unintended modification before it ships to production.

---
