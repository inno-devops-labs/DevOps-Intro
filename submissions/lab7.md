# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

> **Note on approach.** The host is Windows + VirtualBox with Ansible available in WSL2.
> WSL2's separate network stack cannot reach the Vagrant VM's forwarded SSH port
> (Windows firewall blocks the WSL subnet entirely — `ping` to the host gateway
> returns 100% packet loss). Rather than weaken the host firewall, this lab uses the
> **ansible_local / self-reconcile** model: Ansible runs *inside* the Lab 5 VM and
> applies the playbook to `localhost` via `connection: local`. The playbook, Jinja2
> template, idempotency, handlers, variables, and `--check --diff` are all exactly as
> the spec requires — only the control-node location differs (it is the VM itself).
> This is also the natural model for the bonus `ansible-pull` loop, which runs inside
> the VM by design. Ansible version in the VM: community `2.10.8` (ansible-core).

## Task 1 — Idempotent Deploy

### Layout

```
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── quicknotes        (static binary, CGO_ENABLED=0, built in the VM)
│   └── seed.json
└── templates/
    └── quicknotes.service.j2
```

See [`ansible/playbook.yaml`](../ansible/playbook.yaml), [`ansible/inventory.ini`](../ansible/inventory.ini), [`ansible/templates/quicknotes.service.j2`](../ansible/templates/quicknotes.service.j2).

The binary was built inside the VM with the Go 1.24.5 toolchain from Lab 5:
`CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o files/quicknotes .`

### First-run PLAY RECAP

```
TASK [Create the quicknotes system user]            changed
TASK [Ensure the data directory exists]             changed
TASK [Copy the QuickNotes static binary into place] changed
TASK [Copy the seed file into the data directory]   changed
TASK [Render the systemd unit from the template]    changed
TASK [Enable and start QuickNotes]                  changed
RUNNING HANDLER [restart quicknotes]                changed
PLAY RECAP: localhost : ok=7  changed=7  unreachable=0  failed=0
```

### Service status + curl

```
● quicknotes.service - QuickNotes service (deployed via Ansible — Lab 7)
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; ...)
     Active: active (running)
   Main PID: 10151 (quicknotes)

$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

(From the host via the Vagrant port forward: `curl http://localhost:18080/health` → same `{"notes":4,"status":"ok"}`.)

### Design questions

**a) `command:` vs dedicated modules — which is idempotent and why it matters?**

`command:`/`shell:` run an arbitrary command every run — Ansible has no idea what the command *means*, so it can't tell whether the desired state already holds; it reports `changed` every time (unless you hand-write `creates:`/`changed_when:`). Dedicated modules (`apt`, `file`, `copy`, `systemd`, `template`) are declarative and idempotent: they describe a desired end state, check current state first, and act only on drift — so a no-op second run reports `changed=0`. That matters because idempotency is the whole point of config management: run repeatedly and safely, converge to target without redoing work or causing churn (needless restarts).

**b) `notify:` and handlers — when does a handler fire, when not, why is that the right default?**

A handler fires only if the notifying task actually reported `changed`; if the task is `ok`, the notification isn't sent and the handler doesn't run. Handlers also run once, at the end of the play, even if notified by multiple tasks. This is the right default because a handler is a reaction to change — you want to restart the service only when the binary or unit file actually changed, not every run. Restarting an unchanged service would cause needless downtime and break idempotency. (Demonstrated: changing only `listen_addr` fired the restart handler; an unchanged run did not.)

**c) Variable hierarchy — top 3 places for this lab's variables, and why?**

Lowest-to-highest: (1) role/play **`defaults`** — sane baselines that are easy to override; (2) **`group_vars/`** — values shared by all hosts in the `quicknotes_vm` group, good for environment-wide settings; (3) playbook **`vars:`** — play-specific values that override the two above. I keep everything in playbook `vars:` here (single host, single play); in a larger setup, defaults + group_vars would let multiple environments share one playbook while overriding only what differs.

**d) `gather_facts: true` is default — needed here? What does off save?**

This playbook references no `ansible_*` facts — every value is a variable I set. So I set `gather_facts: false`. Turning it off skips the implicit `setup` task that probes the host for hundreds of facts at the start of every play, saving a few seconds and one module run per execution. Small on a fast local connection, but free and correct to skip what you don't use.

---

## Task 2 — Prove Idempotency + Selective Re-run

### Second run = changed=0

```
all six tasks: ok
PLAY RECAP: localhost : ok=6  changed=0  unreachable=0  failed=0
```

No handler fired — nothing changed.

### Variable tweak (listen_addr :8080 → :9090) = selective change

```
TASK [Render the systemd unit from the template]    changed
(other 5 tasks: ok)
RUNNING HANDLER [restart quicknotes]                changed
PLAY RECAP: localhost : ok=7  changed=2  unreachable=0  failed=0
```

Only the `template` task changed, and only then did the `restart quicknotes` handler fire — exactly the selective behaviour required.

### --check --diff preview (third change, :9090 → :7070)

```
TASK [Render the systemd unit from the Jinja2 template]
--- before: /etc/systemd/system/quicknotes.service
+++ after: .../quicknotes.service.j2
@@ -8,7 +8,7 @@
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:7070
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
changed: [localhost]
PLAY RECAP: localhost : ok=7  changed=2 ...   (NOT applied — --check dry run)
```

The diff shows the exact rendered change before any file is touched. (Port was then restored to `:8080`.)

### Design questions

**e) Why does the second run report changed=0? What does file/template check?**

Each module compares desired vs actual and finds no drift. `file` checks path existence, type, owner, group, mode. `copy` compares the source file's SHA checksum against the destination's — identical → no copy. `template` renders the Jinja2 template in memory and compares the rendered result's checksum (plus owner/group/mode) against the existing file — byte-identical → `ok`. Nothing changed between runs, so the recap shows `changed=0`.

**f) What if you used `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` instead of `template:`?**

Failure modes: (1) no idempotency — `shell` runs and reports `changed` every run, so you can't prove convergence and the handler fires needlessly every time; (2) no change detection — Ansible can't tell if content is already correct, so `--check`/`--diff` show nothing useful; (3) fragile quoting — building a multi-line unit file via `echo`/redirection breaks on special chars, newlines, interpolation; (4) no metadata management — you'd need separate non-idempotent `chmod`/`chown`; (5) partial-write risk — a redirect failing midway leaves a truncated unit file. `template:` renders atomically, manages owner/group/mode, and is fully idempotent.

**g) `--check --diff` — what bug does it catch that plain `--check` misses?**

Plain `--check` tells you *that* a task would change something, not *what*. `--diff` shows the actual content difference. The bug you catch: a template edit that's subtly wrong — `--check` says "template would change", but only `--diff` reveals the rendered unit now has a typo, wrong port, or a dropped line. Without the diff you'd approve a change blind and discover the breakage only after deploying. `--check --diff` lets you eyeball the exact rendered output before it touches production.

---

## Bonus Task — ansible-pull GitOps Loop

Configured inside the VM: a systemd service runs `ansible-pull` against the fork's
`feature/lab7` branch, and a timer fires it every 5 minutes.

- Service `ExecStart`: `ansible-pull -U https://github.com/ivanalpatov2003-design/DevOps-Intro.git -C feature/lab7 -i /etc/ansible-pull/inventory.ini --limit localhost ansible/playbook.yaml`
- Timer: `OnBootSec=1min`, `OnUnitActiveSec=5min`

### systemctl list-timers

```
$ systemctl list-timers | grep ansible-pull
Mon 2026-06-29 18:05:17 UTC  3min 26s left  Mon 2026-06-29 18:00:17 UTC  1min 33s ago  ansible-pull.timer  ansible-pull.service
```

### ansible-pull run (applies the playbook locally)

```
localhost | SUCCESS => { "before": "5ca46eb...", "after": "5ca46eb...", "changed": false }
PLAY [Deploy QuickNotes]
  ... tasks ...
PLAY RECAP: localhost : ok=6  changed=1  unreachable=0  failed=0
```

(The `--limit localhost` flag was needed: `ansible-pull` defaults to `--limit <hostname>` = `quicknotes-vm`, which doesn't match the `localhost` inventory entry, so without it the play reported "no hosts matched".)

### Convergence timeline (push-to-Git → VM reconciled)

```
17:55:22 UTC  VM unit file:  Environment=ADDR=:8080   (state BEFORE)
~17:56     UTC  git commit f76d8b3 (listen_addr → :9090) pushed to feature/lab7
18:00:17 UTC  ansible-pull.timer fires (automatic, no human action)
18:01:51 UTC  VM unit file:  Environment=ADDR=:9090   (state AFTER — reconciled from Git)
```

The VM converged to the new Git state within the 5-minute window with zero commands run by hand — pure pull-based GitOps. (The change was then reverted to `:8080` via another commit, which the VM also picked up on the next tick.)

### Design questions

**h) `ansible-pull` is pull mode — security benefit vs push?**

In push mode a control node holds SSH credentials and connects *into* every managed host — that node is a high-value target (compromise it, reach everything), and every host must accept inbound SSH. In pull mode each host runs `ansible-pull` locally and *fetches* config from Git: no inbound SSH needed (hosts can sit behind firewalls/NAT with no open management port), no central node holding fleet-wide keys, and the blast radius shrinks — a host only ever pulls its own config. The trust boundary becomes "read access to the Git repo," which is far easier to lock down than fleet-wide SSH.

**i) Same pattern at the Kubernetes layer — what's it called, why is ansible-pull a fair simulator?**

At the Kubernetes layer this is **GitOps**, implemented by **ArgoCD** or **Flux**: an in-cluster controller continuously watches a Git repo and reconciles actual cluster state to the declared state in Git. `ansible-pull` is a fair VM-layer simulator because it embodies the same core loop — the managed node itself periodically pulls declarative config from Git and converges to it, with no human pushing and no external control node. The systemd timer plays the role of the reconciliation loop; Git is the single source of truth in both cases.

---

## Summary

| Task | Status |
|------|--------|
| Task 1 — idempotent Ansible deploy, service active (running), health ok | ✅ |
| Task 2 — changed=0, selective handler fire, --check --diff captured | ✅ |
| Bonus — ansible-pull systemd timer active, push→reconcile in <5 min observed | ✅ |
