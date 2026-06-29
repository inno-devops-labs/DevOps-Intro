# Lab 7 Submission

## Task 1 - Idempotent Deploy to the Lab 5 VM

### `ansible/inventory.ini`

```ini
[quicknotes]
lab5 ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa'
```

### `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_group: quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_binary_src: files/quicknotes
    quicknotes_binary_path: /usr/local/bin/quicknotes
    quicknotes_service_name: quicknotes
    quicknotes_service_path: /etc/systemd/system/quicknotes.service
    quicknotes_addr: ":8080"
    quicknotes_data_path: /var/lib/quicknotes/notes.json
    quicknotes_seed_path: /var/lib/quicknotes/seed.json
    quicknotes_restart_backoff: 2

  tasks:
    - name: Ensure QuickNotes group exists
      ansible.builtin.group:
        name: "{{ quicknotes_group }}"
        system: true

    - name: Ensure QuickNotes system user exists
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        system: true
        create_home: false
        home: /nonexistent
        shell: /usr/sbin/nologin

    - name: Ensure QuickNotes data directory exists
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        mode: "0750"

    - name: Copy QuickNotes binary
      ansible.builtin.copy:
        src: "{{ quicknotes_binary_src }}"
        dest: "{{ quicknotes_binary_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart QuickNotes

    - name: Render QuickNotes systemd unit
      ansible.builtin.template:
        src: quicknotes.service.j2
        dest: "{{ quicknotes_service_path }}"
        owner: root
        group: root
        mode: "0644"
      notify:
        - Reload systemd
        - Restart QuickNotes

    - name: Apply pending service changes
      ansible.builtin.meta: flush_handlers

    - name: Enable and start QuickNotes service
      ansible.builtin.systemd_service:
        name: "{{ quicknotes_service_name }}"
        enabled: true
        state: started

  handlers:
    - name: Reload systemd
      ansible.builtin.systemd_service:
        daemon_reload: true

    - name: Restart QuickNotes
      ansible.builtin.systemd_service:
        name: "{{ quicknotes_service_name }}"
        state: restarted
```

### `ansible/templates/quicknotes.service.j2`

```ini
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
User={{ quicknotes_user }}
Group={{ quicknotes_group }}
WorkingDirectory={{ quicknotes_data_dir }}
Environment=ADDR={{ quicknotes_addr }}
Environment=DATA_PATH={{ quicknotes_data_path }}
Environment=SEED_PATH={{ quicknotes_seed_path }}
ExecStart={{ quicknotes_binary_path }}
Restart=on-failure
RestartSec={{ quicknotes_restart_backoff }}

[Install]
WantedBy=multi-user.target
```

### Dry run

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check
```

Output:

```text
PLAY [Deploy QuickNotes] ************************************************************************

TASK [Ensure QuickNotes group exists] ***********************************************************
ok: [lab5]

TASK [Ensure QuickNotes system user exists] *****************************************************
ok: [lab5]

TASK [Ensure QuickNotes data directory exists] **************************************************
ok: [lab5]

TASK [Copy QuickNotes binary] *******************************************************************
ok: [lab5]

TASK [Render QuickNotes systemd unit] ***********************************************************
ok: [lab5]

TASK [Apply pending service changes] ************************************************************

TASK [Enable and start QuickNotes service] ******************************************************
ok: [lab5]

PLAY RECAP **************************************************************************************
lab5                       : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Playbook run

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Output:

```text
PLAY [Deploy QuickNotes] ************************************************************************

TASK [Ensure QuickNotes group exists] ***********************************************************
ok: [lab5]

TASK [Ensure QuickNotes system user exists] *****************************************************
ok: [lab5]

TASK [Ensure QuickNotes data directory exists] **************************************************
ok: [lab5]

TASK [Copy QuickNotes binary] *******************************************************************
ok: [lab5]

TASK [Render QuickNotes systemd unit] ***********************************************************
ok: [lab5]

TASK [Apply pending service changes] ************************************************************

TASK [Enable and start QuickNotes service] ******************************************************
ok: [lab5]

PLAY RECAP **************************************************************************************
lab5                       : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Service verification

Command:

```bash
curl -s http://localhost:18080/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

### Design questions

#### a) What is the difference between `command:` and dedicated modules?

`command:` runs a command on the remote host exactly as requested. It usually does not know whether the target state is already correct, so it can easily report changes every run or repeat work unnecessarily.

Dedicated modules such as `apt`, `file`, `copy`, `template`, and `systemd_service` understand the state they manage. For example, `file` can check ownership and permissions, `copy` can compare file content and mode, and `systemd_service` can check whether a service is already enabled or running. These modules are idempotent because they only change the host when the current state differs from the requested state.

Idempotency matters because the same playbook should be safe to run repeatedly. A second run should confirm the VM is already configured instead of causing unnecessary service restarts or configuration drift.

#### b) When does `notify:` fire a handler, and when does it not fire?

A handler fires when a task that contains `notify:` reports `changed`. If the task reports `ok`, the handler is not queued.

In this playbook, the restart handler is notified by the binary copy task and the systemd unit template task. That means QuickNotes restarts only when the deployed binary or service unit actually changes. This is the right default because it avoids unnecessary restarts while still applying real deployment changes.

#### c) Where would you put variables for this lab, and why?

The top three useful places for this lab are:

- Playbook `vars`: good for this small lab because the variables are close to the tasks and easy to inspect.
- `group_vars/quicknotes.yaml`: good if the inventory grows or multiple VMs share the same QuickNotes settings.
- Role defaults: good if the playbook is later refactored into a reusable role, because defaults provide safe base values that can be overridden by inventory or playbook variables.

For this submission, the variables are in `ansible/playbook.yaml` because the lab is small and has one target group.

#### d) Do you need `gather_facts: true` for this playbook?

No. This playbook does not use facts such as OS version, network interfaces, CPU architecture, memory, or distribution details. Setting `gather_facts: false` saves the setup/facts collection step on each run, which reduces runtime and SSH overhead.

If the playbook later needed OS-specific package names or conditional logic based on the target system, then enabling facts would be useful.

## Task 2 - Prove Idempotency and Selective Re-run

### Second run with zero changes

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Output:

```text
PLAY [Deploy QuickNotes] ************************************************************************

TASK [Ensure QuickNotes group exists] ***********************************************************
ok: [lab5]

TASK [Ensure QuickNotes system user exists] *****************************************************
ok: [lab5]

TASK [Ensure QuickNotes data directory exists] **************************************************
ok: [lab5]

TASK [Copy QuickNotes binary] *******************************************************************
ok: [lab5]

TASK [Render QuickNotes systemd unit] ***********************************************************
ok: [lab5]

TASK [Apply pending service changes] ************************************************************

TASK [Enable and start QuickNotes service] ******************************************************
ok: [lab5]

PLAY RECAP **************************************************************************************
lab5                       : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

The second run reported `changed=0`, which shows that the current VM state already matched the playbook.

### Selective variable change

I changed `quicknotes_restart_backoff` from `2` to `3` in `ansible/playbook.yaml`.

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Output:

```text
PLAY [Deploy QuickNotes] ************************************************************************

TASK [Ensure QuickNotes group exists] ***********************************************************
ok: [lab5]

TASK [Ensure QuickNotes system user exists] *****************************************************
ok: [lab5]

TASK [Ensure QuickNotes data directory exists] **************************************************
ok: [lab5]

TASK [Copy QuickNotes binary] *******************************************************************
ok: [lab5]

TASK [Render QuickNotes systemd unit] ***********************************************************
changed: [lab5]

TASK [Apply pending service changes] ************************************************************

RUNNING HANDLER [Reload systemd] ****************************************************************
ok: [lab5]

RUNNING HANDLER [Restart QuickNotes] ************************************************************
changed: [lab5]

TASK [Enable and start QuickNotes service] ******************************************************
ok: [lab5]

PLAY RECAP **************************************************************************************
lab5                       : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Only the systemd unit template changed. That change notified the systemd reload and QuickNotes restart handlers.

### Health check after selective change

Command:

```bash
curl -s http://localhost:18080/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

### `--check --diff` preview

I changed `quicknotes_restart_backoff` from `3` to `4` in `ansible/playbook.yaml`, then ran check mode with diff.

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
```

Output:

```text
PLAY [Deploy QuickNotes] ************************************************************************

TASK [Ensure QuickNotes group exists] ***********************************************************
ok: [lab5]

TASK [Ensure QuickNotes system user exists] *****************************************************
ok: [lab5]

TASK [Ensure QuickNotes data directory exists] **************************************************
ok: [lab5]

TASK [Copy QuickNotes binary] *******************************************************************
ok: [lab5]

TASK [Render QuickNotes systemd unit] ***********************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/mostafa/.ansible/tmp/ansible-local-221449qtsrweyz/tmptmwotypc/quicknotes.service.j2
@@ -12,7 +12,7 @@
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=3
+RestartSec=4
 
 [Install]
 WantedBy=multi-user.target

changed: [lab5]

TASK [Apply pending service changes] ************************************************************

RUNNING HANDLER [Reload systemd] ****************************************************************
ok: [lab5]

RUNNING HANDLER [Restart QuickNotes] ************************************************************
changed: [lab5]

TASK [Enable and start QuickNotes service] ******************************************************
ok: [lab5]

PLAY RECAP **************************************************************************************
lab5                       : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

This was a dry-run preview. Ansible reported the predicted template change and the predicted notified handler, but it did not actually apply the `RestartSec=4` change to the VM.

### Design questions

#### e) Why does the second run report `changed=0`?

The second run reports `changed=0` because each Ansible module compares the remote host's current state with the desired state in the playbook.

The `file` module checks that `/var/lib/quicknotes` exists as a directory with the requested owner, group, and mode. The `copy` module checks whether the destination binary already has the same content and file metadata. The `template` module renders the template with the current variable values, compares the rendered result with the remote unit file, and changes the file only if the content or metadata differs.

Because the VM already matched the requested state, no tasks reported changes and no handlers were triggered.

#### f) What would happen if `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` was used instead of `template:`?

Using `shell` for the unit file would be less reliable and less idempotent. The shell command would rewrite the file whenever it ran unless extra manual checks were added. That could cause Ansible to report changes every run and restart QuickNotes unnecessarily.

It would also be easier to introduce quoting, escaping, or formatting mistakes in the systemd unit. The `template` module is safer because it manages the whole file declaratively, compares the rendered content before writing, supports check mode and diff output, and reports changes only when the generated unit actually differs.

#### g) What bug can `ansible-playbook --check --diff` catch that plain `--check` may miss?

Plain `--check` can show that a task would change something, but it does not show the exact content of the change. `--check --diff` shows the before and after content, which can catch mistakes before they are applied.

For example, it could reveal a wrong port, an incorrect data path, a missing environment variable, or an accidental edit that removes part of the systemd unit. In this task, the diff clearly showed the intended change from `RestartSec=3` to `RestartSec=4`.

## Bonus Task - `ansible-pull` GitOps Loop

### Bootstrap run from host

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

Output:

```text
PLAY [Deploy QuickNotes] ************************************************************************

TASK [Ensure QuickNotes group exists] ***********************************************************
ok: [lab5]

TASK [Ensure QuickNotes system user exists] *****************************************************
ok: [lab5]

TASK [Ensure QuickNotes data directory exists] **************************************************
ok: [lab5]

TASK [Copy QuickNotes binary] *******************************************************************
ok: [lab5]

TASK [Render QuickNotes systemd unit] ***********************************************************
ok: [lab5]

TASK [Apply pending service changes] ************************************************************

TASK [Enable and start QuickNotes service] ******************************************************
ok: [lab5]

TASK [Install ansible-pull dependencies] ********************************************************
changed: [lab5]

TASK [Ensure Ansible configuration directory exists] ********************************************
changed: [lab5]

TASK [Ensure ansible-pull working directory exists] *********************************************
changed: [lab5]

TASK [Create local ansible-pull inventory] ******************************************************
changed: [lab5]

TASK [Render ansible-pull service unit] *********************************************************
changed: [lab5]

TASK [Render ansible-pull timer unit] ***********************************************************
changed: [lab5]

TASK [Apply pending ansible-pull unit changes] **************************************************

RUNNING HANDLER [Reload systemd] ****************************************************************
ok: [lab5]

RUNNING HANDLER [Restart ansible-pull timer] ****************************************************
changed: [lab5]

TASK [Enable and start ansible-pull timer] ******************************************************
changed: [lab5]

PLAY RECAP **************************************************************************************
lab5                       : ok=15   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

This run installed Git and Ansible on the VM, created the local inventory, rendered the `ansible-pull` service and timer units, reloaded systemd, and enabled the timer.

### Timer status

Command:

```bash
systemctl list-timers | grep ansible-pull
```

Output:

```text
n/a                         n/a         Mon 2026-06-29 13:31:03 UTC 11ms ago      ansible-pull-quicknotes.timer  ansible-pull-quicknotes.service
```

Command:

```bash
systemctl status ansible-pull-quicknotes.timer
```

Output:

```text
● ansible-pull-quicknotes.timer - Run ansible-pull for QuickNotes every 5 minutes
     Loaded: loaded (/etc/systemd/system/ansible-pull-quicknotes.timer; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2026-06-29 13:26:02 UTC; 5min ago
    Trigger: n/a
   Triggers: ● ansible-pull-quicknotes.service
```

### Convergence demonstration

The GitOps loop was tested by changing `quicknotes_addr` to `:9090`, committing and pushing the change, then waiting for the systemd timer to run `ansible-pull`.

Timeline:

```text
Git commit timestamp: 2026-06-29 13:27:18 UTC
Timer fire observed: Mon 2026-06-29 13:31:03 UTC
QuickNotes reconciled: Mon 2026-06-29 13:31:19 UTC
```

Command:

```bash
date
```

Output:

```text
Mon Jun 29 01:31:27 PM UTC 2026
```

Command:

```bash
journalctl -u ansible-pull-quicknotes.service --since "10 minutes ago"
```

Output:

```text
Hint: You are currently not seeing messages from other users and the system.
      Users in groups 'adm', 'systemd-journal' can see all messages.
      Pass -q to turn off this notice.
-- No entries --
```

The service journal output was not visible as the `vagrant` user because journal access is restricted. The timer and resulting QuickNotes service state were used as evidence instead.

Command:

```bash
systemctl status quicknotes
```

Output:

```text
● quicknotes.service - QuickNotes API
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2026-06-29 13:31:19 UTC; 5min ago
   Main PID: 6749 (quicknotes)
      Tasks: 7 (limit: 1099)
     Memory: 1.5M
        CPU: 4ms
     CGroup: /system.slice/quicknotes.service
             └─6749 /usr/local/bin/quicknotes
```

Command:

```bash
systemctl cat quicknotes
```

Output:

```ini
# /etc/systemd/system/quicknotes.service
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
User=quicknotes
Group=quicknotes
WorkingDirectory=/var/lib/quicknotes
Environment=ADDR=:9090
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/var/lib/quicknotes/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec=4

[Install]
WantedBy=multi-user.target
```

The rendered unit contains `Environment=ADDR=:9090`, showing that the VM reconciled to the Git change without running `ansible-playbook` from the host again.

### Design questions

#### h) What is the security benefit of `ansible-pull` compared with push mode?

`ansible-pull` uses a pull model: the VM initiates an outbound connection to Git and applies the desired state locally. This reduces the need for a central control node with SSH access into every managed machine. It also reduces exposed inbound access requirements on the VM, because the VM does not need to accept configuration pushes from an external controller.

In push mode, the control node must be able to SSH into the VM. If that control node or its SSH credentials are compromised, every reachable managed host may be exposed. With pull mode, each VM only needs enough access to read the repository and converge itself.

#### i) What is the same pattern called at the Kubernetes layer?

At the Kubernetes layer, this pattern is called GitOps. Common tools for it include Argo CD and Flux.

`ansible-pull` is a fair VM-layer simulator because it follows the same core idea: Git stores the desired state, a machine periodically pulls that desired state, and the machine reconciles itself until the live state matches the repository. In this lab, the VM plays the role of the reconciler by running `ansible-pull` every 5 minutes through a systemd timer.
