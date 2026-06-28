# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

## Environment note

Ansible was executed from a temporary Docker control node because Ansible was not installed directly on Windows/Git Bash. The control container mounted the repository into `/work`, installed Ansible 10.x, copied the Vagrant SSH key into `/tmp/vagrant_key`, and connected to the Lab 5 Vagrant VM through `host.docker.internal:2222`.

Ansible version:

```text
ansible [core 2.17.14]
python version = 3.12.3
```

## Task 1 — Idempotent Deploy to the Lab 5 VM

### Project layout

```text
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   └── quicknotes
└── templates/
    └── quicknotes.service.j2
```

The static QuickNotes binary was built with:

```bash
cd app
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o ../ansible/files/quicknotes .
cd ..
```

## `ansible/inventory.ini`

```ini
[quicknotes_vm]
lab5-vm ansible_host=host.docker.internal ansible_port=2222 ansible_user=vagrant ansible_private_key_file=/tmp/vagrant_key ansible_python_interpreter=/usr/bin/python3

[quicknotes_vm:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostkeyAlgorithms=+ssh-rsa'
```

Connection test:

```bash
ansible -i ansible/inventory.ini quicknotes_vm -m ping
```

Output:

```text
lab5-vm | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes to Lab 5 VM
  hosts: quicknotes_vm
  become: true
  gather_facts: false

  vars:
    service_description: "QuickNotes service"
    service_name: "quicknotes"
    service_user: "quicknotes"
    service_group: "quicknotes"
    data_dir: "/var/lib/quicknotes"
    binary_path: "/usr/local/bin/quicknotes"
    listen_addr: ":8080"
    data_path: "/var/lib/quicknotes/notes.json"
    seed_path: "/var/lib/quicknotes/seed.json"
    restart_sec: "3s"

  tasks:
    - name: Ensure quicknotes system user exists
      ansible.builtin.user:
        name: "{{ service_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false

    - name: Ensure QuickNotes data directory exists
      ansible.builtin.file:
        path: "{{ data_dir }}"
        state: directory
        owner: "{{ service_user }}"
        group: "{{ service_group }}"
        mode: "0750"

    - name: Copy seed data
      ansible.builtin.copy:
        src: ../app/seed.json
        dest: "{{ seed_path }}"
        owner: "{{ service_user }}"
        group: "{{ service_group }}"
        mode: "0640"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ binary_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart quicknotes

    - name: Render systemd unit
      ansible.builtin.template:
        src: quicknotes.service.j2
        dest: "/etc/systemd/system/{{ service_name }}.service"
        owner: root
        group: root
        mode: "0644"
      notify: Restart quicknotes

    - name: Enable and start QuickNotes service
      ansible.builtin.systemd_service:
        name: "{{ service_name }}"
        enabled: true
        state: started
        daemon_reload: true

  handlers:
    - name: Restart quicknotes
      ansible.builtin.systemd_service:
        name: "{{ service_name }}"
        state: restarted
        daemon_reload: true
```

## `ansible/templates/quicknotes.service.j2`

```ini
[Unit]
Description={{ service_description }}
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User={{ service_user }}
Group={{ service_group }}
WorkingDirectory={{ data_dir }}
Environment="ADDR={{ listen_addr }}"
Environment="DATA_PATH={{ data_path }}"
Environment="SEED_PATH={{ seed_path }}"
ExecStart={{ binary_path }}
Restart=on-failure
RestartSec={{ restart_sec }}

[Install]
WantedBy=multi-user.target
```

## First real run

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Output:

```text
PLAY [Deploy QuickNotes to Lab 5 VM] ************************************************

TASK [Ensure quicknotes system user exists] *****************************************
changed: [lab5-vm]

TASK [Ensure QuickNotes data directory exists] **************************************
changed: [lab5-vm]

TASK [Copy seed data] ***************************************************************
changed: [lab5-vm]

TASK [Copy QuickNotes binary] *******************************************************
changed: [lab5-vm]

TASK [Render systemd unit] **********************************************************
changed: [lab5-vm]

TASK [Enable and start QuickNotes service] ******************************************
changed: [lab5-vm]

RUNNING HANDLER [Restart quicknotes] ************************************************
changed: [lab5-vm]

PLAY RECAP **************************************************************************
lab5-vm : ok=7 changed=7 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

## Service verification

Command from Windows host:

```bash
curl -s http://localhost:18080/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

Service status from Ansible:

```bash
ansible -i ansible/inventory.ini quicknotes_vm -a "systemctl status quicknotes --no-pager"
```

Output excerpt:

```text
quicknotes.service - QuickNotes service
Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; preset: enabled)
Active: active (running)
Main PID: 2214 (quicknotes)
CGroup: /system.slice/quicknotes.service
        └─2214 /usr/local/bin/quicknotes

quicknotes listening on :8080 (notes loaded: 4)
```

## Task 1 — Design Questions

### a) What is the difference between `command:` and dedicated modules like `apt`, `file`, `copy`, and `systemd`?

`command:` runs a raw command on the target machine and usually does not know whether the system is already in the desired state. Dedicated modules like `apt`, `file`, `copy`, and `systemd` understand the resource they manage and can check the current state before changing anything. For example, `file` can check owner, mode, and path state, while `copy` can compare file content checksums before replacing a file. This matters because idempotent modules allow the same playbook to be re-run safely and report `changed=0` when nothing actually changed.

### b) When does a handler fire? When does it not fire? Why is that the right default?

A handler fires when a task with `notify:` reports `changed`. In this playbook, the `Restart quicknotes` handler runs when the QuickNotes binary or the systemd unit template changes. It does not fire when the task reports `ok`, meaning the file or template is already correct. This is the right default because services should restart only when their configuration or binary changes, not on every playbook run.

### c) Where would you put variables for this lab and why?

For this lab, I would put the main service variables directly in `playbook.yaml` because the deployment has one target and the values are easy to read next to the tasks. If the project grew to multiple environments, I would move shared values into `group_vars/quicknotes_vm.yml` so all hosts in the group use the same defaults. For role-based reuse, I would put safe default values in `defaults/main.yml`, because role defaults are easy to override from inventory, group variables, or extra variables. This keeps the playbook simple now but gives a clean path to scale later.

### d) Do you need `gather_facts: true` for this playbook? What does turning it off save?

This playbook does not need `gather_facts: true` because it does not use facts like OS family, memory, interfaces, or distribution version. All paths, users, ports, and service settings are explicitly defined as variables. Turning fact gathering off saves time on every run because Ansible skips the setup phase that collects system information from the VM. It also makes the playbook output shorter and easier to inspect for this small deployment.

## Task 2 — Prove Idempotency + Selective Re-run

## Second run — zero changes

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Output:

```text
PLAY [Deploy QuickNotes to Lab 5 VM] ************************************************

TASK [Ensure quicknotes system user exists] *****************************************
ok: [lab5-vm]

TASK [Ensure QuickNotes data directory exists] **************************************
ok: [lab5-vm]

TASK [Copy seed data] ***************************************************************
ok: [lab5-vm]

TASK [Copy QuickNotes binary] *******************************************************
ok: [lab5-vm]

TASK [Render systemd unit] **********************************************************
ok: [lab5-vm]

TASK [Enable and start QuickNotes service] ******************************************
ok: [lab5-vm]

PLAY RECAP **************************************************************************
lab5-vm : ok=6 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

## Selective variable change

I changed one variable in `ansible/playbook.yaml`:

```diff
-restart_sec: "2s"
+restart_sec: "3s"
```

Command:

```bash
sed -i 's/restart_sec: "2s"/restart_sec: "3s"/' ansible/playbook.yaml
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Output:

```text
PLAY [Deploy QuickNotes to Lab 5 VM] ************************************************

TASK [Ensure quicknotes system user exists] *****************************************
ok: [lab5-vm]

TASK [Ensure QuickNotes data directory exists] **************************************
ok: [lab5-vm]

TASK [Copy seed data] ***************************************************************
ok: [lab5-vm]

TASK [Copy QuickNotes binary] *******************************************************
ok: [lab5-vm]

TASK [Render systemd unit] **********************************************************
changed: [lab5-vm]

TASK [Enable and start QuickNotes service] ******************************************
ok: [lab5-vm]

RUNNING HANDLER [Restart quicknotes] ************************************************
changed: [lab5-vm]

PLAY RECAP **************************************************************************
lab5-vm : ok=7 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

## Idempotency after selective change

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Output:

```text
PLAY [Deploy QuickNotes to Lab 5 VM] ************************************************

TASK [Ensure quicknotes system user exists] *****************************************
ok: [lab5-vm]

TASK [Ensure QuickNotes data directory exists] **************************************
ok: [lab5-vm]

TASK [Copy seed data] ***************************************************************
ok: [lab5-vm]

TASK [Copy QuickNotes binary] *******************************************************
ok: [lab5-vm]

TASK [Render systemd unit] **********************************************************
ok: [lab5-vm]

TASK [Enable and start QuickNotes service] ******************************************
ok: [lab5-vm]

PLAY RECAP **************************************************************************
lab5-vm : ok=6 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

## `--check --diff` preview

I made a temporary variable change:

```diff
-service_description: "QuickNotes service"
+service_description: "QuickNotes managed by Ansible"
```

Command:

```bash
sed -i 's/service_description: "QuickNotes service"/service_description: "QuickNotes managed by Ansible"/' ansible/playbook.yaml
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
```

Output excerpt:

```diff
TASK [Render systemd unit] **********************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /root/.ansible/tmp/ansible-local-6872h9oihe6/tmpzsj1dor2/quicknotes.service.j2
@@ -1,5 +1,5 @@
 [Unit]
-Description=QuickNotes service
+Description=QuickNotes managed by Ansible
 Wants=network-online.target
 After=network-online.target

changed: [lab5-vm]
```

PLAY RECAP:

```text
PLAY RECAP **************************************************************************
lab5-vm : ok=7 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

After the diff preview, I reverted the temporary variable change:

```bash
sed -i 's/service_description: "QuickNotes managed by Ansible"/service_description: "QuickNotes service"/' ansible/playbook.yaml
```

Final clean run:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Output:

```text
PLAY RECAP **************************************************************************
lab5-vm : ok=6 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

Final health check:

```bash
curl -s http://localhost:18080/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

## Task 2 — Design Questions

### e) Why does the second run report `changed=0`?

The second run reports `changed=0` because the target VM already matches the desired state described by the playbook. The `file` module checks whether the directory exists with the correct owner, group, and mode. The `copy` module checks whether the destination file already has the same content and permissions. The `template` module renders the template and compares it with the existing remote file, so if the rendered content is identical, it reports `ok` instead of `changed`.

### f) What would happen if you used `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` instead of the `template:` module?

Using `shell` with `echo` would be less reliable and less idempotent than using `template`. The shell command may report `changed` every time even if the file content is the same, which would cause unnecessary service restarts. It would also be easier to break quoting, formatting, environment variables, or multi-line systemd syntax. The `template` module is safer because it renders a structured Jinja2 file, compares the result with the current remote file, and only reports a change when the actual content differs.

### g) What bug would `--check --diff` catch that plain `--check` would miss?

Plain `--check` tells me whether Ansible expects a change, but it does not clearly show the exact content that would change. `--check --diff` would catch mistakes inside the rendered systemd unit, such as a wrong `Description`, incorrect `ADDR`, wrong `DATA_PATH`, or a broken `ExecStart` line. Without `--diff`, I might only see that the template would change, but not notice that the generated file contains the wrong value. This is useful before production deploys because it lets me review the exact configuration change before applying it.
