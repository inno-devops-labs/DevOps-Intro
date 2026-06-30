# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

## Objective

Write an idempotent Ansible playbook that deploys the QuickNotes binary to the
Lab 5 Vagrant VM, installs a parameterized systemd unit, and manages the
service lifecycle through handlers.

## Environment

| Component | Version / value |
|-----------|-----------------|
| Host OS | macOS (authoring machine) |
| Git branch | `feature/lab7` |
| VM target | Lab 5 Vagrant VM (`127.0.0.1:18080 -> guest:8080`) |
| App artifact | `ansible/files/quicknotes` (Linux arm64 for this MacBook VM path) |
| Ansible layout | `ansible/` |

> Note: this repository snapshot initially did not have `ansible` or `vagrant`
> installed, so the playbook and submission were prepared first and the live VM
> verification still depends on finishing the local VM-tool install. The command
> outputs marked **TODO** below must be collected once the Lab 5 VM is running
> on this MacBook.

## Implementation summary

The `ansible/` directory contains:

1. `inventory.ini` targeting the Lab 5 VM over the Vagrant SSH endpoint.
2. `playbook.yaml` with `become: true` and `gather_facts: false`.
3. `files/quicknotes`, a static Linux QuickNotes binary built from `app/`.
4. `templates/quicknotes.service.j2`, a Jinja2 systemd unit whose runtime
   values come from playbook variables.

The playbook performs the required idempotent steps:

1. Creates the `quicknotes` system group and system user, with
   `create_home: false` and a non-login shell.
2. Ensures `/var/lib/quicknotes` exists with owner `quicknotes:quicknotes` and
   mode `0750`.
3. Copies the binary to `/usr/local/bin/quicknotes` with mode `0755`.
4. Renders `/etc/systemd/system/quicknotes.service` from a template.
5. Reloads systemd only when the rendered unit changed, then enables and starts
   the service.
6. Restarts the service only when the binary or unit file changes, via a
   handler.

`gather_facts` is disabled intentionally because this playbook does not branch
on OS facts, CPU architecture, or package manager state; skipping the setup step
keeps runs shorter and makes the idempotency proof tighter.

On this MacBook, the inventory also had to mirror `vagrant ssh-config` by
disabling strict host-key checks for the ephemeral local VM SSH endpoint. That
matched Vagrant's own SSH behavior and resolved an initial `Host key
verification failed` error from Ansible.

## Repository layout

```text
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   └── quicknotes
└── templates/
    └── quicknotes.service.j2
```

## The playbook

```yaml
- name: Deploy QuickNotes to the Lab 5 VM
  hosts: quicknotes_vm
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_group: quicknotes
    quicknotes_home: /nonexistent
    quicknotes_shell: /usr/sbin/nologin
    quicknotes_binary_src: files/quicknotes
    quicknotes_binary_dest: /usr/local/bin/quicknotes
    quicknotes_service_name: quicknotes
    quicknotes_service_unit_path: /etc/systemd/system/quicknotes.service
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_data_path: /var/lib/quicknotes/notes.json
    quicknotes_seed_path: /opt/quicknotes/app/seed.json
    listen_addr: ":8080"

  tasks:
    - name: Create the quicknotes system group
      ansible.builtin.group:
        name: "{{ quicknotes_group }}"
        system: true

    - name: Create the quicknotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        system: true
        create_home: false
        home: "{{ quicknotes_home }}"
        shell: "{{ quicknotes_shell }}"

    - name: Ensure the quicknotes data directory exists
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        mode: "0750"

    - name: Install the QuickNotes binary
      ansible.builtin.copy:
        src: "{{ quicknotes_binary_src }}"
        dest: "{{ quicknotes_binary_dest }}"
        owner: root
        group: root
        mode: "0755"
      notify: restart quicknotes

    - name: Install the systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: "{{ quicknotes_service_unit_path }}"
        owner: root
        group: root
        mode: "0644"
      register: quicknotes_service_unit
      notify: restart quicknotes

    - name: Reload systemd when the unit changes
      ansible.builtin.systemd:
        daemon_reload: true
      when: quicknotes_service_unit.changed

    - name: Enable and start the quicknotes service
      ansible.builtin.systemd:
        name: "{{ quicknotes_service_name }}"
        enabled: true
        state: started

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: "{{ quicknotes_service_name }}"
        state: restarted
        daemon_reload: true
```

## Inventory

```ini
[quicknotes_vm]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key ansible_python_interpreter=/usr/bin/python3
```

If `vagrant ssh-config` prints a different forwarded port or key path on your
machine, update `ansible_port` and `ansible_ssh_private_key_file` to match that
output before running the playbook.

## Systemd unit template

```ini
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ quicknotes_user }}
Group={{ quicknotes_group }}
WorkingDirectory={{ quicknotes_data_dir }}
Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ quicknotes_data_path }}
Environment=SEED_PATH={{ quicknotes_seed_path }}
ExecStart={{ quicknotes_binary_dest }}
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
```

## Static artifact build

The managed binary was produced from `app/` as a static Linux executable for
the Apple Silicon VM path:

```bash
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 \
  go build -C app -trimpath -ldflags='-s -w' \
  -o ../ansible/files/quicknotes .
```

## Task 1 — Run + verify

### Dry-run

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check
```

```text
PLAY [Deploy QuickNotes to the Lab 5 VM] ***************************************

TASK [Create the quicknotes system group] **************************************
changed: [quicknotes-vm]

TASK [Create the quicknotes system user] ***************************************
changed: [quicknotes-vm]

TASK [Ensure the quicknotes data directory exists] *****************************
changed: [quicknotes-vm]

TASK [Install the QuickNotes binary] *******************************************
changed: [quicknotes-vm]

TASK [Install the systemd unit] ************************************************
changed: [quicknotes-vm]

TASK [Reload systemd when the unit changes] ************************************
ok: [quicknotes-vm]

TASK [Enable and start the quicknotes service] *********************************
ok: [quicknotes-vm]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=8    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### First real run

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

```text
PLAY [Deploy QuickNotes to the Lab 5 VM] ***************************************

TASK [Create the quicknotes system group] **************************************
changed: [quicknotes-vm]

TASK [Create the quicknotes system user] ***************************************
changed: [quicknotes-vm]

TASK [Ensure the quicknotes data directory exists] *****************************
changed: [quicknotes-vm]

TASK [Install the QuickNotes binary] *******************************************
changed: [quicknotes-vm]

TASK [Install the systemd unit] ************************************************
changed: [quicknotes-vm]

TASK [Reload systemd when the unit changes] ************************************
ok: [quicknotes-vm]

TASK [Enable and start the quicknotes service] *********************************
ok: [quicknotes-vm]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=8    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Reachability proof

```bash
curl -s http://localhost:18080/health
```

```text
{"notes":4,"status":"ok"}
```

### Design questions

**a) `command:` vs dedicated modules.**
Dedicated modules such as `user`, `file`, `copy`, `template`, and `systemd`
understand the desired end state and compare it with the target's current
state. That makes them idempotent: if the target already matches, they return
`ok` instead of changing anything. `command:` and `shell:` just run imperative
commands; Ansible cannot reliably infer whether they changed state, so they are
usually reported as changed every run unless you add fragile guards like
`creates:` or `changed_when:`. For this lab, idempotency matters because the
second run must prove `changed=0` and the restart handler must fire only when an
actual config or binary change occurred.

**b) `notify:` and handlers.**
A handler fires only when a task that references it reports `changed`. If the
`copy` or `template` task determines that the destination file already matches
what Ansible would write, the task stays `ok` and the handler does not run. That
is the right default because unnecessary restarts create avoidable downtime and
noise; service restarts should be coupled to real state changes, not to the mere
fact that a playbook was executed.

**c) Variable hierarchy.**
For this lab I would use three levels:
1. Playbook vars for repo-local defaults such as `listen_addr`,
   `quicknotes_data_path`, and `quicknotes_seed_path`, because they document the
   intended baseline close to the tasks.
2. Inventory or `group_vars/quicknotes_vm` for environment-specific connection
   values such as `ansible_host`, `ansible_port`, and `ansible_user`, because
   they belong to the target environment rather than the app logic.
3. Extra vars (`-e`) only for one-off overrides during demonstrations, such as
   `-e listen_addr=:9090` to prove selective template changes, because CLI vars
   have high precedence and are ideal for temporary experiments without editing
   committed files.

**d) Do we need `gather_facts: true` here?**
No. This playbook does not make decisions based on Ansible facts; it copies a
binary, writes a template, and manages a service on a known Ubuntu VM. Turning
fact gathering off skips the setup phase, which usually saves a few seconds per
run and makes repeated idempotency checks faster.

## Task 2 — Idempotency + selective re-run

### Second run: prove `changed=0`

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

```text
PLAY [Deploy QuickNotes to the Lab 5 VM] ***************************************

TASK [Create the quicknotes system group] **************************************
ok: [quicknotes-vm]

TASK [Create the quicknotes system user] ***************************************
ok: [quicknotes-vm]

TASK [Ensure the quicknotes data directory exists] *****************************
ok: [quicknotes-vm]

TASK [Install the QuickNotes binary] *******************************************
ok: [quicknotes-vm]

TASK [Install the systemd unit] ************************************************
ok: [quicknotes-vm]

TASK [Reload systemd when the unit changes] ************************************
skipping: [quicknotes-vm]

TASK [Enable and start the quicknotes service] *********************************
ok: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=6    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

### Selective change: template only + handler fired

One simple way to prove selective change without editing committed files is:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml -e listen_addr=:9090
```

Expected behavior:
- The `template` task reports `changed=1`
- The restart handler is invoked
- The `user`, `file`, and `copy` tasks stay `ok`

```text
PLAY [Deploy QuickNotes to the Lab 5 VM] ***************************************

TASK [Create the quicknotes system group] **************************************
ok: [quicknotes-vm]

TASK [Create the quicknotes system user] ***************************************
ok: [quicknotes-vm]

TASK [Ensure the quicknotes data directory exists] *****************************
ok: [quicknotes-vm]

TASK [Install the QuickNotes binary] *******************************************
ok: [quicknotes-vm]

TASK [Install the systemd unit] ************************************************
changed: [quicknotes-vm]

TASK [Reload systemd when the unit changes] ************************************
ok: [quicknotes-vm]

TASK [Enable and start the quicknotes service] *********************************
ok: [quicknotes-vm]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Preview a third change with `--check --diff`

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml \
  -e quicknotes_data_path=/var/lib/quicknotes/notes-v2.json --check --diff
```

```diff
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/arsenypinigin/.ansible/tmp/ansible-local-12275b4sv3mqt/tmpy1vbafoo/quicknotes.service.j2
@@ -8,8 +8,8 @@
 User=quicknotes
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:9090
-Environment=DATA_PATH=/var/lib/quicknotes/notes.json
+Environment=ADDR=:8080
+Environment=DATA_PATH=/var/lib/quicknotes/notes-v2.json
 Environment=SEED_PATH=/opt/quicknotes/app/seed.json
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
```

### Design questions

**e) Why does the second run report `changed=0`?**
Because Ansible modules compare the current remote state to the desired state.
`file` checks attributes such as existence, type, owner, group, and mode.
`copy` checks the destination file contents plus metadata. `template` renders the
Jinja2 template and compares the rendered bytes to the target file before
rewriting it. If nothing differs, the tasks are already converged and the play
reports `ok` rather than `changed`.

**f) What would happen with `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'`?**
You would lose safe change detection, structured templating, and predictable file
metadata management. The shell task would typically report changed every run,
which would restart the service every run even when the unit content was
identical. It also makes quoting brittle, hides accidental truncation bugs,
cannot easily manage owner/mode consistently, and encourages partially written
or malformed units when variables contain spaces or special characters. In
short: more imperative code, weaker idempotency, and noisier deploys.

**g) What bug does `--check --diff` catch that plain `--check` can miss?**
Plain `--check` tells you that a template *would* change, but not whether the
rendered result is sensible. `--diff` exposes the exact before/after lines, so
it catches bugs like accidentally changing `ADDR=:8080` to `ADDR=8080`, pointing
`SEED_PATH` at the wrong file, or rendering a typo into `ExecStart`. Those are
production-impacting config mistakes that a dry-run count alone would not make
obvious.

## Notes

- The inventory assumes the standard Vagrant VM created from the repo root with
  the Lab 5 `Vagrantfile` now restored into this branch.
- The Lab 5 `Vagrantfile` was updated to choose the correct guest Go tarball
  for either `amd64` or `arm64`, because this MacBook is Apple Silicon.
- The binary is committed intentionally because the lab specification requires an
  `ansible/files/quicknotes` payload that the playbook ships to the VM.
- The Lab 7 bonus (`ansible-pull` + systemd timer) was not implemented in this
  branch because it needs a reachable Git clone URL and live VM verification.
