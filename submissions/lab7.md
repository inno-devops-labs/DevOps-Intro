# Lab 7 Submission: Deploy QuickNotes via Ansible

## The Environment Setup

> Control node: Ansible **10.7.0** (`ansible-core 2.17.14`) running in WSL2 Ubuntu on the
> Windows host. Target: the Lab 5 `bento/ubuntu-24.04` VirtualBox VM (`vagrant up`),
> reached on `127.0.0.1:2222` via Vagrant's NAT port-forward.
>
> **Networking note:** the Lab 5 VM forwards SSH to `127.0.0.1:2222`. WSL2's default NAT
> networking has its own loopback and cannot see the Windows host's `127.0.0.1`. 
> Enabling WSL **mirrored** networking mode
> (`%USERPROFILE%\.wslconfig` → `[wsl2] networkingMode=mirrored`, then `wsl --shutdown`)
> makes WSL share the host loopback, so the inventory's `127.0.0.1:2222` works unchanged.

---

## Task 1: Idempotent Deploy to the Lab 5 VM

### Layout

```text
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── quicknotes          # static binary: CGO_ENABLED=0 GOOS=linux go build
│   └── seed.json           # initial notes, shipped to the data dir
└── templates/
    └── quicknotes.service.j2
```

The binary is built statically so it has no glibc/runtime dependency on the guest:

```bash
cd app && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o quicknotes .
cp quicknotes seed.json ../ansible/files/
```

### `ansible/inventory.ini`

```ini
[quicknotes_vm]
default ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key

[quicknotes_vm:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa'
ansible_python_interpreter=/usr/bin/python3
```

The key path is the relative path Vagrant generates inside the repo (`vagrant ssh-config`
prints it). The `+ssh-rsa` / `HostKeyAlgorithms` options match what `vagrant ssh-config`
emits for the insecure box key.

> When running from WSL, the key on the `/mnt/d` Windows mount shows as world-readable, so
> OpenSSH refuses it. For my runs I copied it into the WSL filesystem with `chmod 600` and
> overrode the path on the command line — the committed inventory keeps the portable value:
> ```bash
> cp .vagrant/machines/default/virtualbox/private_key ~/.ssh/vagrant_qn_key
> chmod 600 ~/.ssh/vagrant_qn_key
> ansible-playbook -i inventory.ini playbook.yaml \
>   -e ansible_ssh_private_key_file=/home/<user>/.ssh/vagrant_qn_key
> ```

### `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes to the Lab 5 Vagrant VM
  hosts: quicknotes_vm
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_bin_path: /usr/local/bin/quicknotes
    quicknotes_listen_addr: ":8080"
    quicknotes_data_path: "{{ quicknotes_data_dir }}/notes.json"
    quicknotes_seed_path: "{{ quicknotes_data_dir }}/seed.json"

  tasks:
    - name: Create system user for quicknotes
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false

    - name: Ensure quicknotes data directory exists
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0750"

    - name: Ship seed data
      ansible.builtin.copy:
        src: seed.json
        dest: "{{ quicknotes_seed_path }}"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0640"

    - name: Copy quicknotes binary
      ansible.builtin.copy:
        src: quicknotes
        dest: "{{ quicknotes_bin_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: restart quicknotes

    - name: Render quicknotes systemd unit
      ansible.builtin.template:
        src: quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: restart quicknotes

    - name: Reload systemd, enable and start quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        daemon_reload: true
        enabled: true
        state: started

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
```

### `ansible/templates/quicknotes.service.j2`

```ini
[Unit]
Description=QuickNotes service
After=network-online.target
Wants=network-online.target

[Service]
User={{ quicknotes_user }}
Group={{ quicknotes_user }}
WorkingDirectory={{ quicknotes_data_dir }}
Environment=ADDR={{ quicknotes_listen_addr }}
Environment=DATA_PATH={{ quicknotes_data_path }}
Environment=SEED_PATH={{ quicknotes_seed_path }}
ExecStart={{ quicknotes_bin_path }}
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

Every value the unit needs (`User`, `WorkingDirectory`, the three env vars, the binary
path) comes from a playbook variable, so changing a var in the play re-renders the unit —
this is what Task 2's selective-change demonstration exercises.

### 1.7a Connectivity check (before deploying)

Confirm Ansible can reach and authenticate to the VM. The `ping` module is an SSH + Python
round-trip (not ICMP); `pong` means the inventory, key, and (mirrored) networking all work.

**Input:**
```bash
ansible -i inventory.ini quicknotes_vm -m ping \
  -e ansible_ssh_private_key_file=$HOME/.ssh/vagrant_qn_key
```

**Output:**
```text
default | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 1.7b Dry run (`--check`)

**Input:**
```bash
ansible-playbook -i inventory.ini playbook.yaml \
  -e ansible_ssh_private_key_file=$HOME/.ssh/vagrant_qn_key --check
```

**Output:**
```text
PLAY [Deploy QuickNotes to the Lab 5 Vagrant VM] *******************************

TASK [Create system user for quicknotes] ***************************************
changed: [default]

TASK [Ensure quicknotes data directory exists] *********************************
[WARNING]: failed to look up user quicknotes. Create user up to this point in
real play
[WARNING]: failed to look up group quicknotes. Create group up to this point in
real play
changed: [default]

TASK [Ship seed data] **********************************************************
changed: [default]

TASK [Copy quicknotes binary] **************************************************
changed: [default]

TASK [Render quicknotes systemd unit] ******************************************
changed: [default]

TASK [Reload systemd, enable and start quicknotes] *****************************
fatal: [default]: FAILED! => {"changed": false, "msg": "Could not find the requested service quicknotes: host"}

PLAY RECAP *********************************************************************
default                    : ok=5    changed=5    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```

This failure is **expected on a first deploy**. `--check` simulates every task without
actually writing anything, so the unit file is never created on disk; when the last task
asks systemd to enable/start `quicknotes`, the service genuinely doesn't exist yet, so it
errors. The two `WARNING` lines are the same effect one task earlier — the `quicknotes` user
isn't really created in check mode, so the `file` task can't look it up to set ownership.
Both disappear once the service exists: re-running `--check` *after* the first real deploy
returns a clean `ok=6 changed=0`.

### 1.7c First run (real deploy)

**Input:**
```bash
ansible-playbook -i inventory.ini playbook.yaml \
  -e ansible_ssh_private_key_file=$HOME/.ssh/vagrant_qn_key
```

**Output:**
```text
PLAY [Deploy QuickNotes to the Lab 5 Vagrant VM] *******************************

TASK [Create system user for quicknotes] ***************************************
changed: [default]

TASK [Ensure quicknotes data directory exists] *********************************
changed: [default]

TASK [Ship seed data] **********************************************************
changed: [default]

TASK [Copy quicknotes binary] **************************************************
changed: [default]

TASK [Render quicknotes systemd unit] ******************************************
changed: [default]

TASK [Reload systemd, enable and start quicknotes] *****************************
changed: [default]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [default]

PLAY RECAP *********************************************************************
default                    : ok=7    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

With the files actually written, the `systemd` task succeeds and the `restart quicknotes`
handler fires once (notified by both the binary copy and the unit template).

### Verification on host (`curl` via the Vagrant port-forward → `127.0.0.1:18080`)

```console
$ curl.exe -s http://localhost:18080/health
{"notes":4,"status":"ok"}

$ curl.exe -s http://localhost:18080/notes
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]
```

Service state on the guest (confirms it runs as the unprivileged `quicknotes` user, not
root):

```console
$ systemctl is-active quicknotes
active
$ systemctl is-enabled quicknotes
enabled
$ ps -o user:20=,comm= -p $(systemctl show -p MainPID --value quicknotes)
quicknotes           quicknotes
```

### 1.5 Design questions

**a) `command:` vs the dedicated modules (`apt`, `file`, `copy`, `systemd`) — which is
idempotent, and why does it matter?**

`command:`/`shell:` just run a string and report `changed` every run, because Ansible can't
know what state they produce. The dedicated modules are idempotent, they inspect current
state and only act (and only report `changed`) when reality differs from the goal. This
matters because a converged host should report `changed=0`, which makes re-runs safe and
makes any `changed=1` a real drift signal rather than noise.

**b) `notify:` and handlers — when does a handler fire, when does it *not*, and why is that
the right default?**

A handler fires once, at the end of the play, only if at least one notifying task reported
`changed`; it does not fire when those tasks were all `ok`. That's the right default because
you only want to restart the service when something actually changed, and batching means ten
changes that notify "restart quicknotes" cause one restart, not ten. Here both the binary
copy and the unit template notify it, so a no-op run restarts nothing.

**c) Variable hierarchy — top 3 places you'd put a variable for this lab, and why.**

Lowest→highest precedence: (1) **`defaults/`** for baseline fallbacks anything can override;
(2) **playbook `vars:`** (what I used) for values that define this deployment, kept next to
the tasks that use them; (3) **`-e` extra-vars**, which win over everything — I used
`-e ansible_ssh_private_key_file=...` for a per-run override without editing the committed
inventory.

d) **`gather_facts: true` is the default.** Do you need it for *this* playbook? What does turning it off save you per run?

No, the playbook references zero `ansible_*` facts, so I set `gather_facts: false`. That
skips the implicit `setup` run at play start, saving an SSH round-trip and a few hundred ms
per run — worth it for a play the Bonus timer runs every 5 minutes. I'd re-enable it only if
a template needed a fact like `ansible_default_ipv4.address`.

---

## Task 2: Prove Idempotency + Selective Re-run

### 2.1 Second run = zero changes

Re-running the playbook with nothing changed: every task reports `ok`, no handler runs.

**Input:**
```bash
ansible-playbook -i inventory.ini playbook.yaml -e ansible_ssh_private_key_file=$HOME/.ssh/vagrant_qn_key
```

**Output:**
```text
PLAY [Deploy QuickNotes to the Lab 5 Vagrant VM] *******************************

TASK [Create system user for quicknotes] ***************************************
ok: [default]

TASK [Ensure quicknotes data directory exists] *********************************
ok: [default]

TASK [Ship seed data] **********************************************************
ok: [default]

TASK [Copy quicknotes binary] **************************************************
ok: [default]

TASK [Render quicknotes systemd unit] ******************************************
ok: [default]

TASK [Reload systemd, enable and start quicknotes] *****************************
ok: [default]

PLAY RECAP *********************************************************************
default                    : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`changed=0`, and note there is **no `RUNNING HANDLER` line at all** because no task
reported `changed`, the `restart quicknotes` handler was never notified, so the service was
not bounced. The system was already in the desired state.

### 2.2 Variable tweak = selective change + handler fires

Changed exactly one variable in `playbook.yaml`:

```diff
-    quicknotes_listen_addr: ":8080"
+    quicknotes_listen_addr: ":9090"
```

**Input:**
```bash
ansible-playbook -i inventory.ini playbook.yaml -e ansible_ssh_private_key_file=$HOME/.ssh/vagrant_qn_key
```

**Output:**
```text
PLAY [Deploy QuickNotes to the Lab 5 Vagrant VM] *******************************

TASK [Create system user for quicknotes] ***************************************
ok: [default]

TASK [Ensure quicknotes data directory exists] *********************************
ok: [default]

TASK [Ship seed data] **********************************************************
ok: [default]

TASK [Copy quicknotes binary] **************************************************
ok: [default]

TASK [Render quicknotes systemd unit] ******************************************
changed: [default]

TASK [Reload systemd, enable and start quicknotes] *****************************
ok: [default]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [default]

PLAY RECAP *********************************************************************
default                    : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Exactly what the spec asks for: **only** the `template` task is `changed`, every other task
is `ok`, and the `restart quicknotes` **handler fired** (`changed=2` = the template + the
handler restart). `listen_addr` only appears in the unit template, so nothing else had any
reason to change.

Verification that the service actually rebound to `:9090` (checked *inside* the VM, because
the host port-forward only maps guest `:8080`):

```console
$ vagrant ssh -c "curl -s localhost:9090/health"
{"notes":4,"status":"ok"}
$ vagrant ssh -c "curl -s --max-time 3 localhost:8080/health || echo '(no listener on 8080)'"
(no listener on 8080)
```

### 2.3 `--check --diff` preview

Made a *third* one-line change and previewed it without applying:

```diff
-    quicknotes_listen_addr: ":9090"
+    quicknotes_listen_addr: ":9091"
```

**Input:**
```bash
ansible-playbook -i inventory.ini playbook.yaml -e ansible_ssh_private_key_file=$HOME/.ssh/vagrant_qn_key --check --diff
```

**Output:**
```text
PLAY [Deploy QuickNotes to the Lab 5 Vagrant VM] *******************************

TASK [Create system user for quicknotes] ***************************************
ok: [default]

TASK [Ensure quicknotes data directory exists] *********************************
ok: [default]

TASK [Ship seed data] **********************************************************
ok: [default]

TASK [Copy quicknotes binary] **************************************************
ok: [default]

TASK [Render quicknotes systemd unit] ******************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/g-akleh/.ansible/tmp/ansible-local-155569sj_q37/tmp2pgx1rku/quicknotes.service.j2
@@ -7,7 +7,7 @@
 User=quicknotes
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:9091
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes

changed: [default]

TASK [Reload systemd, enable and start quicknotes] *****************************
ok: [default]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [default]

PLAY RECAP *********************************************************************
default                    : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`--diff` prints the exact line-level change (`ADDR=:9090` → `:9091`). Because `--check` is
also set, **nothing was actually written** the VM stayed on `:9090`; the `changed`/handler
lines describe what *would* happen on a real run.

> **Cleanup:** after capturing the diff I reverted the variable back to `:8080` and did one
> final real run (`changed=2` template + handler), so the committed `playbook.yaml`,
> the deployed unit, and the host port-forward (`18080 → 8080`) all agree. `curl.exe -s
> http://localhost:18080/health` returns `{"notes":4,"status":"ok"}` again.

### 2.4 Design questions

**e) Why does the second run report `changed=0`? What specifically do `file` / `template`
check?**

Each module compares desired state to actual state before acting. `file` checks the path
exists with the declared `owner`/`group`/`mode`; `copy` and `template` compare a checksum of
the intended content against the file already on disk. When everything already matches, each task reports `ok`, nothing is notified, and no handler fires, so `changed=0`.

**f) What if you used `shell: 'echo "ADDR=..." > /etc/.../quicknotes.service'` instead of
`template:`?**

`shell:` has no notion of prior content, so it overwrites the file and reports `changed`
**every** run, killing idempotency and firing the restart handler needlessly each time.
You'd also lose `--diff` previews, and hand-escaping a multi-line unit through `echo` is
fragile (quoting/newline bugs, possible injection if a var holds shell metacharacters). The
`template:` module renders deterministically and only writes on a real content difference.

**g) What bug does `--check --diff` catch that plain `--check` would miss?**

Plain `--check` only tells us *that* a file would change, not *what* would change. `--diff`
shows the before/after lines, so it catches a **wrong value that still counts as a change** —
e.g. a `:9009` instead of `:9090`, or a variable that resolved to empty
(`ADDR=`). Plain `--check` reports "template: changed" in all three cases; only `--diff`
reveals the content is wrong *before* it reaches production.

---

## Bonus Task: `ansible-pull` GitOps Loop

Instead of *pushing* config from the host, the VM **pulls** the playbook from the fork on a
systemd timer and converges itself, the same source-of-truth-in-Git model as ArgoCD/Flux,
scaled down to one VM.

### B.2 Artifacts (committed in `ansible/`)

`ansible/inventory-local.ini` — the VM reconciles *itself*, so the target is the loopback
over the local connection plugin (no SSH):

```ini
[quicknotes_vm]
127.0.0.1 ansible_connection=local
```

`ansible/ansible-pull.service` — a `oneshot` unit that clones the fork at `feature/lab7` and
runs the same `playbook.yaml`. It runs as root, so the play's `become: true` is already
satisfied:

```ini
[Unit]
Description=QuickNotes ansible-pull GitOps convergence
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull \
  -U https://github.com/G-Akleh/DevOps-Intro.git \
  -C feature/lab7 \
  -i ansible/inventory-local.ini \
  ansible/playbook.yaml
```

`ansible/ansible-pull.timer` — fires 1 min after boot, then every 5 min:

```ini
[Unit]
Description=Run QuickNotes ansible-pull every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

### Install steps (run once inside the VM)

#### 1. Ansible (the distro package) + Git
```bash
sudo apt-get update && sudo apt-get install -y ansible git   # -> ansible-core 2.16.3
```
#### 2. install the units (from the /vagrant synced repo) and enable the timer
```bash
sudo cp /vagrant/ansible/ansible-pull.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now ansible-pull.timer
```

The HTTPS clone URL is used (not the `git@` SSH remote) because the VM has no GitHub key;
the fork is public, so no token is needed. The local inventory's host `127.0.0.1` matches
the limit `ansible-pull` applies automatically, so the `quicknotes_vm` play runs locally.

### B.5 `systemctl list-timers`

```text
NEXT                        LEFT      LAST                        PASSED   UNIT                ACTIVATES
Tue 2026-06-30 17:42:26 UTC 4min 10s  Tue 2026-06-30 17:37:26 UTC 49s ago  ansible-pull.timer  ansible-pull.service
$ systemctl is-enabled ansible-pull.timer
enabled
```

### Convergence demonstration (push → auto-reconcile)

Changed `quicknotes_listen_addr` from `:8080` to `:9090` on the host, committed, and pushed
to `feature/lab7` — then left the VM completely alone and watched the deployed unit flip on
its own.

**Timeline (all UTC):**

| Event | Time | Evidence |
|-------|------|----------|
| Commit `c50417f` (`:9090`) pushed to fork | `17:31:39` | `git show -s --format=%cI` |
| Timer fires `ansible-pull.service` | `17:32:26` | `list-timers` LAST |
| VM reconciled, deployed unit now `:9090` | `17:32:36` | poll of `/etc/systemd/system/quicknotes.service` |

**~57 seconds, push → reconciled: well under the 5-minute SLA, with no `ansible-playbook`
run from the host.** The service journal for that fire (note `"after"` = the exact commit we
pushed, the template `changed`, and the handler firing):

```text
ansible-pull[5117]:     "after": "c50417f39c202691cc9089d05b058b1fadbc7068",
ansible-pull[5117]: TASK [Create system user for quicknotes] ***************************************
ansible-pull[5117]: ok: [127.0.0.1]
ansible-pull[5117]: TASK [Ensure quicknotes data directory exists] *********************************
ansible-pull[5117]: ok: [127.0.0.1]
ansible-pull[5117]: TASK [Ship seed data] **********************************************************
ansible-pull[5117]: ok: [127.0.0.1]
ansible-pull[5117]: TASK [Copy quicknotes binary] **************************************************
ansible-pull[5117]: ok: [127.0.0.1]
ansible-pull[5117]: TASK [Render quicknotes systemd unit] ******************************************
ansible-pull[5117]: changed: [127.0.0.1]
ansible-pull[5117]: TASK [Reload systemd, enable and start quicknotes] *****************************
ansible-pull[5117]: ok: [127.0.0.1]
ansible-pull[5117]: RUNNING HANDLER [restart quicknotes] *******************************************
ansible-pull[5117]: changed: [127.0.0.1]
```

Service confirmed live on the new port, checked inside the VM:

```console
$ curl -s localhost:9090/health
{"notes":4,"status":"ok"}
```

To leave a clean baseline I pushed `:8080` back; the
**timer reconciled it automatically** at `17:37:37`, and the host port-forward works again:

```console
$ curl.exe -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

### B.4 Design questions

**h) `ansible-pull` is "pull" mode. What's the security benefit vs the "push" model where a
control node SSHes in?**

In push mode a control node holds privileged SSH keys to *every* managed host and opens
inbound connections to each, so every host must expose an SSH/management port, and that one
control node is a high-value target whose compromise hands over the whole fleet. In pull
mode each host makes an *outbound*, read-only fetch from Git and applies the config locally,
so no inbound management port is required and there's no central store of credentials to all
hosts. The blast radius shrinks: a host only needs read access to the repo, nothing needs
keys *into* it.

**i) What's the same pattern called at the Kubernetes layer, and why is `ansible-pull` a fair
simulator?**

It's **GitOps**, implemented by tools like **Argo CD** and **Flux**: Git is the single source
of truth and an in-cluster agent continuously reconciles actual state toward the declared
state, auto-correcting drift. `ansible-pull` is a fair VM-layer simulator because it runs the
identical loop — a timer-driven agent on the node periodically pulls the desired state from
Git and converges the host to it, with no imperative push from outside — just at the
single-VM level instead of a cluster.
