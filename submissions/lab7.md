# Lab 7 submission

# Lab 7

## Task 1 — Idempotent Deploy to the Lab 5 VM

### 1.1 Environment preparation

For this lab I used Ansible on a Kali Linux control node and an Ubuntu virtual machine
provisioned from Windows10 with Vagrant as the managed node.

Connectivity was verified before deployment.

Many network issues was fixed before...

Inventory.ini:
```ini
[quicknotes]
192.168.56.10
[quicknotes:vars]
ansible_user=vagrant
ansible_ssh_private_key_file=~/.ssh/vagrant_lab7
```

Connectivity test:
```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ ansible all -i ansible/inventory.ini -m ping

192.168.56.10 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```
This confirmed that Ansible could successfully connect to the target host.

### 1.2 Playbook implementation Systemd template

The deployment was implemented using Ansible playbook.yaml:
```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_data_dir: /var/lib/quicknotes

    quicknotes_addr: ":8080"
    quicknotes_data_path: "/var/lib/quicknotes/data.json"
    quicknotes_seed_path: "/var/lib/quicknotes/seed.json"

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted

  tasks:
    - name: Create quicknotes user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        system: true
        create_home: false
        shell: /usr/sbin/nologin

    - name: Create data directory
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0750"

    - name: Copy quicknotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: /usr/local/bin/quicknotes
        owner: root
        group: root
        mode: "0755"
      notify: restart quicknotes

    - name: Deploy systemd unit
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
```

quicknotes.service.j2:
```ini
[Unit]
Description=QuickNotes
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
User={{ quicknotes_user }}
Group={{ quicknotes_user }}
WorkingDirectory={{ quicknotes_data_dir }}
Environment="ADDR={{ quicknotes_addr }}"
Environment="DATA_PATH={{ quicknotes_data_path }}"
Environment="SEED_PATH={{ quicknotes_seed_path }}"
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
```

### 1.3 Deploy application
Project structure:

```text
ansible
├── files
│   └── quicknotes
├── inventory.ini
├── playbook.yaml
└── templates
    └── quicknotes.service.j2
```

The playbook performs the following actions:

1. Creates a dedicated system user `quicknotes`.
2. Creates the application data directory `/var/lib/quicknotes`.
3. Copies the QuickNotes binary to `/usr/local/bin/quicknotes`.
4. Deploys a systemd unit from a Jinja2 template.
5. Reloads the systemd daemon.
6. Enables and starts the service.
7. Restarts the service only when the binary or service template changes.

A handler was used to ensure that service restarts occur only when required.

The deployment was executed from the Ansible control node.

Command:
```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```
Result:
```text
PLAY RECAP

192.168.56.10 : ok=7 changed=6 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```
The playbook completed successfully and the QuickNotes service was installed and started on the managed node.

### 1.4 Verify service operation

Service status:

```bash
vagrant@quicknotes-vm:~$ sudo systemctl status quicknotes
● quicknotes.service - QuickNotes
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-06-30 06:24:04 UTC; 1min 36s ago
   Main PID: 2692 (quicknotes)
```
Journal output:

```text
Jun 30 06:24:04 quicknotes-vm quicknotes[2692]:
2026/06/30 06:24:04 quicknotes listening on :8080 (notes loaded: 0)
```

Health check:
```bash
vagrant@quicknotes-vm:~$ curl localhost:8080/health
{"notes":0,"status":"ok"}
```
The service was successfully started and responded correctly to health check requests.

### 1.5 Design questions

a) What's the difference between command: 
and the dedicated modules (apt, file, copy, systemd)? 
Which is idempotent, and why does it matter?

The `command` module executes a command on the remote host but generally does not understand the desired system state. Because of that, Ansible often cannot determine whether a change is required before running the command.
Dedicated modules such as `apt`, `file`, `copy`, `template`, and `systemd` are state-aware.
They inspect the current state of the target system and only perform changes when the actual state differs from the desired state.
These modules are idempotent because repeated executions converge to the same result without introducing additional changes. Idempotency is important because infrastructure automation should be safe to run repeatedly and should not continuously modify an already-correct system.

b) notify: and handlers: when does a handler fire? When does it not fire? Why is that the right default?

handler is triggered only when a task that references it through `notify` reports a change.
In this lab, the handler is notified by the `copy` task that deploys the binary 
and the `template` task that deploys the systemd unit.
If nether task changes anything, the handler is not executed.
This behavior is desirable because service restarts are disruptive operations.
Restarting a service only when configuration or application artifacts change minimizes downtime and avoids unnecessary work.

c) Variable hierarchy: Ansible has at least 22 levels of variable precedence.
List the top 3 places you'd put a variable for this lab 
(defaults, group_vars, playbook vars, …) and why

For this lab I would primarily use the following locations:
1. `defaults/main.yml` (if using roles) for sensible default values that should be easy to override.
2. `group_vars/quicknotes.yml` for environment-specific configuration shared by all hosts in the inventory group.
3. Playbook variables (`vars:`) for values that are tightly coupled to a specific deployment and are unlikely to be reused elsewhere.
This approach keeps defaults reusable, environment configuration centralized,
and deployment-specific values easy to understand.
In this lab I used playbook variables because the deployment consists 
of a single playbook and a single host group.

d) gather_facts: true is the default. 
Do you need it for this playbook? 
What does turning it off save you per run?

The default value of `gather_facts` is `true`,
which causes Ansible to collect information about the target host before executing tasks.
This playbook does not use any host facts such as operating system details, memory size, network interfaces, or CPU information.
Setting `gather_facts: false` reduces the number of remote operations performed at the start of each run, decreases execution time, and reduces SSH traffic between the control node and the managed host.

## Task 2 — Prove Idempotency + Selective Re-run

### 2.1 Second run — zero changes
The playbook was executed a second time without modifying any files.

Command:
```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```
Result:
```text
PLAY RECAP
192.168.56.10 : ok=6 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

This demonstrates that the deployment is idempotent 
and does not introduce unnecessary changes when the target host is already in the desired state.
Because the target host was already in the desired state, Ansible detected no differences and no changes were required.

### 2.2 Variable change — selective update

I modified the playbook variable as needed:

```yaml
quicknotes_addr: ":8080"
```
to:
```yaml
quicknotes_addr: ":9090"
```
and re-ran the deployment.

Result:
```text
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ nano ansible/playbook.yaml                  
                                                                                                              
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
PLAY [Deploy QuickNotes] *********************************************************************************************
TASK [Create quicknotes user] *********************************************************************************************         
ok: [192.168.56.10]
TASK [Create data directory] *********************************************************************************************
ok: [192.168.56.10]
TASK [Copy quicknotes binary] *********************************************************************************************
ok: [192.168.56.10]
TASK [Deploy systemd unit] *********************************************************************************************
changed: [192.168.56.10]
TASK [Reload systemd] *********************************************************************************************
ok: [192.168.56.10]
TASK [Enable and start service] *********************************************************************************************
ok: [192.168.56.10]
RUNNING HANDLER [restart quicknotes] *********************************************************************************************
changed: [192.168.56.10]
PLAY RECAP ********************************************************************************************************
192.168.56.10              : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
Only the template changed because the systemd unit file contained the modified listen address.
The handler was triggered automatically and restarted the service.

Verification:
```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ curl localhost:9090/health
{"notes":0,"status":"ok"}
```
This confirms that the new configuration was applied successfully.

### 2.3 Dry run with --check --diff

A third configuration change was made:
```yaml
quicknotes_addr: ":9090"
```
to:
```yaml
quicknotes_addr: ":10080"
```
The deployment was previewed without applying changes.

Command:
```bash
┌──(p4in㉿kali)-[~/Desktop/DevOps-Intro]
└─$ ansible-playbook \
-i ansible/inventory.ini \
ansible/playbook.yaml \
--check \
--diff
```
Example diff:
```text
TASK [Deploy systemd unit] ****************************************************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/p4in/.ansible/tmp/ansible-local-12986_chi0777/tmp5lyaeezw/quicknotes.service.j2
@@ -11,7 +11,7 @@
 WorkingDirectory=/var/lib/quicknotes
-Environment="ADDR=:9090"
+Environment="ADDR=:10080"
 Environment="DATA_PATH=/var/lib/quicknotes/data.json"
 Environment="SEED_PATH=/var/lib/quicknotes/seed.json"
changed: [192.168.56.10]
```
The diff clearly shows the exact change that would be applied without modifying the target host.

### 2.4 Design questions

#### e) Why does the second run report changed=0?

The second run reports `changed=0` because Ansible compares 
the desired state described in the playbook with the actual state on the managed host.
The `file` module checks file ownership, permissions, and existence.
The `copy` module compares file content and metadata. The `template` module renders the template and compares the generated content with the deployed file.
When all managed resources already match the desired state,
no changes are required and every task reports `ok`.

#### f) What would happen if shell was used instead of template?

Using:
```yaml
shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'
```
would bypass Ansible's state tracking.
Possible failure modes include:
- The command would overwrite the entire service file each run.
- Ansible would often report changes every execution.
- Idempotency would be lost.
- Syntax mistakes could produce an invalid systemd unit.
- No automatic content comparison would occur.
- Selective updates and accurate change reporting would become difficult.
The `template` module avoids these problems by generating deterministic content
and comparing it before applying changes.

#### g) What bug would --check --diff catch that plain --check might miss?

`--check` reports that a file would change but does not clearly show what changed.
`--check --diff` displays the exact modification.
For example, if a template variable accidentally changed from:
```text
ADDR=:9090
```
to:
```text
ADDR=:9009
```
plain `--check` would only indicate that the template would be modified.
`--diff` immediately reveals the incorrect value before deployment,
making configuration mistakes easier to detect and preventing accidental production outages.
