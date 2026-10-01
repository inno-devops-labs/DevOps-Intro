# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

**Host:** MacBook Air (Apple Silicon), Ansible **10** (`ansible [core 2.17.14]`, Python 3.12 venv)
**Target:** Lab 5 VM `quicknotes-vm` (`bento/ubuntu-24.04`, arm64), SSH `127.0.0.1:2222`, port forward `127.0.0.1:18080 → 8080`

## Files

| File | What it is |
|---|---|
| [`ansible/inventory.ini`](../ansible/inventory.ini) | VM via `127.0.0.1:2222`, user `vagrant`, Vagrant key (from `vagrant ssh-config`) |
| [`ansible/playbook.yaml`](../ansible/playbook.yaml) | the deploy (user → dir → binary → seed → unit → handler → enable/start) |
| [`ansible/templates/quicknotes.service.j2`](../ansible/templates/quicknotes.service.j2) | systemd unit, all values are variables |
| `ansible/files/quicknotes` | static binary: `CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build` (VM is arm64) |
| `ansible/files/seed.json` | copy of `app/seed.json` |
| [`ansible/pull-setup.yaml`](../ansible/pull-setup.yaml) + `templates/ansible-pull.*.j2` + `files/inventory-local.ini` | bonus automation |

Variables (play `vars:`): `listen_addr: ":8080"`, `data_dir: /var/lib/quicknotes`, `data_path: {{ data_dir }}/notes.json`, `seed_path: {{ data_dir }}/seed.json`, `restart_sec` (3; set to 10 by the bonus demo commit).
`gather_facts: false`, `become: true`, only dedicated modules (`user`, `file`, `copy`, `template`, `systemd`) — no `shell:`/`command:`.

---

## Task 1 — Idempotent deploy

### First run

```text
TASK [Create quicknotes system user]   changed
TASK [Ensure data directory]           changed
TASK [Copy QuickNotes binary]          changed
TASK [Copy seed.json]                  changed
TASK [Render systemd unit]             changed
RUNNING HANDLER [restart quicknotes]   changed
TASK [Enable and start quicknotes]     changed

PLAY RECAP
quicknotes-vm : ok=7  changed=7  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

### Verify

```text
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}

$ curl -s http://localhost:18080/notes
[{"id":1,"title":"Welcome to QuickNotes",...},{"id":2,"title":"Read app/main.go first",...},
 {"id":3,"title":"DevOps mantra",...},{"id":4,"title":"Endpoint cheat-sheet",...}]

$ vagrant ssh -c "systemctl status quicknotes --no-pager | head -5"
● quicknotes.service - QuickNotes
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-10-01 10:18:39 UTC; 41s ago
```

`/notes` returns the 4 seeded notes (not `[]`) → `seed.json` reached the VM and `SEED_PATH` is right.

### Design questions

**a) `command:` vs modules.** `command:`/`shell:` just run something and always report `changed` — Ansible can't know what it did. Modules (`apt`, `file`, `copy`, `systemd`) first check the current state and change only what differs, so they are idempotent. That matters because I can rerun the playbook any time safely, and `changed` actually means something changed.

**b) Handlers.** A handler runs once, at the end of the play (or at `meta: flush_handlers`), and only if a task that `notify`s it reported `changed`. If nothing changed, it doesn't run. Good default: no needless restarts (no downtime), and several changes still give just one restart.

**c) Top-3 places for variables.** 1) **Play `vars:`** — one host, one playbook, everything visible in one file (what I used). 2) **`group_vars/quicknotes.yml`** — different values per environment (dev/prod) without touching the playbook. 3) **Role `defaults/main.yml`** — lowest priority, sane defaults if this becomes a role. (`-e` extra vars beat everything — only for one-off overrides.)

**d) `gather_facts`.** Not needed — no task uses `ansible_*` facts. Turning it off skips the `setup` module: one less SSH round trip and Python run on the VM, about 1–2 s per run per host.

---

## Task 2 — Idempotency + selective re-run

### 1. Second run, nothing changed → `changed=0`

```text
TASK [Create quicknotes system user]   ok
TASK [Ensure data directory]           ok
TASK [Copy QuickNotes binary]          ok
TASK [Copy seed.json]                  ok
TASK [Render systemd unit]             ok
TASK [Enable and start quicknotes]     ok

PLAY RECAP
quicknotes-vm : ok=6  changed=0  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

### 2. `listen_addr: ":8080"` → `":9090"` → only template + handler

```text
TASK [Copy QuickNotes binary]          ok
TASK [Copy seed.json]                  ok
TASK [Render systemd unit]             changed
RUNNING HANDLER [restart quicknotes]   changed
TASK [Enable and start quicknotes]     ok

PLAY RECAP
quicknotes-vm : ok=7  changed=2  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0

$ vagrant ssh -c "curl -s localhost:9090/health"
{"notes":4,"status":"ok"}
```

`changed=2` = the template task (1) + the `restart quicknotes` handler (1). All other tasks `ok`. (Checked inside the VM because the port forward only covers 8080.)

### 3. Third change, `restart_sec: 3` → `5`, with `--check --diff` (not applied)

```diff
TASK [Render systemd unit]
--- before: /etc/systemd/system/quicknotes.service
+++ after: .../quicknotes.service.j2
@@ -14,7 +14,7 @@
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=3
+RestartSec=5
```

Afterwards both variables were set back (`:8080`, `3`) and applied; `curl localhost:18080/health` → `{"notes":4,"status":"ok"}`.

### Design questions

**e) Why `changed=0` on the second run?** `file` compares owner, group, mode and state with what's on the VM. `copy`/`template` render/read the new content, compare its SHA-1 checksum with the file on the VM, plus owner/group/mode. Everything equal → `ok`, nothing is written, so no handler fires.

**f) `shell: 'echo "ADDR=..." > quicknotes.service'` instead of `template:`.** It rewrites the file on every run → always `changed` → the handler restarts the service on every run (needless downtime). No real `--check`/`--diff` support, so you can't preview it. Quoting/newline mistakes can silently write a broken unit. Owner/mode aren't managed. Values are hard-coded in a string instead of clean variables.

**g) `--check --diff` vs plain `--check`.** `--check` only says *that* a file would change; `--diff` shows *what*. With it you catch a wrong value or template bug before prod — e.g. a typo'd variable giving `ADDR=:9090` instead of `:8080`, an empty `{{ }}`, or an unexpected owner/mode change — which plain `--check` would just report as "changed".

---

## Bonus — `ansible-pull` GitOps loop

Setup is automated: `ansible-playbook -i ansible/inventory.ini ansible/pull-setup.yaml` (`ok=5 changed=5 failed=0`). It installs `ansible` + `git` (apt), the local inventory, the service + timer, and enables the timer.

**Local inventory** → `/etc/ansible-pull/inventory.ini` ([`files/inventory-local.ini`](../ansible/files/inventory-local.ini))
```ini
[quicknotes]
127.0.0.1 ansible_connection=local
```

**`ansible-pull.service`** ([template](../ansible/templates/ansible-pull.service.j2), rendered)
```ini
[Unit]
Description=ansible-pull: converge QuickNotes from Git
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull -U https://github.com/illmmmiira/DevOps-Intro.git -C feature/lab7 -d /var/lib/ansible-pull/repo -i /etc/ansible-pull/inventory.ini ansible/playbook.yaml
```

**`ansible-pull.timer`** ([template](../ansible/templates/ansible-pull.timer.j2))
```ini
[Unit]
Description=Run ansible-pull every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=ansible-pull.service

[Install]
WantedBy=timers.target
```

### Timer + journal

```text
$ systemctl list-timers --all | grep ansible-pull
Thu 2026-10-01 10:38:40 UTC 4min 51s  Thu 2026-10-01 10:33:40 UTC 8s ago  ansible-pull.timer  ansible-pull.service

$ sudo journalctl -u ansible-pull.service   (run after the demo push)
ansible-pull[4469]: 127.0.0.1 | CHANGED => { "before": "646349fa...", "after": "e71f4b13...", "changed": true }
ansible-pull[4469]: TASK [Copy QuickNotes binary] ... ok
ansible-pull[4469]: TASK [Render systemd unit] ... changed: [127.0.0.1]
ansible-pull[4469]: RUNNING HANDLER [restart quicknotes] ... changed: [127.0.0.1]
ansible-pull[4469]: TASK [Enable and start quicknotes] ... ok: [127.0.0.1]
ansible-pull[4469]: 127.0.0.1 : ok=7  changed=2  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
ansible-pull[4469]: Starting Ansible Pull at 2026-10-01 10:33:40
systemd[1]: Finished ansible-pull.service - ansible-pull: converge QuickNotes from Git.
```

(The earlier run at 10:28:40 UTC, right after setup, gave `changed=0`. The warning `Could not match supplied host pattern: quicknotes-vm` is harmless — `ansible-pull` also adds the VM hostname to `--limit`.)

### Convergence timeline (demo: `restart_sec: 3 → 10`, no `ansible-playbook` from the host)

| Time (UTC) | Event |
|---|---|
| 10:33:16 | commit `e71f4b1` (13:33:16 +0300) pushed to `feature/lab7` |
| 10:33:40 | timer fires → `ansible-pull` starts, checkout `646349f → e71f4b1` |
| 10:33:46 | `Render systemd unit` changed + handler restarted quicknotes → `RestartSec=10` on the VM |

Reconciled **30 s** after the push (worst case would be ≤ 5 min).

```text
$ vagrant ssh -c "systemctl cat quicknotes | grep RestartSec"
RestartSec=10
```

### Design questions

**h) Security benefit of pull mode.** No control node holding SSH keys with root on every server, and no inbound SSH has to be open — the VM only makes an outbound HTTPS request to Git. The Git repo (signed commits, PR review) becomes the single, audited path for changes.

**i) Same pattern on Kubernetes.** GitOps — **Argo CD** (or Flux). `ansible-pull` is a fair simulator: desired state lives in Git, an agent on the target pulls it on a schedule and reconciles any drift — the same loop, just at the VM layer instead of the cluster.
