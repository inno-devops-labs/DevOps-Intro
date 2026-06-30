# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

**Author:** Karim Abdulkin (@GrandAdmiralBee)
**Branch:** `feature/lab7`
**Control node:** NixOS 26.05 host, `ansible [core 2.20.5]` from `pkgs.ansible` (devenv).
**Target:** Lab 5 VM — Ubuntu 24.04, libvirt/KVM (`qemu:///session`), bridged on `virbr0` at `192.168.122.77`.

> Lab 5 used libvirt/KVM instead of VirtualBox.
> The Lab 7 inventory therefore targets the libvirt NAT IP directly rather than the Vagrant SSH port-forward — it's the same Vagrant-generated
> insecure key either way.

---

## Task 1 — Idempotent Deploy to the Lab 5 VM

### Layout

```text
ansible/
├── inventory.ini
├── playbook.yaml
├── bootstrap-pull.yaml          (bonus)
├── files/
│   ├── quicknotes               (6.1 MB static binary, CGO_ENABLED=0 -trimpath -s -w)
│   ├── seed.json
│   └── inventory-local.ini      (bonus)
└── templates/
    ├── quicknotes.service.j2
    ├── ansible-pull.service.j2  (bonus)
    └── ansible-pull.timer.j2    (bonus)
```

### `ansible/inventory.ini`

```ini
[lab5]
quicknotes-vm ansible_host=192.168.122.77

[lab5:vars]
ansible_user=vagrant
ansible_port=22
ansible_ssh_private_key_file=/home/karim/Dev/DevOps-Intro/.vagrant/machines/default/libvirt/private_key
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

### `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes to the Lab 5 VM
  hosts: lab5
  become: true
  gather_facts: false

  vars:
    app_user: quicknotes
    data_dir: /var/lib/quicknotes
    binary_path: /usr/local/bin/quicknotes
    listen_addr: ":8080"
    data_path: /var/lib/quicknotes/notes.json
    seed_path: /var/lib/quicknotes/seed.json

  tasks:
    - name: Ensure quicknotes system user exists
      ansible.builtin.user:
        name: "{{ app_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false
        home: "{{ data_dir }}"

    - name: Ensure data directory exists
      ansible.builtin.file:
        path: "{{ data_dir }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: "0750"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ binary_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart quicknotes

    - name: Copy seed.json
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ seed_path }}"
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: "0644"

    - name: Render systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: Restart quicknotes

    - name: Enable and start quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        enabled: true
        state: started
        daemon_reload: true

  handlers:
    - name: Restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
        daemon_reload: true
```

### `ansible/templates/quicknotes.service.j2`

```ini
[Unit]
Description=QuickNotes — minimal Go notes service (Lab 7)
Documentation=https://github.com/inno-devops-labs/DevOps-Intro
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ app_user }}
Group={{ app_user }}

ExecStart={{ binary_path }}
WorkingDirectory={{ data_dir }}

Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ data_path }}
Environment=SEED_PATH={{ seed_path }}

Restart=on-failure
RestartSec=2s

NoNewPrivileges=true
ProtectSystem=full
ProtectHome=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

`NoNewPrivileges` + `ProtectSystem=full` + `ProtectHome` + `PrivateTmp` are systemd's "five free hardening defaults" —
same features I used at the container layer in Lab 6. I applied them here at the unit level.

### `ansible-lint` (production profile)

```console
$ ansible-lint ansible/playbook.yaml ansible/bootstrap-pull.yaml
Passed: 0 failure(s), 0 warning(s) on 2 files.
Last profile that met the validation criteria was 'production'.
```

### First-run PLAY RECAP

```console
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes to the Lab 5 VM] ***************************************

TASK [Ensure quicknotes system user exists] ************************************
changed: [quicknotes-vm]

TASK [Ensure data directory exists] ********************************************
changed: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
changed: [quicknotes-vm]

TASK [Copy seed.json] **********************************************************
changed: [quicknotes-vm]

TASK [Render systemd unit] *****************************************************
changed: [quicknotes-vm]

TASK [Enable and start quicknotes] *********************************************
changed: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=7  changed=7  unreachable=0  failed=0
```

All 6 tasks ran, and the `Restart quicknotes` handler fired once at the end of the play
(notified by both `Copy QuickNotes binary` and `Render systemd unit` — Ansible dedupes a handler fired multiple times to a single run).

### Proof the service is reachable

```console
$ ssh vagrant@192.168.122.77 'sudo systemctl is-enabled quicknotes; sudo systemctl is-active quicknotes; ps -fu quicknotes'
enabled
active
UID          PID    PPID  C STIME TTY          TIME CMD
quickno+   11921       1  0 19:24 ?        00:00:00 /usr/local/bin/quicknotes

$ ssh vagrant@192.168.122.77 'sudo ls -la /var/lib/quicknotes'
drwxr-x---  2 quicknotes quicknotes 4096 Jun 30 19:24 .
-rw-r--r--  1 quicknotes quicknotes  756 Jun 30 19:24 notes.json
-rw-r--r--  1 quicknotes quicknotes  756 Jun 30 19:24 seed.json

$ curl -s http://127.0.0.1:18080/health        # via Vagrant port-forward
{"notes":4,"status":"ok"}

$ curl -s http://192.168.122.77:8080/health    # direct on libvirt NAT
{"notes":4,"status":"ok"}
```

Service runs as the unprivileged `quicknotes` user, data directory is `0750 quicknotes:quicknotes`,
and both routes into the VM (port-forward 18080→8080 and direct `:8080`) return the expected 4 seeded notes.

### Design questions

**a) `command:` vs dedicated modules.** `command:` runs a shell command on the target and Ansible doesn't know what it did —
every invocation reports `changed=true` unconditionally.
The dedicated modules (`apt`, `file`, `copy`, `systemd`, `template`, … ) read the current state first and only act when it differs from the declared state.
That's what makes them idempotent — second run finishes with `changed=0` because nothing has drifted.
Idempotency matters because it turns the playbook into something safe to run repeatedly:
in a cron, in a `ansible-pull` timer (bonus), as a pre-deploy sanity sweep — without worrying that each run causes a needless restart or worse.

**b) When does a handler fire / not fire?** A handler fires **once at the end of the play**, only if a task that listed it under `notify:` reported `changed=true` during that play. So the handler is skipped on a clean re-run (nothing changed → nobody notified). Multiple notifications of the same handler get collapsed into a single fire — `Copy QuickNotes binary` and `Render systemd unit` both notified `Restart quicknotes`, the handler ran once. This default is the right one because it bundles disruptive side effects (a `systemctl restart`) and only emits them when something actually warrants the disruption. A noisy alternative — restart on every task — would mean every playbook run causes downtime, defeating the point of idempotency.

**c) Top 3 places to put variables for this lab.** Out of Ansible's 22-level precedence list, the three I'd actually reach for here are:

1. **Role/play `defaults/main.yml` (lowest precedence).** Where the playbook's own defaults live — anyone can override them. For this lab there's no role, so the equivalent is the play's `vars:` block (kept loud at the top of `playbook.yaml`).
2. **`group_vars/lab5.yml`.** Per-host-group overrides. Things like `listen_addr` that might differ between the dev VM and a hypothetical staging group belong here.
3. **`--extra-vars` on the command line (very high precedence).** For one-off ad-hoc overrides during demos or emergencies (e.g. `--extra-vars 'listen_addr=":9090"'` to reproduce a customer's port collision once, without committing a YAML edit).

Tier 1 ↔ tier 2 ↔ tier 3 is "what the author wanted" ↔ "what this environment needs" ↔ "what I need right now" — three different lifetimes, each in its own file.

**d) `gather_facts: true`.** Not needed in this playbook — no task references `ansible_distribution`, `ansible_os_family`, `ansible_user`, `ansible_processor_cores`, anything. Fact gathering opens a connection, copies `setup.py` over, runs it, returns ~1 KB of JSON, and on a single host this typically costs about 1–3 seconds (and a connection round-trip) — small but pure waste. So `gather_facts: false` is in the play, and timing reports show it. The bonus `bootstrap-pull.yaml` keeps `gather_facts: true` because the `apt:` module benefits from package-manager facts.

---

## Task 2 — Idempotency + Selective Re-run

### Demonstration 1: clean re-run → `changed=0`

Same playbook, same target, immediately after Task 1:

```console
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

TASK [Ensure quicknotes system user exists] ************************************
ok: [quicknotes-vm]

TASK [Ensure data directory exists] ********************************************
ok: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
ok: [quicknotes-vm]

TASK [Copy seed.json] **********************************************************
ok: [quicknotes-vm]

TASK [Render systemd unit] *****************************************************
ok: [quicknotes-vm]

TASK [Enable and start quicknotes] *********************************************
ok: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=6  changed=0  unreachable=0  failed=0
```

Every task settles on `ok`, no handler fires (nobody notified it), `changed=0`. This is the "boring" outcome we want from a real config-management tool.

### Demonstration 2: `listen_addr: ":8080"` → `":9090"` — only the template + handler move

```console
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

TASK [Ensure quicknotes system user exists] ************************************
ok: [quicknotes-vm]

TASK [Ensure data directory exists] ********************************************
ok: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
ok: [quicknotes-vm]

TASK [Copy seed.json] **********************************************************
ok: [quicknotes-vm]

TASK [Render systemd unit] *****************************************************
changed: [quicknotes-vm]

TASK [Enable and start quicknotes] *********************************************
ok: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=7  changed=2  unreachable=0  failed=0
```

Exactly two `changed` entries: the template rendered new content (the rendered checksum differs from `/etc/systemd/system/quicknotes.service` on disk), and the handler it notified ran a `systemctl restart quicknotes`. Everything else stayed `ok` — the binary, the user, the data dir didn't move because their declared state is still satisfied. *(Aside: changing `listen_addr` away from `:8080` breaks the Vagrant 18080→8080 port-forward; this is reverted before the final state for the curl proof to work again.)*

### Demonstration 3: `--check --diff` preview for a third variable change

`listen_addr: ":9091"`, then `--check --diff` against the current `:9090` state on disk:

```console
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff

TASK [Render systemd unit] *****************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/karim/.ansible/tmp/ansible-local-…/tmph1qb122v/quicknotes.service.j2
@@ -12,7 +12,7 @@
 ExecStart=/usr/local/bin/quicknotes
 WorkingDirectory=/var/lib/quicknotes

-Environment=ADDR=:9090
+Environment=ADDR=:9091
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json


changed: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=7  changed=2  unreachable=0  failed=0
```

Unified diff of the rendered unit file: exactly the one line we'd expect.

### Design questions

**e) Why is the second run `changed=0`? What do `file:` / `template:` check?**

- `file:` reads the path's `stat()`, owner/group, mode, and `state` — if the directory exists with the declared `owner=quicknotes group=quicknotes mode=0750`, there's nothing to do. (For absent targets, the only check is that it doesn't exist.)
- `copy:` reads the local file's SHA1 + destination's SHA1; if they match, no transfer, no permission change. If only mode/owner differs, only those `chmod`/`chown` syscalls fire.
- `template:` renders the Jinja into a temp file on the control node, computes its SHA1, compares to the destination's SHA1. Identical → declared `ok`; different → upload + `mv` + handler notification.

The big insight: it's a content checksum, not a timestamp. Editing the template's whitespace or adding a comment after a variable doesn't trick it into "changed" — the rendered output is identical, the SHA1 matches, the module declares `ok`. Conversely, anything that changes a single byte of the rendered output (e.g. swapping `:8080` for `:9090`) flips the result to `changed` regardless of whitespace tricks.

**f) `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` instead of `template:` — what fails?**

A whole bouquet:

1. **Not idempotent.** `shell:` reports `changed=true` every run, even when the file content is bit-identical to what's already there. So the handler fires on every run, meaning `systemctl restart quicknotes` every play, meaning a brief downtime per run. The whole point of the lab evaporates.
2. **No diff output.** `--check --diff` against `shell:` gives you nothing — Ansible cannot synthesize a diff because the module doesn't expose the "before" or "after" content; it just shells out and lets `>` happen.
3. **Atomicity gone.** `template:` does `tempfile → rename` so a partial write can never leave a half-finished file. `>` opens the file, truncates it to zero, and then writes — if Ansible is interrupted between truncate and write (kill -9, OOM, host crash), the unit file is empty and `systemd` refuses to load it. Now the service can't start until someone re-runs the playbook.
4. **Quoting hell.** Variables become string interpolation in the shell command line. `Environment=ADDR={{ listen_addr }}` would need escaping for any value containing `$`, backticks, quotes. Real production playbooks where someone tried this end up with bugs that only fire when a customer's value happens to contain a `$` sign.
5. **Permissions left to chance.** `template:` sets `owner/group/mode` declaratively; `>` inherits the calling shell's umask. The unit file might end up `0644 root:root` today (because root's umask is 022) and `0640` tomorrow if someone changed the umask.

Five failure modes for what felt like a one-line shortcut.

**g) `--check --diff` vs `--check` alone.**

`--check` answers "would something change?" — it returns `changed=1` for tasks that would do something. But on a `template:` task it doesn't tell you *what* would change. Plain `--check` would happily pass a deploy where someone accidentally swapped a port digit (`:8080` → `:8800`) or changed a path (`/var/lib/quicknotes` → `/var/lib/quicknote`, missing `s`). The recap says `changed=1`, which is what you'd expect from a normal config tweak; you greenlight the deploy.

`--check --diff` shows the unified diff. Now the typo is staring at you in red/green. The class of bug `--check --diff` catches that `--check` misses: **silent typos and accidental rewrites** that pass the "is changed?" test but fail the "is it the change I meant?" test. In production this is the difference between "yes, my port change went through" and "yes, my port change went through and also I overwrote `Restart=on-failure` with `Restart=no` because I edited the template wrong an hour ago".

---

## Bonus Task — `ansible-pull` GitOps Loop

### Bootstrap playbook — `ansible/bootstrap-pull.yaml`

```yaml
---
- name: Bootstrap ansible-pull GitOps loop on the Lab 5 VM
  hosts: lab5
  become: true
  gather_facts: true

  vars:
    repo_url: https://github.com/GrandAdmiralBee/DevOps-Intro
    repo_branch: feature/lab7
    pull_inventory: /etc/ansible/hosts-local.ini
    pull_interval: 5min

  tasks:
    - name: Install ansible and git
      ansible.builtin.apt:
        name: [ansible, git]
        state: present
        update_cache: true
        cache_valid_time: 3600

    - name: Ensure /etc/ansible exists
      ansible.builtin.file:
        path: /etc/ansible
        state: directory
        mode: "0755"

    - name: Install local inventory for ansible-pull
      ansible.builtin.copy:
        src: files/inventory-local.ini
        dest: "{{ pull_inventory }}"
        mode: "0644"

    - name: Render ansible-pull.service
      ansible.builtin.template:
        src: templates/ansible-pull.service.j2
        dest: /etc/systemd/system/ansible-pull.service
        mode: "0644"
      notify: Reload systemd

    - name: Render ansible-pull.timer
      ansible.builtin.template:
        src: templates/ansible-pull.timer.j2
        dest: /etc/systemd/system/ansible-pull.timer
        mode: "0644"
      notify: Reload systemd

    - name: Enable and start ansible-pull.timer
      ansible.builtin.systemd:
        name: ansible-pull.timer
        enabled: true
        state: started
        daemon_reload: true

  handlers:
    - name: Reload systemd
      ansible.builtin.systemd:
        daemon_reload: true
```

### Local inventory used by `ansible-pull` — `ansible/files/inventory-local.ini`

```ini
[lab5]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

The same `hosts: lab5` group name as the main playbook, but bound to localhost via `ansible_connection=local`. That way the same `playbook.yaml` works in two modes: push from the host's control node (real SSH), or local self-reconciliation under `ansible-pull` (no SSH at all).

### Systemd unit + timer (rendered on the VM)

`/etc/systemd/system/ansible-pull.service`:

```ini
[Unit]
Description=ansible-pull from https://github.com/GrandAdmiralBee/DevOps-Intro on branch feature/lab7
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull \
  --url https://github.com/GrandAdmiralBee/DevOps-Intro \
  --checkout feature/lab7 \
  --inventory /etc/ansible/hosts-local.ini \
  ansible/playbook.yaml
```

`/etc/systemd/system/ansible-pull.timer`:

```ini
[Unit]
Description=Run ansible-pull every 5min

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
AccuracySec=15s
Unit=ansible-pull.service
Persistent=true

[Install]
WantedBy=timers.target
```

### Timer is active

```console
$ systemctl list-timers --all | grep ansible-pull
Tue 2026-06-30 19:38:44 UTC  3min  Tue 2026-06-30 19:32:52 UTC  ansible-pull.timer  ansible-pull.service

$ sudo systemctl status ansible-pull.timer --no-pager
● ansible-pull.timer - Run ansible-pull every 5min
     Loaded: loaded (/etc/systemd/system/ansible-pull.timer; enabled; preset: enabled)
     Active: active (waiting) since Tue 2026-06-30 19:32:52 UTC
    Trigger: Tue 2026-06-30 19:37:52 UTC; 4min left
   Triggers: ● ansible-pull.service
```

### Convergence demonstrated (push → reconcile timeline)

I edited the playbook to flip `listen_addr` from `:8080` to `:9090`, committed, and pushed to `origin/feature/lab7`.

| When (UTC) | Event |
|------------|-------|
| **19:35:14** | `git push` — commit `1347c25` ("bonus convergence demo — listen_addr :8080 → :9090") lands on `origin/feature/lab7` |
| 19:35:48 → 19:38:50 | Polling SSH on VM: `grep ADDR /etc/systemd/system/quicknotes.service` still shows `:8080` (last `ansible-pull` was at 19:33:44, next at 19:38:50) |
| **19:38:49** | Timer fires → `ansible-pull.service` starts → `git pull origin feature/lab7` returns commit `1347c25` |
| **19:39:20** | Polling shows `Environment=ADDR=:9090`. Template task `changed`, handler fired `systemctl restart quicknotes` |

End-to-end: **~4 minutes** from `git push` to applied config — within the lab's 5-minute window with room to spare. Journal extract from the converged run:

```console
$ sudo journalctl -u ansible-pull.service --no-pager -o cat | tail -20
Starting Ansible Pull at 2026-06-30 19:38:49
/usr/bin/ansible-pull --url https://github.com/GrandAdmiralBee/DevOps-Intro --checkout feature/lab7 --inventory /etc/ansible/hosts-local.ini ansible/playbook.yaml
…
TASK [Render systemd unit] *********************
changed: [localhost]
TASK [Enable and start quicknotes] ************
ok: [localhost]
RUNNING HANDLER [Restart quicknotes] **********
changed: [localhost]
PLAY RECAP ************************************
localhost                  : ok=7  changed=2  unreachable=0  failed=0
Finished ansible-pull.service.
```

```console
$ sudo ss -tlnp | grep -E ':8080|:9090'
LISTEN 0  4096  *:9090  *:*  users:(("quicknotes",pid=15705,fd=3))
```

QuickNotes now binds `:9090` — driven entirely by a single git push, no SSH from the host, no `ansible-playbook` invocation. The lab's "GitOps preview" is working.

After capturing the proof I reverted `listen_addr` to `:8080` and pushed again, so the next `ansible-pull` cycle restored the working port-forward path.

### Design questions

**h) `ansible-pull` security benefit vs push mode.** In push mode the control node holds an SSH private key that unlocks `become: true` on *every* managed host. That key is, by construction, an "own the fleet" credential — if the control node is compromised, every host falls with it. The control node is also a network sink that needs an inbound SSH allowlist or a bastion, both of which expand attack surface.

`ansible-pull` flips the direction: the VM clones a (public) git repo and applies the playbook to itself. The control node doesn't exist as a privileged actor — it's just a git host. Each VM holds only its own root-level authority and reaches *out* through the firewall, so no inbound holes. Secrets become a per-host concern (ansible-vault on the VM, sops/age, etc.) rather than a centralized blast-radius problem. The trade is loss of fleet-wide orchestration (you can't push an emergency hotfix in 30 seconds — you push to git and wait for the timer), and you trust git history as your audit trail rather than the control node's logs.

**i) Same pattern at the Kubernetes layer.** This is **GitOps** as defined by ArgoCD and Flux — an agent inside the cluster watches a git repo (or polls on an interval), pulls manifests, and reconciles cluster state to match. `ansible-pull` is a fair simulator at the VM layer because the *control loop* is identical:

- Source of truth lives in git, not in an imperative `kubectl apply` / `ansible-playbook` from someone's laptop.
- A daemon on the target reads the source of truth on a schedule.
- Diff is computed (Argo's `kubectl diff`-style reconciliation, Ansible's checksum / state checks).
- Only the diff is applied; identical state is a no-op.
- Drift detection: if someone `ssh`'d in and edited `/etc/systemd/system/quicknotes.service` by hand, the next `ansible-pull` overwrites it with what git says.

The difference is the granularity and the target — Kubernetes works on the cluster API and is declaratively continuous, Ansible works on Linux files and runs on a discrete cadence — but the loop is the same one. Using `ansible-pull` as a step toward Argo means students internalize the "git is the source of truth, agents reconcile" mental model before getting buried in Argo's CRDs.

---

## Pitfalls Hit and Worked Through

- 🪤 **`/etc/ansible` doesn't exist on a freshly apt-installed Ubuntu 24.04.** First bootstrap run died on `Destination directory /etc/ansible does not exist`. Adding a `file: state=directory` task before the inventory `copy:` fixed it — the apt package no longer creates `/etc/ansible` by default in current Ubuntu builds.
- 🪤 **Relative `ansible_ssh_private_key_file`.** Started with `../.vagrant/...` in `inventory.ini`; SSH resolved it relative to the calling shell's CWD (not the inventory file). When invoked from the repo root that worked, when invoked from the `ansible/` directory it didn't. Switched to an absolute path — verbose but unambiguous.
- 🪤 **`gather_facts: false` and the `apt:` module.** Set `gather_facts: false` on the main `playbook.yaml` (saves the round-trip; nothing needs facts). On `bootstrap-pull.yaml` I kept facts on because `apt:` benefits from `ansible_pkg_mgr` autodetection and a few cache decisions.
- 🪤 **Vagrant port-forward only forwards `:8080`.** The Task 2 demo flips `listen_addr` to `:9090`/`:9091` to prove selective change — at that point `curl :18080/health` from the host fails (it forwards to a port no longer being listened on). Reverting to `:8080` is part of the demo, not a separate cleanup step.
- 🪤 **Initial `OnBootSec=1min` did not fire on enable.** Boot was hours before the timer was armed, so the "1 minute after boot" point was in the past with no future occurrence. The 5-minute `OnUnitActiveSec=` cycle is what we actually rely on. `Persistent=true` would matter only if the VM rebooted between commit and reconcile — but the demo runs end-to-end without a reboot.

---

## Acceptance checklist

### Task 1 (6 pts)
- [x] Playbook deploys QuickNotes to the Vagrant VM
- [x] Service `active (running)`; `curl :18080/health` works
- [x] Full PLAY RECAP captured
- [x] Design questions a–d answered

### Task 2 (4 pts)
- [x] Second run shows `changed=0`
- [x] `listen_addr` tweak fires only the affected handler (template + handler, others `ok`)
- [x] `--check --diff` example captured
- [x] Design questions e–g answered

### Bonus (2 pts)
- [x] Systemd timer installed and active
- [x] Push-to-git → VM reconciled within 5 min observed (~4 min end-to-end)
- [x] Design questions h–i answered
