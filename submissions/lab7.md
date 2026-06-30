# Lab 7 - Configuration Management: Deploy QuickNotes via Ansible

Deploys QuickNotes to the Lab 5 VirtualBox VM as a systemd service, idempotently.
Files: [`ansible/playbook.yaml`](../ansible/playbook.yaml),
[`ansible/inventory.ini`](../ansible/inventory.ini),
[`ansible/templates/quicknotes.service.j2`](../ansible/templates/quicknotes.service.j2),
[`ansible/files/quicknotes`](../ansible/files/quicknotes) (the static binary).

---

## Task 1 - Idempotent deploy

The playbook (`become: true`, `gather_facts: false`) runs five tasks: create the
`quicknotes` system user (nologin, no home) → ensure `/var/lib/quicknotes` owned
`quicknotes:quicknotes` mode `0750` → copy the binary to `/usr/local/bin` (0755)
→ render the systemd unit from the Jinja template (all values are variables) →
`daemon_reload` + enable + start. A single handler restarts the service, notified
only by the binary-copy and template tasks.

### First-run PLAY RECAP

```
TASK [Create the quicknotes system user] ... changed
TASK [Ensure the data directory exists] ..... changed
TASK [Install the QuickNotes binary] ........ changed
TASK [Render the systemd unit from template]  changed
TASK [Reload systemd, enable and start] ..... changed
RUNNING HANDLER [restart quicknotes] ........ changed

PLAY RECAP
localhost : ok=6 changed=6 unreachable=0 failed=0
```

### Service reachable

```
$ systemctl is-active quicknotes
active
# from the guest:
$ curl -s http://localhost:8080/health
{"notes":0,"status":"ok"}
# from the HOST via the Vagrant forward (18080 -> 8080):
$ curl -s http://localhost:18080/health
{"notes":0,"status":"ok"}
```

### 1.5 Design questions

a) `command:` vs dedicated modules - which is idempotent? `command:`/`shell:`
just execute and (by default) report `changed` every run - they don't inspect
state, so they're not idempotent unless you bolt on `creates:`/`changed_when:`.
The dedicated modules (`apt`, `file`, `copy`, `template`, `systemd`) are
declarative: each checks the current state and only acts if it differs, and
reports `changed` truthfully. That matters because it makes re-runs safe and makes
the PLAY RECAP an honest drift report rather than noise.

b) When does a handler fire / not fire? A handler runs once, at the end of
the play, and only if a task that `notify:`-ed it reported `changed`. It does
not fire if the notifying task was `ok` (no change), and it won't run if the
play aborts earlier (unless `--force-handlers`). That's the right default: you
only want the side effect (a restart) when something it depends on actually
changed - restarting every run would cause needless downtime.

c) Variable hierarchy - top 3 places for this lab. From lowest to highest
precedence I'd use: (1) role/play defaults for sane defaults like
`listen_addr`; (2) group_vars / host_vars for per-environment values (a
prod vs the VM); (3) playbook `vars:` or `-e` extra-vars for explicit
per-run overrides (extra-vars win over everything). For this lab I keep them
in the playbook `vars:` block; a bigger setup would push them down to defaults +
group_vars and reserve `-e` for one-offs.

d) Do you need `gather_facts`? No, the playbook references no `ansible_*`
facts, so I set `gather_facts: false`. That skips the implicit `setup` task
(a full system inventory) on every run, shaving a round-trip per host for nothing.

---

## Task 2 - Idempotency + selective re-run

### Second run - `changed=0`

```
TASK [Create the quicknotes system user] ... ok
TASK [Ensure the data directory exists] ..... ok
TASK [Install the QuickNotes binary] ........ ok
TASK [Render the systemd unit from template]  ok
TASK [Reload systemd, enable and start] ..... ok

PLAY RECAP
localhost : ok=5 changed=0 unreachable=0 failed=0
```
No handler runs (nothing notified it). This is idempotency.

### One variable changed - only the template + handler

Re-running with `-e listen_addr=:9090` re-renders the unit and fires the restart
handler; every other task stays `ok`:

```
TASK [Render the systemd unit from template]  changed
TASK [Reload systemd, enable and start] ..... ok
RUNNING HANDLER [restart quicknotes] ........ changed

PLAY RECAP
localhost : ok=6 changed=2 unreachable=0 failed=0
```

### `--check --diff` preview

`-e listen_addr=:9595 --check --diff` (dry run - nothing applied):

```
TASK [Render the systemd unit from template]
--- before: /etc/systemd/system/quicknotes.service
+++ after:  (rendered template)
@@ -7,7 +7,7 @@
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:9595
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
```

### 2.2 Design questions

e) Why does the second run report `changed=0`? The `copy`/`template`/`file`
modules compare desired vs actual before acting: `copy` and `template` compare the
content checksum (template renders first, then hashes), and all three check
owner, group, and mode. If the rendered content and metadata already match
what's on disk, the module makes no change and reports `ok`. Identical inputs →
identical checksum → `changed=0`.

f) What if you used `shell: 'echo "ADDR=..." > /etc/systemd/system/...'`?
Several failure modes: it reports `changed` every run (not idempotent), so the
handler would restart the service on *every* play; `--check`/`--diff` can't preview
it; shell quoting/escaping of the unit content is fragile and easy to corrupt;
there's no `owner`/`mode` management; the write isn't atomic (a crash mid-write
leaves a broken unit); and the values get interpolated by the shell, not Jinja, so
templating logic breaks. `template:` solves all of these declaratively.

g) `--check` vs `--check --diff` - the bug you'd catch. `--check` only tells
you a task would change something; `--check --diff` shows you what changes,
line by line. The bug you'd miss with plain `--check`: the unit would change,
but the diff reveals the change is wrong (a typo'd address, a secret
accidentally rendered into the file, an unintended whitespace/format shift). You
catch a bad change before it deploys, not just the fact that a change exists.

---

## Bonus - `ansible-pull` GitOps loop

Inside the VM I installed a oneshot `ansible-pull.service` and an
`ansible-pull.timer` (`OnBootSec=1min`, `OnUnitActiveSec=5min`). The service runs:

```
/usr/bin/ansible-pull -U https://github.com/RoukayaZaki/DevOps-Intro.git \
  -C feature/lab7 -i ansible/inventory-local.ini ansible/playbook.yaml
```

`systemctl list-timers`:
```
NEXT                        LEFT      LAST                        UNIT                ACTIVATES
Sun 2026-06-21 17:41:03 UTC 4min 16s  Sun 2026-06-21 17:36:03 UTC ansible-pull.timer  ansible-pull.service
```

Convergence observed (no `ansible-playbook` from my host):

| event | time (UTC) |
|-------|-----------|
| pushed `listen_addr: :8085` to `feature/lab7` | 17:37:20 |
| timer fired → `ansible-pull` ran | 17:41:08 |
| VM unit reconciled to `ADDR=:8085` | 17:41:33 |

~4 minutes end-to-end, within the 5-minute window. The pull's journal showed
`TASK [Render the systemd unit] changed` + the restart handler, `changed=2`. (A
benign `WARNING: Could not match supplied host pattern ... quicknotes-vm` appears
because `ansible-pull` defaults `--limit` to the hostname; the play matched
`localhost` from the inventory and ran fine.) I then pushed `:8080` back, and the
next timer cycle reconciled the VM to `:8080` automatically - drift correction in
both directions.

### B.4 Design questions

### B.4 Design questions

h) Security benefit of pull vs push. In push mode a control node holds SSH
credentials to every host and must reach inbound into each one - a juicy central
target and a wide attack surface. In pull mode each node reconciles itself by
pulling from Git (read-only), so there's no central node with keys to everything,
hosts don't need to expose SSH to a control plane, and the only credential a node
needs is a read-only repo token. Smaller blast radius, and it scales without a
fan-out push.

i) Same pattern at the Kubernetes layer. GitOps - the industry tools are
Argo CD / Flux. `ansible-pull` is a fair VM-layer simulator because it's the
identical loop: Git is the single source of truth, the node periodically pulls and
reconciles itself to the declared state, and drift is auto-corrected - exactly
what Argo CD/Flux do for cluster manifests, just at the OS level instead of the
Kubernetes API.
