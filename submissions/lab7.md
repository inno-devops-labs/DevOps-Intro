# Lab 7 Submission — Ansible Deploy QuickNotes

## Environment note

Lab 5’s VirtualBox VM could not be started on the course server (`VERR_SVM_NO_SVM` — no nested AMD-V inside the KVM guest). For Ansible evidence I used an Ubuntu 24.04 **systemd Docker target** that mirrors the Lab 5 SSH pattern:

- `ansible_host=127.0.0.1`, `ansible_port=2222`
- user `vagrant` + Vagrant insecure key (`ansible/files/vagrant_insecure_key`)
- port forward `127.0.0.1:18080 → guest :8080`

Image: `ansible/Dockerfile.lab7-vm` (built by `ansible/scripts/start-docker-vm.sh`).

---

## Task 1 — Idempotent deploy

### Files
- Playbook: `ansible/playbook.yaml`
- Inventory: `ansible/inventory.ini`
- Template: `ansible/templates/quicknotes.service.j2`
- Binary: `ansible/files/quicknotes` (linux/amd64, `CGO_ENABLED=0`)

### First run PLAY RECAP
```text
PLAY RECAP *********************************************************************
qn-vm                      : ok=7    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Handler `restart quicknotes` ran after binary + unit were installed.

### Health check (`curl` from host)
```text
$ curl -s http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
```

### Design questions (a–d)

**a) `command:` vs dedicated modules**  
Dedicated modules (`user`, `file`, `copy`, `template`, `systemd`) encode desired state and compare before acting, so they are idempotent. `command:`/`shell:` always run unless guarded and do not understand resources — bad for config management.

**b) `notify:` and handlers**  
Handlers run **once at the end of the play**, only if a notifying task reported `changed`. If nothing changed, handlers are skipped. That avoids unnecessary restarts while still reacting to real drift.

**c) Variable hierarchy (top 3 for this lab)**  
1. **Play `vars:`** — defaults for this deploy (paths, listen address).  
2. **`group_vars/` / inventory vars** — per-environment SSH targets (VM IP/port).  
3. **Extra vars (`-e`) / CLI** — one-off overrides for testing (e.g. staged rollout).

**d) `gather_facts`**  
Not required here: the play only manages users, files, templates, and systemd — no fact-driven branching. Setting `gather_facts: false` skips the fact-gathering SSH round-trip (~1–2s per host).

---

## Task 2 — Idempotency + selective change

### Second run (`changed=0`)
```text
PLAY RECAP *********************************************************************
qn-vm                      : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Variable tweak (`listen_addr` → `0.0.0.0:9090`)
Only template + handler changed:
```text
TASK [Render quicknotes systemd unit] ******************************************
changed: [qn-vm]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [qn-vm]

PLAY RECAP *********************************************************************
qn-vm                      : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### `--check --diff` (preview `listen_addr` → `0.0.0.0:9191`)
```diff
-Environment=ADDR=0.0.0.0:9090
+Environment=ADDR=0.0.0.0:9191
```

### Design questions (e–g)

**e) Why `changed=0` on second run?**  
Modules compare current state to desired state (file checksums/attributes, user properties, template-rendered content). When nothing drifted, each task returns `ok` without modifying the system.

**f) Using `shell: echo ... > unit` instead of `template:`**  
Every run would rewrite the file → always `changed`, handler fires every time, unnecessary restarts. No validation, race-prone, and easy to leave a broken unit if the command fails mid-way.

**g) What `--check --diff` catches that plain `--check` misses**  
`--check` says *whether* something would change; `--diff` shows *what* would change (e.g. wrong `ADDR` in the unit). You’d spot a bad port before applying it in production.

---

## Bonus — `ansible-pull` GitOps loop

Prepared but **not demonstrated end-to-end** in this submission: `ansible/ansible-pull-setup.yaml` is included for when the VM can pull from the public fork. Convergence demo (push → ≤5 min timer → reconciled state) was not recorded in this session.

Design answers (for reference):

**h) Security benefit of pull vs push**  
Pull mode avoids storing long-lived SSH keys/credentials on a central control node that can reach all hosts; each node fetches only what it needs from Git (can be scoped/tokenized).

**i) Kubernetes analogue**  
**Argo CD / Flux** — Git as source of truth with periodic/ event-driven reconciliation; `ansible-pull` is the same pattern at the VM layer.
