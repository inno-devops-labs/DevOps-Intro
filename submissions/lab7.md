# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

## Task 1 — Idempotent Deploy to the Lab 5 VM

### 1.1 Layout

```
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── quicknotes         (static binary, built with CGO_ENABLED=0)
│   └── seed.json
└── templates/
    └── quicknotes.service.j2
```

### 1.2 Files

#### `ansible/inventory.ini`

```ini
quicknotes ansible_host=192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=~/.ssh/quicknotes_vagrant ansible_python_interpreter=/usr/bin/python3 ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

#### `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true
  gather_facts: false

  vars:
    listen_addr: ":8080"
    data_dir: /var/lib/quicknotes
    data_path: /var/lib/quicknotes/notes.json
    seed_path: /var/lib/quicknotes/seed.json

  tasks:
    - name: Create quicknotes user
      ansible.builtin.user:
        name: quicknotes
        system: true
        create_home: false
        shell: /usr/sbin/nologin

    - name: Create data directory
      ansible.builtin.file:
        path: "{{ data_dir }}"
        state: directory
        owner: quicknotes
        group: quicknotes
        mode: "0750"

    - name: Copy binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: /usr/local/bin/quicknotes
        owner: root
        group: root
        mode: "0755"
      notify: restart quicknotes

    - name: Copy seed
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ seed_path }}"
        owner: quicknotes
        group: quicknotes
        mode: "0644"

    - name: Install systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: restart quicknotes

    - name: Reload systemd
      ansible.builtin.systemd:
        daemon_reload: true

    - name: Enable and start service
      ansible.builtin.systemd:
        name: quicknotes
        enabled: true
        state: started

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
        daemon_reload: true
```

#### `ansible/templates/quicknotes.service.j2`

```ini
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=quicknotes
Group=quicknotes
WorkingDirectory={{ data_dir }}
Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ data_path }}
Environment=SEED_PATH={{ seed_path }}
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

### 1.7 Run + Verify

**First run (real deploy):**

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] ***********************************************************************************************************************

TASK [Create quicknotes user] ******************************************************************************************************************
changed: [quicknotes]

TASK [Create data directory] *******************************************************************************************************************
changed: [quicknotes]

TASK [Copy binary] *****************************************************************************************************************************
changed: [quicknotes]

TASK [Copy seed] *******************************************************************************************************************************
changed: [quicknotes]

TASK [Install systemd unit] ********************************************************************************************************************
changed: [quicknotes]

TASK [Reload systemd] **************************************************************************************************************************
ok: [quicknotes]

TASK [Enable and start service] ****************************************************************************************************************
changed: [quicknotes]

RUNNING HANDLER [restart quicknotes] ***********************************************************************************************************
changed: [quicknotes]

PLAY RECAP *************************************************************************************************************************************
quicknotes                 : ok=8    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

**Service health check:**

```
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

### 1.5 Design Questions

**a) What's the difference between `command:` and the dedicated modules (`apt`, `file`, `copy`, `systemd`)? Which is idempotent, and why does it matter?**

`command:` executes an arbitrary shell command and is **not idempotent by default** — it runs every time the playbook is invoked and always reports `changed=1`. Dedicated modules like `apt`, `file`, `copy`, and `systemd` are **idempotent by construction**: they inspect the current state of the system and only perform actions if the desired state differs from the actual state. This matters because idempotency allows safe re-runs of the playbook without unintended side effects or unnecessary service restarts. If a playbook is re-run after a partial failure, idempotent modules will only fix what's actually broken, not re-apply everything.

**b) `notify:` and handlers: when does a handler fire? When does it not fire? Why is that the right default?**

A handler fires **only when a task that notifies it reports `changed`**. If the task reports `ok` (meaning the desired state already matches the actual state and no action was needed), the handler does **not** fire. This is the right default because it prevents unnecessary service restarts when configurations haven't actually changed. Restarting a service causes brief downtime and can drop active connections — we only want to restart when something genuinely changed. Handlers also run at the end of the play (or when explicitly flushed), so multiple changes to the same service within a single play result in only one restart.

**c) Variable hierarchy: Ansible has at least 22 levels of variable precedence. List the top 3 places you'd put a variable for this lab and why.**

1. **`vars` in the playbook** (or `defaults/main.yaml` in a role): For variables that have a sensible default value but should be easily overridable. In this lab, `listen_addr`, `data_dir`, `data_path`, and `seed_path` are defined here because they are core to the playbook's logic and should be visible alongside the tasks.
2. **Inventory (`group_vars` / `host_vars`)**: For environment-specific variables. If we had multiple VMs (dev, staging, prod), each would have different values for `listen_addr` or `data_path` defined in their respective `group_vars` or `host_vars`. This keeps environment-specific config separate from the playbook logic.
3. **`--extra-vars` (`-e` CLI flag)**: For one-off overrides during execution. This has the **highest precedence** in Ansible's variable hierarchy. It's useful for quick testing (e.g., `ansible-playbook ... -e 'listen_addr=:9090'`) or CI/CD pipelines where you need to inject values at runtime without modifying files.

**d) `gather_facts: true` is the default. Do you need it for this playbook? What does turning it off save you per run?**

No, we don't need `gather_facts: true` for this playbook. We don't use any system facts (like `ansible_os_family`, `ansible_distribution`, `ansible_memtotal_mb`, etc.) in our tasks or templates. All the information we need is provided via variables. Turning it off saves **2-5 seconds per run** because Ansible skips the `setup` module, which normally connects to the target, collects a large amount of system information (OS, network interfaces, hardware, etc.), and returns it as facts. For a simple deployment playbook targeting a known OS, this is pure overhead.

---

## Task 2 — Prove Idempotency + Selective Re-run (4 pts)

### 2.1 Required Demonstrations

**Second run (idempotency — zero changes):**

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] ***********************************************************************************************************************

TASK [Create quicknotes user] ******************************************************************************************************************
ok: [quicknotes]

TASK [Create data directory] *******************************************************************************************************************
ok: [quicknotes]

TASK [Copy binary] *****************************************************************************************************************************
ok: [quicknotes]

TASK [Copy seed] *******************************************************************************************************************************
ok: [quicknotes]

TASK [Install systemd unit] ********************************************************************************************************************
ok: [quicknotes]

TASK [Reload systemd] **************************************************************************************************************************
ok: [quicknotes]

TASK [Enable and start service] ****************************************************************************************************************
ok: [quicknotes]

PLAY RECAP *************************************************************************************************************************************
quicknotes                 : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

**Variable tweak — selective change (changed `listen_addr` from `:8080` to `:9090`):**

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] ***********************************************************************************************************************

TASK [Create quicknotes user] ******************************************************************************************************************
ok: [quicknotes]

TASK [Create data directory] *******************************************************************************************************************
ok: [quicknotes]

TASK [Copy binary] *****************************************************************************************************************************
ok: [quicknotes]

TASK [Copy seed] *******************************************************************************************************************************
ok: [quicknotes]

TASK [Install systemd unit] ********************************************************************************************************************
changed: [quicknotes]

TASK [Reload systemd] **************************************************************************************************************************
ok: [quicknotes]

TASK [Enable and start service] ****************************************************************************************************************
ok: [quicknotes]

RUNNING HANDLER [restart quicknotes] ***********************************************************************************************************
changed: [quicknotes]

PLAY RECAP *************************************************************************************************************************************
quicknotes                 : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Verification that the service now listens on 9090:

```
$ vagrant ssh -c "ss -tlnp | grep 9090"
LISTEN 0      4096               *:9090            *:*
```

**`--check --diff` preview (changed `listen_addr` back from `:9090` to `:8080`):**

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff

PLAY [Deploy QuickNotes] ***********************************************************************************************************************

TASK [Create quicknotes user] ******************************************************************************************************************
ok: [quicknotes]

TASK [Create data directory] *******************************************************************************************************************
ok: [quicknotes]

TASK [Copy binary] *****************************************************************************************************************************
ok: [quicknotes]

TASK [Copy seed] *******************************************************************************************************************************
ok: [quicknotes]

TASK [Install systemd unit] ********************************************************************************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/levak/.ansible/tmp/ansible-local-875ykf7ccw8/tmp9vg1srt2/quicknotes.service.j2
@@ -11,7 +11,7 @@

 WorkingDirectory=/var/lib/quicknotes

-Environment=ADDR=:9090
+Environment=ADDR=:8080
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json


changed: [quicknotes]

TASK [Reload systemd] **************************************************************************************************************************
ok: [quicknotes]

TASK [Enable and start service] ****************************************************************************************************************
ok: [quicknotes]

RUNNING HANDLER [restart quicknotes] ***********************************************************************************************************
changed: [quicknotes]

PLAY RECAP *************************************************************************************************************************************
quicknotes                 : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### 2.2 Design Questions

**e) Why does the second run report `changed=0`? What specifically does the `file` / `template` module check to decide?**

The second run reports `changed=0` because idempotent modules compare the **desired state** (specified in the playbook) with the **actual state** on the target system. Specifically:

- The `file` module checks: Does the directory exist? Does it have the correct owner, group, and permissions (mode)? If all match, no action is taken.
- The `copy` module checks: Does the destination file exist? Does its **checksum** (SHA1/SHA256) match the source file? Are the owner, group, and mode correct? If all match, no action is taken.
- The `template` module checks: Does the destination file exist? Does its content match the **rendered output** of the Jinja2 template (again, via checksum)? Are permissions correct? If all match, no action is taken.

Since all these conditions were already satisfied after the first run, the second run found no discrepancies and reported `ok` (not `changed`) for every task.

**f) What would happen if you used `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` instead of the `template:` module? Trace the failure modes.**

Using `shell:` instead of `template:` would cause several problems:

1. **Loss of idempotency**: The `shell:` module executes the command every time the playbook runs, always reporting `changed=1`. This means the handler would fire on every run, causing unnecessary service restarts.
2. **No atomic writes**: `shell: echo "..." > file` is not atomic. If the playbook is interrupted mid-write, the file could be left in a corrupted state. The `template` module writes to a temporary file first, then atomically renames it.
3. **No checksum comparison**: The `template` module compares checksums to decide if a change is needed. `shell:` has no such mechanism — it blindly overwrites the file every time.
4. **No Jinja2 rendering**: You'd lose the ability to use variables like `{{ listen_addr }}` and would have to manually construct the string, making the playbook harder to maintain.
5. **No diff support**: The `template` module supports `--diff` to show what would change. `shell:` does not.
6. **Error handling**: If the `echo` command fails (e.g., disk full), the error handling is less robust than the built-in module.

**g) `ansible-playbook --check` is dry-run. `--diff` shows changes. What's the bug you'd catch by running `--check --diff` before a production deploy that you'd miss with plain `--check`?**

Plain `--check` tells you **if** a change would occur, but `--diff` shows **what exactly** would change. A bug you'd catch with `--check --diff` but miss with plain `--check` could be:

- **Incorrect variable substitution**: If a variable name is misspelled (e.g., `{{ listen_adr }}` instead of `{{ listen_addr }}`), `--check` might show that the template would change, but `--diff` would reveal that the rendered output contains an empty string or the literal text `{{ listen_adr }}` instead of the expected value.
- **Unintended permission changes**: `--check` might show `changed=1` for a file, but `--diff` would reveal that only the permissions (mode) are changing, not the content — which might be unexpected if you thought you were only updating the file content.
- **Template rendering errors**: If a Jinja2 template has a syntax error or references an undefined variable, `--diff` would show the partially rendered output, helping you identify the issue before it causes a deployment failure.

In short, `--check` is a boolean (will something change?), while `--diff` is a diagnostic tool (what exactly will change?). Using both together gives you full visibility into the impact of your playbook before it touches production.