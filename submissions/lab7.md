<h1>Task 1</h1>

```touch ansible/inventory.ini && nano inventory.ini EOF```
[quicknotes_vm]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_private_key_file=~/.vagrant.d/insecure_private_key ansible_ssh_extra_args="-o StrictHostKeyChecking=no"


```touch ansible/playbook.yaml && nano playbook.yaml EOF```

---
- name: Deploy QuickNotes to Lab 5 VM
  hosts: quicknotes_vm
  become: true
  gather_facts: true

  vars:
    app_user: quicknotes
    app_data_dir: /var/lib/quicknotes
    app_binary_path: /usr/local/bin/quicknotes
    app_listen_addr: ":8080"
    app_data_path: "{{ app_data_dir }}/data.db"
    app_seed_path: "{{ app_data_dir }}/seed.json"

  tasks:
    - name: Create quicknotes system user
      ansible.builtin.user:
        name: "{{ app_user }}"
        system: true
        shell: /usr/sbin/nologin
        home: "{{ app_data_dir }}"
        create_home: false

    - name: Ensure data directory exists
      ansible.builtin.file:
        path: "{{ app_data_dir }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0750'

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ app_binary_path }}"
        mode: '0755'
        owner: root
        group: root
      notify: restart quicknotes

    - name: Render systemd unit file
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: '0644'
      notify: restart quicknotes

    - name: Reload systemd daemon
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

```touch ansible/templates/quicknotes.service.j2 && nano quicknotes.service.j2 EOF ```

[Unit]
Description=QuickNotes Service
After=network-online.target
Wants=network-online.target

[Service]
User={{ app_user }}
Group={{ app_user }}
WorkingDirectory={{ app_data_dir }}
ExecStart={{ app_binary_path }}
Restart=on-failure
RestartSec=5
Environment="ADDR={{ app_listen_addr }}"
Environment="DATA_PATH={{ app_data_path }}"
Environment="SEED_PATH={{ app_seed_path }}"

[Install]
WantedBy=multi-user.target

binary static
```CGO_ENABLED=0 go build -o ../ansible/files/quicknotes```


```ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml```

PLAY [Deploy QuickNotes to Lab 5 VM] *******************************************

TASK [Gathering Facts] *********************************************************
ok: [quicknotes-vm]

TASK [Create quicknotes system user] *******************************************
changed: [quicknotes-vm]

TASK [Ensure data directory exists] ********************************************
changed: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
changed: [quicknotes-vm]

TASK [Render systemd unit file] ************************************************
changed: [quicknotes-vm]

TASK [Reload systemd daemon] ***************************************************
changed: [quicknotes-vm]

TASK [Enable and start QuickNotes service] *************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=7    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```curl -s http://localhost:18080/health```

{"status":"ok"}

<h1>Task 2</h1>

```ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml```

PLAY [Deploy QuickNotes to Lab 5 VM] *******************************************

TASK [Gathering Facts] *********************************************************
ok: [quicknotes-vm]

TASK [Create quicknotes system user] *******************************************
changed: [quicknotes-vm]

TASK [Ensure data directory exists] ********************************************
changed: [quicknotes-vm]

TASK [Copy QuickNotes binary] **************************************************
changed: [quicknotes-vm]

TASK [Render systemd unit file] ************************************************
changed: [quicknotes-vm]

TASK [Reload systemd daemon] ***************************************************
changed: [quicknotes-vm]

TASK [Enable and start QuickNotes service] *************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=7    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```curl -s http://localhost:18080/health```

{"status":"ok"}

<b>Change in playbook.yaml app_listen_addr: "9090"</b>

```ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml```

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=7    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

<b>Destroy playbook.yaml and start again</b>

```ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml```

PLAY [Deploy QuickNotes to Lab 5 VM] *********************************************************************

TASK [Gathering Facts] *********************************************************************

fatal: [quicknotes-vm]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: ssh: connect to host 127.0.0.1 port 2222: Connection refused", "unreachable": true}

PLAY RECAP *********************************************************************

quicknotes-vm              : ok=0    changed=0    unreachable=1    failed=0    skipped=0    rescued=0    ignored=0  


<h1>Questions:</h1>
a) What's the difference between command: and the dedicated modules (apt, file, copy, systemd)? Which is idempotent, and why does it matter?

All idempotent - they check the current state of the system before making changes and only modify what does not match the desired state. The command module always executes the given command unconditionally, so it is not idempotent

Idempotence is critical for configuration management because:
* It allows safe re‑runs of playbooks

* It guarantees a predictable, consistent system state

* It simplifies debugging and auditing of changes


b) notify: and handlers: when does a handler fire? When does it not fire? Why is that the right default?

A handler only triggers if the task that notifies it finishes with a changed status. If the task reports ok (no change), the handler is not called

c) Variable hierarchy: Ansible has at least 22 levels of variable precedence. List the top 3 places you'd put a variable for this lab (defaults, group_vars, playbook vars, …) and why

<b>vars section in the playbook</b> - all deployment‑specific variables are visible in one place, easy to edit and understand
<b>group_vars/</b> - would be used if multiple VMs belonged to the same group, allowing shared settings
<b>host_vars/</b> - for host‑specific settings (e.g., IP address, port)

In this lab I used vars inside the playbook because:
There is only one target VM
The variables are specific to this particular deployment
It keeps everything simple and transparent

d) gather_facts: true is the default. Do you need it for this playbook? What does turning it off save you per run?

<b>gather_facts</b> is needed. The systemd module may use system facts. The user module may check existing user information


e) Why does the second run report changed=0? What specifically does the file / template module check to decide?

The second run shows <b>changed=0</b> because the system state already matches the desired state


f) What would happen if you used shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service' instead of the template: module? Trace the failure modes

* No idempotence - the command always runs, always reporting changed.
* No content comparison - Ansible does not know if the file changed, so it overwrites it every time.
* Poor error handling - a failing command may break the playbook or be silently ignored.
* No escaping - special characters in variables can break the shell command.
* Permission issues - harder to control file ownership and permissions properly.

g) ansible-playbook --check is dry-run. --diff shows changes. What's the bug you'd catch by running --check --diff before a production deploy that you'd miss with plain --check?

<b>--check --diff </b> shows actual content differences in files, whereas plain --check only tells you that a task would change, but not how.
