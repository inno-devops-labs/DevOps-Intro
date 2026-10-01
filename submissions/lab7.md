# Lab 7 submission

**Note on tooling:** Lab 5 VM runs via **UTM** on Apple Silicon (VirtualBox doesn't work on arm64 Macs). The Ansible workflow is identical — inventory points at the same Vagrant-managed SSH endpoint (`127.0.0.1:2222`, vagrant user, private key from `.vagrant/machines/default/utm/`). The QuickNotes binary is built for `linux/arm64` (VM's architecture).

## Task 1 — Idempotent Deploy

### 1.1 — Layout

```
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── quicknotes         (linux/arm64 static binary, 6.5 MB)
│   └── seed.json
└── templates/
    └── quicknotes.service.j2
```

### 1.2 — inventory.ini

```ini
[quicknotes]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=/Users/witch/DevOps-Intro/.vagrant/machines/default/utm/private_key

[quicknotes:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3
```

Connectivity check:
```
$ ansible -i ansible/inventory.ini quicknotes-vm -m ping
quicknotes-vm | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 1.3 — playbook.yaml

```yaml
---
- name: Deploy QuickNotes to the Lab 5 VM
  hosts: quicknotes
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_group: quicknotes
    quicknotes_description: "QuickNotes service (managed by Ansible)"
    quicknotes_bin_path: /usr/local/bin/quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_listen_addr: ":8080"

  tasks:
    - name: Ensure quicknotes system group exists
      ansible.builtin.group:
        name: "{{ quicknotes_group }}"
        system: true
        state: present

    - name: Ensure quicknotes system user exists
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        system: true
        create_home: false
        shell: /usr/sbin/nologin
        state: present

    - name: Ensure data directory exists with correct ownership
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        mode: "0750"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ quicknotes_bin_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart quicknotes

    - name: Copy seed.json
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ quicknotes_data_dir }}/seed.json"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        mode: "0640"

    - name: Render systemd unit file
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: Restart quicknotes

    - name: Reload systemd daemon
      ansible.builtin.systemd:
        daemon_reload: true

    - name: Enable and start quicknotes service
      ansible.builtin.systemd:
        name: quicknotes.service
        enabled: true
        state: started

  handlers:
    - name: Restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes.service
        state: restarted
        daemon_reload: true
```

### 1.4 — templates/quicknotes.service.j2

```jinja
[Unit]
Description=QuickNotes — {{ quicknotes_description }}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ quicknotes_user }}
Group={{ quicknotes_group }}
WorkingDirectory={{ quicknotes_data_dir }}
Environment=ADDR={{ quicknotes_listen_addr }}
Environment=DATA_PATH={{ quicknotes_data_dir }}/notes.json
Environment=SEED_PATH={{ quicknotes_data_dir }}/seed.json
ExecStart={{ quicknotes_bin_path }}
Restart=on-failure
RestartSec=3

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths={{ quicknotes_data_dir }}

[Install]
WantedBy=multi-user.target
```

### 1.7 — First run + verification

First `ansible-playbook` run:

```
PLAY RECAP *********************************************************************
quicknotes-vm : ok=9  changed=8  unreachable=0  failed=0  skipped=0  rescued=0
```

Service is active and running:
```
$ ansible ... -a 'systemctl status quicknotes --no-pager | head -10'
● quicknotes.service - QuickNotes — QuickNotes service (managed by Ansible)
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled)
     Active: active (running) since ...
   Main PID: 3199 (quicknotes)
     CGroup: /system.slice/quicknotes.service
             └─3199 /usr/local/bin/quicknotes
```

Service reachable from host, seed data served:
```
$ curl -s http://localhost:18080/health | jq
{ "notes": 4, "status": "ok" }

$ curl -s http://localhost:18080/notes | jq
[
  { "id": 1, "title": "Welcome to QuickNotes", ... },
  { "id": 2, "title": "Read app/main.go first", ... },
  { "id": 3, "title": "DevOps mantra", ... },
  { "id": 4, "title": "Endpoint cheat-sheet", ... }
]
```

**Four seeded notes are served** — proving `seed.json` reached the VM and `SEED_PATH` is correctly wired.

### 1.5 — Design questions

**a) `command:` vs dedicated modules — which is idempotent, and why does it matter?**

`command:` / `shell:` run a string **unconditionally** and report `changed` every time. They have no way to know whether the action they perform was already done — Ansible just sees that a process ran and marks the task as changed. Dedicated modules (`user`, `group`, `file`, `copy`, `template`, `systemd`) are **state declarative**: you describe the desired end state, and the module compares current state to desired and only acts if they differ.

This matters because:
1. **Idempotency** is the core value proposition of configuration management — running the playbook twice should not restart every service, rewrite every file, and leave the system in a constant churn.
2. **Handlers rely on it** — `notify:` only fires when the underlying module reports `changed`. If you use `shell:` everywhere, handlers fire on every run, restarting services unnecessarily.
3. **Convergence vs. imperative scripts** — the whole point of Ansible over a bash script is that the same playbook can be run 1 or 100 times safely, and it will reconcile to the target state.

In this lab I used dedicated modules for all state changes: `group`, `user`, `file`, `copy`, `template`, `systemd`. No `shell:` anywhere.

**b) `notify:` and handlers — when do they fire, when not, why is that right?**

A handler is a task that is **only invoked by name** from a task's `notify:` field. It fires **once per play run**, at the end of the play, regardless of how many tasks notified it. The rule is: **the handler fires if and only if the notifying task reported `changed`**. If the notifying task reports `ok` (no change), `notify` is a no-op.

In this playbook:
- `Copy QuickNotes binary` and `Render systemd unit file` both `notify: Restart quicknotes`.
- **First run**: both tasks were `changed`, handler ran at the end. The service was restarted once (not twice — that's the "once per play" rule).
- **Second run**: both tasks were `ok`, handler did not fire. The service was left alone.
- **Variable change** (`:8080 → :9090`): binary copy was `ok`, template was `changed` → handler fired.

This is the right default because it makes "restart" a **consequence of change**, not an unconditional action. If handlers fired every run, you'd get:
- Downtime on every playbook invocation
- `changed` count inflated to the point of uselessness as an idempotency signal
- No way to distinguish "no-op run" from "something changed"

**c) Variable hierarchy — top 3 places for this lab**

Ansible has ~22 precedence levels; the top 3 for a small VM-deploy playbook:

1. **`vars:` block inside the playbook** — highest priority I'm using. These are the values that describe *this specific deployment*: user/group names, binary path, data dir, listen address. They belong here because they are the playbook's own contract — anyone reading `playbook.yaml` sees the exact values that will be applied, without chasing files.
2. **`group_vars/quicknotes.yml`** (or `group_vars/all.yml`) — the next level. I'd move environment-specific values here if I had more than one group of hosts: e.g. `staging` vs `production` group_vars with different `quicknotes_listen_addr`. For a single-host lab it's overkill.
3. **`defaults/main.yml` of a role** — the lowest precedence. If I refactored `playbook.yaml` into a role (`roles/quicknotes/`), I'd put sensible defaults here (e.g. `quicknotes_user: quicknotes`, `quicknotes_bin_path: /usr/local/bin/quicknotes`) so the role is reusable, and let the play-level `vars:` override them per environment.

Anti-pattern to avoid: putting env-specific values in `host_vars/` for a single host, or scattering variables across multiple levels when one would do.

**d) `gather_facts: true` — needed? What does turning it off save?**

I set `gather_facts: false` because **this playbook uses no facts**. It never references `ansible_distribution`, `ansible_os_family`, `ansible_memtotal_mb`, or any other discovered system attribute — every task's input comes from `vars:` or literal values.

Turning it off saves one round-trip of the `setup` module to the target VM: typically **1–3 seconds per play per host**. On a 3-second playbook that's a meaningful fraction. On 1000 hosts, it's a genuine operational cost (parallelism reduces wall-clock, but the total CPU spent on `setup` remains).

Rule of thumb: `gather_facts: true` (the default) when you need facts; `false` when you don't. For a small, explicit playbook like this one, facts are pure overhead.

## Task 2 — Idempotency + Selective Change

### 2.1 — Second run: `changed=0`

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

TASK [Ensure quicknotes system group exists]        ok
TASK [Ensure quicknotes system user exists]         ok
TASK [Ensure data directory exists ...]             ok
TASK [Copy QuickNotes binary]                       ok
TASK [Copy seed.json]                               ok
TASK [Render systemd unit file]                     ok
TASK [Reload systemd daemon]                        ok
TASK [Enable and start quicknotes service]          ok

PLAY RECAP *********************************************************************
quicknotes-vm : ok=8  changed=0  unreachable=0  failed=0
```

No handler fired. The playbook is idempotent.

### 2.2 — Variable change: selective re-run

Changed `quicknotes_listen_addr: ":8080"` → `":9090"`, ran again:

```
TASK [Copy QuickNotes binary]                       ok        ← unchanged
TASK [Copy seed.json]                               ok        ← unchanged
TASK [Render systemd unit file]                     changed   ← only this
TASK [Reload systemd daemon]                        ok
TASK [Enable and start quicknotes service]          ok

RUNNING HANDLER [Restart quicknotes]                changed   ← handler fired

PLAY RECAP *********************************************************************
quicknotes-vm : ok=9  changed=2  unreachable=0  failed=0
```

Exactly two `changed` tasks: the template and the handler. Every other task reported `ok`. Verified the service moved to the new port:

```
$ ansible ... -a 'ss -tlnp | grep -E ":(8080|9090)"'
LISTEN 0  4096  *:9090  *:*  users:(("quicknotes",pid=...,fd=3))
```

Then reverted `:9090` back to `:8080`, re-ran — same `changed=2`, service back on 8080, `curl /health` returns 200.

### 2.3 — `--check --diff` preview

Changed `:8080` → `:7070` but did **not** apply — ran with `--check --diff`:

```
TASK [Render systemd unit file]
--- before: /etc/systemd/system/quicknotes.service
+++ after:  /Users/witch/.ansible/tmp/.../quicknotes.service.j2
@@ -8,7 +8,7 @@
 User=quicknotes
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:8080
+Environment=ADDR=:7070
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes

changed: [quicknotes-vm]
```

The diff shows **exactly** what would change (one line in one file), without touching the VM. Then reverted the variable back to `:8080`; a final regular run reported `changed=0` (the file on the VM was never actually modified by `--check`).

### 2.2 — Design questions

**e) Why does the second run report `changed=0`? What do `file` / `template` check?**

Each state-declaring module compares **current state on the target** against the **desired state in the task**, and reports `changed` only if the two differ:

- `file:` (mode=directory) — checks: does the path exist? Is it a directory? Are owner/group/mode exactly as declared? Any mismatch → `changed`.
- `copy:` — computes a **checksum** (SHA-1) of the source file on the control node and compares it to the checksum of the destination file on the target. If they match, and owner/group/mode match, the task is `ok`.
- `template:` — **renders the Jinja2 template in memory on the control node** using the current variables, then compares the result byte-for-byte (and owner/group/mode) to the existing file on the target. Same bytes + same metadata → `ok`.
- `user:` / `group:` — check existence, and (for user) the primary group, shell, `create_home`, `system` flags. Anything declared but not matching → `changed`.
- `systemd:` (state=enabled+started) — checks whether the unit is enabled and active. Both true → `ok`.
- `systemd:` (daemon_reload=true) — checks the mtime of `/etc/systemd/system` against the last daemon-reload timestamp; if no unit files changed, it reports `ok`.

Because we declared all relevant attributes (owner, group, mode, contents) and they match after the first run, every task reports `ok` on subsequent runs.

**f) What if I used `shell: echo "ADDR=..." > /etc/systemd/system/...` instead of `template:`?**

Trace of the failure modes:

1. **No idempotency.** `shell:` always reports `changed`. Every playbook run rewrites the unit file → `notify: Restart quicknotes` fires → service restarts on every run. Downtime for no reason.
2. **No variable safety.** A literal `echo "ADDR=:8080"` bakes the value into the command. Changing `quicknotes_listen_addr` in `vars:` would have zero effect unless the shell string is also edited. That breaks the entire "change one variable, only the template task reacts" property we demonstrated in Task 2.2.
3. **No handler wiring without extra machinery.** `shell:` can `notify:`, but since it always reports `changed`, the handler always fires — defeating the point.
4. **Quoting hell.** With `shell:` you have to handle: shell escapes, `$` variable expansion inside double quotes, redirection errors, file mode/owner (shell `>` creates a file with default umask, not `0644 root:root`), and — worst — content that includes `"`, `$`, or backticks needs careful escaping.
5. **No `--check --diff` support.** `shell:` gives up on diff. You lose the ability to preview "what would change" — which was one of the graded deliverables in Task 2.3.
6. **No ownership/mode declaration.** `shell:` can't set mode/owner declaratively; you'd need a follow-up `file:` task anyway.

The right answer to "how do I write a file with dynamic content" is always `template:` (for Jinja2) or `copy:` (for static). `shell:` is the last resort when no module exists for the task.

**g) `--check` alone vs `--check --diff` — what bug does `--diff` catch?**

`--check` tells you **whether** a task would change. `--check --diff` tells you **what** it would change.

The bug `--check --diff` catches and `--check` alone misses: **"changed for the wrong reason."** Concrete example — a template that is subtly wrong:

```
$ ansible-playbook ... --check
TASK [Render systemd unit file]  changed        ← suspicious, but no detail
```

`--check` says "something changed." It could be a legitimate change (a new variable) or it could be a bug (a missing trailing newline in the template that flips every run into `changed`, a wrong variable name that renders as empty string, a typo that changes whitespace). Without the diff you don't know which.

With `--diff`:

```
$ ansible-playbook ... --check --diff
--- before
+++ after
-Environment=ADDR=:8080
+Environment=ADDR=:
```

…the bug is immediately visible: the variable rendered as empty because `{{ quicknotes_listen_adrr }}` has a typo. Applying this in production would break the service (empty listen address) — but plain `--check` would have said "changed" and you'd only discover the problem after the run.

`--diff` also catches "silent" changes like trailing whitespace, line-ending differences (CRLF vs LF), which are invisible to `--check` alone.

The professional pattern: `--check --diff` before every production deploy, always.
