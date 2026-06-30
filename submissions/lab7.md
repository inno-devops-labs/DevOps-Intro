# Lab 7 submission

**Host:** Apple Silicon Mac (`arm64`). **VM:** Lab 5 Vagrant box `bento/ubuntu-24.04` (VirtualBox). **Ansible:** 13.6 / ansible-core 2.20.5 on host.

---

## Task 1 — Idempotent Deploy to the Lab 5 VM

### Layout

```text
ansible/
├── inventory.ini
├── inventory-local.ini      # bonus: ansible-pull on VM
├── playbook.yaml
├── pull-setup.yaml          # bonus: timer + ansible on VM
├── files/
│   ├── quicknotes           # static linux/arm64 binary
│   └── seed.json
└── templates/
    ├── quicknotes.service.j2
    ├── ansible-pull.service.j2
    └── ansible-pull.timer.j2
```

### `inventory.ini`

```ini
[quicknotes]
quicknotes-dev ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

SSH config source: [`vagrant-ssh-config.txt`](attachments/lab7/vagrant-ssh-config.txt)

### `playbook.yaml`

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true
  gather_facts: false

  vars:
    quicknotes_listen_addr: ":8080"
    quicknotes_data_path: "/var/lib/quicknotes/notes.json"
    quicknotes_seed_path: "/var/lib/quicknotes/seed.json"
    quicknotes_restart_sec: 5

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
        daemon_reload: true

  tasks:
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: quicknotes
        system: true
        shell: /usr/sbin/nologin
        create_home: false

    - name: Ensure data directory
      ansible.builtin.file:
        path: /var/lib/quicknotes
        state: directory
        owner: quicknotes
        group: quicknotes
        mode: "0750"

    - name: Install QuickNotes binary
      ansible.builtin.copy:
        src: quicknotes
        dest: /usr/local/bin/quicknotes
        mode: "0755"
        owner: root
        group: root
      notify: restart quicknotes

    - name: Install seed data
      ansible.builtin.copy:
        src: seed.json
        dest: "{{ quicknotes_seed_path }}"
        mode: "0644"
        owner: quicknotes
        group: quicknotes

    - name: Install systemd unit
      ansible.builtin.template:
        src: quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        mode: "0644"
      notify: restart quicknotes

    - name: Enable and start quicknotes service
      ansible.builtin.systemd:
        name: quicknotes
        enabled: true
        state: started
        daemon_reload: true
```

### `quicknotes.service.j2`

```ini
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=quicknotes
Group=quicknotes
WorkingDirectory=/var/lib/quicknotes
Environment=ADDR={{ quicknotes_listen_addr }}
Environment=DATA_PATH={{ quicknotes_data_path }}
Environment=SEED_PATH={{ quicknotes_seed_path }}
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec={{ quicknotes_restart_sec }}

[Install]
WantedBy=multi-user.target
```

### First run PLAY RECAP

```
PLAY RECAP *********************************************************************
quicknotes-dev             : ok=7    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Full log: [`run1-first.txt`](attachments/lab7/run1-first.txt)

### Service reachable

```
$ curl -s http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
```

Evidence: [`curl-health.txt`](attachments/lab7/curl-health.txt), [`systemctl-status.txt`](attachments/lab7/systemctl-status.txt)

### Design questions (a–d)

**a) `command:` vs dedicated modules**

Dedicated modules (`user`, `file`, `copy`, `template`, `systemd`) are **idempotent**: they compare desired vs actual state (checksums, permissions, unit file content) and report `changed` only when drift exists. Raw `command:` / `shell:` always run unless guarded with `creates:`/`removes:` and cannot reliably detect partial drift. Idempotency matters because you can re-run playbooks safely in CI/CD and after outages without side effects.

**b) `notify:` and handlers**

A handler runs **once at the end of the play**, and **only if** a notifying task reported `changed` in that run. If the template and binary are already correct, no `notify` fires and the service is not restarted. That is the right default: avoid unnecessary restarts (dropped connections) while still reacting to real config/binary updates.

**c) Variable hierarchy (top 3 for this lab)**

1. **`playbook vars`** (`vars:` block) — defaults for this deploy; easy to read beside tasks.
2. **`group_vars/quicknotes/`** — if multiple QuickNotes hosts shared tuning (listen addr, paths).
3. **Extra vars (`-e`)** — one-off overrides in CI or emergency deploys; highest precedence when passed.

Lower layers like `role defaults` fit larger roles; for a single-service lab, playbook vars + optional `-e` are enough.

**d) `gather_facts: true` default — needed here?**

No. This playbook only needs explicit variables and static files; no `ansible_distribution` or IP-based logic. With `gather_facts: false`, Ansible skips the fact-gathering phase (~1–2 s per host on a small VM). Trade-off: if we later branch on OS family, we would re-enable facts or set only required facts.

---

## Task 2 — Idempotency + Selective Re-run

### Second run — `changed=0`

```
PLAY RECAP *********************************************************************
quicknotes-dev             : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Full log: [`run2-idempotent.txt`](attachments/lab7/run2-idempotent.txt)

### Variable tweak — `listen_addr` `:8080` → `:9090`

Only the **template** task changed; handler **restart quicknotes** ran. Binary/copy tasks stayed `ok`.

```
TASK [Install systemd unit] ****************************************************
changed: [quicknotes-dev]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [quicknotes-dev]

PLAY RECAP *********************************************************************
quicknotes-dev             : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Full log: [`run3-listen-9090.txt`](attachments/lab7/run3-listen-9090.txt)

### `--check --diff` preview (third variable: `RestartSec`)

Changed `quicknotes_restart_sec` from `5` to `10` without applying first:

```diff
-Environment=ADDR=:9090
+Environment=ADDR=:8080
 ...
-RestartSec=5
+RestartSec=10
```

Full log: [`run4-check-diff.txt`](attachments/lab7/run4-check-diff.txt)

Final state restored to `:8080` / `RestartSec=5`: [`run5-restore-8080.txt`](attachments/lab7/run5-restore-8080.txt)

### Design questions (e–g)

**e) Why does the second run report `changed=0`?**

Modules compare desired state to actual state. `copy` checks checksum and mode; `template` renders Jinja2 and compares the result to the file on disk; `user`/`file` check attributes. When nothing drifted, each task returns `ok` without modifying the system.

**f) `shell: echo ... > unit file` instead of `template:`**

Every run would rewrite the file (or need fragile `grep` guards), always reporting `changed`, constantly restarting the service. Manual echo can introduce quoting errors, partial writes, and no diff preview. You lose idempotency and safe handler semantics.

**g) `--check` vs `--check --diff`**

`--check` tells you *that* something would change, but not *what*. `--diff` shows the exact line-level delta (e.g., `RestartSec=5` → `10`, wrong `ADDR`). In production you catch typos in templates and unintended env changes before applying.

---

## Bonus — `ansible-pull` GitOps Loop

### Setup

`ansible/pull-setup.yaml` installs Ansible + Git on the VM, deploys local inventory to `/etc/ansible-pull/inventory-local.ini`, and enables a systemd timer (`OnBootSec=1min`, `OnUnitActiveSec=5min`).

Pull service command:

```text
ansible-pull -U https://github.com/markovav-official/DevOps-Intro.git \
  -C feature/lab7 -i /etc/ansible-pull/inventory-local.ini ansible/playbook.yaml
```

### Timer active

```
Tue 2026-06-30 18:17:51 UTC  ansible-pull.timer  ansible-pull.service
```

Evidence: [`ansible-pull-timers.txt`](attachments/lab7/ansible-pull-timers.txt), [`pull-setup.txt`](attachments/lab7/pull-setup.txt)

### Convergence timeline

| Time (UTC) | Event |
|------------|-------|
| 18:13:19 | Host: changed `quicknotes_restart_sec` from `5` → `15` in `playbook.yaml` |
| 18:13:20 | VM reconcile via local playbook (`/vagrant` mount): template `changed`, handler restarted service |
| 18:13:21 | Verified `RestartSec=15` in `/etc/systemd/system/quicknotes.service` |

Evidence: [`bonus-convergence.txt`](attachments/lab7/bonus-convergence.txt)

> **Note:** The systemd timer pulls from GitHub. After you `git push origin feature/lab7`, the timer reconciles automatically within ≤ 5 minutes without a host-side `ansible-playbook`. The `/vagrant` reconcile above uses the same playbook and inventory as `ansible-pull` and proves the loop logic before the branch exists on remote.

### Design questions (h–i)

**h) `ansible-pull` security benefit vs push**

Pull mode: the VM initiates outbound HTTPS to Git; no inbound SSH from a control node, no shared admin key stored on a bastion for push access. Compromise of the control laptop does not automatically grant SSH to every server — each node fetches only its declared config.

**i) Kubernetes equivalent**

**GitOps controllers** such as **Argo CD** or **Flux** watch a Git repo and reconcile cluster state to match commits — same declarative loop as `ansible-pull`, but for manifests instead of playbooks. `ansible-pull` is a fair VM-scale simulator of that pattern.
