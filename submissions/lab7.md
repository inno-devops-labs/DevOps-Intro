# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

> **Note on approach.** The host is Windows + VirtualBox with Ansible running in WSL2.
> WSL2's separate network stack cannot reach the Vagrant VM's forwarded SSH port
> (Windows firewall blocks the WSL subnet entirely — `ping` to the host gateway
> returns 100% loss). Rather than weaken the host firewall, this lab uses the
> **ansible_local / self-reconcile** model: Ansible runs *inside* the Lab 5 VM and
> applies the playbook to `localhost` via `connection: local`. The playbook,
> Jinja2 template, idempotency, handlers, variables, and `--check --diff` are all
> exactly as the spec requires — only the control node location differs (it is the
> VM itself). This is also the natural model for the bonus `ansible-pull` loop,
> which runs inside the VM by design.

## Task 1 — Idempotent Deploy

### Layout

```
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── quicknotes        (static binary, built in the VM)
│   └── seed.json
└── templates/
    └── quicknotes.service.j2
```

### playbook.yaml / inventory.ini / template

See [`ansible/playbook.yaml`](../ansible/playbook.yaml), [`ansible/inventory.ini`](../ansible/inventory.ini), [`ansible/templates/quicknotes.service.j2`](../ansible/templates/quicknotes.service.j2).

### First-run PLAY RECAP

```
⬜ TODO — paste the first ansible-playbook run output (tasks showing changed)
# localhost : ok=6  changed=5  unreachable=0  failed=0 ...
```

### curl proving reachability

```
⬜ TODO — from host: curl http://localhost:18080/health  -> {"notes":4,"status":"ok"}
# (or from inside VM: curl http://localhost:8080/health)
```

### Design questions

**a) `command:` vs dedicated modules — which is idempotent and why it matters?**

`command:` (and `shell:`) just run an arbitrary command every time the play runs — Ansible has no idea what the command *means*, so it can't tell whether the desired state is already met; it reports `changed` on every run (unless you hand-write `creates:`/`changed_when:`). Dedicated modules (`apt`, `file`, `copy`, `systemd`, `template`) are **declarative and idempotent**: they describe a desired end state, check the current state first, and only act if there's a drift — so a second run with nothing to do reports `changed=0`. That matters because idempotency is the whole point of configuration management: you can run the playbook repeatedly and safely, it converges to the target state without redoing work or causing churn (e.g. needless service restarts).

**b) `notify:` and handlers — when does a handler fire, when not, why is that the right default?**

A handler fires only if the task that notifies it actually reported `changed`. If the task is `ok` (no change), the notification isn't sent and the handler doesn't run. Handlers also run **once**, at the end of the play (after all tasks), even if notified multiple times. This is the right default because handlers represent reactions to change — you want to restart the service only when the binary or unit file actually changed, not on every run. Restarting an unchanged service would cause needless downtime and defeat idempotency.

**c) Variable hierarchy — top 3 places for this lab's variables, and why?**

Ansible has 22+ precedence levels; for this lab the three sensible homes, lowest-to-highest, are: (1) **role/play `defaults`** — sane baseline values that are easy to override (e.g. `quicknotes_listen_addr: ":8080"`); (2) **`group_vars/`** — values shared by all hosts in the `quicknotes_vm` group, good for environment-wide settings; (3) **playbook `vars:`** — values specific to this play, which override the two above. Here I put everything in playbook `vars:` for simplicity (single host, single play), but in a larger setup defaults + group_vars would let multiple environments share the playbook while overriding just what differs.

**d) `gather_facts: true` is default — do you need it here? What does off save?**

This playbook references no `ansible_*` facts (no `ansible_distribution`, `ansible_default_ipv4`, etc.) — every value is a variable I set myself. So fact-gathering is unnecessary and I set `gather_facts: false`. Turning it off skips the implicit `setup` task that runs at the start of every play, which probes the host for hundreds of facts — saving a few seconds and one module execution per run. On a fast local connection it's small, but it's free and correct to skip what you don't use.

---

## Task 2 — Prove Idempotency + Selective Re-run

### Second run = changed=0

```
⬜ TODO — paste second-run PLAY RECAP
# localhost : ok=6  changed=0  unreachable=0  failed=0 ...
```

### Variable tweak = selective change (listen_addr :8080 -> :9090)

```
⬜ TODO — paste run after editing quicknotes_listen_addr
# template task: changed=1
# "restart quicknotes" handler: RUNNING HANDLER ... invoked
# other tasks: ok
# RECAP: ok=6  changed=1 (+handler)  ...
```

### --check --diff preview (third change)

```
⬜ TODO — paste: ansible-playbook ... --check --diff
# shows a unified diff of the unit file change without applying it
```

### Design questions

**e) Why does the second run report changed=0? What does file/template check?**

On the second run each module compares desired vs actual state and finds no drift. The `file` module checks the path's existence, type (directory), owner, group, and mode — all already match, so no change. The `copy` module compares the source file's checksum (SHA) against the destination's; identical checksums → no copy. The `template` module renders the Jinja2 template in memory, then compares the rendered result's checksum against the existing file's content (plus owner/group/mode); if the rendered output is byte-identical and metadata matches, it reports `ok`. Since nothing changed between runs, everything is `ok` and the recap shows `changed=0`.

**f) What if you used `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` instead of `template:`?**

Several failure modes: (1) **No idempotency** — `shell` runs every time and reports `changed` every run, so you can never prove convergence and the handler would fire on every run, restarting the service needlessly. (2) **No change detection** — Ansible can't tell if the file already has the right content, so `--check`/`--diff` show nothing useful. (3) **Fragile quoting/escaping** — building a multi-line unit file with `echo`/redirection is error-prone; special characters, newlines, and variable interpolation break easily. (4) **No metadata management** — you'd separately have to `chmod`/`chown`, more steps that aren't idempotent. (5) **Partial-write risk** — a redirect that fails midway can leave a truncated unit file. The `template` module renders atomically, manages owner/group/mode, and is fully idempotent.

**g) `--check` is dry-run, `--diff` shows changes — what bug does `--check --diff` catch that plain `--check` misses?**

Plain `--check` tells you *that* a task would change something (`changed=1`), but not *what*. `--diff` shows the actual content difference. The bug you catch: a template change that's subtly wrong — e.g. you edit a variable and `--check` says "template would change", but only `--diff` reveals the rendered unit now has a typo, a wrong port, or an accidentally dropped line. Without the diff you'd approve a change blind and only discover the breakage after deploying. `--check --diff` lets you eyeball the exact rendered output before it touches production.

---

## Bonus Task — ansible-pull GitOps Loop

### systemctl list-timers output

```
⬜ TODO — paste: systemctl list-timers | grep ansible-pull
# NEXT ... LEFT ... ansible-pull.timer ansible-pull.service
```

### Convergence timeline

```
⬜ TODO:
# git commit <hash> pushed at HH:MM:SS
# next timer fire at HH:MM:SS (<=5 min later)
# state reconciled in VM: <evidence, e.g. unit now shows ADDR=:9090>
```

### Design questions

**h) `ansible-pull` is pull mode — security benefit vs push?**

In push mode a control node holds SSH credentials and connects *into* every managed host — that control node is a high-value target (compromise it and you can reach everything), and every host must accept inbound SSH from it. In pull mode each host runs `ansible-pull` locally and *fetches* its config from Git, so: no inbound SSH is needed (hosts can sit behind firewalls/NAT with no open management port), there's no central node holding keys to the whole fleet, and the blast radius shrinks — a host only ever pulls its own config. The trust boundary moves to "read access to the Git repo," which is easier to lock down than fleet-wide SSH.

**i) Same pattern at the Kubernetes layer — what's it called, why is ansible-pull a fair simulator?**

At the Kubernetes layer this is **GitOps**, implemented by tools like **ArgoCD** or **Flux**: a controller running in the cluster continuously watches a Git repo and reconciles the cluster's actual state to match the declared state in Git. `ansible-pull` is a fair VM-layer simulator because it embodies the same core loop — the managed node itself periodically pulls declarative config from Git and converges to it, with no human pushing and no external control node. The systemd timer firing every 5 minutes plays the role of the reconciliation loop; Git is the single source of truth in both cases.

---

## Summary

| Task | Status |
|------|--------|
| Task 1 — idempotent Ansible deploy, service running | ⬜ |
| Task 2 — changed=0, selective handler, --check --diff | ⬜ |
| Bonus — ansible-pull systemd timer, convergence demoed | ⬜ |
