# Lab 7 submission

## Task 1 — Idempotent Deploy to the Lab 5 VM (6 pts)

### 1.1: Layout

```
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── quicknotes
│   └── seed.json
└── templates/
    └── quicknotes.service.j2
```

**`ansible/inventory.ini`:**
```ini
[quicknotes-vm]
default ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

Got the SSH config from `vagrant ssh-config`.

**`ansible/playbook.yaml`:**
```yaml
---
- name: Deploy QuickNotes to VM
  hosts: quicknotes-vm
  become: true
  gather_facts: true

  vars:
    quicknotes_user: quicknotes
    data_dir: /var/lib/quicknotes
    binary_path: /usr/local/bin/quicknotes
    addr: ":8080"
    data_path: "/var/lib/quicknotes/notes.json"
    seed_path: "/var/lib/quicknotes/seed.json"

  tasks:
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        shell: /usr/sbin/nologin
        create_home: false
        system: true

    - name: Ensure data directory exists
      ansible.builtin.file:
        path: "{{ data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0750"

    - name: Copy seed data
      ansible.builtin.copy:
        src: files/seed.json
        dest: /var/lib/quicknotes/seed.json
        mode: "0644"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ binary_path }}"
        mode: "0755"
        owner: root
        group: root
      notify: restart quicknotes

    - name: Render systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        mode: "0644"
        owner: root
        group: root
      notify: restart quicknotes

    - name: Reload systemd, enable and start QuickNotes
      ansible.builtin.systemd:
        name: quicknotes
        enabled: true
        state: started
        daemon_reload: true

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
        daemon_reload: true
```

**`ansible/templates/quicknotes.service.j2`:**
```jinja2
[Unit]
Description=QuickNotes API service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=quicknotes
Group=quicknotes
WorkingDirectory=/var/lib/quicknotes
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec=5
Environment=ADDR={{ addr }}
Environment=DATA_PATH={{ data_path }}
Environment=SEED_PATH={{ seed_path }}

[Install]
WantedBy=multi-user.target
```

### First run

Had to cross-compile the binary twice — first tried `GOARCH=amd64` but the Vagrant box was `aarch64`.

```
❯ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes to VM] *************************************************

TASK [Gathering Facts] *********************************************************
ok: [default]

TASK [Create quicknotes system user] *******************************************
changed: [default]

TASK [Ensure data directory exists] ********************************************
changed: [default]

TASK [Copy seed data] **********************************************************
changed: [default]

TASK [Copy QuickNotes binary] **************************************************
changed: [default]

TASK [Render systemd unit] *****************************************************
changed: [default]

TASK [Reload systemd, enable and start QuickNotes] *****************************
changed: [default]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [default]

PLAY RECAP *********************************************************************
default                    : ok=8    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

```
❯ curl -s http://localhost:18080/health | python3 -m json.tool
{
    "notes": 4,
    "status": "ok"
}
```

### Design questions (a-d)

**a) What's the difference between `command:` and the dedicated modules? Which is idempotent, and why does it matter?**

Dedicated modules (`file`, `copy`, `template`, `systemd`) check the current state before doing anything and only report `changed` when they actually modify something. `command:` and `shell:` always run and always report `changed=1` — they kill idempotency. This matters for safe re-runs, accurate `--check` dry-runs, and knowing what actually changed.

**b) `notify:` and handlers: when does a handler fire? When does it not? Why is that the right default?**

Handler fires at the end of the play if (and only if) the notifying task reported `changed`. It doesn't fire if the task was `ok`. This is right because you don't want to restart a service when nothing changed — that wastes time and causes unnecessary downtime.

**c) Variable hierarchy: top 3 places you'd put a variable for this lab.**

1. Playbook `vars:` — most visible, everything in one file
2. Inventory `group_vars/` — good for env-specific overrides
3. Role `defaults/` — lowest, easy to override

For this lab I used playbook vars since there's just one VM and no complex structure.

**d) `gather_facts: true` — do you need it for this playbook?**

Not really — I don't use any facts. Turning it off saves ~1-2 seconds per run. I left it on anyway since it costs almost nothing for a single VM and the playbook is already done.

---

## Task 2 — Prove Idempotency + Selective Re-run (4 pts)

### 2.1: Second run — `changed=0`

```
❯ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes to VM] *************************************************

TASK [Gathering Facts] *********************************************************
ok: [default]

TASK [Create quicknotes system user] *******************************************
ok: [default]

TASK [Ensure data directory exists] ********************************************
ok: [default]

TASK [Copy seed data] **********************************************************
ok: [default]

TASK [Copy QuickNotes binary] **************************************************
ok: [default]

TASK [Render systemd unit] *****************************************************
ok: [default]

TASK [Reload systemd, enable and start QuickNotes] *****************************
ok: [default]

PLAY RECAP *********************************************************************
default                    : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### 2.2: Changed `addr` from `:8080` to `:9090`

```
❯ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

TASK [Create quicknotes system user] *******************************************
ok: [default]
TASK [Ensure data directory exists] ********************************************
ok: [default]
TASK [Copy seed data] **********************************************************
ok: [default]
TASK [Copy QuickNotes binary] **************************************************
ok: [default]
TASK [Render systemd unit] *****************************************************
changed: [default]
TASK [Reload systemd, enable and start QuickNotes] *****************************
ok: [default]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [default]

PLAY RECAP *********************************************************************
default                    : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`template` task changed, handler fired, everything else `ok`.

### 2.3: `--check --diff` preview

Changed `addr` to `:9091` (not yet deployed):

```
❯ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff

TASK [Render systemd unit] *****************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/moflotas/.ansible/tmp/ansible-local-835368_34kzg0/tmp86kkrs90/quicknotes.service.j2
@@ -11,7 +11,7 @@
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
 RestartSec=5
-Environment=ADDR=:9090
+Environment=ADDR=:9091
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json

changed: [default]
```

### Design questions (e-g)

**e) Why does the second run report `changed=0`?**

Each module checks current state before acting. `file` does `stat()`, `copy` compares checksums, `template` renders the Jinja2 template and compares its checksum to the existing file, `systemd` checks if the service is already enabled and running. If everything matches → `ok`, no change.

**f) What would happen with `shell: 'echo "ADDR=..." > ...'` instead of `template:`?**

Every run would be `changed=1` (not idempotent). `--check` wouldn't dry-run — it'd actually write the file. No diff output. Easy to mess up quoting/escaping. No automatic backup of the old file.

**g) What bug does `--check --diff` catch that `--check` alone wouldn't?**

`--check` tells you *which* tasks would change. `--diff` shows the *actual content*. The case you'd catch is a template rendering literally — like `{{ addr }}` appearing verbatim in the output because of a typo in the variable name. With `--check` you'd see "template will change" but not that it's producing broken content.
