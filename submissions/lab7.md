# Lab 7 - Configuration Management with Ansible

## Task 1 - Idempotent QuickNotes Deployment

I created an Ansible playbook that deploys QuickNotes to the Lab 5 Vagrant VM. The playbook creates the `quicknotes` system user, prepares `/var/lib/quicknotes`, copies the static binary and seed data, renders the systemd unit from a Jinja2 template, and enables and starts the service.

The implementation is stored in:
- `ansible/playbook.yaml`
- `ansible/inventory.ini`
- `ansible/templates/quicknotes.service.j2`
- `ansible/files/quicknotes`
- `ansible/files/seed.json`

The inventory uses the IP, SSH port, user, and private key reported by `vagrant ssh-config`.

### First deployment

The first real deployment completed successfully:

```text
PLAY RECAP
quicknotes-vm : ok=8 changed=7 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

The service was enabled and running:

```text
Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled)
Active: active (running)
```

The deployed files had the expected permissions:

```text
uid=996(quicknotes) gid=986(quicknotes)
drwxr-x--- quicknotes quicknotes /var/lib/quicknotes
-rwxr-xr-x root root /usr/local/bin/quicknotes
-rw-r----- quicknotes quicknotes /var/lib/quicknotes/seed.json
```

### Service verification

From the host:

```bash
curl -s http://localhost:18080/health
```

returned:

```json
{"notes":4,"status":"ok"}
```

`curl -s http://localhost:18080/notes` returned the four seeded notes, proving that `seed.json` was copied to the VM and `SEED_PATH=/var/lib/quicknotes/seed.json` was used successfully.

### Design questions

**a) What is the difference between `command:` and dedicated modules?**

`command` simply executes a command and normally does not know the desired state of a resource. Dedicated modules such as `file`, `copy`, `user`, and `systemd` first inspect the current state and only make a change when necessary. This makes them naturally idempotent and prevents unnecessary modifications on repeated runs.

**b) When does a handler fire?**

A handler is triggered by `notify` only when the notifying task reports `changed`. If the binary or systemd unit is already identical to the desired version, the task reports `ok` and the restart handler does not run. This avoids unnecessary service restarts.

**c) Where would I put variables for this lab?**

For this lab I would use:
1. Playbook `vars` for small deployment-specific values such as paths and `restart_sec`.
2. `group_vars` for values shared by all hosts in a group.
3. Role defaults if the deployment were moved into a reusable role, because they provide easy-to-override default values.

**d) Do we need `gather_facts`?**

No. This playbook does not use discovered host facts such as OS family, interfaces, memory, or architecture. Setting `gather_facts: false` skips the setup/fact-gathering stage, reducing connection work and execution time on every run.

---

## Task 2 — Idempotency and Selective Changes

### Second run

Running the same playbook again without changing the desired state produced:

```text
PLAY RECAP
quicknotes-vm : ok=10 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

This demonstrates idempotency: the VM was already in the desired state, so Ansible made no changes and no restart handler was executed.

### Selective variable change

I changed the template variable:

```yaml
restart_sec: "2s"
```

to:

```yaml
restart_sec: "3s"
```

Only the rendered systemd unit changed. Ansible then reloaded systemd and restarted QuickNotes through the handlers:

```text
TASK [Render QuickNotes systemd unit]
changed: [quicknotes-vm]

RUNNING HANDLER [Reload systemd]
ok: [quicknotes-vm]

RUNNING HANDLER [Restart QuickNotes]
changed: [quicknotes-vm]

PLAY RECAP
quicknotes-vm : ok=8 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

The resulting unit contained:

```text
RestartSec=3s
```

### `--check --diff`

I then changed `restart_sec` from `3s` to `4s` and ran:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
```

Ansible showed the expected preview:

```diff
-RestartSec=3s
+RestartSec=4s
```

The check-mode recap was:

```text
PLAY RECAP
quicknotes-vm : ok=8 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

After the dry run, the actual VM still contained:

```text
RestartSec=3s
```

so `--check` previewed the change without applying it. A normal run then applied the new value.

### Design questions

**e) Why does the second run report `changed=0`?**

Ansible modules compare the current state with the requested state. The `file` module checks properties such as existence, ownership, permissions, and file type. The `template` module renders the desired content and compares it with the destination. If they already match, no write is performed and the task reports `ok`.

**f) What if the unit were written using `shell: echo ... > file`?**

The shell command would execute every time without understanding whether the file already contains the correct configuration. It could therefore report unnecessary changes, overwrite the file incorrectly because of quoting or escaping, and trigger unnecessary restarts. The `template` module manages the file declaratively and can detect whether its rendered content actually changed.

**g) What can `--check --diff` catch that plain `--check` cannot?**

Plain `--check` tells me which tasks would change something, but `--diff` also shows the actual content difference. For example, it can reveal an incorrect environment variable, path, port, or accidentally removed systemd directive before the configuration is deployed.

---

## Bonus — `ansible-pull` GitOps Loop

I configured the VM to reconcile itself from my `feature/lab7` branch every five minutes.

The bonus artifacts are committed in:
- `ansible/local.ini`
- `ansible/files/ansible-pull.service`
- `ansible/files/ansible-pull.timer`

The playbook also installs Git and Ansible in the VM, installs the two systemd units, reloads systemd, and enables and starts the timer.

### Local inventory

```ini
[quicknotes]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

### ansible-pull service

```ini
[Unit]
Description=Ansible Pull reconciliation for QuickNotes
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull -U https://github.com/rslwqr/DevOps-Intro.git -C feature/lab7 -i ansible/local.ini ansible/playbook.yaml
```

### ansible-pull timer

```ini
[Unit]
Description=Run Ansible Pull for QuickNotes every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true
Unit=ansible-pull.service

[Install]
WantedBy=timers.target
```

The timer was enabled and active:

```text
ansible-pull.timer
Active: active (waiting)
Triggers: ansible-pull.service
```

### Automatic convergence test

I changed:

```yaml
restart_sec: "4s"
```

to:

```yaml
restart_sec: "5s"
```

and committed and pushed the change as:

```text
8e1055b test(lab7): verify ansible-pull reconciliation
```

Immediately after the push, the VM was still on the previous state:

```text
VM commit: 8253681
RestartSec=4s
```

I did not manually run `ansible-playbook` or start `ansible-pull.service`.

At approximately `16:14:05 UTC`, the systemd timer automatically triggered `ansible-pull`. The repository was updated:

```text
before: 8253681eec2d98a58b9276da794c21079800e23c
after:  8e1055b568b4736c46f1d6d89b44d35f42ba3e82
changed: true
```

The playbook detected the template change and invoked the handlers:

```text
TASK [Render QuickNotes systemd unit]
changed: [localhost]

RUNNING HANDLER [Reload systemd]
ok: [localhost]

RUNNING HANDLER [Restart QuickNotes]
changed: [localhost]

PLAY RECAP
localhost : ok=12 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

After automatic reconciliation:

```text
8e1055b
RestartSec=5s
```

This demonstrates the complete flow:

```text
Git push
   ↓
systemd timer
   ↓
ansible-pull
   ↓
new repository state
   ↓
Ansible convergence
   ↓
QuickNotes restarted with the new configuration
```

### Design questions

**h) What is the security benefit of pull mode?**

In the push model, a central control node needs network access and SSH credentials for managed hosts. With `ansible-pull`, the VM initiates the connection to the Git repository and applies the configuration locally. This can reduce the need to expose inbound SSH access or distribute privileged SSH credentials from a central controller. Repository credentials and supply-chain security still have to be managed securely.

**i) What is the equivalent pattern at the Kubernetes layer?**

The same reconciliation pattern is commonly called GitOps and is implemented by tools such as Argo CD and Flux. A controller continuously compares the desired state stored in Git with the actual cluster state and reconciles differences. `ansible-pull` is a VM-level approximation of the same idea: Git stores the desired configuration and the machine periodically pulls it and converges its local state