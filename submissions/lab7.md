# Lab 7 Submission — Configuration Management with Ansible

## Task 1 — Idempotent Deploy to the Lab 5 VM

### Environment

```text
Ansible community version 10.7.0
```

The target is the Lab 5 VirtualBox VM exposed through Vagrant SSH on `127.0.0.1:2222`.

### Inventory

```ini
[quicknotes_vm]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key ansible_python_interpreter=/usr/bin/python3 ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

### Playbook

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes_vm
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    data_dir: /var/lib/quicknotes
    data_path: /var/lib/quicknotes/notes.json
    seed_path: /var/lib/quicknotes/seed.json
    listen_addr: ":8080"
    restart_sec: 3

  tasks:
    - name: Create QuickNotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false

    - name: Create QuickNotes data directory
      ansible.builtin.file:
        path: "{{ data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0750"

    - name: Copy seed data
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ seed_path }}"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0640"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: /usr/local/bin/quicknotes
        owner: root
        group: root
        mode: "0755"
      notify: Restart QuickNotes

    - name: Install QuickNotes systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: Restart QuickNotes

    - name: Enable and start QuickNotes
      ansible.builtin.systemd_service:
        name: quicknotes
        enabled: true
        state: started
        daemon_reload: true

  handlers:
    - name: Restart QuickNotes
      ansible.builtin.systemd_service:
        name: quicknotes
        state: restarted
        daemon_reload: true
```

### systemd template

```ini
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/quicknotes
User=quicknotes
Group=quicknotes
WorkingDirectory={{ data_dir }}
Environment="ADDR={{ listen_addr }}"
Environment="DATA_PATH={{ data_path }}"
Environment="SEED_PATH={{ seed_path }}"
Restart=on-failure
RestartSec={{ restart_sec }}

[Install]
WantedBy=multi-user.target
```

### First deployment

First real run:

```text
TASK [Create QuickNotes system user]
changed: [quicknotes-vm]

TASK [Create QuickNotes data directory]
changed: [quicknotes-vm]

TASK [Copy seed data]
changed: [quicknotes-vm]

TASK [Copy QuickNotes binary]
changed: [quicknotes-vm]

TASK [Install QuickNotes systemd unit]
changed: [quicknotes-vm]

TASK [Enable and start QuickNotes]
ok: [quicknotes-vm]

RUNNING HANDLER [Restart QuickNotes]
changed: [quicknotes-vm]

PLAY RECAP
quicknotes-vm : ok=7 changed=6 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

### Service verification

```text
$ vagrant ssh -c "systemctl is-active quicknotes && systemctl is-enabled quicknotes"

active
enabled
```

Health endpoint:

```text
$ curl -s http://localhost:18080/health

{"notes":4,"status":"ok"}
```

Seeded notes:

```text
$ curl -s http://localhost:18080/notes

[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]
```

The four seeded notes prove that `seed.json` was deployed and `SEED_PATH` is correct.

## Design questions — Task 1

### a) `command` vs dedicated modules

`command` executes a command and is not idempotent by default because Ansible does not automatically know whether the desired state already exists.

Dedicated modules such as `user`, `file`, `copy`, `template`, and `systemd` understand the resource they manage. They compare the current state with the desired state and change only what is necessary.

This matters because an idempotent playbook can safely be executed repeatedly without causing unnecessary changes.

### b) `notify` and handlers

A handler is notified only when the task containing `notify` reports a change.

For example, if the QuickNotes binary or rendered systemd unit changes, the `Restart QuickNotes` handler runs. If neither file changes, the handler does not run.

Handlers normally execute at the end of the play. This avoids unnecessary service restarts when the configuration is already correct.

### c) Variable hierarchy

Three useful locations for variables in this lab are:

1. Playbook `vars` for simple values used specifically by this deployment, such as `data_dir` and `restart_sec`.
2. `group_vars` for configuration shared by a group of hosts, for example using different ports for development and production groups.
3. Extra variables passed with `-e` for temporary or deployment-time overrides.

This allows one playbook and template to be reused for different environments without hard-coding every value.

### d) `gather_facts`

This playbook does not need gathered host facts because it uses fixed paths, usernames, service names, and configuration values.

Therefore I use:

```yaml
gather_facts: false
```

This avoids the fact-gathering step and reduces the time and SSH work required for every playbook run.

---

## Task 2 — Idempotency and Selective Re-run

### Second run — zero changes

The playbook was executed again without changing anything:

```text
TASK [Create QuickNotes system user]
ok: [quicknotes-vm]

TASK [Create QuickNotes data directory]
ok: [quicknotes-vm]

TASK [Copy seed data]
ok: [quicknotes-vm]

TASK [Copy QuickNotes binary]
ok: [quicknotes-vm]

TASK [Install QuickNotes systemd unit]
ok: [quicknotes-vm]

TASK [Enable and start QuickNotes]
ok: [quicknotes-vm]

PLAY RECAP
quicknotes-vm : ok=6 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

This proves that the deployment is idempotent.

### Selective change and handler

I changed:

```yaml
restart_sec: 2
```

to:

```yaml
restart_sec: 3
```

The next run produced:

```text
TASK [Create QuickNotes system user]
ok: [quicknotes-vm]

TASK [Create QuickNotes data directory]
ok: [quicknotes-vm]

TASK [Copy seed data]
ok: [quicknotes-vm]

TASK [Copy QuickNotes binary]
ok: [quicknotes-vm]

TASK [Install QuickNotes systemd unit]
changed: [quicknotes-vm]

TASK [Enable and start QuickNotes]
ok: [quicknotes-vm]

RUNNING HANDLER [Restart QuickNotes]
changed: [quicknotes-vm]

PLAY RECAP
quicknotes-vm : ok=7 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

Only the rendered template changed, which caused the restart handler to run. The other resources remained unchanged.

### `--check --diff`

For the dry-run preview, I changed `restart_sec` from `3` to `4` and ran:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
```

Relevant diff:

```diff
--- before: /etc/systemd/system/quicknotes.service
+++ after: quicknotes.service.j2
@@ -12,7 +12,7 @@
 Environment="DATA_PATH=/var/lib/quicknotes/notes.json"
 Environment="SEED_PATH=/var/lib/quicknotes/seed.json"
 Restart=on-failure
-RestartSec=3
+RestartSec=4

 [Install]
 WantedBy=multi-user.target
```

Result:

```text
TASK [Install QuickNotes systemd unit]
changed: [quicknotes-vm]

RUNNING HANDLER [Restart QuickNotes]
changed: [quicknotes-vm]

PLAY RECAP
quicknotes-vm : ok=7 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

Because this was check mode, the change was only predicted and was not applied.

## Design questions — Task 2

### e) Why does the second run report `changed=0`?

Each idempotent module compares the actual resource with the desired state.

For example, the `file` module checks properties such as the path, type, ownership, group, and permissions.

The `template` module renders the expected file and compares it with the file already present on the target. If the contents and metadata already match, no update is necessary.

Because all resources already matched the playbook on the second run, Ansible reported `changed=0`.

### f) Why not use `shell` to generate the unit?

Using something like:

```yaml
shell: 'echo "..." > /etc/systemd/system/quicknotes.service'
```

would lose the main benefits of the `template` module.

Ansible would not naturally manage the file as declarative state, detecting content differences would be harder, quoting and escaping would become more fragile, and the command could be reported as changed every run.

That could also cause the restart handler to run unnecessarily every time.

The template module instead renders the desired file, compares it with the existing file, and reports a change only when the generated result actually differs.

### g) Why use `--check --diff` instead of only `--check`?

Plain `--check` tells me which tasks Ansible expects to change.

`--check --diff` also shows the exact content difference.

For example, it showed that:

```text
RestartSec=3
```

would become:

```text
RestartSec=4
```

This can catch a wrong value, incorrect path, accidental deletion, or unexpected template output before deploying it. Plain check mode could tell me that the unit file would change without showing exactly what would change.
