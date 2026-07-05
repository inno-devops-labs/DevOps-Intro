# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

## Ansible Layout

```
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── quicknotes          (static arm64 binary, CGO_ENABLED=0)
│   └── seed.json
└── templates/
    └── quicknotes.service.j2
```

---

## `playbook.yaml`

```yaml
---
- name: Deploy QuickNotes to Vagrant VM
  hosts: quicknotes_vm
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_bin: /usr/local/bin/quicknotes
    quicknotes_service: quicknotes
    listen_addr: ":8080"
    data_path: /var/lib/quicknotes/notes.json
    seed_path: /var/lib/quicknotes/seed.json

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: "{{ quicknotes_service }}"
        state: restarted
        daemon_reload: true

  tasks:
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false

    - name: Ensure data directory exists
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0750"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ quicknotes_bin }}"
        owner: root
        group: root
        mode: "0755"
      notify: restart quicknotes

    - name: Copy seed.json to data directory
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ quicknotes_data_dir }}/seed.json"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0640"

    - name: Render systemd unit from template
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: restart quicknotes

    - name: Enable and start quicknotes service
      ansible.builtin.systemd:
        name: "{{ quicknotes_service }}"
        enabled: true
        state: started
        daemon_reload: true
```

---

## `inventory.ini`

```ini
[quicknotes_vm]
quicknotes ansible_host=127.0.0.1 ansible_port=50022 ansible_user=vagrant \
  ansible_ssh_private_key_file=.vagrant/machines/default/qemu/private_key \
  ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa'
```

Port and key path taken directly from `vagrant ssh-config`.

---

## `templates/quicknotes.service.j2`

```ini
[Unit]
Description=QuickNotes HTTP service
After=network-online.target
Wants=network-online.target

[Service]
User={{ quicknotes_user }}
WorkingDirectory={{ quicknotes_data_dir }}
ExecStart={{ quicknotes_bin }}
Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ data_path }}
Environment=SEED_PATH={{ seed_path }}
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

---

## Task 1 — First Run PLAY RECAP

```
PLAY [Deploy QuickNotes to Vagrant VM] *****************************************

TASK [Create quicknotes system user] *******************************************
changed: [quicknotes]

TASK [Ensure data directory exists] ********************************************
changed: [quicknotes]

TASK [Copy QuickNotes binary] **************************************************
changed: [quicknotes]

TASK [Copy seed.json to data directory] ****************************************
changed: [quicknotes]

TASK [Render systemd unit from template] ***************************************
changed: [quicknotes]

TASK [Enable and start quicknotes service] *************************************
changed: [quicknotes]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [quicknotes]

PLAY RECAP *********************************************************************
quicknotes                 : ok=7    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## `curl` proof

```
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}

$ curl -s http://localhost:18080/notes
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]
```

---

## Task 1 — Design Questions

### a) `command:` vs dedicated modules — idempotency

`command:` and `shell:` simply execute a shell string. They have no awareness of desired state: they run every time unconditionally, so Ansible always reports `changed=1` even when nothing actually needs doing. Dedicated modules like `apt`, `file`, `copy`, and `systemd` know the *desired* state and first check if the system already matches it. If it does, they do nothing and report `ok`. That check-then-act pattern is the definition of idempotency. It matters because a non-idempotent playbook cannot be run safely a second time — you lose the ability to detect drift and to use `--check` for safe pre-flight verification.

### b) `notify:` and handlers — when a handler fires and when it doesn't

A handler fires **once at the end of the play** (in the `RUNNING HANDLERS` section), and only if the task that `notify:`-ed it actually reported `changed`. If the task reports `ok` (nothing changed), the handler is never triggered. If multiple tasks notify the same handler, the handler still runs only once. This is the right default because restarting a service is disruptive — it should happen only when a real change was made (new binary or new config), not on every playbook run. Running handlers only when needed keeps the deploy safe and predictable.

### c) Variable hierarchy — top 3 places for this lab

1. **`vars:` block in the play** — used here. Highest-precedence "source of truth" when you want all variables visible in one place alongside the tasks. Good for lab-sized playbooks.
2. **`group_vars/quicknotes_vm.yaml`** — the right place for per-environment values (staging vs production addr, paths). Separates data from logic and scales when you add more hosts.
3. **`defaults/main.yaml` (role defaults)** — if the playbook were refactored into a role, defaults provide lowest-precedence fallbacks that are easy to override from any other level without touching the role itself.

### d) `gather_facts: true` — is it needed?

Not needed for this playbook. None of the tasks reference `ansible_*` facts (OS family, architecture, IP, etc.) — all values come from explicit variables. Turning it off with `gather_facts: false` saves one SSH round-trip that collects ~200 facts per host. On a single-VM lab run the saving is ~1–2 seconds; across 100 hosts it becomes significant enough to matter in CI.

---

## Task 2 — Second Run (Idempotency)

```
PLAY RECAP *********************************************************************
quicknotes                 : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`changed=0` — all tasks found the host already in the desired state.

---

## Task 2 — Variable Tweak: `listen_addr=:9090`

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml -e "listen_addr=:9090"
```

```
TASK [Create quicknotes system user] *******************************************
ok: [quicknotes]

TASK [Ensure data directory exists] ********************************************
ok: [quicknotes]

TASK [Copy QuickNotes binary] **************************************************
ok: [quicknotes]

TASK [Copy seed.json to data directory] ****************************************
ok: [quicknotes]

TASK [Render systemd unit from template] ***************************************
changed: [quicknotes]

TASK [Enable and start quicknotes service] *************************************
ok: [quicknotes]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [quicknotes]

PLAY RECAP *********************************************************************
quicknotes                 : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Only the `template` task changed (unit file rewritten) and the `restart quicknotes` handler fired. All other tasks: `ok`.

---

## Task 2 — `--check --diff` Preview (`listen_addr=:7070`)

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff -e "listen_addr=:7070"
```

```
TASK [Render systemd unit from template] ***************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/irina/.ansible/tmp/.../quicknotes.service.j2
@@ -7,7 +7,7 @@
 User=quicknotes
 WorkingDirectory=/var/lib/quicknotes
 ExecStart=/usr/local/bin/quicknotes
-Environment=ADDR=:8080
+Environment=ADDR=:7070
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 Restart=on-failure

changed: [quicknotes]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [quicknotes]

PLAY RECAP *********************************************************************
quicknotes                 : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

No actual changes were applied (dry-run mode).

---

## Task 2 — Design Questions

### e) Why does the second run report `changed=0`?

The `file` module computes the desired state (path, owner, group, mode) and compares it to the actual inode metadata on disk — if they match, it does nothing. The `template` module renders the Jinja2 template in memory and computes a checksum of the result, then compares it to the checksum of the existing file on the remote host. The `copy` module does the same with a local file checksum vs remote file checksum. The `user` module reads `/etc/passwd`. Because nothing changed between run 1 and run 2, every check passes and nothing is written — `changed=0`.

### f) `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` instead of `template:`

Multiple failure modes:
1. **Not idempotent**: `shell:` runs unconditionally, so every run overwrites the file and reports `changed=1`, triggering the `restart quicknotes` handler every time — unnecessary service disruptions.
2. **Truncation / quoting**: a complex unit file written via `echo` needs careful quoting (single vs double quotes, `$` signs); a missed escape silently corrupts the file.
3. **No diff**: `--check --diff` can't show what will change because `shell:` doesn't know the current content or the desired content.
4. **No checksum check**: the module won't detect if the file was manually edited between runs (drift is invisible).
5. **Permissions**: `echo ... >` inherits the shell's umask — you'd need an extra `chmod` task to set `0644`, adding another non-idempotent step.

### g) Bug caught by `--check --diff` that plain `--check` misses

`--check` tells you *which* tasks would change, but not *what* would change. With `--diff` you see the exact before/after diff of each file. A common production bug: a variable substitution renders an unexpected value (e.g., `{{ listen_addr }}` evaluates to an empty string because the variable was accidentally unset), making the unit file syntactically invalid. `--check` alone says "template: changed" — looks fine. `--check --diff` shows `-Environment=ADDR=:8080` / `+Environment=ADDR=` — the empty value is immediately visible, and you catch the misconfiguration before it kills the running service.
