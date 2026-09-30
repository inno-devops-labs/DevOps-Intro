# Lab 7 submission

Author: Telman Nuruzov (`Telman3000`)
Branch: `feature/lab7`
Fork: https://github.com/Telman3000/DevOps-Intro
Host: Windows 10 + Vagrant **2.4.9** / VirtualBox + Ansible control node **inside** the Lab 5 VM (`ansible [core 2.16.3]` / package 9.2 — host Windows Store Python cannot run Ansible; inventory from `vagrant ssh-config` is also provided for Linux/WSL control nodes)

Course PR: https://github.com/inno-devops-labs/DevOps-Intro/pull/1686

---

## Layout

```text
ansible/
├── ansible.cfg
├── inventory.ini              # from vagrant ssh-config (host→VM SSH)
├── inventory.local.ini        # local connection (run playbook on the VM)
├── playbook.yaml
├── files/
│   ├── quicknotes             # static linux/amd64 binary (CGO_ENABLED=0)
│   ├── seed.json
│   └── inventory.pull.ini     # bonus: ansible-pull inventory
└── templates/
    ├── quicknotes.service.j2
    ├── ansible-pull.service.j2
    └── ansible-pull.timer.j2
```

---

## Task 1 — Idempotent deploy

### Inventory (`ansible/inventory.ini`)

```ini
[lab5]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant

[lab5:vars]
ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
```

(`vagrant ssh-config`: HostName 127.0.0.1, Port 2222, User vagrant, IdentityFile …/private_key)

On this Windows laptop the playbook was executed **on the VM** with `inventory.local.ini` (`ansible_connection=local`) against the synced tree at `/vagrant/ansible`.

### Playbook + template

See `ansible/playbook.yaml` and `ansible/templates/quicknotes.service.j2` in the PR.

Unit uses variables: `listen_addr`, `data_path`, `seed_path`, `quicknotes_user/group`, `quicknotes_data_dir`, `quicknotes_bin`, `restart_sec`. Handler `restart quicknotes` fires when binary or unit changes.

### First-run PLAY RECAP

```text
PLAY RECAP *********************************************************************
quicknotes-vm              : ok=7    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Service: `active (running)`; log: `quicknotes listening on :8080 (notes loaded: 4)`.

### curl (guest + host via Vagrant forward)

```text
# guest
{"notes":4,"status":"ok"}

# guest /notes — seeded notes (not [])
[{"id":1,"title":"Welcome to QuickNotes",...}, ...]

# host http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
```

Artifacts: `submissions/lab7-artifacts/play-run1.txt`, `curl-*-guest.txt`, `curl-*-host.txt`.

### Design questions (1.5)

**a) `command:` vs dedicated modules**

`command:`/`shell:` always run the string (or need manual creates/removes checks). Modules like `file`, `copy`, `template`, `user`, `systemd` declare desired state and only change when reality differs — that **is** idempotency. It matters so re-runs are safe and PLAY RECAP stays `changed=0` when nothing drifted.

**b) `notify:` / handlers**

A handler runs **once at end of play** if ≥1 task that notified it reported `changed`. It does **not** fire when those tasks are `ok`. That batches restarts and avoids bouncing the service on no-op runs.

**c) Variable places for this lab**

1. **Play `vars:`** — defaults for listen addr / paths (what we used; visible next to tasks).
2. **`group_vars/lab5.yml`** — if we had multiple hosts sharing QuickNotes settings.
3. **`-e` / extra-vars** — one-off overrides (`listen_addr=:9090`) without editing files (highest precedence among common options).

**d) `gather_facts`**

Not needed here — we don't use `ansible_facts`. Turning it off skips the setup module SSH/local fact gather (~seconds saved every run).

---

## Task 2 — Idempotency + selective re-run

### Second run → `changed=0`

```text
PLAY RECAP *********************************************************************
quicknotes-vm              : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Selective tweak (`listen_addr` `:8080` → `:9090`)

Only the template task changed; handler `restart quicknotes` ran; other tasks `ok`:

```text
TASK [Render systemd unit] ***
changed: [quicknotes-vm]
...
RUNNING HANDLER [restart quicknotes] ***
changed: [quicknotes-vm]

PLAY RECAP ***
quicknotes-vm              : ok=7    changed=2    unreachable=0    failed=0 ...
```

Unit after: `Environment=ADDR=:9090`; process listening on `*:9090`.

### `--check --diff` (third change `:9090` → `:8081`)

```diff
-Environment=ADDR=:9090
+Environment=ADDR=:8081
```

Then restored `:8080` and re-converged so host `:18080` works again.

Artifacts: `play-run2.txt`, `play-run3-selective.txt`, `play-check-diff.txt`.

### Design questions (2.2)

**e) Why `changed=0` on second run?**

`file`/`copy`/`template` compare destination metadata + content checksum (and ownership/mode). Unchanged → `ok`. `user`/`systemd` similarly no-op when state already matches.

**f) If you `shell: echo … > quicknotes.service`**

Every run rewrites the file → always `changed`, handlers fire every time, races, no `--diff` preview of meaningful drift, easy to clobber permissions, and you lose Jinja variables.

**g) Bug `--check --diff` catches that plain `--check` misses**

`--check` says “would change” but not *what*. `--diff` shows the exact line drift (wrong port, typo’d path, accidental wipe). You catch a bad template/variable before production.

---

## Bonus — `ansible-pull` GitOps loop

Automation lives in `ansible/playbook.yaml` (tasks tagged `pull`) + templates:

- `ansible/templates/ansible-pull.service.j2`
- `ansible/templates/ansible-pull.timer.j2`
- `ansible/files/inventory.pull.ini` → installed as `/etc/ansible/pull-inventory.ini`

### Installed units (rendered)

**ansible-pull.service**

```ini
[Unit]
Description=ansible-pull QuickNotes converge
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
WorkingDirectory=/var/lib/ansible-pull
ExecStart=/usr/bin/ansible-pull -o -d /var/lib/ansible-pull/repo -U https://github.com/Telman3000/DevOps-Intro.git -C feature/lab7 -i /etc/ansible/pull-inventory.ini ansible/playbook.yaml
Nice=10

[Install]
WantedBy=multi-user.target
```

**ansible-pull.timer**

```ini
[Unit]
Description=Run ansible-pull every 5 minutes
Requires=ansible-pull.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=ansible-pull.service
Persistent=true

[Install]
WantedBy=timers.target
```

**Local inventory**

```ini
[lab5]
quicknotes-vm ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

### Timer status

```text
Thu 2026-09-24 12:40:12 UTC ... ansible-pull.timer  ansible-pull.service
```

(`systemctl list-timers | grep ansible-pull` → artifact `list-timers.txt`)

### Convergence timeline

| Step | Time (UTC+3 / UTC) | Evidence |
|------|--------------------|----------|
| Git push `restart_sec: 3 → 7` | 2026-09-30 **21:26:13 +0300** | commit `84c1d5d` on `feature/lab7` |
| Timer / manual `systemctl start ansible-pull.service` | **18:26:33 UTC** | journal: Starting ansible-pull.service |
| Git on VM advanced | **18:27:10 UTC** | `before: 9e0cc50` → `after: 84c1d5d` |
| Playbook applied | **18:27:10 UTC** | `Render systemd unit` **changed**; handler `restart quicknotes`; PLAY RECAP `failed=0` |
| State reconciled | after pull | `/etc/systemd/system/quicknotes.service` → **`RestartSec=7`** (was 3) |

Elapsed push → reconciled: **~1 minute** (well under 5 min).

Artifacts: `submissions/lab7-artifacts/journal-pull-converge.txt`, `converge-timeline.txt`.

### Design questions (B.4)

**h) Pull vs push security**

Pull: nodes initiate outbound HTTPS to Git; no inbound SSH from a central control plane, smaller attack surface / no long-lived “ansible SSH as root from CI” path into every host. Compromising the control node doesn't give a free SSH blast radius.

**i) Kubernetes analogue**

**Argo CD** / **Flux** (GitOps controllers). Same idea: desired state in Git; an agent reconciles the cluster. `ansible-pull` + systemd timer is that loop at VM scale.

---

## How to run (this machine)

```bash
vagrant up
vagrant ssh -c 'export ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg
  cd /vagrant/ansible
  ansible-playbook -i inventory.local.ini playbook.yaml'
curl -s http://127.0.0.1:18080/health
curl -s http://127.0.0.1:18080/notes
```
