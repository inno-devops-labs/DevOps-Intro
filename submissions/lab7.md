# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + WSL Ansible 2.16.3 + Lab 5 Vagrant VM (`quicknotes-lab5`)

---

## Task 1 — Idempotent deploy to Lab 5 VM

### Layout

```text
ansible/
├── inventory.ini
├── inventory.local.ini
├── playbook.yaml
├── files/
│   ├── quicknotes
│   └── seed.json
└── templates/
    ├── quicknotes.service.j2
    ├── ansible-pull.service.j2
    └── ansible-pull.timer.j2
```

### `playbook.yaml` / `inventory.ini` / template

See [`ansible/`](../ansible/) directory.

### First run PLAY RECAP

```text
PLAY [Deploy QuickNotes to Lab 5 VM] *******************************************************************

TASK [Ensure quicknotes system user exists] ************************************************************
changed: [lab5-vm]

TASK [Ensure data directory exists] ********************************************************************
changed: [lab5-vm]

TASK [Install QuickNotes binary] ***********************************************************************
changed: [lab5-vm]

TASK [Install seed data file] **************************************************************************
changed: [lab5-vm]

TASK [Install systemd unit] ****************************************************************************
changed: [lab5-vm]

TASK [Enable and start QuickNotes service] *************************************************************
changed: [lab5-vm]

RUNNING HANDLER [restart quicknotes] *******************************************************************
changed: [lab5-vm]

PLAY RECAP *********************************************************************************************
lab5-vm                    : ok=7    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Health check from host

```powershell
PS> Invoke-RestMethod http://127.0.0.1:18080/health

notes status
----- ------
    4 ok
```

Screenshot: [`submissions/screenshots/lab_7.png`](screenshots/lab_7.png)

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
PLAY RECAP *********************************************************************
lab5-vm                    : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Variable tweak (`listen_addr` → `:9090`)

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml -e quicknotes_listen_addr=:9090
```

```text
TASK [Install systemd unit] ****************************************************
changed: [lab5-vm]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [lab5-vm]

PLAY RECAP *********************************************************************
lab5-vm                    : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### `--check --diff` preview

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml -e quicknotes_listen_addr=:8080 --check --diff
```

```diff
--- before: /etc/systemd/system/quicknotes.service
+++ after: .../quicknotes.service.j2
@@ -8,7 +8,7 @@
-Environment=ADDR=:9090
+Environment=ADDR=:8080
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

### Added files

```text
ansible/
├── inventory.local.ini          # local connection for pull on VM
└── templates/
    ├── ansible-pull.service.j2
    └── ansible-pull.timer.j2
```

Playbook vars: `ansible_pull_repo_url`, `ansible_pull_branch`, `ansible_pull_checkout_dir`.

### `systemctl list-timers | grep ansible-pull`

```text
Wed 2026-06-24 23:02:39 UTC 3min 31s left  Wed 2026-06-24 22:55:17 UTC 3min 50s ago ansible-pull.timer  ansible-pull.service
```

Timer is `active`; service unit runs `ansible-pull -U https://github.com/selysecr332/DevOps-Intro.git -C feature/lab7`.

### Convergence timeline (`listen_addr` :8080 → :9191)

| Event | Timestamp (UTC) |
|-------|-----------------|
| Git commit + push `761551e` (`quicknotes_listen_addr: ":9191"`) | **2026-06-24 23:38:29** |
| Next timer fire (`ansible-pull.service` started) | **2026-06-24 23:38:48** |
| VM reconciled (`changed=2`, template + handler) | **2026-06-24 23:39:36** |

Verified on VM after timer (no manual `ansible-playbook` from host):

```text
$ grep ADDR /etc/systemd/system/quicknotes.service
Environment=ADDR=:9191
```

Journal excerpt:

```text
2026-06-24T23:39:36 quicknotes-vm ansible-pull[11038]: 127.0.0.1 : ok=12 changed=2 ...
2026-06-24T23:39:36 quicknotes-vm systemd[1]: Finished GitOps reconcile QuickNotes via ansible-pull.
```

**Elapsed push → reconcile: ~67 seconds** (next 5-minute timer window).

**h) Security benefit of pull vs push?**

Pull mode: VM initiates outbound HTTPS to Git — no inbound SSH from a control node, smaller attack surface, works behind NAT.

**i) Kubernetes equivalent?**

**GitOps** tools like **Argo CD** or **Flux** — cluster pulls desired state from Git and reconciles. `ansible-pull` + systemd timer is the same loop at VM scale.

---

## Lab 7 completion checklist

### Task 1 (6 pts)

- [x] Playbook deploys to Lab 5 VM
- [x] `curl :18080/health` works
- [x] First-run PLAY RECAP captured
- [x] Design questions a–d answered

### Task 2 (4 pts)

- [x] Second run `changed=0`
- [x] Variable tweak + handler demo
- [x] `--check --diff` captured
- [x] Design questions e–g answered

### Bonus (2 pts)

- [x] ansible-pull timer active
- [x] Push → VM converges ≤ 5 min
- [x] Design questions h–i answered

### Submission

- [x] Course PR (`feature/lab7` → `inno-devops-labs/main`)
- [x] Fork PR (`feature/lab7-fork` → `selysecr332/main`)
