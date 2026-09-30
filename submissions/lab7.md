# Lab 7 — Configuration Management: QuickNotes with Ansible

## Environment

- Host: macOS on Apple Silicon (`arm64`)
- Vagrant: 2.4.9
- VirtualBox: 7.2.20
- Guest: Ubuntu 24.04 LTS (`bento/ubuntu-24.04`)
- Ansible: `core 2.21.4`
- Python: `3.13.9 (Anaconda)`
- Jinja: `3.1.6`
- VM hostname: `quicknotes`
- SSH port: `2222`

## Task 1 — Ansible Setup

### Inventory

```ini
[quicknotes]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file="/Users/arinaagafonova/Documents/work/intro to DevOps/DevOps-Intro/.vagrant/machines/default/virtualbox/private_key" ansible_ssh_common_args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa"

[quicknotes:vars]
ansible_python_interpreter=/usr/bin/python3
```

### SSH configuration

```text
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile "/Users/arinaagafonova/Documents/work/intro to DevOps/DevOps-Intro/.vagrant/machines/default/virtualbox/private_key"
  IdentitiesOnly yes
  LogLevel FATAL
  PubkeyAcceptedKeyTypes +ssh-rsa
  HostKeyAlgorithms +ssh-rsa
```

### Connectivity test

```bash
ansible -i ansible/inventory.ini quicknotes -m ping
```

Output:

```text
quicknotes-vm | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

## Task 2 — Ansible Playbook

### Files

```text
ansible/
├── inventory.ini
├── playbook.yaml
├── bootstrap-pull.yaml               # bonus
├── files/
│   ├── quicknotes
│   ├── seed.json
│   └── local-inventory.ini           # bonus
└── templates/
    ├── quicknotes.service.j2
    ├── ansible-pull.service.j2       # bonus
    └── ansible-pull.timer.j2         # bonus
```

### `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes to Lab 5 VM
  hosts: quicknotes
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_group: quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_bin_path: /usr/local/bin/quicknotes
    quicknotes_addr: ":8080"
    quicknotes_seed_src: files/seed.json
    quicknotes_bin_src: files/quicknotes

  tasks:
    - name: Ensure system group quicknotes exists
      ansible.builtin.group:
        name: "{{ quicknotes_group }}"
        system: true
        state: present

    - name: Ensure system user quicknotes exists
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        system: true
        create_home: false
        shell: /usr/sbin/nologin
        state: present

    - name: Ensure data directory exists
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        mode: "0750"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: "{{ quicknotes_bin_src }}"
        dest: "{{ quicknotes_bin_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart quicknotes

    - name: Copy seed.json to data dir
      ansible.builtin.copy:
        src: "{{ quicknotes_seed_src }}"
        dest: "{{ quicknotes_data_dir }}/seed.json"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        mode: "0640"

    - name: Render systemd unit
      ansible.builtin.template:
        src: quicknotes.service.j2
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

### `ansible/templates/quicknotes.service.j2`

```jinja
[Unit]
Description=QuickNotes service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ quicknotes_user }}
Group={{ quicknotes_group }}
WorkingDirectory={{ quicknotes_data_dir }}
Environment=ADDR={{ quicknotes_addr }}
Environment=DATA_PATH={{ quicknotes_data_dir }}/notes.json
Environment=SEED_PATH={{ quicknotes_data_dir }}/seed.json
ExecStart={{ quicknotes_bin_path }}
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
```

### First run

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Output:

```text
PLAY [Deploy QuickNotes to Lab 5 VM] *******************************************

TASK [Ensure system group quicknotes exists] ***********************************
changed: [quicknotes-vm]

TASK [Ensure system user quicknotes exists] ************************************
changed: [quicknotes-vm]

TASK [Ensure data directory exists] ********************************************
changed: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
changed: [quicknotes-vm]

TASK [Copy seed.json to data dir] **********************************************
changed: [quicknotes-vm]

TASK [Render systemd unit] *****************************************************
changed: [quicknotes-vm]

TASK [Reload systemd daemon] ***************************************************
ok: [quicknotes-vm]

TASK [Enable and start quicknotes service] *************************************
changed: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=9    changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Service state

```text
$ vagrant ssh -c "sudo systemctl status quicknotes --no-pager"
● quicknotes.service - QuickNotes service
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; preset: enabled)
     Active: active (running) since Wed 2026-09-30 21:37:48 UTC
   Main PID: 4893 (quicknotes)
             └─4893 /usr/local/bin/quicknotes

Sep 30 21:37:48 quicknotes quicknotes[4893]: quicknotes listening on :8080 (notes loaded: 4)
```

### QuickNotes verification

```bash
curl -s http://localhost:18080/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

```bash
curl -s http://localhost:18080/notes | python3 -m json.tool
```

Output:

```json
[
    {
        "id": 3,
        "title": "DevOps mantra",
        "body": "If it hurts, do it more often.",
        "created_at": "2026-01-15T10:10:00Z"
    },
    {
        "id": 4,
        "title": "Endpoint cheat-sheet",
        "body": "GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics",
        "created_at": "2026-01-15T10:15:00Z"
    },
    {
        "id": 1,
        "title": "Welcome to QuickNotes",
        "body": "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.",
        "created_at": "2026-01-15T10:00:00Z"
    },
    {
        "id": 2,
        "title": "Read app/main.go first",
        "body": "Start by understanding the entry point — env vars, signal handling, graceful shutdown.",
        "created_at": "2026-01-15T10:05:00Z"
    }
]
```

`/notes` returns the four seeded notes (not `[]`), proving that `seed.json` was shipped to `/var/lib/quicknotes/seed.json` and `SEED_PATH` points at it.

## Task 3 — Idempotency

Run the playbook a second time:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Actual `PLAY RECAP`:

```text
PLAY RECAP *********************************************************************
quicknotes-vm              : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

All tasks returned `ok`, and the `Restart quicknotes` handler did not fire.

## Task 4 — Selective Handler

Changed one configuration value in the systemd service template:

```text
quicknotes_addr: ":8080"  →  ":9090"
```

This variable feeds `Environment=ADDR=...` in `quicknotes.service.j2`.

Run:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Relevant output:

```text
TASK [Ensure system group quicknotes exists] ***********************************
ok: [quicknotes-vm]

TASK [Ensure system user quicknotes exists] ************************************
ok: [quicknotes-vm]

TASK [Ensure data directory exists] ********************************************
ok: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
ok: [quicknotes-vm]

TASK [Copy seed.json to data dir] **********************************************
ok: [quicknotes-vm]

TASK [Render systemd unit] *****************************************************
changed: [quicknotes-vm]

TASK [Reload systemd daemon] ***************************************************
ok: [quicknotes-vm]

TASK [Enable and start quicknotes service] *************************************
ok: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=9    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Only `Render systemd unit` (`changed=1`) and the handler it notifies (`changed=1`) fired. Every other task stayed `ok`.

Verification:

```text
$ vagrant ssh -c "sudo journalctl -u quicknotes --no-pager -n 5"
Sep 30 22:06:33 quicknotes quicknotes[925]: 2026/09/30 22:06:33 shutting down
Sep 30 22:06:33 quicknotes systemd[1]: quicknotes.service: Deactivated successfully.
Sep 30 22:06:33 quicknotes systemd[1]: Stopped quicknotes.service - QuickNotes service.
Sep 30 22:06:33 quicknotes systemd[1]: Started quicknotes.service - QuickNotes service.
Sep 30 22:06:33 quicknotes quicknotes[4263]: 2026/09/30 22:06:33 quicknotes listening on :9090 (notes loaded: 4)
```

## Task 5 — Check Mode and Diff

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
```

Output (changed `:9090` → `:7070` before running):

```text
TASK [Render systemd unit] *****************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/arinaagafonova/.ansible/tmp/ansible-local-6918o6ge4rm7/tmpzxqgb7np/quicknotes.service.j2
@@ -8,7 +8,7 @@
 User=quicknotes
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:7070
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes

changed: [quicknotes-vm]
```

## Design Questions

### Why configuration management instead of manual SSH?

Ansible makes the server configuration reproducible and version-controlled. The same playbook can be applied again to recreate the desired state instead of relying on manually performed SSH commands. Every change to the VM is a commit, so it is reviewable, revertable, and repeatable across environments.

### What makes the playbook idempotent?

Tasks describe the desired state. Ansible checks the current state and changes only resources that differ from the desired configuration. On the second run every resource already matched, so all tasks reported `ok` and `changed=0` — no unnecessary copies, no spurious restarts.

### Why use a handler?

The QuickNotes service should be restarted only when its configuration changes. A handler avoids unnecessary restarts on normal idempotent runs: it fires only if a notifying task reports `changed`, and Ansible deduplicates multiple notifications into a single restart at the end of the play.

### Why use a template for the systemd unit?

A template allows configuration values to be generated from variables while keeping the service definition under version control. Changing one variable (`quicknotes_addr`) updates exactly one line of the rendered unit and triggers exactly one handler — the diff stays scoped and reviewable.

### Why use check mode?

`--check --diff` allows changes to be reviewed before they are applied. `--check` answers "will anything change?", and `--diff` answers "what exactly will change?" — so a reviewer can catch a semantically wrong change (e.g. an empty `ADDR=` from a mistyped variable) before it hits production.

## Verification Summary

| Check | Result |
|---|---|
| Vagrant VM running | PASS |
| Ansible ping | PASS |
| QuickNotes deployed | PASS |
| QuickNotes health check | PASS |
| `/notes` returns seeded data (4 notes, not `[]`) | PASS |
| Second playbook run: `changed=0` | PASS |
| Selective handler verified (`changed=2`) | PASS |
| `--check --diff` verified | PASS |

## Bonus — `ansible-pull` GitOps Loop

### Artifacts

- `ansible/bootstrap-pull.yaml`
- `ansible/files/local-inventory.ini` → installed to `/etc/ansible/local-inventory.ini`
- `ansible/templates/ansible-pull.service.j2` → `/etc/systemd/system/ansible-pull.service`
- `ansible/templates/ansible-pull.timer.j2` → `/etc/systemd/system/ansible-pull.timer`

### `ansible/files/local-inventory.ini`

```ini
[quicknotes]
localhost ansible_connection=local

[quicknotes:vars]
ansible_python_interpreter=/usr/bin/python3
```

### `ansible/templates/ansible-pull.service.j2`

```jinja
[Unit]
Description=Run ansible-pull to converge QuickNotes from Git
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
WorkingDirectory=/var/lib/ansible-pull
Environment=HOME=/root
ExecStart=/usr/bin/ansible-pull \
    -U {{ ansible_pull_repo }} \
    -C {{ ansible_pull_branch }} \
    -i /etc/ansible/local-inventory.ini \
    -d /var/lib/ansible-pull \
    ansible/playbook.yaml
```

### `ansible/templates/ansible-pull.timer.j2`

```jinja
[Unit]
Description=Timer for ansible-pull QuickNotes convergence
Requires=ansible-pull.service

[Timer]
OnBootSec={{ ansible_pull_on_boot }}
OnUnitActiveSec={{ ansible_pull_interval }}
Unit=ansible-pull.service

[Install]
WantedBy=timers.target
```

### Bootstrap PLAY RECAP

```text
PLAY RECAP *********************************************************************
quicknotes-vm              : ok=8    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Timer active

```text
$ vagrant ssh -c "systemctl list-timers | grep ansible-pull"
Wed 2026-09-30 22:16:41 UTC  2min 54s  Wed 2026-09-30 22:11:41 UTC  2min 5s ago  ansible-pull.timer  ansible-pull.service

$ vagrant ssh -c "sudo systemctl status ansible-pull.timer --no-pager"
● ansible-pull.timer - Timer for ansible-pull QuickNotes convergence
     Loaded: loaded (/etc/systemd/system/ansible-pull.timer; enabled; preset: enabled)
     Active: active (waiting) since Wed 2026-09-30 21:50:37 UTC
    Trigger: Wed 2026-09-30 22:16:41 UTC
   Triggers: ● ansible-pull.service
```

### Journal excerpt — successful pull (commit `29822d7`)

```text
Sep 30 22:06:27 quicknotes systemd[1]: Starting ansible-pull.service - Run ansible-pull to converge QuickNotes from Git...
Sep 30 22:06:27 quicknotes python3[3883]: ansible-git Invoked with name=https://github.com/ariiagaf/DevOps-Intro.git dest=/var/lib/ansible-pull version=feature/lab7 ...
Sep 30 22:06:31 quicknotes python3[4088]: ansible-ansible.legacy.stat Invoked with path=/etc/systemd/system/quicknotes.service ...
Sep 30 22:06:32 quicknotes python3[4102]: ansible-ansible.legacy.copy Invoked with src=.../quicknotes.service.j2 dest=/etc/systemd/system/quicknotes.service ...
Sep 30 22:06:32 quicknotes python3[4127]: ansible-ansible.builtin.systemd Invoked with daemon_reload=True ...
Sep 30 22:06:33 quicknotes python3[4220]: ansible-ansible.builtin.systemd Invoked with name=quicknotes.service state=restarted daemon_reload=True ...
Sep 30 22:06:33 quicknotes ansible-pull[3857]: localhost | CHANGED => {
Sep 30 22:06:33 quicknotes ansible-pull[3857]:     "after": "29822d7d107204eb707f9c0ead94a1e181a2780c",
Sep 30 22:06:33 quicknotes ansible-pull[3857]:     "before": "094152187e58264b39b6b424892729da448b26fd",
Sep 30 22:06:33 quicknotes ansible-pull[3857]:     "changed": true,
Sep 30 22:06:33 quicknotes ansible-pull[3857]: }
Sep 30 22:06:33 quicknotes ansible-pull[3857]: TASK [Render systemd unit] *****************************************************
Sep 30 22:06:33 quicknotes ansible-pull[3857]: changed: [localhost]
...
Sep 30 22:06:33 quicknotes ansible-pull[3857]: RUNNING HANDLER [Restart quicknotes] *******************************************
Sep 30 22:06:33 quicknotes ansible-pull[3857]: changed: [localhost]
Sep 30 22:06:33 quicknotes ansible-pull[3857]: PLAY RECAP *********************************************************************
Sep 30 22:06:33 quicknotes ansible-pull[3857]: localhost                  : ok=9    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Convergence timeline

| Event | Timestamp (UTC) |
|---|---|
| `git commit` + `git push` to `feature/lab7` (commit `29822d7`) | `2026-09-30T22:02:34Z` |
| Timer fires → `ansible-pull.service` starts | `2026-09-30T22:06:27Z` |
| Git fetch fast-forwards to `29822d7` | `2026-09-30T22:06:33Z` |
| `Render systemd unit` + `Restart quicknotes` handler fire | `2026-09-30T22:06:33Z` |
| State reconciled — `quicknotes listening on :9090` | `2026-09-30T22:06:33Z` |

Push → converge: **~3 min 53 s** (within the 5-minute requirement).

### Reverted change (`:9090` → `:8080`)

| Event | Timestamp (UTC) |
|---|---|
| `git push` (commit `416c44b`) | `2026-09-30T22:08:02Z` |
| Timer fires → `ansible-pull.service` starts | `2026-09-30T22:11:41Z` |
| State reconciled — `listening on :8080` | `2026-09-30T22:11:48Z` |

Push → converge: **~3 min 46 s**.

```text
Sep 30 22:11:48 quicknotes quicknotes[4861]: quicknotes listening on :8080 (notes loaded: 4)
```

Final host-side check:

```text
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}

$ curl -s http://localhost:18080/notes | python3 -c "import sys,json; print(len(json.load(sys.stdin)), 'notes')"
4 notes
```

### Design questions

**`ansible-pull` vs push — security benefit.** In pull mode the VM reaches out to a Git URL and applies the playbook to itself. There are no inbound SSH credentials on a control node, no shared private keys, no long-lived agent with broad reach. Each host's only credential is read-only access to the repo, so compromising a single VM does not give lateral movement to the rest of the fleet. The blast radius of any one host is bounded by that host. The Git history is also the audit log: every change that reached the VM went through a commit, which push mode cannot guarantee.

**Same pattern at the Kubernetes layer.** It is **GitOps**, and the industry-standard tools are **ArgoCD** and **Flux**. Both run inside the cluster as controllers, watch a Git repository, compare declared state to live state, and reconcile on a loop — exactly what `ansible-pull` + a systemd timer does for a single VM. The mapping is one-to-one: repo polling ↔ `git fetch`; controller applying manifests ↔ `ansible-playbook` applying tasks; rolling a Deployment ↔ restarting a systemd unit; the ~3-minute reconcile loop ↔ the 5-minute systemd timer. `ansible-pull` is a fair simulator because the core invariants are identical: Git is the source of truth, the target is self-healing, convergence is idempotent (`changed=0` ↔ "Synced / Healthy"), and the loop is pull-based so the target holds no inbound control-plane credentials.

## Conclusion

QuickNotes was deployed to the existing Lab 5 Vagrant VM using Ansible. The configuration is reproducible and idempotent, and the systemd service is restarted only when its configuration changes. As a bonus, the VM was wired into an `ansible-pull` GitOps loop: a systemd timer converges the VM from the Git fork every 5 minutes, and a push was observed to reconcile within under 4 minutes with no host-side `ansible-playbook` run.

## Commits on `feature/lab7`

```text
347f211 feat(lab7): add ansible-pull GitOps loop (bonus)
416c44b fix(lab7): restore listen_addr to :8080
29822d7 test(lab7): change listen_addr to :9090 for ansible-pull convergence demo
0941521 feat(lab7): add Ansible playbook to deploy QuickNotes to Lab 5 VM
```
