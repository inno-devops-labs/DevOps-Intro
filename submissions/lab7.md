# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

Files: [`ansible/playbook.yaml`](../ansible/playbook.yaml),
[`ansible/inventory.ini`](../ansible/inventory.ini),
[`ansible/templates/quicknotes.service.j2`](../ansible/templates/quicknotes.service.j2),
[`ansible/files/quicknotes`](../ansible/files/) (static `CGO_ENABLED=0` binary).

> **Managed-node note.** The nominal target is the Lab 5 Vagrant VM, and the
> committed [`inventory.ini`](../ansible/inventory.ini) points at it (vagrant
> user + Hyper-V key + dynamic IP). On this host the VM is only reachable with a
> full-tunnel VPN disabled (documented in Lab 5), which made iterative
> development against it impractical, so the **identical playbook** was developed
> and verified against an equivalent **Ubuntu 24.04 systemd node**
> (`inventory.local.ini`, `ansible_connection=local`). Same modules, same
> handlers, same idempotency — only the connection differs. Ansible: `core 2.16`.

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
TASK [Create the quicknotes system user (no login, no home)] : changed
TASK [Ensure the data directory exists]                      : changed
TASK [Ship the QuickNotes binary]                            : changed
TASK [Seed initial notes]                                    : changed
TASK [Render the systemd unit from template]                 : changed
TASK [Enable and start QuickNotes]                           : changed
RUNNING HANDLER [restart quicknotes]                         : changed

PLAY RECAP
localhost : ok=7  changed=7  unreachable=0  failed=0  skipped=0
```

### Reachability

```text
$ systemctl is-active quicknotes
active
$ curl -s localhost:8080/health          # (VM: curl :18080 via the port forward)
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
localhost : ok=6  changed=0  unreachable=0  failed=0  skipped=0
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
localhost : ok=7  changed=2  unreachable=0  failed=0  skipped=0
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

<!-- filled after the timer + convergence demo -->
