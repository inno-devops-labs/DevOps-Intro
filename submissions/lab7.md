# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + Ansible 10.x + Lab 5 Vagrant VM

---

## Task 1 — Idempotent deploy to Lab 5 VM

### Layout

```text
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── quicknotes
│   └── seed.json
└── templates/
    └── quicknotes.service.j2
```

### `playbook.yaml` / `inventory.ini` / template

See [`ansible/`](../ansible/) directory.

### First run PLAY RECAP

```text
<!-- paste after ansible-playbook run -->
```

### Health check from host

```text
<!-- curl http://127.0.0.1:18080/health -->
```

### Design questions (Task 1)

**a) `command:` vs dedicated modules?**

Dedicated modules (`user`, `file`, `copy`, `template`, `systemd`) check desired state before acting — they report `ok` when nothing needs changing. Raw `command:`/`shell:` always run unless wrapped with `creates:`/`removes:`. Idempotency matters because re-runs are safe deploys, not one-off scripts.

**b) `notify:` and handlers?**

Handlers fire **once at the end of the play**, only if a notifying task reports `changed`. If the task is `ok` (already converged), the handler does **not** run. That's correct: restart only when binary or unit file actually changed.

**c) Variable hierarchy — top 3 for this lab?**

1. **Play `vars:`** — defaults for this deploy (`quicknotes_listen_addr`, paths) visible in one file  
2. **`group_vars/quicknotes_vms/`** — host-group overrides if inventory grows  
3. **Extra vars (`-e`)** — one-off overrides for Task 2 demo (`listen_addr` tweak) without editing the playbook

**d) `gather_facts: true` default — need it here?**

No. This playbook uses only explicit variables and static paths — no `ansible_distribution` or package facts. `gather_facts: false` skips the fact-gathering SSH round-trip (~1–2 s per host).

---

## Task 2 — Idempotency + selective re-run

### Second run (`changed=0`)

```text
<!-- paste PLAY RECAP -->
```

### Variable tweak (`listen_addr` → `:9090`)

```text
<!-- paste PLAY RECAP showing template changed + handler -->
```

### `--check --diff` preview

```text
<!-- paste diff output -->
```

### Design questions (Task 2)

**e) Why `changed=0` on second run?**

`copy` compares checksums; `template` compares rendered content; `file` checks path/mode/owner. If all match desired state, Ansible reports `ok` not `changed`.

**f) `shell: echo ... > unit file` instead of `template:`?**

Every run would rewrite the file (or need manual idempotency guards). Handlers wouldn't fire reliably; drift is invisible; partial failures leave a broken unit. `template` + `notify` is declarative.

**g) `--check` vs `--check --diff`?**

`--check` says *whether* something would change. `--diff` shows *what* would change (e.g. `ADDR=:9090` in the unit). You catch wrong variable values before applying.

---

## Bonus — `ansible-pull` GitOps loop

```text
<!-- TODO: systemd timer + convergence timeline -->
```

**h) Security benefit of pull vs push?**

Pull mode: VM initiates outbound HTTPS to Git — no inbound SSH from a control node, smaller attack surface, works behind NAT.

**i) Kubernetes equivalent?**

**GitOps** tools like **Argo CD** or **Flux** — cluster pulls desired state from Git and reconciles. `ansible-pull` + systemd timer is the same loop at VM scale.

---

## Lab 7 completion checklist

### Task 1 (6 pts)

- [ ] Playbook deploys to Lab 5 VM
- [ ] `curl :18080/health` works
- [ ] First-run PLAY RECAP captured
- [ ] Design questions a–d answered

### Task 2 (4 pts)

- [ ] Second run `changed=0`
- [ ] Variable tweak + handler demo
- [ ] `--check --diff` captured
- [ ] Design questions e–g answered

### Bonus (2 pts)

- [ ] ansible-pull timer active
- [ ] Push → VM converges ≤ 5 min
- [ ] Design questions h–i answered

### Submission

- [ ] Course PR (`feature/lab7` → `inno-devops-labs/main`)
- [ ] Fork PR (`feature/lab7-fork` → `selysecr332/main`)
- [ ] Moodle URLs
