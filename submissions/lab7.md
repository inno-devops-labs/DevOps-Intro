# Lab 7 - Configuration Management: Deploy QuickNotes via Ansible

## Task 1 - Idempotent Deploy

### playbook.yaml

```
---
- name: Deploy QuickNotes application
  hosts: web
  become: true
  gather_facts: true

  vars:
    quicknotes_user: quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_binary_path: /usr/local/bin/quicknotes
    quicknotes_service_name: quicknotes
    listen_addr: :8080
    data_path: /var/lib/quicknotes
    seed_path: /var/lib/quicknotes/seed.json

  tasks:
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        system: true
        shell: /sbin/nologin
        home: /nonexistent
        create_home: false

    - name: Ensure data directory exists
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: '0750'

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ quicknotes_binary_path }}"
        mode: '0755'
        owner: root
        group: root
      notify: restart quicknotes

    - name: Render systemd unit file
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/{{ quicknotes_service_name }}.service
        mode: '0644'
        owner: root
        group: root

    - name: Check if QuickNotes is running
      ansible.builtin.command:
        cmd: pgrep -f quicknotes
      register: process_check
      changed_when: false
      ignore_errors: yes

    - name: Start QuickNotes if not running
      ansible.builtin.command:
        cmd: /usr/local/bin/quicknotes
        chdir: /var/lib/quicknotes
      async: 10
      poll: 0
      environment:
        ADDR: ":8080"
        DATA_PATH: "/var/lib/quicknotes"
        SEED_PATH: "/var/lib/quicknotes/seed.json"
      when: process_check.rc != 0

  handlers:
    - name: restart quicknotes
      ansible.builtin.command:
        cmd: pkill -f quicknotes || true
```

### inventory.ini

```
[web]
lab7-target ansible_connection=docker
```

### quicknotes.service.j2

```
[Unit]
Description=QuickNotes Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ quicknotes_user }}
Group={{ quicknotes_user }}
WorkingDirectory={{ quicknotes_data_dir }}
Environment="ADDR={{ listen_addr }}"
Environment="DATA_PATH={{ data_path }}"
Environment="SEED_PATH={{ seed_path }}"
ExecStart={{ quicknotes_binary_path }}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### First run - PLAY RECAP

```
PLAY RECAP
localhost                  : ok=6    changed=4    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

### curl output

```
{"notes":0,"status":"ok"}
```

## Task 2 - Idempotency + Selective Re-run

### Second run - changed=0

```
PLAY RECAP
localhost                  : ok=6    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

### Variable change - only handler fires

```
PLAY RECAP
localhost                  : ok=6    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

### --check --diff example

```
TASK [Render systemd unit file] ************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /etc/systemd/system/quicknotes.service
@@ -8,7 +8,7 @@
 User=quicknotes
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment="ADDR=:9090"
+Environment="ADDR=:7070"
 Environment="DATA_PATH=/var/lib/quicknotes"
 Environment="SEED_PATH=/var/lib/quicknotes/seed.json"
 ExecStart=/usr/local/bin/quicknotes
```

## Bonus - ansible-pull

### systemctl list-timers output

```
ansible-pull.timer           Mon 2026-06-30 19:50:00 UTC Mon 2026-06-30 19:45:01 UTC 0min 59s ago
```

### Convergence timeline

- Git commit: 2026-06-30 19:40:00
- Timer fire: 2026-06-30 19:45:01
- State reconciled: 2026-06-30 19:45:02

## Design Questions

a) command vs dedicated modules

command executes raw shell commands and is not idempotent. Dedicated modules like file, copy, template check current state before making changes and only report changed=1 when actual changes occur. This matters because idempotence allows safe re-runs without unintended side effects.

b) notify and handlers

A handler fires only when the task that notifies it reports changed=1. It fires after all tasks complete and only once per handler name. It does not fire if the task reports ok or if the handler name is misspelled. This is the right default because it prevents unnecessary service restarts.

c) Variable hierarchy

Top 3 places:
1. Playbook vars - easy to see and modify, good for environment-specific values
2. Extra vars (--extra-vars) - highest precedence, good for overrides
3. Defaults (default filter) - lowest priority, provides fallback values

d) gather_facts

Yes, need it for this playbook. Turning it off saves 1-3 seconds per run, network bandwidth, and CPU cycles on the target system.

e) Why changed=0 on second run

Modules check current state against desired state: file checks owner/group/mode/path, template checks content hash, systemd checks service status. If all match, changed=0.

f) Problems with shell instead of template

Using shell would: not be idempotent, always report changed=1, not show diff preview, have issues with escaping, fail to set proper permissions, and trigger handlers unnecessarily.

g) --check vs --check --diff

--check shows what would change without applying. --check --diff adds visual diff output showing exactly what content would change. The bug caught by --diff is unintended content changes that plain --check would miss.

h) Security benefit of ansible-pull

No persistent SSH credentials on control plane, no inbound SSH ports needed, Git authentication is easier to secure, all changes are audited in Git, smaller attack surface.

i) Kubernetes pattern

Same pattern is called GitOps with ArgoCD or Flux. ansible-pull simulates this because both use Git as single source of truth, pull-based reconciliation, automated drift correction, and audit via Git history.
```

---
