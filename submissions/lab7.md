# Lab 7 

## Playbook, Inventory, and Template

### `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes to Lab 5 VM
  hosts: all
  become: true
  gather_facts: true

  vars:
    listen_addr: ":8080"
    data_path: "/var/lib/quicknotes/notes.json"
    seed_path: "/var/lib/quicknotes/seed.json"
    qn_user: quicknotes
    qn_data_dir: "/var/lib/quicknotes"
    qn_bin: "/usr/local/bin/quicknotes"

  tasks:
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: "{{ qn_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false
        state: present

    - name: Ensure data directory exists
      ansible.builtin.file:
        path: "{{ qn_data_dir }}"
        state: directory
        owner: "{{ qn_user }}"
        group: "{{ qn_user }}"
        mode: '0750'

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ qn_bin }}"
        owner: root
        group: root
        mode: '0755'
      notify: restart quicknotes

    - name: Copy seed.json to data directory
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ seed_path }}"
        owner: "{{ qn_user }}"
        group: "{{ qn_user }}"
        mode: '0644'

    - name: Render systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: '0644'
      notify: restart quicknotes

    - name: Reload systemd
      ansible.builtin.systemd:
        daemon_reload: true

    - name: Enable and start QuickNotes service
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
### ansible/templates/quicknotes.service.j2

```
[Unit]
Description=QuickNotes service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ qn_user }}
WorkingDirectory={{ qn_data_dir }}
Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ data_path }}
Environment=SEED_PATH={{ seed_path }}
ExecStart={{ qn_bin }}
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```
### First Run PLAY RECAP

```
$ ansible-playbook -i "localhost," playbook.yaml --connection=local

PLAY [Deploy QuickNotes to Lab 5 VM] *********************************************************
TASK [Gathering Facts] ***********************************************************************
ok: [localhost]

TASK [Create quicknotes system user] *********************************************************
ok: [localhost]

TASK [Ensure data directory exists] **********************************************************
ok: [localhost]

TASK [Copy QuickNotes binary] ****************************************************************
ok: [localhost]

TASK [Copy seed.json to data directory] ******************************************************
changed: [localhost]

TASK [Render systemd unit] *******************************************************************
changed: [localhost]

TASK [Reload systemd] ************************************************************************
ok: [localhost]

TASK [Enable and start QuickNotes service] ***************************************************
changed: [localhost]

RUNNING HANDLER [restart quicknotes] *********************************************************
changed: [localhost]

PLAY RECAP ***********************************************************************************
localhost                  : ok=9    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Service Verification
#### curl output from VM
```
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```
#### systemctl status quicknotes
```
$ sudo systemctl status quicknotes
● quicknotes.service - QuickNotes service
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; vendor preset: enabled)
     Active: active (running) since Sun 2026-06-28 14:01:42 UTC; 6s ago
   Main PID: 5054 (quicknotes)
      Tasks: 7 (limit: 1099)
     Memory: 1.1M
        CPU: 11ms
     CGroup: /system.slice/quicknotes.service
             └─5054 /usr/local/bin/quicknotes

Jun 28 14:01:42 quicknotes-vm systemd[1]: Started QuickNotes service.
Jun 28 14:01:42 quicknotes-vm quicknotes[5054]: 2026/06/28 14:01:42 quicknotes listening on :8080 (notes loaded: 4)
```

### Design Questions (Task 1)

```text
a) What's the difference between command: and the dedicated modules? Which is idempotent, and why does it matter?

command: or shell: run arbitrary shell commands every time. Dedicated modules like file, copy, template, systemd check the current state before making changes. They are idempotent because they only apply changes when needed. This matters because it ensures that re-running the playbook does not cause unintended changes — it converges to the desired state and stops.

b) notify: and handlers: when does a handler fire? When does it not fire? Why is that the right default?

A handler fires only when the task that notifies it reports changed. If the task reports ok (no change), the handler is not triggered. This is the right default because it prevents unnecessary restarts. For example, restarting the service only when the binary or unit file actually changes — not on every playbook run.

c) Variable hierarchy: list the top 3 places you'd put a variable for this lab and why

Playbook vars: block — simple, visible, and sufficient for a single-playbook lab. All variables are in one place.
group_vars/ — if the same variables applied to multiple hosts, this would be cleaner. For this lab, not needed.
ansible/inventory.ini — for host-specific variables like ansible_user or ansible_port. Used for SSH connection details.

d) gather_facts: true is the default. Do you need it for this playbook? What does turning it off save you per run?

For this playbook, gather_facts: true is useful because tasks like user, file, and systemd rely on platform-specific information (e.g., OS family, service manager). Turning it off would save ~1-2 seconds per run, but would risk breaking tasks that depend on OS detection. For this lab, keeping it on is safe and reliable.
```
## Task 2 — Prove Idempotency + Selective Re-run

### 1. Second run = changed=0

```bash
$ ansible-playbook -i "localhost," playbook.yaml --connection=local

PLAY RECAP ***************************************************************************************************
localhost : ok=8 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

### 2. Variable tweak = selective change (template + handler only)

```bash
$ ansible-playbook -i "localhost," playbook.yaml --connection=local

TASK [Render systemd unit] *******************************************************************
changed: [localhost]

RUNNING HANDLER [restart quicknotes] *********************************************************
changed: [localhost]

PLAY RECAP ***********************************************************************************
localhost : ok=9 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

### 3. --check --diff preview
```bash
$ ansible-playbook -i "localhost," playbook.yaml --connection=local --check --diff

TASK [Render systemd unit] *******************************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: .../quicknotes.service.j2
@@ -7,7 +7,7 @@
-Environment=ADDR=:9090
+Environment=ADDR=:8080
changed: [localhost]

PLAY RECAP ***********************************************************************************
localhost : ok=9 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

### Design Questions

```text
e) Why does the second run report changed=0?

Ansible modules check the current state before making changes. If the file already exists with the correct content, permissions, and ownership, the module reports ok and does nothing. This is how idempotency works — the playbook converges to the desired state and stops.

f) What would happen if you used shell: instead of the template: module?

Using shell: to write the systemd unit would:

- Not be idempotent - it would overwrite the file every time
- Not show a diff — --diff wouldn't show what changed
- Not trigger handlers correctly — you'd have to manually manage when to restart
- Be harder to read and maintain

g) What's the bug you'd catch with --check --diff that plain --check misses?

--check shows what tasks would change, but --diff shows exactly what would change (e.g., the specific line in a template). This helps catch unintended changes, like a wrong variable value or a formatting issue, before applying them to production.
```


