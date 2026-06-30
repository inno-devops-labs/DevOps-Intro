# Lab 7: Configuration Management: Deploy QuickNotes via Ansible

### `ansible/inventory.ini`

```ini
[quicknotes]
vm ansible_host=127.0.0.1 ansible_port=2222

[quicknotes:vars]
ansible_user=vagrant
ansible_ssh_private_key_file=~/.ssh/quicknotes_vm_key
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa
```

The Vagrant insecure key was copied into the WSL filesystem and set to mode 600, because keys on the `/mnt/d` Windows mount are world-readable and SSH rejects them. The `+ssh-rsa` options re-enable the box's legacy RSA host and login keys that modern OpenSSH disables by default.

### `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true
  gather_facts: false

  vars:
    app_user: quicknotes
    data_dir: /var/lib/quicknotes
    bin_path: /usr/local/bin/quicknotes
    listen_addr: ":8080"

  tasks:
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: "{{ app_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false

    - name: Ensure data directory
      ansible.builtin.file:
        path: "{{ data_dir }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: "0750"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ bin_path }}"
        mode: "0755"
      notify: Restart quicknotes

    - name: Copy seed file
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ data_dir }}/seed.json"
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: "0640"

    - name: Render systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
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

### `ansible/templates/quicknotes.service.j2`

```jinja
[Unit]
Description=QuickNotes service
After=network-online.target
Wants=network-online.target

[Service]
User={{ app_user }}
Group={{ app_user }}
WorkingDirectory={{ data_dir }}
Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ data_dir }}/notes.json
Environment=SEED_PATH={{ data_dir }}/seed.json
ExecStart={{ bin_path }}
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

## Task 1

```text
TASK [Create quicknotes system user] *******************************************
changed: [vm]
TASK [Ensure data directory] ***************************************************
changed: [vm]
TASK [Copy QuickNotes binary] **************************************************
changed: [vm]
TASK [Copy seed file] **********************************************************
changed: [vm]
TASK [Render systemd unit] *****************************************************
changed: [vm]
TASK [Enable and start quicknotes] *********************************************
changed: [vm]
RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [vm]

PLAY RECAP *********************************************************************
vm  : ok=7    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Service reachable via the Vagrant port forward 18080 to 8080

```text
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

### Design questions

**a) `command:` versus the dedicated modules.**
`command:` and `shell:` just run a string, so Ansible does not know what they do and marks them `changed` every time. The modules check the current state first and act only if something differs. That is what makes re-runs safe and `changed=0` meaningful.

**b) When a handler fires.**
A handler runs only if a task that notifies it reports `changed`, and it runs once at the end. It is skipped when the task is `ok` or `failed`. So the service restarts only when its files actually changed.

**c) Variable hierarchy, top three places for this lab.**

1. `group_vars/` for per-environment values like `listen_addr`.
2. Play `vars:`, simple when there is one target (used here).
3. Role `defaults/`, a fallback if this became a role.

Extra-vars (`-e`) beat all of them and are for one-off overrides.

**d) Is `gather_facts` needed here.**
No. The playbook uses no facts, only `vars`. Turning it off skips the setup step and saves one round-trip per run.

## Task 2

```text
PLAY RECAP *********************************************************************
vm  : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Variable `listen_addr` changed from :8080 to :9090 and only template and handler react

```text
TASK [Create quicknotes system user] *******************************************
ok: [vm]
TASK [Ensure data directory] ***************************************************
ok: [vm]
TASK [Copy QuickNotes binary] **************************************************
ok: [vm]
TASK [Copy seed file] **********************************************************
ok: [vm]
TASK [Render systemd unit] *****************************************************
changed: [vm]
TASK [Enable and start quicknotes] *********************************************
ok: [vm]
RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [vm]

PLAY RECAP *********************************************************************
vm  : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### `--check --diff` preview of a third change (`listen_addr` :9090 to :8080)

```text
TASK [Render systemd unit] *****************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/danielpancake/.ansible/tmp/.../quicknotes.service.j2
@@ -7,7 +7,7 @@
 User=quicknotes
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:8080
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes

changed: [vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [vm]

PLAY RECAP *********************************************************************
vm  : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Design questions

**e) Why the second run reports `changed=0`.**
The modules compare the wanted result with what is already on disk. `template` renders the file and compares its checksum plus owner, group, and mode. If everything matches, nothing changes. On a second run nothing differs, so `changed=0`.

**f) Using `shell: 'echo "ADDR=..." > /etc/.../quicknotes.service'` instead.**
It always reports `changed`, so the handler restarts every run. `--check` and `--diff` cannot preview it. It overwrites the whole file, potentially breaking it. It also sets no owner or mode. The `template` module avoids all of this.

**g) The bug `--check --diff` catches that plain `--check` misses.**
`--check` only says a task would change. `--diff` shows the exact lines. A typo that renders an empty `ADDR=` still looks like a normal "would change" under `--check`, but `--diff` shows the bad line before it deploys.
