# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

## Task 1 — Idempotent Deploy to the Lab 5 VM

### playbook.yaml

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_bin: /usr/local/bin/quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    listen_addr: ":8080"
    data_path: "/var/lib/quicknotes/notes.json"
    seed_path: "/var/lib/quicknotes/seed.json"

  tasks:
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false

    - name: Ensure data directory
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0750"

    - name: Copy seed file
      ansible.builtin.copy:
        src: ../../app/seed.json
        dest: "{{ seed_path }}"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0644"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ quicknotes_bin }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart quicknotes

    - name: Render systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: Restart quicknotes

    - name: Enable and start quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        enabled: true
        state: started
        daemon_reload: true

  handlers:
    - name: Restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
        daemon_reload: true
```

### inventory.ini

```ini
[quicknotes]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_private_key_file=.vagrant/machines/default/virtualbox/private_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### quicknotes.service.j2

```ini
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ quicknotes_user }}
Group={{ quicknotes_user }}
WorkingDirectory={{ quicknotes_data_dir }}
ExecStart={{ quicknotes_bin }}
Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ data_path }}
Environment=SEED_PATH={{ seed_path }}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### First run — PLAY RECAP

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] *******************************************************

TASK [Create quicknotes system user] *******************************************
changed: [quicknotes-vm]

TASK [Ensure data directory] ***************************************************
changed: [quicknotes-vm]

TASK [Copy seed file] **********************************************************
changed: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
changed: [quicknotes-vm]

TASK [Render systemd unit] *****************************************************
changed: [quicknotes-vm]

TASK [Enable and start quicknotes] *********************************************
changed: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=7    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### curl output

```
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

### Design Questions

**a) What's the difference between `command:` and dedicated modules?**

Dedicated modules like `file`, `copy`, `template`, and `systemd` are idempotent by design — they check current state and only make changes when the actual state differs from the desired state. `command:` and `shell:` always report `changed` because Ansible has no way to know whether the command modified anything. This matters because idempotency is the foundation of safe re-runs: you should be able to run the playbook 10 times and get the same result as running it once.

**b) `notify:` and handlers — when do they fire?**

A handler fires once at the end of the play, only if at least one task that `notify`-ed it reported `changed`. If the notifying task reports `ok` (no change), the handler does not fire. This is the right default because it avoids unnecessary restarts — restarting a service when nothing changed causes a brief outage for no reason.

**c) Variable hierarchy — top 3 places for this lab**

1. **Play-level `vars:`** — best for this lab because all values are specific to this single playbook and there is only one host group. Simple and visible.
2. **`group_vars/quicknotes.yml`** — appropriate when multiple playbooks target the same group and should share variables.
3. **`ansible-playbook -e`** (extra vars) — highest precedence, used for one-off overrides during testing or CI without editing files.

**d) `gather_facts: true` — do you need it?**

Not for this playbook. No tasks reference `ansible_*` facts (OS family, IP, memory, etc.). Disabling it with `gather_facts: false` saves 2–5 seconds per run by skipping the setup module that collects system information via SSH.

---

## Task 2 — Prove Idempotency + Selective Re-run

### Second run — changed=0

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] *******************************************************

TASK [Create quicknotes system user] *******************************************
ok: [quicknotes-vm]

TASK [Ensure data directory] ***************************************************
ok: [quicknotes-vm]

TASK [Copy seed file] **********************************************************
ok: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
ok: [quicknotes-vm]

TASK [Render systemd unit] *****************************************************
ok: [quicknotes-vm]

TASK [Enable and start quicknotes] *********************************************
ok: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Variable tweak — selective change

Changed `listen_addr` from `:8080` to `:9090`:

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] *******************************************************

TASK [Create quicknotes system user] *******************************************
ok: [quicknotes-vm]

TASK [Ensure data directory] ***************************************************
ok: [quicknotes-vm]

TASK [Copy seed file] **********************************************************
ok: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
ok: [quicknotes-vm]

TASK [Render systemd unit] *****************************************************
changed: [quicknotes-vm]

TASK [Enable and start quicknotes] *********************************************
ok: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Only the template task and the restart handler fired — all other tasks reported `ok`.

### --check --diff preview

Changed `listen_addr` from `:9090` to `:8080`:

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff

TASK [Render systemd unit] *****************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/vagrant/.ansible/tmp/.../quicknotes.service.j2
@@ -9,7 +9,7 @@
 ExecStart=/usr/local/bin/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:8080
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 Restart=on-failure

changed: [quicknotes-vm]
```

### Design Questions

**e) Why does the second run report `changed=0`?**

Each module compares the desired state against the current state on the target. `file` checks ownership, permissions, and existence. `template` renders the Jinja2 template and compares the checksum against the file already on disk. `copy` compares checksums of the source and destination files. If everything matches, the module reports `ok` and makes no changes.

**f) What if you used `shell:` instead of `template:`?**

`shell:` always reports `changed=1` because Ansible can't inspect the command's effect. This means the restart handler fires every run, causing unnecessary service downtime. It also breaks `--check` mode (shell commands are skipped in check mode, so you can't preview changes). And if the echo command has a quoting bug, it silently writes a broken unit file — the `template` module validates Jinja2 syntax before writing.

**g) What does `--check --diff` catch that plain `--check` misses?**

`--check` alone tells you *which tasks would change* but not *what the change is*. `--diff` shows the actual line-by-line difference. You might see that a template change accidentally removed an `Environment=` line or changed a file mode — problems that `changed=1` alone doesn't reveal. In production, this is the difference between "something will change" and "here is exactly what will change."

---

## Bonus Task — `ansible-pull` GitOps Loop

### systemd timer status

```
$ systemctl list-timers | grep ansible-pull
Thu 2026-06-26 12:10:00 UTC  4min left  Thu 2026-06-26 12:05:00 UTC  53s ago  ansible-pull.timer  ansible-pull.service
```

### Convergence timeline

| Event                     | Timestamp            |
|---------------------------|----------------------|
| Git commit pushed         | 2026-06-26 12:02:14  |
| Timer fired               | 2026-06-26 12:05:00  |
| ansible-pull completed    | 2026-06-26 12:05:38  |
| Service reconciled (curl) | 2026-06-26 12:05:40  |

### Design Questions

**h) Security benefit of pull mode**

In push mode, the control node needs SSH access to every managed host — a compromised control node can reach all servers. In pull mode, no inbound SSH is needed: the VM pulls from a Git repo over HTTPS. The attack surface is smaller because the VM only needs outbound HTTPS access to a repository, and credentials (if any) are scoped to read-only Git access, not root SSH.

**i) What's the same pattern at the Kubernetes layer?**

This is the same pattern as ArgoCD (or Flux) — a controller watches a Git repo and reconciles the cluster state to match the declared state. `ansible-pull` with a systemd timer is a fair simulator at the VM layer because it implements the same loop: poll repo → detect drift → converge → wait → repeat. The difference is granularity: ArgoCD reconciles Kubernetes manifests, `ansible-pull` reconciles OS-level state.
