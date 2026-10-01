# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

**Author:** Kolpakova Valeriia — v.kolpakova@innopolis.university

**One deviation from the Prerequisites:** they ask for Ansible 10.x; Homebrew installs
**ansible 14.4.0 (ansible-core 2.21.4)** on this machine. Everything used here is the stable
module set (`user`, `file`, `copy`, `template`, `systemd_service`), unchanged across those
releases. The target is the Lab 5 VM — Ubuntu 24.04 arm64 on VirtualBox.

---

## Task 1 — Idempotent Deploy to the Lab 5 VM

### `ansible/inventory.ini`

Values taken from `vagrant ssh-config` (host `127.0.0.1`, port `2222`, user `vagrant`, and the
key Vagrant generated for this machine):

```ini
[quicknotes]
lab5-vm ansible_host=127.0.0.1 ansible_port=2222

[quicknotes:vars]
ansible_user=vagrant
ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
```

### `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_binary_path: /usr/local/bin/quicknotes
    quicknotes_listen_addr: ":8080"
    quicknotes_data_path: /var/lib/quicknotes/notes.json
    quicknotes_seed_path: /var/lib/quicknotes/seed.json
    quicknotes_restart_sec: 4

  tasks:
    - name: Create the quicknotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false
        home: "{{ quicknotes_data_dir }}"

    - name: Ensure the data directory exists
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0750"

    - name: Install the QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ quicknotes_binary_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart quicknotes

    - name: Install the seed file
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ quicknotes_seed_path }}"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0640"

    - name: Render the systemd unit
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
        daemon_reload: true
        enabled: true
        state: started

  handlers:
    - name: Restart quicknotes
      ansible.builtin.systemd_service:
        name: quicknotes
        daemon_reload: true
        state: restarted
```

### `ansible/templates/quicknotes.service.j2`

```jinja
[Unit]
Description=QuickNotes
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ quicknotes_user }}
Group={{ quicknotes_user }}
WorkingDirectory={{ quicknotes_data_dir }}
Environment=ADDR={{ quicknotes_listen_addr }}
Environment=DATA_PATH={{ quicknotes_data_path }}
Environment=SEED_PATH={{ quicknotes_seed_path }}
ExecStart={{ quicknotes_binary_path }}
Restart=on-failure
RestartSec={{ quicknotes_restart_sec }}

[Install]
WantedBy=multi-user.target
```

The binary shipped in `ansible/files/quicknotes` is 5.3 MB, built for the VM's architecture
with `CGO_ENABLED=0 go build -trimpath -ldflags='-s -w'` — `ELF 64-bit LSB executable, ARM
aarch64, statically linked, stripped`.

### First run — full PLAY RECAP

```console
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] *******************************************************

TASK [Create the quicknotes system user] ***************************************
changed: [lab5-vm]

TASK [Ensure the data directory exists] ****************************************
changed: [lab5-vm]

TASK [Install the QuickNotes binary] *******************************************
changed: [lab5-vm]

TASK [Install the seed file] ***************************************************
changed: [lab5-vm]

TASK [Render the systemd unit] *************************************************
changed: [lab5-vm]

TASK [Enable and start quicknotes] *********************************************
changed: [lab5-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [lab5-vm]

PLAY RECAP *********************************************************************
lab5-vm   : ok=7  changed=7  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

**A note on `--check` before the first run.** The brief's 1.7 runs `--check` first. On a
greenfield host that dry-run *fails* at the last task:

```
fatal: [lab5-vm]: FAILED! => {"msg": "Could not find the requested service quicknotes: host"}
```

This is check mode behaving correctly, not a playbook bug: in check mode the unit file is never
actually written, so when the `systemd_service` task asks systemd about a unit that does not
exist yet, systemd answers truthfully. `--check` is meaningful against a host that has already
converged once — which is exactly where it is used in Task 2 below.

### Service reachable, and serving the seed

```console
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}

$ curl -s http://localhost:18080/notes
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize,
deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},
{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env
vars, signal handling, grace...
```

`/notes` returns the seeded records rather than `[]`, which is the proof that `seed.json`
reached `/var/lib/quicknotes/seed.json` and that `SEED_PATH` points at it.

And it runs as the unprivileged user the play created, not root:

```console
$ vagrant ssh -c 'systemctl is-active quicknotes; systemctl is-enabled quicknotes; ps -o user= -C quicknotes'
active
enabled
quicknotes
```

### 1.5 — Design questions

**a) `command:` versus the dedicated modules — which is idempotent, and why does it matter?**

`command:`/`shell:` run a process and report `changed` every single time, because Ansible has
no idea what the command does — it cannot inspect the end state, only the exit code. The
dedicated modules are written around a desired state: `copy` compares a checksum, `file`
compares ownership and mode, `user` asks whether the account already exists, `systemd_service`
queries the unit's current state. Each one makes a change only when reality differs from the
declaration, and reports `ok` otherwise.

Why it matters beyond tidy output: `changed` is a signal other things act on. My handler fires
on `notify` from the binary and template tasks, so if those tasks reported `changed` on every
run the service would be restarted on every run, turning a no-op playbook into an outage
generator. Idempotency is also what makes the playbook safe to run on a schedule — which the
bonus does literally, every five minutes.

**b) `notify:` and handlers — when does a handler fire, when does it not, and why is that right?**

A handler fires when a task that notifies it reports `changed`, and it runs once at the end of
the play no matter how many tasks notified it. It does *not* fire when the notifying task
reports `ok`, and it does not fire when that task is skipped or fails.

That default is right because a restart is a side effect you want tied to a cause. Restarting
QuickNotes is a brief outage; doing it because the playbook ran, rather than because the binary
or the unit actually changed, would mean the cost of configuration management scaled with how
often you check rather than how often something changes. Deferring to the end of the play also
means ten changed tasks produce one restart, not ten.

The sharp edge is that `notify:` matches handlers **by name, as a string**. A typo does not
error — the notification silently goes nowhere, and you get a deployed binary that is never
actually running.

**c) Variable hierarchy — the top 3 places for this lab's variables.**

1. **Role/play `defaults`** for every value that has a sane default and that someone might want
   to override — the ports, paths and user name. Lowest precedence by design, so overriding one
   never requires editing the thing that defines it.
2. **`group_vars/quicknotes.yml`** for anything that is a property of *this environment* rather
   than of the application — if the VM needed a different data directory from production, that
   belongs here, keyed to the inventory group, not sprinkled through the play.
3. **`--extra-vars`** for the one-off override at run time (a smoke test on a different port).
   Highest precedence of all, which is what you want for "just this once" without touching a
   committed file.

For this lab the values live in `vars:` on the play, which sits above `defaults` and below
`group_vars`. That is the honest choice for a single-play, single-host exercise: the variables
are not yet shared by anything, and inventing `group_vars/` for one group of one host would be
structure without purpose. The moment a second environment appears, they move to `defaults` +
`group_vars`.

**d) `gather_facts: true` is the default. Do you need it here?**

No, and I turned it off. Fact gathering runs the `setup` module, which collects several hundred
facts about the host — network interfaces, mounts, hardware, distribution, every environment
variable. This play references none of them: every value it uses is a variable I declared.

What it saves is one extra round trip per run: `setup` must be copied over SSH, executed, and
have its JSON serialised back before the first real task starts — typically a second or two,
and more on a slow link. That is negligible when you deploy by hand and significant when a
timer runs the same play every five minutes forever, which the bonus does. The trade is that
if I later need `ansible_distribution` to branch on OS, the play will fail with an undefined
variable until I turn gathering back on or add `setup` explicitly — a loud failure rather than
a silent wrong answer, which is the acceptable direction.

---

## Task 2 — Prove Idempotency + Selective Re-run

### 1. Re-run with nothing changed → `changed=0`

```console
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

TASK [Install the seed file] ***************************************************
ok: [lab5-vm]

TASK [Render the systemd unit] *************************************************
ok: [lab5-vm]

TASK [Enable and start quicknotes] *********************************************
ok: [lab5-vm]

PLAY RECAP *********************************************************************
lab5-vm   : ok=6  changed=0  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

Six tasks `ok`, nothing changed, and the handler did not run — `ok=6` rather than `ok=7`
because a handler that is never notified is never counted.

### 2. One variable changed → only the template task, and the handler

Changed `quicknotes_listen_addr` from `":8080"` to `":9090"` and re-ran:

```console
TASK [Ensure the data directory exists] ****************************************
ok: [lab5-vm]

TASK [Install the QuickNotes binary] *******************************************
ok: [lab5-vm]

TASK [Install the seed file] ***************************************************
ok: [lab5-vm]

TASK [Render the systemd unit] *************************************************
changed: [lab5-vm]

TASK [Enable and start quicknotes] *********************************************
ok: [lab5-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [lab5-vm]

PLAY RECAP *********************************************************************
lab5-vm   : ok=7  changed=2  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

Exactly the required shape: `template` is `changed=1`, the `Restart quicknotes` handler is
invoked, and every other task reports `ok`. The two changes are the template plus the handler
it triggered. (Reverted to `:8080` afterwards so the Vagrant port forward keeps working.)

### 3. `--check --diff` on a third change

Changed `quicknotes_restart_sec` from `2` to `5` and previewed it:

```console
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff

TASK [Render the systemd unit] *************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/ivozhs/.ansible/tmp/.../quicknotes.service.j2
@@ -13,7 +13,7 @@
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=2
+RestartSec=5

 [Install]
 WantedBy=multi-user.target

changed: [lab5-vm]

PLAY RECAP *********************************************************************
lab5-vm   : ok=7  changed=2  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

### 2.2 — Design questions

**e) Why does the second run report `changed=0`? What do `file` / `template` actually check?**

Because each module compares declared state against observed state before touching anything.

`copy` and `template` hash the content they are about to write and compare it with a checksum
of the file already on the host — `template` renders the Jinja source first, so the comparison
is against the *rendered* result, not the template. If the digests match, no write happens.
Both then separately reconcile the metadata — owner, group, mode — because a file can have
correct content and wrong permissions, and that is still a change.

`file` has no content to compare, so it checks existence, type (directory vs file vs link) and
the same ownership/mode triple.

The practical corollary is the pitfall in the brief: a template that reports `changed` on every
run usually has identical content and a mismatched `mode:` or `owner:`, and `--diff` is how you
find out which.

**f) What if I used `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'`?**

It would appear to work and then fail in four distinct ways.

First, idempotency dies: the shell task reports `changed` on every run, so the handler restarts
QuickNotes every run — a needless outage each time the playbook is executed, and on the bonus's
five-minute timer, a restart every five minutes forever.

Second, `--check` becomes a lie. Ansible cannot dry-run an arbitrary shell command, so in check
mode the task is skipped and reports nothing useful; `--diff` has nothing to diff. The
pre-deploy preview that Task 2.3 is built around stops existing.

Third, correctness. `echo` with `>` gives no control over owner or mode — the file lands with
whatever the umask dictates. There is no atomic write either: `template` renders to a temporary
file and moves it into place, so systemd never sees a half-written unit, whereas a redirect
truncates the file first and fills it afterwards.

Fourth, quoting. A unit file is multi-line with `$`, `%` and quotes in it; getting that through
a shell string intact is a source of bugs that simply does not exist when Jinja renders it.

**g) What does `--check --diff` catch that plain `--check` misses?**

`--check` tells you *that* a task would change something; `--diff` tells you *what*. The bug
that needs both is the change you did not intend, hiding inside one you did.

Concretely: suppose I edit `quicknotes_listen_addr` and run `--check`. It reports
`Render the systemd unit: changed` — which is exactly what I expected, so I deploy. What
`--diff` would have shown is that the rendered file differs in *two* places, because an
unrelated variable I edited last week and forgot about also feeds that template, or because the
file on the host was hand-edited during an incident and my deploy is about to silently revert
that fix. Plain `--check` collapses "one intended change" and "one intended plus one surprise"
into the same single word, `changed`. On a production deploy that difference is the whole
review.

---

## Bonus Task — `ansible-pull` GitOps Loop

### The artifacts

Rather than configure the VM by hand I automated the setup, so the units and inventory live in
the repo as Ansible resources and are reproducible. Run once from the host with
`ansible-playbook -i ansible/inventory.ini ansible/ansible-pull.yaml`.

**`ansible/files/local-inventory.ini`** — the VM reconciling itself, no SSH hop:

```ini
[quicknotes]
localhost ansible_connection=local
```

**`ansible/templates/ansible-pull.service.j2`**:

```jinja
[Unit]
Description=Converge this host from Git with ansible-pull
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull \
    -U {{ pull_repo_url }} \
    -C {{ pull_branch }} \
    -d {{ pull_checkout_dir }} \
    -i {{ pull_inventory_path }} \
    ansible/playbook.yaml
```

**`ansible/templates/ansible-pull.timer.j2`**:

```jinja
[Unit]
Description=Run ansible-pull every {{ pull_interval }}

[Timer]
OnBootSec={{ pull_boot_delay }}
OnUnitActiveSec={{ pull_interval }}

[Install]
WantedBy=timers.target
```

**`ansible/ansible-pull.yaml`** installs `ansible` and `git` from apt, writes the local
inventory to `/etc/ansible/local-inventory.ini`, renders both units, and enables the timer —
with `pull_repo_url: https://github.com/ovsvp/DevOps-Intro.git`, `pull_branch: feature/lab7`,
`pull_interval: 5min`, `pull_boot_delay: 1min`.

### Timer installed and active

```console
$ systemctl list-timers --all | grep ansible-pull
Thu 2026-10-01 23:23:40 UTC  4min 47s  Thu 2026-10-01 23:18:40 UTC  12s ago
ansible-pull.timer  ansible-pull.service
```

### A successful pull run

```console
$ journalctl -u ansible-pull.service -o cat
Starting Ansible Pull at 2026-10-01 23:18:54
/usr/bin/ansible-pull -U https://github.com/ovsvp/DevOps-Intro.git -C feature/lab7 \
    -d /var/lib/ansible-pull -i /etc/ansible/local-inventory.ini ansible/playbook.yaml
...
TASK [Render the systemd unit] *************************************************
ok: [localhost]
TASK [Enable and start quicknotes] *********************************************
ok: [localhost]
PLAY RECAP *********************************************************************
localhost   : ok=6  changed=0  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
ansible-pull.service: Deactivated successfully.
Finished ansible-pull.service - Converge this host from Git with ansible-pull.
```

`changed=0` on this run because the host was already in the declared state — the loop is
converged, not idle.

### Convergence timeline

I changed `quicknotes_restart_sec` from `2` to `4`, pushed to `feature/lab7`, and touched
nothing else — no `ansible-playbook` from the host after the push. (The brief suggests
`listen_addr`; I used the backoff instead so the Vagrant port forward kept working while the
VM reconciled.)

| When (UTC) | What |
|---|---|
| 23:19:33 | `git push` of commit `c3553b1` — `quicknotes_restart_sec: 2 → 4` |
| 23:19:35 | VM still at `RestartSec=2`; next timer fire scheduled for 23:23:54 |
| 23:24:03 | Timer fires, `ansible-pull` starts: *"Starting Ansible Pull at 2026-10-01 23:24:03"* |
| 23:24:36 | VM observed at `RestartSec=4` — reconciled |

**Elapsed: 5 minutes 3 seconds from push to reconciled**, of which 4 min 28 s was simply
waiting for the next tick — the reconciliation itself took about 30 seconds.

The journal from that run shows it was a real change, not a no-op:

```console
$ journalctl -u ansible-pull.service --since 23:23:00 -o cat
Starting Ansible Pull at 2026-10-01 23:24:03
...
TASK [Render the systemd unit] *************************************************
changed: [localhost]
RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [localhost]
PLAY RECAP *********************************************************************
localhost   : ok=7  changed=2  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
Finished ansible-pull.service - Converge this host from Git with ansible-pull.
```

Confirmed on the VM afterwards, with the service healthy across the handler's restart:

```console
$ vagrant ssh -c 'grep RestartSec /etc/systemd/system/quicknotes.service'
RestartSec=4

$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

### B.4 — Design questions

**h) What is the security benefit of pull mode over push?**

In push mode a control node holds credentials that let it log in as root on every machine it
manages. That node is therefore the most valuable target in the estate: compromise it once and
you have root everywhere, simultaneously. It also requires every managed host to accept inbound
SSH from it, so the fleet carries an open management port and a trust relationship pointing
*inward*.

Pull mode inverts the arrows. Each host reaches *out* to a Git repository it can read, and
nothing needs to be able to log into it to configure it — inbound SSH for management can be
closed entirely. No shared credential exists that unlocks the fleet, because the only thing the
host needs is read access to a repo. The blast radius of a compromised host shrinks to that
host, and the thing an attacker would want to compromise instead is the Git repository, which
is a system you can protect with code review, branch protection and signed commits — controls
that have no equivalent for "someone has the SSH key".

The honest trade: convergence becomes eventual rather than immediate, you lose the ability to
orchestrate ordered rollouts across hosts, and a host that stops pulling fails silently unless
you monitor for it.

**i) What is this pattern called at the Kubernetes layer, and why is `ansible-pull` a fair simulator?**

**GitOps**, as implemented by **ArgoCD** and **Flux**. The shape is identical: Git holds the
declared desired state, an agent inside the target environment polls that repository on an
interval, diffs declared against actual, and reconciles the difference — with no operator
pushing anything in.

`ansible-pull` is a fair simulator because it reproduces every structural property that makes
GitOps what it is, only at the VM layer instead of the cluster layer: the repository is the
single source of truth, the pull is initiated from inside the trust boundary, reconciliation is
periodic and idempotent, and drift introduced by hand is silently corrected on the next cycle —
I could edit `/etc/systemd/system/quicknotes.service` on the VM right now and it would be
overwritten within five minutes.

What it does not reproduce is the parts that come from Kubernetes rather than from GitOps:
there is no continuous control loop (a timer is coarse where a controller is event-driven), no
health assessment or automated rollback of a bad sync, and no first-class notion of an
application's resources being pruned when they disappear from Git.
