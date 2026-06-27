# Lab 7 Submission
## Task 1

### Configuration Files

**`app/ansible/local.ini`** (Local Inventory used inside the VM):

```ini
[quicknotes_vm]
127.0.0.1 ansible_connection=local

```

**`app/ansible/playbook.yaml`**:

```yaml
---
- name: Deploy QuickNotes to VM
  hosts: quicknotes_vm
  become: true
  vars:
    listen_addr: ":8080"
    data_path: "/var/lib/quicknotes/notes.json"

  tasks:
    - name: 1. Create system user quicknotes
      ansible.builtin.user:
        name: quicknotes
        system: true
        create_home: false
        shell: /usr/sbin/nologin

    - name: 2. Ensure data directory exists with right permissions
      ansible.builtin.file:
        path: /var/lib/quicknotes
        state: directory
        owner: quicknotes
        group: quicknotes
        mode: '0750'

    - name: 3. Copy binary to /usr/local/bin
      ansible.builtin.copy:
        src: files/quicknotes
        dest: /usr/local/bin/quicknotes
        mode: '0755'
      notify: restart quicknotes

    - name: 4. Template systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
      notify: restart quicknotes

    - name: 5. Enable and start service
      ansible.builtin.systemd:
        name: quicknotes
        state: started
        enabled: true
        daemon_reload: true

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted

```

**`app/ansible/templates/quicknotes.service.j2`**:

```ini
[Unit]
Description=QuickNotes App
After=network-online.target

[Service]
Type=simple
User=quicknotes
WorkingDirectory=/var/lib/quicknotes
Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ data_path }}
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure

[Install]
WantedBy=multi-user.target

```

### Deployment

**PLAY RECAP:**

```text
PLAY RECAP *************************************************************************************************************************************************************************
127.0.0.1                  : ok=6    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

**Verification:**

```text
vagrant@quicknotes-vm:/vagrant$ curl http://localhost:8080/health
{"notes":0,"status":"ok"}

```

### Design Questions

**a) What's the difference between `command:` and the dedicated modules (`apt`, `file`, `copy`, `systemd`)? Which is idempotent, and why does it matter?**
```
The command: module blindly executes the provided shell commands every time the playbook runs, making them inherently non-idempotent. Dedicated modules like file or copy are declarative and idempotent because they first check the current state of the system (checking if a file exists) and only apply changes if the desired state differs from the actual state. It matters because it prevents unnecessary service restarts, minimizes downtime, and ensures the playbook can be safely run multiple times without breaking the system.
```

**b) `notify:` and `handlers:` when does a handler fire? When does it not fire? Why is that the right default?**
```
A handler fires at the very end of a play, and only if the task that contains the notify directive reports a changed status. If the task reports ok, the handler does not fire. It is a right default - restarting a service should only happen when its configuration or binary has actually been modified.
```
**c) Variable hierarchy: List the top 3 places you'd put a variable for this lab and why.**
```
1. Playbook variables (vars: block): Ideal for this lab because the scope is limited to this specific deployment, making it easy to read and modify directly within the playbook file.
2. group_vars/: Best for variables that apply to specific environments.
3. Role defaults: Used when creating reusable roles; they have the lowest precedence, allowing users to easily override them with playbook or inventory variables without modifying the role itself.
```

**d) `gather_facts: true` is the default. Do you need it for this playbook? What does turning it off save you per run?**
```
We do not strictly need it for this specific playbook because we are not using any automatically gathered system variables. Turning it off saves execution time, as Ansible skips the process of connecting to the host and running setup scripts to collect hardware and OS information before executing the tasks.
```
---

## Task 2

### Re-run = zero changes

```text
PLAY RECAP *************************************************************************************************************************************************************************
127.0.0.1                  : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

### Variable Tweak

```text
TASK [4. Template systemd unit] ****************************************************************************************************************************************************
changed: [127.0.0.1]

TASK [5. Enable and start service] *************************************************************************************************************************************************
ok: [127.0.0.1]

RUNNING HANDLER [restart quicknotes] ***********************************************************************************************************************************************
changed: [127.0.0.1]

PLAY RECAP *************************************************************************************************************************************************************************
127.0.0.1                  : ok=6    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```

###  `--check --diff`

```diff
vagrant@quicknotes-vm:/vagrant$ ansible-playbook -i app/ansible/local.ini app/ansible/playbook.yaml --check --diff

PLAY [Deploy QuickNotes to VM] *****************************************************************************************************************************************************

TASK [1. Create system user quicknotes] ********************************************************************************************************************************************
ok: [127.0.0.1]

TASK [2. Ensure data directory exists with right permissions] **********************************************************************************************************************
ok: [127.0.0.1]

TASK [3. Copy binary to /usr/local/bin] ********************************************************************************************************************************************
ok: [127.0.0.1]

TASK [4. Template systemd unit] ****************************************************************************************************************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/vagrant/.ansible/tmp/ansible-local-479661os78vt/tmp_8qb216v/quicknotes.service.j2
@@ -6,7 +6,7 @@
 Type=simple
 User=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:8081
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure

changed: [127.0.0.1]

TASK [5. Enable and start service] *************************************************************************************************************************************************
ok: [127.0.0.1]

RUNNING HANDLER [restart quicknotes] ***********************************************************************************************************************************************
changed: [127.0.0.1]

PLAY RECAP *************************************************************************************************************************************************************************
127.0.0.1                  : ok=6    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Design Questions

**e) Why does the second run report `changed=0`? What specifically does the `file` / `template` module check to decide?**
```
Second run reports changed=0 due to idempotency. The module doesn't just blindly execute commands; it checks the desired state against the actual state. Specifically, the template module calculates the SHA-1 checksum of the destination file on the server and compares it with the checksum of the rendered template. The file module checks the current file permissions, owner, and group. If everything matches exactly, Ansible safely skips the task to prevent unnecessary changes.
```

**f) What would happen if you used `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` instead of the `template:` module? Trace the failure modes**
```
The shell module is not naturally idempotent.
It would run the echo command every single time the playbook is executed, so the task would always report changed=1, even if the file content hasn't actually changed. As it always reports changed, it would continuously trigger the handler to restart the service on every run, leading to unnecessary application downtime.
```

**g) `ansible-playbook --check` is dry-run. `--diff` shows changes. What's the bug you'd catch by running `--check --diff` before a production deploy that you'd miss with plain `--check`?**
```
Plain --check only tells that a file will be modified, but it doesn't tell you how. If you made a typo in a variable, --check would hide this detail. By adding --diff, you see exactly the lines being added/removed, allowing you to catch typos.
```
---

## Bonus Task

### Timer Status

```text
vagrant@quicknotes-vm:/vagrant$ systemctl list-timers | grep ansible-pull
Mon 2026-06-22 18:09:35 UTC 3min 15s left Mon 2026-06-22 18:04:35 UTC 1min 44s ago  ansible-pull.timer             ansible-pull.service
```

### Convergence Timeline

* **18:10 UTC:** Changed listen_addr to 8080, committed, and pushed to `feature/lab7` branch on GitHub. Forced pushed the compiled Linux binary to the repository so the agent could download it.
* **18:12 UTC:** Triggered the `ansible-pull.service` agent to fetch changes.
* **18:17 UTC:** The systemd timer automatically fired `ansible-pull`. It successfully cloned the repository, recognized the file differences, applied the template changes, and restarted the service.
* **18:18 UTC:** Verified convergence by running `curl http://localhost:8080/health`, which successfully returned `{"notes":0,"status":"ok"}`, proving the VM auto-reconciled its state.

### Design Questions

**h) `ansible-pull` is "pull" mode. What's the security benefit vs the "push" model where a control node SSHes in?**
```
In the push model, the control node requires inbound SSH access and credentials to every server. If the control node is compromised, the attacker gains access to the entire infrastructure. In the pull model, servers only need outbound internet access to the Git repository. There are no open inbound ports required, and no central repository of highly privileged SSH keys, drastically reducing the attack surface.
```
**i) What's the same pattern called when applied at the Kubernetes layer? Why is `ansible-pull` a fair simulator at the VM layer?**
```
At the Kubernetes layer, this pattern is called GitOps. ansible-pull is a fair simulator because it follows the exact same philosophy: a Git repository acts as the single source of truth, and a continuous background loop automatically pulls the desired state and reconciles the local environment to match it without manual intervention.
```