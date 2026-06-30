# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

Deploys QuickNotes to the Lab 5 Vagrant VM with an idempotent Ansible playbook,
proves selective re-runs, and wires an `ansible-pull` GitOps loop (bonus).

Repo layout produced:

```text
ansible/
├── inventory.ini                  # targets the Lab 5 VM (vagrant ssh-config)
├── inventory-local.ini            # local inventory used inside the VM (bonus)
├── playbook.yaml                  # the deploy
├── bonus-pull-setup.yaml          # installs the ansible-pull timer in the VM
├── files/
│   └── quicknotes                 # the static Linux binary (committed — ansible-pull needs it in the repo)
└── templates/
    ├── quicknotes.service.j2
    ├── ansible-pull.service.j2
    └── ansible-pull.timer.j2
```

The binary is built before the run:

```bash
CGO_ENABLED=0 go build -C app -o ../ansible/files/quicknotes .
```

---

## Task 1 — Idempotent Deploy

### inventory.ini

```ini
[lab5]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=2222

[lab5:vars]
ansible_user=vagrant
ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
ansible_python_interpreter=/usr/bin/python3
```

The host/port/key all come straight from `vagrant ssh-config`:

```text
$ vagrant ssh-config
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /Users/dmitrijnaumov/Code/Inno/DevOps/DevOps-Intro/.vagrant/machines/default/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
```

### playbook.yaml

```yaml
---
- name: Deploy QuickNotes to the Lab 5 VM
  hosts: lab5
  become: true
  gather_facts: false
  vars:
    qn_user: quicknotes
    qn_group: quicknotes
    qn_data_dir: /var/lib/quicknotes
    qn_bin: /usr/local/bin/quicknotes
    listen_addr: ":8080"
    data_path: "{{ qn_data_dir }}/notes.json"
    seed_path: "{{ qn_data_dir }}/seed.json"
  tasks:
    - name: Create quicknotes system group
      ansible.builtin.group:
        name: "{{ qn_group }}"
        system: true
    - name: Create quicknotes system user (no login, no interactive home)
      ansible.builtin.user:
        name: "{{ qn_user }}"
        group: "{{ qn_group }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false
        home: "{{ qn_data_dir }}"
    - name: Ensure data directory exists
      ansible.builtin.file:
        path: "{{ qn_data_dir }}"
        state: directory
        owner: "{{ qn_user }}"
        group: "{{ qn_group }}"
        mode: "0750"
    - name: Copy the QuickNotes static binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ qn_bin }}"
        owner: root
        group: root
        mode: "0755"
      notify: restart quicknotes
    - name: Copy the seed file (used on first boot when notes.json is absent)
      ansible.builtin.copy:
        src: ../app/seed.json
        dest: "{{ seed_path }}"
        owner: "{{ qn_user }}"
        group: "{{ qn_group }}"
        mode: "0640"
    - name: Render the systemd unit from template
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: restart quicknotes
    - name: Reload systemd, enable and start QuickNotes
      ansible.builtin.systemd_service:
        name: quicknotes.service
        daemon_reload: true
        enabled: true
        state: started
  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd_service:
        name: quicknotes.service
        daemon_reload: true
        state: restarted
```

### templates/quicknotes.service.j2

```jinja
[Unit]
Description=QuickNotes service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ qn_user }}
Group={{ qn_group }}
WorkingDirectory={{ qn_data_dir }}
Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ data_path }}
Environment=SEED_PATH={{ seed_path }}
ExecStart={{ qn_bin }}
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

### First run — PLAY RECAP

The binary must be cross-compiled for the VM (arm64 **Linux**) — building on the
macOS host without `GOOS=linux` yields a Mach-O binary the VM can't execute:

```bash
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -C app -o ../ansible/files/quicknotes .
file ansible/files/quicknotes
#   ansible/files/quicknotes: ELF 64-bit LSB executable, ARM aarch64, ...
```

First run against a clean VM creates everything and brings the service up:

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes to the Lab 5 VM] ***************************************

TASK [Create quicknotes system group] *****************************************
changed: [quicknotes-vm]
TASK [Create quicknotes system user (no login, no interactive home)] **********
changed: [quicknotes-vm]
TASK [Ensure data directory exists] *******************************************
changed: [quicknotes-vm]
TASK [Copy the QuickNotes static binary] **************************************
changed: [quicknotes-vm]
TASK [Copy the seed file (used on first boot when notes.json is absent)] *******
changed: [quicknotes-vm]
TASK [Render the systemd unit from template] **********************************
changed: [quicknotes-vm]
TASK [Reload systemd, enable and start QuickNotes] ****************************
changed: [quicknotes-vm]

RUNNING HANDLER [restart quicknotes] ******************************************
changed: [quicknotes-vm]

PLAY RECAP ********************************************************************
quicknotes-vm : ok=8    changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Service reachable from the host (via port forward)

```text
$ vagrant ssh -c 'systemctl is-active quicknotes && systemctl is-enabled quicknotes'
active
enabled

$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

### Design questions

**a) `command:` vs the dedicated modules (`apt`, `file`, `copy`, `systemd`). Which is idempotent and why does it matter?**

`command:` (and `shell:`) just run a string on the host. Ansible has no idea what the
command *does*, so by default it reports `changed=1` every single run — it cannot know
whether anything actually changed. The dedicated modules are **declarative**: you state the
desired end state (`mode: "0755"`, `state: present`) and the module first *checks* the
current state, then acts only if reality differs. That makes them idempotent — second run is
`ok`/`changed=0`. It matters because idempotency is what makes a playbook safe to re-run on a
schedule: convergence becomes a no-op when nothing drifted, and `changed` becomes a true
signal of "something was actually modified" rather than noise. It also makes `--check`
(dry-run) meaningful, which a bare `command:` cannot support.

**b) `notify:` and handlers — when does a handler fire, when does it *not*, and why is that the right default?**

A handler fires only if a task that notifies it reports `changed`. If the notifying tasks all
report `ok` (no change), the handler does **not** run. Handlers also run **once**, batched at
the end of the play (or at a `meta: flush_handlers`), even if notified by many tasks. Here the
`restart quicknotes` handler fires only when the binary copy *or* the template render changed —
so the service restarts exactly when its bits actually changed, and stays up untouched
otherwise. That is the right default because a restart is a disruptive action: you want it
coupled to real change, not run blindly every converge. It avoids needless downtime and keeps
re-runs cheap.

**c) Variable hierarchy — top 3 places to put a variable for this lab, and why.**

Ansible has 22+ precedence levels; for this lab the three I'd actually use, lowest→highest:

1. **Role/`defaults/`** (lowest) — sane fallbacks like `listen_addr: ":8080"`,
   `qn_data_dir: /var/lib/quicknotes`. Lowest precedence so anything can override them.
2. **`group_vars/lab5.yml`** — values true for the whole target group (the VM), e.g. paths or
   the data dir. Keeps host-targeting config out of the playbook body.
3. **Playbook `vars:`** — what I actually did here, because it's a single-host single-play lab
   and keeping the vars next to the tasks is the most readable. It outranks defaults/group_vars,
   which is fine for one play.

(`-e` extra-vars wins over all of these, handy for one-off overrides like
`-e listen_addr=":9090"` without editing files.)

**d) `gather_facts: true` is the default. Do you need it here? What does turning it off save?**

No — this playbook references no `ansible_*` facts (no OS detection, no `ansible_default_ipv4`,
etc.), so fact gathering is dead weight. I set `gather_facts: false`. Turning it off skips the
implicit `setup` task on every run: one fewer module execution and round-trip per host per run,
so the play connects and goes straight to work. On one VM it's a small win; across a fleet, or
on a 5-minute `ansible-pull` loop, those saved setups add up.

---

## Task 2 — Idempotency + Selective Re-run

### 1. Second run with no changes → `changed=0`

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

TASK [Create quicknotes system group] *****************************************
ok: [quicknotes-vm]
TASK [Create quicknotes system user (no login, no interactive home)] **********
ok: [quicknotes-vm]
TASK [Ensure data directory exists] *******************************************
ok: [quicknotes-vm]
TASK [Copy the QuickNotes static binary] **************************************
ok: [quicknotes-vm]
TASK [Copy the seed file (used on first boot when notes.json is absent)] *******
ok: [quicknotes-vm]
TASK [Render the systemd unit from template] **********************************
ok: [quicknotes-vm]
TASK [Reload systemd, enable and start QuickNotes] ****************************
ok: [quicknotes-vm]

PLAY RECAP ********************************************************************
quicknotes-vm : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

No task changed → the handler was never notified (no `RUNNING HANDLER` block), so `ok=7`.

### 2. Tweak one variable (`listen_addr: ":8080"` → `":9090"`) → selective change

Only the template content depends on `listen_addr`, so only the template task changes and only
the restart handler fires:

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

TASK [Create quicknotes system group] *****************************************
ok: [quicknotes-vm]
TASK [Create quicknotes system user (no login, no interactive home)] **********
ok: [quicknotes-vm]
TASK [Ensure data directory exists] *******************************************
ok: [quicknotes-vm]
TASK [Copy the QuickNotes static binary] **************************************
ok: [quicknotes-vm]
TASK [Copy the seed file (used on first boot when notes.json is absent)] *******
ok: [quicknotes-vm]
TASK [Render the systemd unit from template] **********************************
changed: [quicknotes-vm]
TASK [Reload systemd, enable and start QuickNotes] ****************************
ok: [quicknotes-vm]

RUNNING HANDLER [restart quicknotes] ******************************************
changed: [quicknotes-vm]

PLAY RECAP ********************************************************************
quicknotes-vm : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`template` = `changed=1`, handler invoked, every other task `ok`. (Reverted back to `:8080`
afterward so the host port-forward keeps working.)

### 3. `--check --diff` preview of a third change

Third change: `listen_addr: ":8081"`. Dry-run shows the unified diff without touching the VM:

```text
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff

TASK [Render the systemd unit from template] **********************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/dmitrijnaumov/.ansible/tmp/ansible-local-.../quicknotes.service.j2
@@ -8,7 +8,7 @@
 User=quicknotes
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:8080
+Environment=ADDR=:8081
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes
changed: [quicknotes-vm]

RUNNING HANDLER [restart quicknotes] ******************************************
changed: [quicknotes-vm]

PLAY RECAP ********************************************************************
quicknotes-vm : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

(In check mode the notify still queues, so the handler is shown as "would
restart" — no actual change is applied to the VM.)

### Design questions

**e) Why does the second run report `changed=0`? What do `file`/`template` check?**

Because each module compares desired vs current state and finds them already equal, so it does
nothing. `file` checks the path's existence, type (directory), owner, group, and mode against
what's declared. `template` renders the Jinja2 to a temp file in memory and compares its
**checksum (SHA)** against the file already on the host, plus the owner/group/mode; identical
content + identical attributes ⇒ `ok`, no write. `copy` does the same checksum comparison on
the source bytes. Nothing changed on disk, so every module short-circuits to `ok`.

**f) What if you used `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'`?**

Several failure modes stack up:

- **Never idempotent.** The redirect runs every time, so the task is `changed=1` on *every*
  run — the recap lies about drift and the restart-on-change logic becomes restart-always.
- **No notify coupling that means anything.** Since it always "changes," the handler restarts
  the service on every converge whether the content differs or not — needless downtime.
- **Clobbers the whole unit.** A single `echo` writes one line; you lose `[Unit]`, `[Service]`,
  `[Install]`, `ExecStart`, etc. — the unit is now malformed and `systemctl` won't start it.
- **No `--check`/`--diff` support.** A bare `shell:` can't preview; in check mode it's skipped
  or runs blind, so you lose the dry-run safety net entirely.
- **Quoting/escaping hazards.** Building the file by string interpolation invites broken quoting
  and partial writes (a crash mid-redirect truncates the live unit file).
- **No file attributes.** You'd still need extra steps for owner/group/mode that `template`
  does in one declaration.

**g) `--check` is dry-run, `--diff` shows changes. What bug does `--check --diff` catch that plain `--check` misses?**

Plain `--check` only tells you a task *would* change (`changed=1`) — not *what* or *why*.
`--diff` shows the exact before/after content, which catches a **silent unintended diff**: e.g.
a stray whitespace/templating change, a variable resolving to the wrong value, or a CRLF/line-
ending flip that would rewrite the unit and trigger a production restart. With plain `--check`
you'd see "template: changed" and shrug; with `--diff` you'd see that, say, `ADDR` is about to
become `:8081` when you only meant to bump the description — and stop before deploying.

---

## Bonus — `ansible-pull` GitOps loop

### inventory-local.ini (used inside the VM)

```ini
[self]
127.0.0.1 ansible_connection=local
```

### templates/ansible-pull.service.j2

```jinja
[Unit]
Description=QuickNotes ansible-pull convergence run
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull -U {{ pull_repo }} -C {{ pull_branch }} -i ansible/inventory-local.ini ansible/playbook.yaml
```

### templates/ansible-pull.timer.j2

```jinja
[Unit]
Description=Run QuickNotes ansible-pull every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=ansible-pull.service

[Install]
WantedBy=timers.target
```

These are installed in the VM by `bonus-pull-setup.yaml`, run once from the host:

```bash
ansible-playbook -i ansible/inventory.ini ansible/bonus-pull-setup.yaml
```

It installs `ansible` + `git` (distro packages), renders the two units, and enables/starts the
timer.

### Timer installed + active

```text
$ ansible-playbook -i ansible/inventory.ini ansible/bonus-pull-setup.yaml

TASK [Install ansible and git (distro packages)] ******************************
changed: [quicknotes-vm]
TASK [Render the ansible-pull service unit] ***********************************
changed: [quicknotes-vm]
TASK [Render the ansible-pull timer unit] *************************************
changed: [quicknotes-vm]
TASK [Enable and start the ansible-pull timer] ********************************
changed: [quicknotes-vm]

PLAY RECAP ********************************************************************
quicknotes-vm : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

```text
$ vagrant ssh -c 'systemctl list-timers | grep ansible-pull'
NEXT                         LEFT     LAST                         PASSED       UNIT                ACTIVATES
Mon 2026-06-29 16:20:39 UTC  3min 8s  Mon 2026-06-29 16:15:39 UTC  1min 51s ago ansible-pull.timer  ansible-pull.service
```

### Convergence timeline

> The timer pulls from `feature/lab7`, so that branch must be **pushed** first
> (the VM clones it). Steps to capture: push the branch → change `listen_addr`,
> commit, `git log -1 --format='%cd' --date=iso` (record commit time) → push →
> wait for the next timer fire (`systemctl list-timers`) → verify in the VM.

| Event                              | Timestamp (UTC)      |
|------------------------------------|----------------------|
| `git commit` (listen_addr → :9090) | 2026-06-29 16:18:10  |
| `git push origin feature/lab7`     | 2026-06-29 16:18:22  |
| Next timer fire (ansible-pull)     | 2026-06-29 16:20:39  |
| State reconciled in VM (verified)  | 2026-06-29 16:20:43  |

```text
# right after the fire, inside the VM, with no host ansible-playbook run:
$ vagrant ssh -c 'grep ADDR= /etc/systemd/system/quicknotes.service'
Environment=ADDR=:9090
$ vagrant ssh -c 'systemctl show quicknotes -p Environment'
Environment=ADDR=:9090 DATA_PATH=/var/lib/quicknotes/notes.json SEED_PATH=/var/lib/quicknotes/seed.json
```

The change pushed at 16:18 was live in the VM by 16:20 — under the 5-minute bound, host-free.

### Design questions

**h) `ansible-pull` is "pull" mode. What's the security benefit vs the push model?**

In push mode a control node holds SSH credentials and can log in to every managed host — that
control node (and its key) is a high-value, single point of compromise, and every host must
accept inbound SSH from it. In pull mode each VM **reaches out** to Git on its own and applies
the playbook locally. There's no inbound management port to expose, no shared SSH private key
sitting on a control node that can reach the whole fleet, and the blast radius of a stolen host
credential is just that one host (read access to a repo), not lateral SSH into everything. The
trust boundary shrinks to "can this node read the repo," and the node needs no listening
management surface at all.

**i) What's the same pattern called at the Kubernetes layer, and why is `ansible-pull` a fair simulator?**

It's **GitOps** — the industry-standard tools being **ArgoCD** and **Flux** (Lecture 7). The
cluster runs an agent that continuously pulls the declared desired state from Git and reconciles
the live state to match. `ansible-pull` is a fair VM-layer simulator because it's the same
control loop with the same properties: **Git is the single source of truth**, the node **pulls**
(no external push), and it **reconciles on a schedule** so drift is automatically corrected.
The differences are scope, not concept — Argo/Flux reconcile Kubernetes objects continuously
and report sync status, while `ansible-pull` reconciles OS/service state on a timer — but the
"declared state in Git → agent pulls → converge" pattern is identical.

---

## Common pitfalls I avoided

- Used dedicated modules (`group`, `user`, `file`, `copy`, `template`, `systemd_service`)
  throughout — no `shell:`/`command:` — so every re-run is genuinely idempotent.
- `become: true` set at the play level (every task needs root).
- Handler notified by *both* the binary copy and the template render, so a restart happens on
  either change and only then.
- Inventory key path + port copied from `vagrant ssh-config` to avoid "connection refused".
- Binary built with `CGO_ENABLED=0` so it's fully static and runs on the VM with no libc
  coupling.
