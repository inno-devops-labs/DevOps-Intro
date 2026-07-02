# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

Target: the **Lab 5 Vagrant VM** (Ubuntu, systemd). Files:
[`ansible/playbook.yaml`](../ansible/playbook.yaml),
[`ansible/inventory.ini`](../ansible/inventory.ini),
[`ansible/templates/quicknotes.service.j2`](../ansible/templates/quicknotes.service.j2),
[`ansible/files/quicknotes`](../ansible/files/) (static `CGO_ENABLED=0` binary).
Ansible: **`core 2.17.14` (Ansible 10)**.

---

## Task 1 — Idempotent Deploy

### What the playbook does

Deploying as root (`become: true`) it: creates a `quicknotes` system user
(nologin, no home), ensures `/var/lib/quicknotes` (`0750`, owned by the user),
ships the static binary to `/usr/local/bin/quicknotes` (`0755`), seeds the data
dir, **renders the systemd unit from a Jinja2 template** (all values are
variables), then enables + starts the service. A single **handler** restarts the
service, and it fires *only* when the binary or the unit template changed.

### First run — PLAY RECAP

```text
TASK [Create the quicknotes system user (no login, no home)] : changed: [lab5-vm]
TASK [Ensure the data directory exists]                      : changed: [lab5-vm]
TASK [Ship the QuickNotes binary]                            : changed: [lab5-vm]
TASK [Seed initial notes]                                    : changed: [lab5-vm]
TASK [Render the systemd unit from template]                 : changed: [lab5-vm]
TASK [Enable and start QuickNotes]                           : changed: [lab5-vm]
RUNNING HANDLER [restart quicknotes]                         : changed: [lab5-vm]

PLAY RECAP
lab5-vm : ok=7  changed=7  unreachable=0  failed=0  skipped=0
```

### Reachability

```text
# in the VM
$ systemctl is-active quicknotes
active
$ curl -s localhost:8080/health
{"notes":4,"status":"ok"}

# from the host, via the port forward
$ curl -s http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
```

### 1.5 Design questions

**a) `command:`/`shell:` vs dedicated modules (`apt`, `file`, `copy`, `systemd`).**
The dedicated modules are **declarative and idempotent**: each inspects the
current state and acts only if it differs — `copy`/`template` compare file
checksums (plus mode/owner), `file` compares attributes, `systemd` checks whether
the unit is already enabled/started. `command:`/`shell:` are **imperative**: they
run their command *every* time and report `changed` unconditionally (unless you
hand-roll `creates:`/`changed_when:`). Idempotency matters because it makes a run
safe to repeat, gives a *truthful* `changed=` signal (you can see what actually
moved), and is what powers `--check`/`--diff`. Reserve `command`/`shell` for the
rare thing no module covers.

**b) `notify:` and handlers — when do they fire (and not)?**
A handler runs **once, at the end of the play, and only if a task that notified
it reported `changed`**. It does *not* fire when the notifying task was `ok` (no
change), and it does *not* fire mid-play (notifications are queued and
de-duplicated). That's the right default because a restart is a *side effect you
only want when something actually changed* — restarting on every run would cause
needless downtime and flapping. Tying "restart" to "binary or unit changed" is
exactly the behavior you want.

**c) Variable hierarchy — top 3 places for this lab.**
Precedence runs (low→high): role defaults → inventory/group_vars → **play
`vars:`** → task vars → **`-e` extra-vars** (highest). For this lab I'd use:
1. **Play `vars:`** — the canonical values (`listen_addr`, `data_dir`, …). Used
   here: visible, scoped to the play, easy to read.
2. **`group_vars/quicknotes.yml`** — per-environment overrides (e.g. a `prod`
   group that listens on a different address) without touching the play.
3. **`-e` extra-vars** — one-off/CI overrides (`-e listen_addr=:9090`), highest
   precedence, never committed.
Defaults belong lowest (role `defaults/`) so anything above can override cleanly.

**d) Do you need `gather_facts` here?**
No — the playbook references no `ansible_*` facts, so I set `gather_facts:
false`. That skips the implicit `setup` module at the start of every run, saving
a full fact-collection round-trip (an extra SSH + Python scan of the host) each
time. On a small deploy like this the fact-gather is a noticeable slice of total
runtime, and it buys us nothing.

---

## Task 2 — Idempotency + Selective Re-run

### 1. Second run = zero changes

```text
PLAY RECAP
lab5-vm : ok=6  changed=0  unreachable=0  failed=0  skipped=0
```

Every module found the desired state already in place, so nothing changed and the
handler was never notified (`ok=6` — the handler task simply didn't run).

### 2. Change one variable → only the template + handler move

Re-running with `-e listen_addr=":9090"` (one variable that feeds the unit
template):

```text
TASK [Render the systemd unit from template]  : changed   (ADDR line differs)
RUNNING HANDLER [restart quicknotes]          : changed   (fired by the template change)
... every other task: ok

PLAY RECAP
lab5-vm : ok=7  changed=2  unreachable=0  failed=0  skipped=0
```

`changed=2` = the `template` task + the `restart quicknotes` handler. The user,
dir, binary, and seed tasks stayed `ok`.

### 3. `--check --diff` preview

Third change (`-e listen_addr=":9091"`, `--check --diff`):

```diff
--- before: /etc/systemd/system/quicknotes.service
+++ after:  (rendered template)
@@ -7,7 +7,7 @@
 [Service]
 User=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:9091
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
```

Dry run — no file was written; the diff shows exactly what *would* change.

### 2.2 Design questions

**e) Why does the second run report `changed=0`?**
Because every module is state-comparing, not action-running. `copy` and
`template` render/stage the intended content, compute its **checksum**, and
compare that (plus mode/owner) against the file already on disk; identical →
`ok`. `file` compares directory attributes; `user` checks the account exists with
the right shell/home; `systemd` checks the unit is already `enabled` + `started`.
Nothing differs, so nothing is rewritten and no handler is notified → `changed=0`.

**f) What if you used `shell: 'echo "ADDR=..." > /etc/.../quicknotes.service'`?**
Failure modes stack up: (1) **not idempotent** — the `shell` runs every time and
reports `changed` on every run, so `changed=` becomes meaningless and the restart
handler fires needlessly each run; (2) **no `--check`/`--diff`** — you can't
preview it, and in check mode it either no-ops or runs for real; (3) **no
atomicity or validation** — a partial write or a quoting slip leaves a corrupt
unit, whereas `template` writes to a temp file and moves it into place and sets
mode/owner; (4) **escaping hell** — building a multi-line unit with `echo`/quotes
is fragile (newlines, `$`, special chars); (5) it **clobbers unconditionally**,
so it can't detect or report drift. The `template:` module fixes every one.

**g) What does `--check --diff` catch that plain `--check` misses?**
Plain `--check` tells you a task *would* change (`changed=1`) but not *what*.
`--diff` shows the actual content. The bug you catch: a task that is **silently
non-idempotent** — a unit/template that rewrites itself every run over something
you didn't intend (a trailing newline, a re-ordered value, a mode mismatch).
`--check` alone just says "would change," which you might wave through as the
edit you meant; `--diff` reveals the change is *not* what you intended (or that a
"no-op" deploy is actually churning a file). Before a prod deploy, `--diff` is
what shows you the real blast radius, line by line.

---

## Bonus — `ansible-pull` GitOps Loop

The managed node reconciles *itself* from the fork on a schedule — no control
node SSHes in. A oneshot service runs `ansible-pull` against a local inventory;
a timer fires it every 5 minutes.

- [`ansible/ansible-pull-quicknotes.service`](../ansible/ansible-pull-quicknotes.service)
  — `ansible-pull -U <fork> -C feature/lab7 -i ansible/inventory.local.ini ansible/playbook.yaml`
- [`ansible/ansible-pull-quicknotes.timer`](../ansible/ansible-pull-quicknotes.timer)
  — `OnBootSec=1min`, `OnUnitActiveSec=5min`

### Timer active (on `lab5-vm`)

```text
$ systemctl list-timers ansible-pull-quicknotes.timer
NEXT             LEFT       LAST            PASSED   UNIT                           ACTIVATES
Thu 2026-07-02 … 4min 34s   Thu 2026-07-02  25s ago  ansible-pull-quicknotes.timer  ansible-pull-quicknotes.service
```

`LAST … 25s ago` = the timer already fired once; `ansible-pull` cloned the fork,
ran the playbook against `127.0.0.1` (local connection), and the node came up
reconciled — `quicknotes` active on the committed `:8080`, `curl :18080/health`
→ `{"notes":4,"status":"ok"}`. The next fire is 5 minutes out.

### Convergence observed (push → timer → reconciled)

The pull loop end-to-end: a `listen_addr` change pushed to `feature/lab7` is
picked up by the next timer fire and reconciled with no control-node action.

| Step | Elapsed |
|------|---------|
| `git push` — `listen_addr` change to `feature/lab7` | T+0 |
| `ansible-pull-quicknotes.timer` fires → `ansible-pull` clones + runs the playbook | ~T+2 min |
| Node reconciled — the templated unit picks up the new `ADDR` and the service restarts | ~T+2 min |

Reconcile happens well inside the 5-minute period, and no `ansible-playbook` runs
from any control node — the node pulls Git and converges itself.

### B.4 Design questions

**h) `ansible-pull` (pull) — security benefit vs push.**
In **push** mode a control node holds SSH keys into *every* managed host and
connects inbound; that control node becomes a fleet-wide crown jewel (own it →
own everything), and every host must expose SSH and trust the control node. In
**pull** mode each host reaches *out* to Git, clones, and applies to itself:
- **No inbound management port** — hosts can sit behind NAT/firewalls with no open
  SSH for a control node; the attack surface loses the "central SSH-er."
- **No central store of fleet credentials** — there's no one box whose compromise
  yields every host; each node needs only *read* access to the repo (a scoped
  token for private repos).
- **Git is the audited source of truth** — every desired-state change is a
  reviewed, signed commit, not an ad-hoc push from someone's laptop.

**i) Same pattern at the Kubernetes layer.**
It's **GitOps**, implemented by tools like **Argo CD** and **Flux**: an agent
runs *in* the cluster, watches a Git repo, and continuously reconciles the
cluster to the declared state. `ansible-pull` is a fair VM-layer simulator
because it's the identical control loop — *the repo is the source of truth, and a
scheduled agent on the target pulls desired state and converges the local system
to it*. Argo CD/Flux do this for Kubernetes objects; `ansible-pull` + a systemd
timer does it for a VM's packages, files, and systemd units. Same loop, different
layer.
