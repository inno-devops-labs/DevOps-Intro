# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

## Environment

```text
Ansible 10.7.0
ansible-core 2.17.14
Python 3.12.3
```

Vagrant SSH configuration used for the Lab 5 VM:

```text
HostName 127.0.0.1
User vagrant
Port 2222
IdentityFile /home/kriss/VSProjects/DevOps-Intro/.vagrant/machines/default/virtualbox/private_key
```

Connectivity check:

```text
lab5-vm | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

# Task 1 — Idempotent Deploy

## Repository layout

```text
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── local-inventory.ini
│   ├── quicknotes
│   └── seed.json
└── templates/
    ├── ansible-pull.service.j2
    ├── ansible-pull.timer.j2
    └── quicknotes.service.j2
```

The QuickNotes binary was built with:

```bash
CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o ../ansible/files/quicknotes .
```

`file` confirmed that it is `statically linked` and `stripped`.

## inventory.ini

```ini
[quicknotes]
lab5-vm ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=/home/kriss/VSProjects/DevOps-Intro/.vagrant/machines/default/virtualbox/private_key ansible_python_interpreter=/usr/bin/python3

[quicknotes:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

## quicknotes.service.j2

```ini
[Unit]
Description=QuickNotes service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User={{ quicknotes_user }}
Group={{ quicknotes_group }}
WorkingDirectory={{ data_dir }}

Environment="ADDR={{ listen_addr }}"
Environment="DATA_PATH={{ data_path }}"
Environment="SEED_PATH={{ seed_path }}"

ExecStart={{ binary_path }}

Restart=on-failure
RestartSec={{ restart_backoff }}

[Install]
WantedBy=multi-user.target
```

## Final playbook

The final playbook uses dedicated Ansible modules to:

- create the `quicknotes` system group and non-login system user;
- create `/var/lib/quicknotes` as `quicknotes:quicknotes` with mode `0750`;
- copy the static binary to `/usr/local/bin/quicknotes` with mode `0755`;
- copy `seed.json` to `/var/lib/quicknotes/seed.json` as `quicknotes:quicknotes`, mode `0640`;
- render `/etc/systemd/system/quicknotes.service`;
- reload systemd and restart QuickNotes only when the binary or unit changes;
- enable and start the service;
- install/configure the bonus `ansible-pull` service and timer.

Final variables include:

```yaml
quicknotes_user: quicknotes
quicknotes_group: quicknotes
data_dir: /var/lib/quicknotes
data_path: /var/lib/quicknotes/notes.json
seed_path: /var/lib/quicknotes/seed.json
binary_path: /usr/local/bin/quicknotes
listen_addr: ":8080"
restart_backoff: "3s"

ansible_pull_repo_url: "https://github.com/Kriss221/DevOps-Intro.git"
ansible_pull_branch: "feature/lab7"
ansible_pull_inventory_path: "/etc/ansible/quicknotes-local.ini"
```

The handlers are:

```yaml
handlers:
  - name: reload systemd
    ansible.builtin.systemd:
      daemon_reload: true
    when: not ansible_check_mode

  - name: restart quicknotes
    ansible.builtin.systemd:
      name: quicknotes
      state: restarted
    when: not ansible_check_mode
```

## First dry-run

```text
PLAY RECAP
lab5-vm : ok=6 changed=6 unreachable=0 failed=0 skipped=3 rescued=0 ignored=0
```

The initial check-mode warnings about looking up the future `quicknotes` user/group were expected because check mode does not physically create them.

## First real deployment

```text
PLAY RECAP
lab5-vm : ok=9 changed=8 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

Service status:

```text
● quicknotes.service - QuickNotes service
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; vendor preset: enabled)
     Active: active (running)
   Main PID: 2491 (quicknotes)
     CGroup: /system.slice/quicknotes.service
             └─2491 /usr/local/bin/quicknotes
```

Health:

```json
{"notes":4,"status":"ok"}
```

`/notes` returned all four records shipped in `seed.json`, proving that the seed file reached the VM and `SEED_PATH` is correct.

## Design questions a–d

### a) `command:` vs dedicated modules

`command:` runs a process but generally does not understand the desired state of the resource it changes. Dedicated modules such as `file`, `copy`, `template`, `apt`, and `systemd` inspect current state and only make a change when necessary. That built-in state awareness is what makes them naturally idempotent and safe to run repeatedly.

### b) `notify:` and handlers

A handler is notified only when a notifying task reports `changed`. If the task reports `ok`, the handler does not run. This is the correct default because the service should restart only when a binary or unit-file change actually requires it, avoiding unnecessary downtime.

### c) Variable hierarchy

Three suitable locations are: playbook vars for values tightly coupled to this small play; `group_vars/quicknotes` for values shared by all QuickNotes hosts; and role defaults if the deployment is later turned into a reusable role. For this lab, playbook vars keep the configuration explicit and easy to inspect.

### d) `gather_facts`

This playbook does not need gathered facts because it does not branch on OS, interfaces, hardware, or other discovered host data. `gather_facts: false` skips the setup/fact-collection step and reduces work on every run.

# Task 2 — Idempotency + Selective Re-run

## Second run: zero changes

```text
PLAY RECAP
lab5-vm : ok=7 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

No handlers fired.

## Selective variable change

`listen_addr` was changed from `:8080` to `:9090`.

Result:

```text
TASK [Create QuickNotes system group]        ok
TASK [Create QuickNotes system user]         ok
TASK [Ensure QuickNotes data directory exists] ok
TASK [Copy QuickNotes binary]                ok
TASK [Copy seed data]                        ok
TASK [Render QuickNotes systemd unit]        changed
RUNNING HANDLER [reload systemd]             ok
RUNNING HANDLER [restart quicknotes]         changed
TASK [Enable and start QuickNotes]           ok

PLAY RECAP
lab5-vm : ok=9 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

Only the template changed; the second change in the recap is the restart handler itself.

## `--check --diff`

A third test value `:8081` was previewed without applying it:

```diff
--- before: /etc/systemd/system/quicknotes.service
+++ after: .../quicknotes.service.j2
@@ -9,7 +9,7 @@
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes

-Environment="ADDR=:9090"
+Environment="ADDR=:8081"
 Environment="DATA_PATH=/var/lib/quicknotes/notes.json"
 Environment="SEED_PATH=/var/lib/quicknotes/seed.json"
```

```text
PLAY RECAP
lab5-vm : ok=6 changed=1 unreachable=0 failed=0 skipped=3 rescued=0 ignored=0
```

The final configuration was restored to `:8080`, applied, and one more run again produced:

```text
lab5-vm : ok=7 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

Final health remained:

```json
{"notes":4,"status":"ok"}
```

## Design questions e–g

### e) Why `changed=0`?

Modules compare actual state with desired state. `file` checks properties such as existence, ownership, group, and mode. `template` renders the Jinja2 template and compares the rendered content and metadata with the destination file. When they already match, the tasks report `ok`, so no handlers are notified.

### f) Why not `shell: echo ... > quicknotes.service`?

A shell command has no built-in understanding of whether the current unit already matches the desired state. It can overwrite the file every run, obscure whether a real change occurred, complicate quoting, and requires custom `changed_when` logic. `template` provides deterministic rendering, metadata management, idempotent change detection, diffs, and clean handler integration.

### g) What does `--diff` add?

Plain `--check` says that something would change. `--check --diff` shows exactly what the change would be. That would reveal a wrong `ADDR`, `DATA_PATH`, `SEED_PATH`, or other unit-file value before production deployment.

# Bonus — `ansible-pull` GitOps Loop

## Local inventory

```ini
[quicknotes]
quicknotes-vm ansible_host=127.0.0.1 ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

## ansible-pull.service.j2

```ini
[Unit]
Description=Ansible Pull QuickNotes convergence
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull   -U {{ ansible_pull_repo_url }}   -C {{ ansible_pull_branch }}   -i {{ ansible_pull_inventory_path }}   ansible/playbook.yaml
```

Installed command:

```text
/usr/bin/ansible-pull -U https://github.com/Kriss221/DevOps-Intro.git -C feature/lab7 -i /etc/ansible/quicknotes-local.ini ansible/playbook.yaml
```

## ansible-pull.timer.j2

```ini
[Unit]
Description=Run ansible-pull every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=ansible-pull.service
Persistent=true

[Install]
WantedBy=timers.target
```

Timer evidence:

```text
● ansible-pull.timer - Run ansible-pull every 5 minutes
     Loaded: loaded (/etc/systemd/system/ansible-pull.timer; enabled; vendor preset: enabled)
     Active: active (waiting)
    Triggers: ● ansible-pull.service
```

## Successful automatic convergence

A GitOps change moved `RestartSec` to a variable.

Before:

```text
RestartSec=2s
```

Repository change:

```yaml
restart_backoff: "3s"
```

Template:

```ini
RestartSec={{ restart_backoff }}
```

Commit:

```text
commit=6866706f6cb7fb7dd5a8313df7230da8301c0971
timestamp=2026-09-24T23:25:56+03:00
```

The timer fired at `2026-09-24 20:26:29 UTC`, which is `23:26:29 +03:00`, approximately 33 seconds after the commit timestamp.

The VM automatically pulled:

```text
before: f1e037a9d3bc641a88e009790296c19808167909
after:  6866706f6cb7fb7dd5a8313df7230da8301c0971
changed: true
```

The pull then changed the template and invoked the handlers:

```text
TASK [Render QuickNotes systemd unit]
changed: [localhost]

RUNNING HANDLER [reload systemd]
ok: [localhost]

RUNNING HANDLER [restart quicknotes]
changed: [localhost]

PLAY RECAP
localhost : ok=15 changed=3 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

After reconciliation:

```text
RestartSec=3s
```

QuickNotes was still healthy:

```json
{"notes":4,"status":"ok"}
```

## Design questions h–i

### h) Pull-mode security benefit

In a push model, a control node must hold credentials that allow inbound administration of managed machines. In pull mode, the VM initiates an outbound connection to Git and applies configuration locally. This reduces the need for centralized SSH credentials and removes the need for a separate controller to open inbound management sessions to the VM.

### i) Kubernetes equivalent

The same GitOps reconciliation pattern is used by tools such as Argo CD and Flux at the Kubernetes layer. They continuously reconcile actual state toward declarative state stored in Git. `ansible-pull` is a VM-level simulation of the same source-of-truth and reconciliation model.

# Final state

```text
On branch feature/lab7
Your branch is up to date with 'origin/feature/lab7'.

nothing to commit, working tree clean
```

Recent commits:

```text
6866706 feat(lab7): update ansible-pull managed config
f1e037a feat(lab7): deploy QuickNotes with Ansible
```

Final health:

```json
{"notes":4,"status":"ok"}
```

The `/notes` endpoint returned all four seeded records.
