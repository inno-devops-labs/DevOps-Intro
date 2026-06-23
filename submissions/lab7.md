# Lab 7 Submission — Configuration Management: Deploy QuickNotes via Ansible

A single `ansible-playbook` run provisions a running QuickNotes service on the Lab 5
Vagrant VM, with idempotency and a change-triggered restart handler.

> The `ansible/` tree is complete; the **PLAY RECAP** outputs and `curl` checks are
> marked _(paste from your machine)_ — they require the Lab 5 VM running and Ansible
> installed on your host.

## Directory

```
ansible/
├── inventory.ini                     # targets the Vagrant VM over SSH
├── inventory-local.ini               # bonus: localhost for ansible-pull
├── playbook.yaml                     # the idempotent deploy
├── files/quicknotes                  # prebuilt static linux/amd64 binary (CGO off, stripped)
├── files/seed.json                   # initial data
└── templates/quicknotes.service.j2   # systemd unit rendered from vars
```

The binary in [../ansible/files/quicknotes](../ansible/files/quicknotes) was built with
`CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags='-s -w'` (rebuild
with that command if you prefer not to ship a binary in git).

---

## Task 1 — Idempotent Deploy

### How each requirement is met ([playbook.yaml](../ansible/playbook.yaml))

| Requirement | Task / module |
|---|---|
| Run as root | `become: true` |
| System user, no login shell | `ansible.builtin.user` (`system: true`, `shell: /usr/sbin/nologin`) |
| `/var/lib/quicknotes` 0750 owned by quicknotes | `ansible.builtin.file` (state: directory) |
| Binary → `/usr/local/bin/quicknotes` 0755 | `ansible.builtin.copy` |
| Render systemd unit from Jinja2 + vars | `ansible.builtin.template` from `quicknotes.service.j2` |
| Reload, enable, start | `ansible.builtin.systemd` (`daemon_reload`, `enabled`, `started`) |
| Restart **only** on binary/unit change | `notify: Restart quicknotes` handler on the two `copy`/`template` tasks |

The systemd template starts `After=network-online.target`, restarts on failure with
backoff (`Restart=on-failure`, `RestartSec=5`), runs as the `quicknotes` user, passes
`ADDR`/`DATA_PATH`/`SEED_PATH` from vars, and sets `WorkingDirectory` to the data dir.

### Run it

```bash
# from the repo root, with the Lab 5 VM up:
vagrant ssh-config                 # confirm host/port/key, then check ansible/inventory.ini
cd ansible
ansible-playbook -i inventory.ini playbook.yaml --syntax-check
ansible-playbook -i inventory.ini playbook.yaml
curl -s http://localhost:18080/health   # via the Lab 5 port-forward
```

**First-run PLAY RECAP:** _(paste — expect `changed>0`)_
```text
<!-- TODO -->
```
**`curl` health/notes after deploy:** _(paste)_
```text
<!-- TODO: {"status":"ok",...} -->
```

### Design answers

**a) `command:` vs dedicated modules — which is idempotent and why.**
Dedicated modules (`apt`, `file`, `copy`, `systemd`) are **declarative**: they inspect
the current state and act only on drift, reporting `ok` when nothing changes and
`changed` only when they modify something. `command:`/`shell:` are **imperative** —
they execute every run and Ansible cannot know whether state changed, so they report
`changed` every time (unless you bolt on `creates:`/`changed_when:`). The dedicated
modules maintain idempotency because they compare desired vs actual state (content
checksums, mode, owner, unit state) before acting.

**b) When do handlers fire vs skip? Why is the default appropriate?**
A handler fires only when a task that `notify`s it reports **changed**, runs **once**
at the **end** of the play (even if notified by several tasks), and is **skipped** if
nothing changed. That default is exactly right here: restart QuickNotes only when the
binary or unit file actually changed, and only once per run — no needless restarts on
a no-op converge.

**c) Three variable-precedence locations (justify).**
From lower to higher: **inventory `group_vars`** (`[quicknotes:vars]`) for
host/environment specifics → **playbook `vars:`** (where `listen_addr`, paths live) →
**extra-vars `-e`** (highest) for ad-hoc overrides. I keep stable defaults in playbook
`vars`, environment specifics in the inventory, and use `-e listen_addr=:9090` for the
Task-2 change test so I don't edit files. Extra-vars win so a one-off override is
predictable.

**d) Does `gather_facts: true` help? What does disabling save?**
No — this play references no `ansible_*` facts, so fact-gathering is pure overhead. I
set `gather_facts: false`; each play then skips the `setup` step (an extra remote
execution over SSH), shaving seconds per run. I'd only enable it if I needed
OS-conditional logic (e.g. `ansible_distribution`).

---

## Task 2 — Idempotency Verification

### Run 1 — re-run unchanged (expect `changed=0`)
```bash
ansible-playbook -i inventory.ini playbook.yaml      # second time
```
**PLAY RECAP:** _(paste — must show `changed=0`)_
```text
<!-- TODO: ok=N changed=0 -->
```

### Run 2 — change one template variable (expect template changed + handler)
```bash
ansible-playbook -i inventory.ini playbook.yaml -e 'listen_addr=:9090'
```
**PLAY RECAP / output:** _(paste — template task `changed`, handler `Restart quicknotes` runs, others `ok`)_
```text
<!-- TODO -->
```

### Run 3 — preview a second change with `--check --diff`
```bash
ansible-playbook -i inventory.ini playbook.yaml -e 'listen_addr=:7070' --check --diff
```
**Output:** _(paste — diff of the rendered unit file, nothing applied)_
```text
<!-- TODO -->
```

### Design answers

**e) Why does the second run report zero changes? What attributes are inspected?**
Idempotent modules compare **desired vs actual** and act only on drift, so on an
already-converged host everything matches → `ok`, `changed=0`. They inspect:
`copy` → file **content checksum** + owner/group/mode; `template` → the rendered
content vs the file on disk; `file` → path/state/mode/owner; `user` → existence +
shell; `systemd` → enabled/active state.

**f) What fails if `template:` is replaced by `shell: 'echo "ADDR=..." > unit'`?**
It loses idempotency — `shell` runs **every time** and always reports `changed`, so
the handler restarts the service on every run. You also lose `--check`/`--diff`
support, atomic writes, and owner/mode management, and you invite **shell-escaping
bugs** with the quotes/variables (a wrong quote silently writes a broken unit file).

**g) How does `--check --diff` catch what `--check` alone misses?**
`--check` is a dry run that reports *that* a task would change something, but not
*what*. Adding `--diff` prints the **line-level diff** of the file/template that would
change — so you actually see the rendered unit-file delta (e.g. `ADDR=:7070`) and can
catch a wrong value before it ever reaches production, instead of just "would change".

---

## Bonus — `ansible-pull` GitOps Loop

The VM converges itself from Git on a timer (no inbound SSH). On the VM:

```bash
sudo apt-get update && sudo apt-get install -y ansible git
```

`/etc/systemd/system/ansible-pull.service`:
```ini
[Unit]
Description=ansible-pull GitOps converge
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull \
  -U https://github.com/1AM6ADA/DevOps-Intro.git \
  -C feature/lab7 \
  -i ansible/inventory-local.ini \
  ansible/playbook.yaml
```

`/etc/systemd/system/ansible-pull.timer`:
```ini
[Unit]
Description=Run ansible-pull every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ansible-pull.timer
```

**Convergence demo:** push a change to `feature/lab7` (e.g. `listen_addr`), wait ≤5
min, then verify the VM reconciled it. _(paste `journalctl -u ansible-pull` + a curl
showing the new state)_

### Design answers

**h) Security advantage of pull-mode vs push-mode SSH.**
Pull-mode removes inbound SSH entirely: each node pulls from Git and converges itself,
so there's no central "god box" holding SSH keys to every host and no need to expose
inbound SSH ports on the fleet. The attack surface shrinks (compromising one node
doesn't hand over credentials to all others), and it scales without a central pusher.

**i) Which Kubernetes-layer tech implements this pattern? Why does `ansible-pull` simulate it?**
**GitOps controllers — Argo CD / Flux** — run inside the cluster and continuously pull
desired state from Git and reconcile it. `ansible-pull` on a systemd timer is the same
loop at VM scale: Git is the source of truth, the node periodically pulls and
re-applies the playbook, self-healing toward declared state with no central pusher.

---

## Submission Checklist

- [ ] `ansible/` tree (inventory, playbook, template, `files/quicknotes`, `files/seed.json`)
- [ ] `submissions/lab7.md` with PLAY RECAPs (3 runs) + curl + design answers a–i
- [ ] Run 1 `changed=0`; Run 2 selective change + handler; Run 3 `--check --diff`
- [ ] (Bonus) `ansible-pull` service + timer, convergence demo
- [ ] PR `feature/lab7 → main` against **upstream** and against **your fork**
- [ ] Both PR URLs in Moodle
