# Lab 7 Submission

## Task 1
### Playbook 
```yaml
---
- name: Deploy QuickNotes to Lab 5 VM
  hosts: lab5_vm
  become: true
  gather_facts: true
  
  vars:
    quicknotes_user: quicknotes
    quicknotes_group: quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_bin_path: /usr/local/bin/quicknotes
    quicknotes_listen_addr: ":9090"
    quicknotes_seed_path: /var/lib/quicknotes/seed.json
    
  tasks:
    - name: Create quicknotes system group
      ansible.builtin.group:
        name: "{{ quicknotes_group }}"
        system: true
        state: present
      
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false
        state: present
      
    - name: Create data directory
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        mode: '0750'
        state: directory
        
    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ quicknotes_bin_path }}"
        mode: '0755'
        owner: root
        group: root
      notify: restart quicknotes
      
    - name: Render systemd service unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        mode: '0644'
        owner: root
        group: root
      notify: restart quicknotes
      
    - name: Reload systemd and start service
      ansible.builtin.systemd:
        daemon_reload: true
        name: quicknotes
        state: started
        enabled: true
        
  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
        daemon_reload: true

Inventory

[lab5_vm]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_private_key_file=/home/ksu/lab5/.vagrant/machines/default/virtualbox/private_key ansible_ssh_extra_args='-o StrictHostKeyChecking=no'

[all:vars]
ansible_python_interpreter=/usr/bin/python3

Systemd

[Unit]
Description=QuickNotes Service
After=network-online.target
Wants=network-online.target

[Service]
User={{ quicknotes_user }}
Group={{ quicknotes_group }}
WorkingDirectory={{ quicknotes_data_dir }}
Environment=ADDR={{ quicknotes_listen_addr }}
Environment=DATA_PATH={{ quicknotes_data_dir }}
Environment=SEED_PATH={{ quicknotes_seed_path }}
ExecStart={{ quicknotes_bin_path }}
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

1st PLAY RECAP
PLAY RECAP **********************************************************************************************
quicknotes-vm              : ok=8    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

service check
$ curl -s http://localhost:18080/health
{"notes":2,"status":"ok"}

$ vagrant ssh -c "sudo systemctl status quicknotes"
● quicknotes.service - QuickNotes Service
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2026-06-25 14:08:52 UTC; 49s ago
   Main PID: 4941 (quicknotes)
      Tasks: 4 (limit: 1099)
     Memory: 1.2M
        CPU: 7ms
     CGroup: /system.slice/quicknotes.service
             └─4941 /usr/local/bin/quicknotes

Jun 25 14:08:52 quicknotes-vm systemd[1]: Started QuickNotes Service.
Jun 25 14:08:52 quicknotes-vm quicknotes[4941]: 2026/06/25 14:08:52 Server listening on :9090 (DATA_PATH=/var/lib/quicknotes)

Design Questions
a) What's the difference between command: and the dedicated modules?

Dedicated modules (user, file, copy, template, systemd) are idempotent - they check current state and only make changes if needed. command:/shell: just execute commands without state checking, making them non-idempotent. This matters because idempotency ensures consistent, predictable, and repeatable deployments.

b) notify: and handlers: when does a handler fire?

A handler fires only when the task that notifies it reports changed=true. It does NOT fire if the task reports ok (no changes were made). This is the right default because it prevents unnecessary service restarts and maintains system stability.

c) Variable hierarchy: list the top 3 places you'd put a variable

    Playbook vars - highest priority, defined directly in the playbook

    Group vars (group_vars/all/) - for environment-wide settings

    Host vars - for machine-specific overrides

d) gather_facts: true is the default. Do you need it?

Yes, for this playbook we need facts to work with systemd and user management modules. Turning it off would save ~0.5-1s per run but would break idempotency checks.


Task 2 

Second run (changed=0)

PLAY RECAP **********************************************************************************************
quicknotes-vm              : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

Variable tweak (changed=1 only for template)
port 9090 to 9091
PLAY RECAP **********************************************************************************************
quicknotes-vm              : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

Task Render systemd service unit: changed=1

Handler restart quicknotes: changed=1 (invoked)

All other tasks: ok (no changes)

--check --diff example

TASK [Render systemd service unit] **********************************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/ksu/.ansible/tmp/.../quicknotes.service.j2
@@ -7,7 +7,7 @@
 User=quicknotes
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:9091
 Environment=DATA_PATH=/var/lib/quicknotes
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes

Design Questions

e) Why does the second run report changed=0?

The file and template modules check file hashes, ownership, permissions, and content. Since everything matches the desired state exactly, no changes are made.

f) What would happen if you used shell: instead of template:?

Every run would change the file (no idempotency), causing unnecessary service restarts. No syntax checking, harder to debug, and prone to errors.

g) --check --diff - what bug would you catch?

Shows exactly what will change (diff) before applying. Would catch unexpected changes in configuration files that you wouldn't see with plain --check.
