# Lab 7 Submission


## Task 1. Deploy QuickNotes Using Ansible

### Project Layout

The following Ansible project was created:

```text
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   └── quicknotes
└── templates/
    └── quicknotes.service.j2
```

---

### SSH Configuration

Source file:

```text
submissions/src/lab07/vagrant_ssh_config.txt
```

Command:

```powershell
vagrant ssh-config
```

Output:

```text
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  IdentityFile .vagrant/machines/default/virtualbox/private_key
```

---

### Ansible Version

Source file:

```text
submissions/src/lab07/ansible_version.txt
```

Command:

```bash
ansible --version
```

Result:

```text
Ansible 10.x
```

---

### QuickNotes Binary

Source file:

```text
submissions/src/lab07/quicknotes_binary_ls.txt
```

Command:

```bash
ls -lh ansible/files/quicknotes
```

Output:

```text
-rwxrwxrwx ... 5.6M ansible/files/quicknotes
```

---

### Dry Run

Source file:

```text
submissions/src/lab07/check_run.txt
```

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check
```

PLAY RECAP:

```text
ok=8
changed=6
failed=0
```

The dry run showed which resources would be created without modifying the VM.

---

### First Deployment

Source file:

```text
submissions/src/lab07/first_run.txt
```

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

PLAY RECAP:

```text
ok=8
changed=6
failed=0
```

The playbook successfully:

- created the `quicknotes` system user;
- created the data directory;
- copied the application binary;
- copied the seed file;
- rendered the systemd service;
- enabled and started the service.

---

### Verify systemd Service

Source file:

```text
submissions/src/lab07/systemctl_status.txt
```

Command:

```bash
systemctl status quicknotes --no-pager
```

Output:

```text
Loaded: loaded
Active: active (running)
```

The service is running successfully under systemd.

---

## Task 1 Design Questions

### Question a. command vs Dedicated Modules

Dedicated modules know the desired state and only change the system when necessary. Modules such as `user`, `file`, `copy`, `template`, and `systemd` are idempotent.

The `command` module simply executes a command every time and usually cannot determine whether a change is needed.

---

### Question b. notify and Handlers

A handler runs only when a task reports `changed`.

If no task changes anything, the handler is not executed.

This avoids unnecessary service restarts.

---

### Question c. Variable Hierarchy

For this lab I would use:

1. Playbook variables for deployment settings.
2. Inventory or group variables for host-specific configuration.
3. Role defaults for reusable default values.

This keeps configuration organized and easy to override.

---

### Question d. gather_facts

This playbook does not require system facts.

Setting

```yaml
gather_facts: false
```

reduces execution time because Ansible skips collecting hardware and operating system information.

---

## Task 2. Idempotency

### Second Run

Source file:

```text
submissions/src/lab07/second_run_idempotent.txt
```

Command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

PLAY RECAP:

```text
ok=6
changed=0
failed=0
```

The second execution made no changes, proving that the playbook is idempotent.

---

### Selective Reconfiguration

Source file:

```text
submissions/src/lab07/selective_change_9090.txt
```

A single variable was modified:

```yaml
listen_addr: ":9090"
```

The playbook was executed again.

PLAY RECAP:

```text
ok=8
changed=2
failed=0
```

Only the template changed and the restart handler executed.

All other tasks remained unchanged.

---

### Verify Updated Port

Source file:

```text
submissions/src/lab07/health_9090_inside_vm.txt
```

Command:

```bash
curl http://localhost:9090/health
```

Output:

```json
{"notes":4,"status":"ok"}
```

The application was successfully reconfigured.

---

### Check Mode with Diff

Source file:

```text
submissions/src/lab07/check_diff.txt
```

Command:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yaml \
  --check --diff
```

The output shows only the modified line:

```diff
-RestartSec=2
+RestartSec=3
```

This previews configuration changes before deployment.

---

## Task 2 Design Questions

### Question e. Why changed=0?

Modules compare the desired state with the current state.

If file contents, permissions, ownership, and configuration already match, no changes are required.

---

### Question f. Why Not Use shell?

Using

```yaml
shell:
```

would overwrite files every execution.

The task would always report changes, making the playbook non-idempotent and restarting services unnecessarily.

The `template` module compares the rendered file and updates it only when required.

---

### Question g. Why Use --check --diff?

`--check` predicts which tasks would change.

`--diff` additionally shows the exact file modifications.

This helps detect incorrect configuration changes before applying them.

---


# Observations

- Ansible successfully deployed QuickNotes to the Lab 5 VM.
- The playbook is fully idempotent.
- Dedicated Ansible modules simplify configuration management.
- Handlers restart services only when configuration actually changes.
- Jinja2 templates make systemd configuration reusable.
- `--check --diff` provides a safe preview before deployment.
- Running with `gather_facts: false` reduces execution time.


# Conclusions

- QuickNotes was successfully deployed using Ansible.
- The application runs as a managed systemd service.
- The playbook is idempotent and reproducible.
- Configuration changes affect only the required resources.
- Ansible provides a reliable and maintainable way to automate server configuration.
