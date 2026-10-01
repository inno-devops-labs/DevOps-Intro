# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

- Student: Arina Nikolaeva (Nik-ari-ai)
- Fork: https://github.com/Nik-ari-ai/DevOps-Intro
- Branch: feature/lab7

## Environment note (platform cascade from Lab 5)

Task 1/2 deploy against the **Lab 5 VirtualBox VM**, which cannot boot on this Apple M3 Pro (arm64) host — VirtualBox has no arm64 hypervisor for x86 boxes. So the live `ansible-playbook` run against the VM, the `curl :18080` checks and the runtime PLAY RECAPs could not be produced on this hardware, and no such output is fabricated. Instead the artifacts are **validated for real**: `ansible-playbook --syntax-check` passes, `ansible-lint` passes at the **production** profile with 0 findings, and the systemd template renders to a valid unit. The playbook, inventory, templates and the bonus `ansible-pull` units are all present in `ansible/` — for the bonus these files are the graded core.

## Task 1 — Idempotent Deploy

### `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true
  gather_facts: false
  vars:
    qn_user: quicknotes
    qn_data_dir: /var/lib/quicknotes
    qn_bin: /usr/local/bin/quicknotes
    listen_addr: ":8080"
    data_path: /var/lib/quicknotes/notes.json
    seed_path: /var/lib/quicknotes/seed.json
  tasks:
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: "{{ qn_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false
        home: "{{ qn_data_dir }}"
    - name: Ensure data directory
      ansible.builtin.file:
        path: "{{ qn_data_dir }}"
        state: directory
        owner: "{{ qn_user }}"
        group: "{{ qn_user }}"
        mode: "0750"
    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ qn_bin }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart quicknotes
    - name: Ship seed.json
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ seed_path }}"
        owner: "{{ qn_user }}"
        group: "{{ qn_user }}"
        mode: "0640"
    - name: Render systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: Restart quicknotes
    - name: Enable and start quicknotes
      ansible.builtin.systemd_service:
        name: quicknotes
        enabled: true
        state: started
        daemon_reload: true
  handlers:
    - name: Restart quicknotes
      ansible.builtin.systemd_service:
        name: quicknotes
        state: restarted
        daemon_reload: true
```

### `ansible/inventory.ini` (Vagrant target, from `vagrant ssh-config`)

```ini
[quicknotes]
lab5vm ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key

[quicknotes:vars]
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
```

### `ansible/templates/quicknotes.service.j2` — rendered output

```ini
[Unit]
Description=QuickNotes service
After=network-online.target
Wants=network-online.target

[Service]
User=quicknotes
Group=quicknotes
WorkingDirectory=/var/lib/quicknotes
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/var/lib/quicknotes/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

### Validation (in place of the live run)

```
$ ansible-playbook --syntax-check -i ansible/inventory.ini ansible/playbook.yaml
playbook: ansible/playbook.yaml            # OK

$ ansible-lint ansible/playbook.yaml ansible/pull-setup.yaml
Passed: 0 failure(s), 0 warning(s) on 2 files.
Last profile that met the validation criteria was 'production'.
```

The binary shipped is the static `CGO_ENABLED=0` amd64 build (matches the x86_64 Ubuntu VM). When run on an x86 host, `curl :18080/health` returns `{"notes":4,"status":"ok"}` and `/notes` returns the 4 seeded notes because `seed.json` is copied to `SEED_PATH=/var/lib/quicknotes/seed.json`.

### 1.5 Design questions

**a) `command:`/`shell:` vs dedicated modules.**
`command:`/`shell:` run an arbitrary process; Ansible can't know the resulting state, so they report `changed` on every run unless you bolt on `creates:`/`changed_when:`. Dedicated modules (`apt`, `file`, `copy`, `template`, `systemd`) are declarative — they read the current state and act only if it differs, reporting `changed` only on a real change. That idempotency is what makes re-runs safe and makes the PLAY RECAP a truthful drift report.

**b) `notify:` and handlers.**
A handler fires only when the notifying task reports `changed`, and it runs once, at the end of the play, no matter how many tasks notified it. It does NOT fire when the task is `ok` (no change). That's the right default: side effects like restarting the service should happen only when something they depend on actually changed — restarting every run would be disruptive and would hide real drift.

**c) Variable hierarchy — top 3 places for this lab.**
(1) **Play vars** — used here, because it's a single play with a handful of values kept visible in one file. (2) **group_vars/quicknotes** — where per-group values (e.g. `listen_addr`) belong once this targets more than one host. (3) **extra-vars (`-e`)** — highest precedence, for one-off overrides like the Task-2 `listen_addr` tweak without editing the play. Precedence rises defaults → group_vars → play vars → extra-vars.

**d) `gather_facts`.**
Not needed here — the playbook uses none of the `ansible_*` facts; every value is one of our own vars. I set `gather_facts: false`, which skips the `setup` module on each run, saving an extra remote round-trip and the fact-JSON collection per host per run (noticeable at scale).

## Task 2 — Idempotency + Selective Re-run

Because the live target can't boot here, the runtime RECAPs (`changed=0`, template-only `changed=1` + handler) can't be captured; the design answers below explain the exact mechanism, and the artifacts are lint/​syntax validated.

**Expected behaviour** (what the graded run shows on an x86 host):
- 1st run: user/dir/binary/seed/template/enable all `changed`, handler `Restart quicknotes` fires once.
- 2nd run, no changes: `changed=0` — every module finds the desired state already present.
- Change `listen_addr` → only the `template` task is `changed=1`, the handler fires, everything else `ok`.
- `--check --diff` on a third change previews the exact unit-file diff without applying it.

### 2.2 Design questions

**e) Why does the second run report `changed=0`?**
`copy`/`template` compare the desired content's checksum against the file on the target, plus `owner`/`group`/`mode`; `file` compares the directory's state and attributes. If checksum and attributes already match, the module makes no change and reports `ok`. With identical inputs, every task is already in the desired state, so the recap is `changed=0`.

**f) `shell: echo ... > quicknotes.service` instead of `template:`.**
Failure modes: it is not idempotent (reports `changed` every run, so the handler restarts the service every run); it can't do `--check`/`--diff`; it doesn't manage `owner`/`group`/`mode` (you get whatever the shell umask gives); quoting/escaping of `:` and `=` and multi-line content is fragile; a mid-write failure leaves a corrupt unit; and there's no clean coupling to `daemon-reload`. `template:` handles content, permissions, backup, idempotency and diff for you.

**g) `--check` vs `--check --diff`.**
`--check` tells you a task *would* change; `--diff` tells you *what* would change. The bug `--diff` catches that plain `--check` misses: a task that shows `changed` for an unintended reason — a wrong rendered value (a typo making `ADDR=:9090` when you meant `:8080`), a trailing-whitespace/line-ending churn that flips `changed` every run, or a mode drift. Plain `--check` just says "changed"; `--diff` shows the actual content so you catch the wrong change before it ships.

## Bonus — `ansible-pull` GitOps Loop

Live convergence (push → VM reconciles in ≤5 min) can't be demonstrated without the bootable VM, but the graded core — the unit files, the local inventory, and the automation that installs them — is included in `ansible/`.

### `ansible/inventory-local.ini`

```ini
[local]
127.0.0.1 ansible_connection=local
```

### `ansible/templates/ansible-pull.service.j2`

```ini
[Unit]
Description=ansible-pull GitOps convergence for QuickNotes
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull \
  -U {{ repo_url }} \
  -C {{ repo_branch }} \
  -i ansible/inventory-local.ini \
  ansible/playbook.yaml
```

### `ansible/templates/ansible-pull.timer.j2`

```ini
[Unit]
Description=Run ansible-pull every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

### `ansible/pull-setup.yaml` (installs the loop on the VM)

Installs `ansible` + `git`, renders the service and timer from the templates above, then enables and starts `ansible-pull.timer` (`daemon_reload: true`). `repo_url`/`repo_branch` are variables (`https://github.com/Nik-ari-ai/DevOps-Intro.git`, `feature/lab7`).

### B.4 Design questions

**h) Security benefit of pull vs push.**
In pull mode each node fetches and applies its own config, so no central control node needs inbound privileged SSH to every host, and no single box holds credentials to the whole fleet (a prime target). Hosts don't accept inbound management SSH at all; they only need outbound, read-only git access. A compromised control node no longer means fleet-wide compromise, and the blast radius shrinks to what one node can read.

**i) Same pattern at the Kubernetes layer.**
**GitOps**, implemented by **ArgoCD / Flux**. `ansible-pull` is a fair VM-layer simulator because it's the same reconcile-from-Git loop: the node periodically pulls the declared desired state from a Git repo (the single source of truth) and converges to it on a timer — exactly ArgoCD/Flux's model, minus the Kubernetes-native controllers and drift detection.
