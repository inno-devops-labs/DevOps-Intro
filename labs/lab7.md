# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

![difficulty](https://img.shields.io/badge/difficulty-intermediate-yellow)
![topic](https://img.shields.io/badge/topic-Config%20Management-blue)
![points](https://img.shields.io/badge/points-10%2B2-orange)
![tech](https://img.shields.io/badge/tech-Ansible%2010.x-informational)

> **Goal:** Write an Ansible playbook that deploys QuickNotes to your Lab 5 VirtualBox VM. Prove idempotency. Bonus: wire `ansible-pull` so the VM auto-converges from your Git repo every 5 minutes.
> **Deliverable:** A PR from `feature/lab7` to the course repo with `ansible/` + `submissions/lab7.md`. Submit the PR link via Moodle.

---

## Overview

This is the lab that proves cattle-vs-pets in practice. By the end:
- An `ansible/playbook.yaml` deploys QuickNotes to your Lab 5 VM
- Re-running the playbook against the same VM produces `changed=0` (idempotency)
- Editing one variable causes **only** the affected handler to fire
- *(Bonus)* The VM pulls config from your Git repo via a systemd timer

You write the playbook from requirements. No copy-paste YAML in this spec.

---

## Project State

**Starting point:** Lab 5 VM exists; `vagrant up` works. QuickNotes runs locally.

**After this lab:** `ansible-playbook -i ... ansible/playbook.yaml` is the one command that produces a running QuickNotes service on the VM.

---

## Prerequisites

- Lab 5 VM running (`vagrant up`)
- Ansible **10.x** on your host (`ansible --version` — needs Python 3.11+)
- A pre-built static QuickNotes binary you'll ship to the VM (build with `CGO_ENABLED=0 go build` in `app/`)

---

## Task 1 — Idempotent Deploy to the Lab 5 VM (6 pts)

### 1.1: Layout

You will produce, at minimum, this layout in your fork:

```text
ansible/
├── inventory.ini          (or .yaml)
├── playbook.yaml
├── files/
│   ├── quicknotes         (the static binary)
│   └── seed.json          (copy of app/seed.json — shipped to the VM)
└── templates/
    └── quicknotes.service.j2
```

### 1.2: Playbook requirements

Your playbook MUST, deploying as `root` (via `become: true`) on the Lab 5 VM:

1. **Create a system user** `quicknotes` (no login shell, no interactive home)
2. **Ensure a data directory** at `/var/lib/quicknotes`, owned by `quicknotes:quicknotes`, mode `0750`
3. **Copy the QuickNotes binary** to `/usr/local/bin/quicknotes`, mode `0755`
4. **Copy `seed.json`** to `/var/lib/quicknotes/seed.json`, owned `quicknotes:quicknotes`, mode `0640` — this is the file your `SEED_PATH` variable must point at
5. **Render a systemd unit** to `/etc/systemd/system/quicknotes.service` from a Jinja2 template — values must be **variables** (so changing them in the play changes the deployed unit)
6. **Reload systemd**, **enable** the service, **start** it
7. Use a **handler** to restart the service whenever the binary OR the unit file changes — and *only* then

### 1.3: Inventory requirements

- Target the Lab 5 VM via the IP + port + SSH key Vagrant uses
- `vagrant ssh-config` prints exactly what you need
- Use the `vagrant` user with the Vagrant-generated insecure key

### 1.4: Systemd unit template requirements

The Jinja template produces a unit file that:
- Starts QuickNotes after `network-online.target`
- Restarts on failure with a short backoff
- Runs as the `quicknotes` user, not root
- Sets `ADDR`, `DATA_PATH`, `SEED_PATH` env vars from playbook variables
- Sets `WorkingDirectory` to the data dir

### 1.5: Design questions — answer in your submission

- a) **What's the difference between `command:` and the dedicated modules** (`apt`, `file`, `copy`, `systemd`)? Which is idempotent, and why does it matter?
- b) **`notify:` and handlers:** when does a handler fire? When does it *not* fire? Why is that the right default?
- c) **Variable hierarchy:** Ansible has at least 22 levels of variable precedence. List the top 3 places you'd put a variable for this lab (defaults, group_vars, playbook vars, …) and why
- d) **`gather_facts: true` is the default.** Do you need it for *this* playbook? What does turning it off save you per run?

### 1.6: Where to start

- 📖 [Ansible — User Guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- 📖 [Module index — alphabetical](https://docs.ansible.com/ansible/latest/collections/index_module.html). You'll need: `user`, `file`, `copy`, `template`, `systemd`
- 📖 [Jinja2 templating](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html)
- 📖 [Ansible — Handlers](https://docs.ansible.com/ansible/latest/user_guide/playbooks_handlers.html)
- 📖 [Vagrant — Ansible provisioner notes on inventory](https://developer.hashicorp.com/vagrant/docs/provisioning/ansible_intro)

### 1.7: Run + verify

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check    # dry-run
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml            # real run

# from your host:
curl -s http://localhost:18080/health   # via Vagrant port forward
curl -s http://localhost:18080/notes    # MUST return the seeded notes, not []
```

> ⚠️ If `/notes` returns `[]`, your seed never reached the VM — the app silently falls back to an empty store when the file at `SEED_PATH` doesn't exist. See Common Pitfalls.

### 1.8: Document

In `submissions/lab7.md`:
- Your `playbook.yaml`, `inventory.ini`, and template (paste or link)
- Full PLAY RECAP from the first run (showing tasks `changed`)
- `curl` output proving the service is reachable **and** `/notes` output proving the seed data is served
- Written answers to all 4 design questions in 1.5

---

## Task 2 — Prove Idempotency + Selective Re-run (4 pts)

### 2.1: Required demonstrations

1. **Re-run = zero changes.** Run the playbook a second time without changing anything. Capture the PLAY RECAP — it should show `changed=0`
2. **Variable tweak = selective change.** Edit *one* variable that affects the template (e.g., `listen_addr` from `:8080` to `:9090`). Re-run. The PLAY RECAP must show:
   - The `template` task: `changed=1`
   - The `restart quicknotes` handler: invoked
   - Other tasks: `ok` (no change)
3. **`--check --diff`** preview. Make a *third* variable change. Run with `--check --diff` and capture an example diff

### 2.2: Design questions

- e) **Why does the second run report `changed=0`?** What specifically does the `file` / `template` module check to decide?
- f) **What would happen if you used `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` instead of the `template:` module?** Trace the failure modes
- g) **`ansible-playbook --check`** is dry-run. **`--diff`** shows changes. What's the bug you'd catch by running `--check --diff` before a production deploy that you'd miss with plain `--check`?

### 2.3: Document

In `submissions/lab7.md`:
- `changed=0` second-run PLAY RECAP
- `changed=1` (template only) + handler-fired PLAY RECAP
- `--check --diff` example
- Design questions e, f, g answered

---

## Bonus Task — `ansible-pull` GitOps Loop (2 pts)

### B.1: Goal

Make the VM **auto-converge** from your Git repo via a systemd timer. After this:
- You push a change to `playbook.yaml` on your fork
- Within ≤ 5 minutes, the VM has reconciled to the new state
- No `ansible-playbook` from your host needed

### B.2: Requirements

Inside the VM, install + configure:

1. **Ansible** (the package the VM's distro ships) + Git
2. A **local inventory** that targets `127.0.0.1` via `ansible_connection=local` (the VM is reconciling itself)
3. A **systemd service unit** that runs `ansible-pull -U <your fork URL> -C <your branch> -i <local inventory> ansible/playbook.yaml`
4. A **systemd timer** that fires the service every 5 minutes (`OnUnitActiveSec=5min`, also `OnBootSec=1min`)
5. Enable + start the timer

### B.3: Demonstrate convergence

From your host:
1. Edit `playbook.yaml` (e.g., change `listen_addr`)
2. Commit + push to your fork's `feature/lab7`
3. Record the commit timestamp
4. Wait for the next timer fire (≤ 5 minutes)
5. SSH into the VM, confirm the change reconciled

### B.4: Design questions

- h) **`ansible-pull` is "pull" mode. What's the security benefit** vs the "push" model where a control node SSHes in?
- i) **What's the same pattern called when applied at the Kubernetes layer?** (Hint: Lecture 7 mentioned an industry-standard tool by name.) Why is `ansible-pull` a fair simulator at the VM layer?

### B.5: Document

In `submissions/lab7.md`:
- **The artifacts themselves** — this is the graded core of the bonus:
  - the `ansible-pull.service` and `ansible-pull.timer` unit files (paste contents), **and** the local inventory
  - *or*, if you automated the setup (recommended), the Ansible tasks/templates that install them — in that case those files live in `ansible/` in your PR and you link to them
- `systemctl list-timers | grep ansible-pull` output
- A `journalctl -u ansible-pull.service` excerpt from one successful pull run
- Timeline of: git commit timestamp → next timer fire → state reconciled in VM
- Design questions h, i answered

> ⚠️ **Logs alone earn no bonus points.** Timer output, journal excerpts, and timelines are *evidence* — the graded deliverable is the unit files / inventory / automation that produce them. A submission without those files gets 0 for the bonus regardless of the logs attached.

---

## How to Submit

1. `ansible/` directory in your fork with playbook, inventory template, files, templates
2. `submissions/lab7.md` covers all attempted tasks
3. PR from `feature/lab7` → course repo's `main`
4. Submit the PR URL via Moodle

---

## Acceptance Criteria

### Task 1 (6 pts)
- ✅ Playbook deploys QuickNotes to the Vagrant VM
- ✅ Service is `active (running)`; `curl :18080/health` works
- ✅ `curl :18080/notes` returns the seeded notes (not `[]`) — proves `seed.json` was shipped and `SEED_PATH` is correct
- ✅ Full PLAY RECAP captured
- ✅ All 4 design questions answered

### Task 2 (4 pts)
- ✅ Second run shows `changed=0`
- ✅ Variable tweak fires only the affected handler
- ✅ `--check --diff` example captured
- ✅ Design questions e, f, g answered

### Bonus Task (2 pts)
- ✅ `ansible-pull` service + timer unit files and local inventory in the submission (pasted, or as Ansible automation in the PR)
- ✅ Systemd timer installed and active
- ✅ Push-to-Git → VM reconciled within 5 min observed
- ✅ Design questions h, i answered

---

## Rubric

| Task | Points | Criteria |
|------|-------:|----------|
| **Task 1** — Idempotent Ansible deploy | **6** | Playbook works, service runs, recap + design questions |
| **Task 2** — Idempotency + handler logic | **4** | `changed=0`, selective change, --diff, design questions |
| **Bonus** — `ansible-pull` GitOps loop | **2** | Unit files/inventory in PR, timer active, convergence demoed, design questions |
| **Total** | **10 + 2 bonus** | |

---

## Common Pitfalls

- 🪤 **SSH connection refused** — `vagrant ssh-config` prints the exact key path and port; copy it into your inventory
- 🪤 **`shell:` everywhere instead of dedicated modules** — kills idempotency. Reserve `shell:` / `command:` for absolute last resorts
- 🪤 **`become: true` missing** — most tasks need sudo. Either set on the play or per-task
- 🪤 **`changed=1` every run for the same template** — file mode / owner mismatch. Run with `--diff` to see what differs
- 🪤 **Handler not firing** — `notify:` looks up handlers *by name*; typos silently disable them
- 🪤 **`/health` OK but `/notes` returns `[]`** — you set `SEED_PATH` but never copied `seed.json` to the VM. The app doesn't crash on a missing seed; it silently starts with an empty store. Also note: seeding runs only when the data file doesn't exist yet — after fixing the seed, delete the file at `DATA_PATH` on the VM and restart the service
- 🪤 **`ansible-pull` URL wrong** — must be an HTTPS clone URL the VM can reach (private repo → needs an access token)
- 🪤 **VM Python missing** — old boxes ship without Python; use `raw: apt install -y python3` as a bootstrap task

---

## Guidelines

- The skill of this lab is **writing idempotent Ansible**. If you find yourself reaching for `shell:`, stop and look for a module that does it
- `--check --diff` before every production deploy is professional hygiene — treat it that way in this lab too
- The bonus is the "GitOps preview" — the same conceptual pattern as ArgoCD/Flux, scaled down

---

## Resources

- 📖 [Ansible User Guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- 📖 [Module index](https://docs.ansible.com/ansible/latest/collections/index_module.html)
- 📕 *Ansible Up & Running* — Lorin Hochstein & René Moser (3rd ed)
- 📗 *Ansible for DevOps* — Jeff Geerling
- 📖 [`ansible-pull` reference](https://docs.ansible.com/ansible/latest/cli/ansible-pull.html)
- 📖 [Variable precedence — exhaustive list](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#understanding-variable-precedence)
- 🛠️ `ansible-lint`
