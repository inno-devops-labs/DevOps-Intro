# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

## Task 1 — Idempotent Deploy

### ansible/inventory.ini

```ini
[quicknotes]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### ansible/playbook.yaml

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true
  vars:
    quicknotes_user: quicknotes
    data_dir: /var/lib/quicknotes
    listen_addr: ":8080"
    seed_path: /usr/local/share/quicknotes/seed.json

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
        daemon_reload: true

  tasks:
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false

    - name: Ensure data directory
      ansible.builtin.file:
        path: "{{ data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0750"

    - name: Ensure seed directory
      ansible.builtin.file:
        path: /usr/local/share/quicknotes
        state: directory
        owner: root
        group: root
        mode: "0755"

    - name: Copy seed.json
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ seed_path }}"
        mode: "0644"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: /usr/local/bin/quicknotes
        mode: "0755"
        owner: root
        group: root
      notify: restart quicknotes

    - name: Render systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        mode: "0644"
      notify: restart quicknotes

    - name: Enable and start quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        enabled: true
        state: started
        daemon_reload: true

- name: Bootstrap ansible-pull GitOps timer
  hosts: quicknotes
  become: true
  vars:
    fork_url: "https://github.com/Ten-Do/DevOps-Intro.git"
    branch: feature/lab7

  tasks:
    - name: Install ansible and git
      ansible.builtin.apt:
        name: [ansible, git]
        state: present
        update_cache: true

    - name: Ensure /etc/ansible directory exists
      ansible.builtin.file:
        path: /etc/ansible
        state: directory
        owner: root
        group: root
        mode: "0755"

    - name: Write local inventory
      ansible.builtin.copy:
        dest: /etc/ansible/local-inventory.ini
        content: |
          [quicknotes]
          127.0.0.1 ansible_connection=local
        mode: "0644"

    - name: Write ansible-pull service unit
      ansible.builtin.copy:
        dest: /etc/systemd/system/ansible-pull.service
        content: |
          [Unit]
          Description=ansible-pull convergence run

          [Service]
          Type=oneshot
          ExecStart=/usr/bin/ansible-pull \
            -U {{ fork_url }} \
            -C {{ branch }} \
            -i /etc/ansible/local-inventory.ini \
            ansible/playbook.yaml
          StandardOutput=journal
          StandardError=journal
        mode: "0644"
      notify: reload systemd

    - name: Write ansible-pull timer unit
      ansible.builtin.copy:
        dest: /etc/systemd/system/ansible-pull.timer
        content: |
          [Unit]
          Description=Run ansible-pull every 5 minutes

          [Timer]
          OnBootSec=1min
          OnUnitActiveSec=5min

          [Install]
          WantedBy=timers.target
        mode: "0644"
      notify: reload systemd

    - name: Enable and start ansible-pull timer
      ansible.builtin.systemd:
        name: ansible-pull.timer
        enabled: true
        state: started
        daemon_reload: true

  handlers:
    - name: reload systemd
      ansible.builtin.systemd:
        daemon_reload: true
```

### ansible/templates/quicknotes.service.j2

```jinja2
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ quicknotes_user }}
WorkingDirectory={{ data_dir }}
ExecStart=/usr/local/bin/quicknotes
Environment="ADDR={{ listen_addr }}"
Environment="DATA_PATH={{ data_dir }}/notes.json"
Environment="SEED_PATH={{ seed_path }}"
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
```

### First-run PLAY RECAP

```
TASK [Create quicknotes system user] *** changed: [quicknotes-vm]
TASK [Ensure data directory] *** changed: [quicknotes-vm]
TASK [Ensure seed directory] *** changed: [quicknotes-vm]
TASK [Copy seed.json] *** changed: [quicknotes-vm]
TASK [Copy QuickNotes binary] *** changed: [quicknotes-vm]
TASK [Render systemd unit] *** changed: [quicknotes-vm]
TASK [Enable and start quicknotes] *** changed: [quicknotes-vm]
RUNNING HANDLER [restart quicknotes] *** changed: [quicknotes-vm]
TASK [Install ansible and git] *** changed: [quicknotes-vm]
TASK [Ensure /etc/ansible directory exists] *** changed: [quicknotes-vm]
TASK [Write local inventory] *** changed: [quicknotes-vm]
TASK [Write ansible-pull service unit] *** changed: [quicknotes-vm]
TASK [Write ansible-pull timer unit] *** changed: [quicknotes-vm]
TASK [Enable and start ansible-pull timer] *** changed: [quicknotes-vm]

PLAY RECAP
quicknotes-vm : ok=17  changed=14  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

### curl health check

```
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

### Design questions (Task 1.5)

**a) `command:` vs dedicated modules — idempotency**

`command:` / `shell:` always reports `changed` and always re-runs because Ansible has no way to know whether the side-effect already happened. Dedicated modules (`apt`, `file`, `copy`, `template`, `systemd`, `user`) query current state first and only act when there is a divergence from the desired state. That makes them idempotent: re-running produces `changed=0` if the system is already correct, which is the whole point of configuration management — safe, repeatable runs.

**b) `notify:` and handlers — when they fire**

A handler fires at the end of the play, once, if at least one task that has `notify: <name>` reported `changed`. It does *not* fire if every notifying task was `ok`. The right default: you restart a service only when something about it actually changed. Running `systemctl restart` unconditionally on every playbook run would cause needless downtime and mask real state drift.

**c) Variable precedence — top 3 placement choices**

1. **`vars:` in the play** — used here; highest practical precedence, good for per-play values that are always visible in the playbook file.
2. **`group_vars/quicknotes.yaml`** — the right home for environment-specific values (staging vs. prod hosts use different addresses) without cluttering the playbook.
3. **`defaults/main.yaml` (role defaults)** — lowest precedence, the "document the interface" layer; any other source overrides it. Used when packaging the play as a reusable role.

**d) `gather_facts: true` — do we need it?**

Not strictly for this playbook; no `ansible_*` facts are referenced. Turning it off (`gather_facts: false`) skips the implicit *Gathering Facts* task, saving roughly 1–3 seconds per host per run. Useful in large inventories or when iteration speed matters. The downside: modules that implicitly depend on facts (e.g., OS-conditional tasks) would break.

---

## Task 2 — Idempotency + Selective Re-run

### Second run — `changed=0`

```
PLAY RECAP
quicknotes-vm : ok=15  changed=0  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

### Variable tweak — `listen_addr: ":9090"` — template + handler only

```
TASK [Render systemd unit] *** changed: [quicknotes-vm]
RUNNING HANDLER [restart quicknotes] *** changed: [quicknotes-vm]

PLAY RECAP
quicknotes-vm : ok=16  changed=2  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

All other tasks reported `ok` — the binary, user, dirs, seed file and timer were untouched.

### `--check --diff` preview (reverting `listen_addr` back to `:8080`)

```
TASK [Render systemd unit]
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/tend/.ansible/tmp/.../quicknotes.service.j2
@@ -8,7 +8,7 @@
 User=quicknotes
 WorkingDirectory=/var/lib/quicknotes
 ExecStart=/usr/local/bin/quicknotes
-Environment="ADDR=:9090"
+Environment="ADDR=:8080"
 Environment="DATA_PATH=/var/lib/quicknotes/notes.json"
 Environment="SEED_PATH=/usr/local/share/quicknotes/seed.json"
 Restart=on-failure

changed: [quicknotes-vm]

PLAY RECAP
quicknotes-vm : ok=16  changed=2  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

No change was applied to the VM.

### Design questions (Task 2.2)

**e) Why does the second run report `changed=0`?**

Each dedicated module reads the actual on-disk or in-memory state and compares it to the desired state. `file` checks owner, group, and mode via `stat`. `copy` computes a checksum of the source and compares it to the remote file. `template` renders the Jinja2 template and does the same checksum comparison. `user` calls `getpwnam`. `systemd` inspects the unit's enabled/active state. All match, so no task fires.

**f) What if `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` were used?**

`shell:` always reports `changed` regardless of outcome, so every run would overwrite the file and fire the restart handler — causing unnecessary service restarts. Worse, the shell expansion happens on the control node, so the quoting must survive two shells and a Python subprocess — a fragile pipeline. There is no diff, no dry-run preview, and no checksum guard. The approach also collapses the entire unit into one unreadable task.

**g) Bug caught by `--check --diff` but not plain `--check`**

`--check` only tells you *which* tasks would change; `--diff` shows *what* would change. A template might report `changed` in both modes, but only `--diff` reveals that the `ExecStart` path changed from `/usr/local/bin/quicknotes` to `/usr/bin/quicknotes` — perhaps because a variable wasn't overridden correctly for this environment. Plain `--check` would confirm a restart is coming; `--diff` tells you *why* it's coming, letting you catch a misconfigured variable before it hits production.

---

## Bonus — `ansible-pull` GitOps Loop

### `systemctl list-timers | grep ansible-pull`

```
Tue 2026-06-30 16:38:50 UTC  4min 28s left  Tue 2026-06-30 16:33:50 UTC  31s ago  ansible-pull.timer  ansible-pull.service
```

### Convergence timeline

| Event | Time (UTC) |
|---|---|
| `git push` — `RestartSec=3s` committed | 16:33:06 |
| Timer fires | 16:33:44 |
| `ansible-pull.service` starts | 16:33:50 |
| VM reconciled — `grep RestartSec` returns `3s` | 16:34:09 |

Total time from push to reconciled: **63 seconds** (well under the 5-minute SLA).

### Design questions (Bonus B.4)

**h) Security benefit of `ansible-pull` vs push**

In push mode, the control node needs SSH access to every managed host. A compromised control node can reach all hosts simultaneously. In pull mode, each host reaches out only to a Git repository over HTTPS. The control node has no inbound access to the managed hosts; a compromised host affects only itself. The attack surface of a push-mode control node is proportional to fleet size; a pull-mode host's blast radius is exactly one machine.

**i) Same pattern at the Kubernetes layer**

GitOps at the Kubernetes layer is called **continuous delivery via a GitOps operator**, and the industry-standard tools are **ArgoCD** and **Flux**. Both continuously reconcile a cluster's live state against a Git repository, exactly as `ansible-pull` does for a VM. `ansible-pull` is a fair VM-layer simulator of this pattern: the Git repo is the source of truth, the managed node polls it on a timer, and every converging run is idempotent.
