# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

## Overview

This lab deploys the QuickNotes Go application to the existing Lab 5 Ubuntu
VirtualBox VM using Ansible.

The implementation:

- creates a dedicated non-login system account;
- creates and secures the application data directory;
- deploys a statically linked QuickNotes binary;
- renders a variable-driven systemd unit;
- enables and starts the service;
- restarts the service only when the binary or unit changes;
- demonstrates idempotency and check mode;
- implements a five-minute `ansible-pull` GitOps reconciliation loop.

## Environment

- Host: Ubuntu under WSL
- Host Ansible distribution: 10.7.0
- Host Ansible Core: 2.17.14
- Target VM: Ubuntu 22.04.5 LTS
- VM SSH user: `vagrant`
- VM Python: 3.10.12
- VM distribution `ansible-pull`: 2.10.8
- Application port in VM: `8080`
- Forwarded host endpoint: `http://127.0.0.1:18080`
- Lab branch: `feature/lab7`

The Lab 5 VM was reached from WSL through the Windows host gateway at
`192.168.240.1:2200`, using the Vagrant-generated SSH key copied to
`~/.ssh/lab5_vagrant_rsa`.

## Repository Layout

The implementation files are:

- [`ansible/inventory.ini`](../ansible/inventory.ini)
- [`ansible/inventory-local.ini`](../ansible/inventory-local.ini)
- [`ansible/playbook.yaml`](../ansible/playbook.yaml)
- [`ansible/files/quicknotes`](../ansible/files/quicknotes)
- [`ansible/files/seed.json`](../ansible/files/seed.json)
- [`ansible/templates/quicknotes.service.j2`](../ansible/templates/quicknotes.service.j2)
- [`ansible/templates/ansible-pull.service.j2`](../ansible/templates/ansible-pull.service.j2)
- [`ansible/templates/ansible-pull.timer.j2`](../ansible/templates/ansible-pull.timer.j2)

---

# Task 1 — Idempotent QuickNotes Deployment

## Inventory

The remote inventory contains the VM connection information:

```ini
[quicknotes_vm]
quicknotes-vm ansible_host=192.168.240.1

[quicknotes_vm:vars]
ansible_port=2200
ansible_user=vagrant
ansible_ssh_private_key_file=~/.ssh/lab5_vagrant_rsa
ansible_python_interpreter=/usr/bin/python3.10
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedKeyTypes=+ssh-rsa'
```

## Playbook Behaviour

The playbook runs with privilege escalation and performs the following steps:

1. Creates the `quicknotes` system group.
2. Creates the `quicknotes` system user.
3. Disables interactive login with `/usr/sbin/nologin`.
4. Creates no home directory for the service account.
5. Creates `/var/lib/quicknotes`.
6. Sets directory ownership to `quicknotes:quicknotes`.
7. Sets directory mode to `0750`.
8. Copies the static binary to `/usr/local/bin/quicknotes`.
9. Sets binary mode to `0755`.
10. Copies the seed data to `/var/lib/quicknotes/seed.json`.
11. Renders `/etc/systemd/system/quicknotes.service`.
12. Reloads systemd.
13. Enables and starts QuickNotes.
14. Restarts QuickNotes only when the binary or unit changes.

## QuickNotes systemd Unit

The Jinja2 template renders a unit with:

```ini
[Unit]
Description=QuickNotes API
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=quicknotes
Group=quicknotes
WorkingDirectory=/var/lib/quicknotes
Environment="ADDR=:8080"
Environment="DATA_PATH=/var/lib/quicknotes/notes.json"
Environment="SEED_PATH=/var/lib/quicknotes/seed.json"
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec=6s

[Install]
WantedBy=multi-user.target
```

The service therefore:

- waits for the network-online target;
- runs as a non-root user;
- uses the protected data directory;
- receives all application paths through variables;
- automatically restarts after a failure.

## Initial Check-Mode Run

Command:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yaml \
  --check
```

Recap:

```text
PLAY RECAP *********************************************************************
quicknotes-vm : ok=6 changed=6 unreachable=0 failed=0 skipped=2 rescued=0 ignored=0
```

The dry run predicted six changes.

Ansible warned that the `quicknotes` user and group did not physically exist
yet. This is expected on a clean machine because check mode predicts their
creation without actually creating them.

The service start task and restart handler were intentionally skipped in check
mode to prevent systemd operations against a unit that had not yet been
created.

## First Real Deployment

Command:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yaml
```

Task results:

```text
TASK [Ensure the QuickNotes system group exists]       changed
TASK [Ensure the QuickNotes system user exists]        changed
TASK [Ensure the QuickNotes data directory exists]     changed
TASK [Copy the QuickNotes binary]                      changed
TASK [Copy the QuickNotes seed data]                   changed
TASK [Render the QuickNotes systemd unit]              changed
TASK [Enable and start QuickNotes]                     changed
RUNNING HANDLER [Restart QuickNotes]                   changed
```

First-run recap:

```text
PLAY RECAP *********************************************************************
quicknotes-vm : ok=8 changed=8 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

## Service and File Verification

The service was enabled and running:

```text
active=active
enabled=enabled
```

The service log confirmed that QuickNotes loaded the seed data:

```text
quicknotes listening on :8080 (notes loaded: 4)
```

The dedicated system account was created:

```text
uid=997(quicknotes) gid=998(quicknotes) groups=998(quicknotes)
```

Ownership and permissions were:

```text
quicknotes:quicknotes 750 /var/lib/quicknotes
quicknotes:quicknotes 640 /var/lib/quicknotes/seed.json
root:root 755 /usr/local/bin/quicknotes
root:root 644 /etc/systemd/system/quicknotes.service
```

The running process was owned by the dedicated service account:

```text
quicknotes quicknotes /usr/local/bin/quicknotes
```

## Host Health Check

Command:

```bash
curl.exe -sS http://127.0.0.1:18080/health
```

Result:

```json
{"notes":4,"status":"ok"}
```

## Task 1 Design Questions

### a) What is the difference between `command` and dedicated Ansible modules?

The `command` module executes an operating-system command. It generally does
not understand the desired state of the resource being managed. Unless
conditions such as `creates`, `removes`, or custom `changed_when` logic are
provided, it may execute on every run and report unnecessary changes.

Dedicated modules such as `apt`, `file`, `copy`, `template`, `user`, and
`systemd` understand their resource type. They inspect the current package,
file, user, or service state and make a change only when the declared target
state differs.

This makes the playbook declarative and idempotent.

### b) When do handlers and `notify` run?

A task queues a notified handler only when that task reports `changed`.

Several tasks may notify the same handler, but Ansible normally executes that
handler once at the end of the play. If all notifying tasks report `ok`, the
handler does not run.

In this implementation, both the binary copy task and systemd template task
notify the QuickNotes restart handler. Therefore, the service restarts only
when its executable or effective configuration changes.

### c) Where should variables be stored?

For this compact lab, the application paths and service settings are stored in
the playbook `vars` section.

For a larger inventory, shared host-group settings could be moved to
`group_vars/quicknotes_vm.yml`. Host-specific values could be placed in
`host_vars/<hostname>.yml`. Reusable role defaults should be placed in
`roles/<role-name>/defaults/main.yml`.

Extra variables supplied with `-e` are useful for temporary overrides but
should not normally be the permanent configuration source.

### d) Is fact gathering required?

Fact gathering is disabled with:

```yaml
gather_facts: false
```

The playbook does not use discovered facts such as interfaces, processor
architecture, memory, or operating-system family.

Disabling fact gathering avoids the automatic setup phase and can save
approximately 5–30 seconds per run, depending on the host and connection
latency. The benefit becomes more significant across many machines or
high-latency SSH connections.

---

# Task 2 — Idempotency and Selective Re-run

## Unchanged Second Run

The unchanged playbook was executed a second time.

Result:

```text
TASK [Ensure the QuickNotes system group exists]       ok
TASK [Ensure the QuickNotes system user exists]        ok
TASK [Ensure the QuickNotes data directory exists]     ok
TASK [Copy the QuickNotes binary]                      ok
TASK [Copy the QuickNotes seed data]                   ok
TASK [Render the QuickNotes systemd unit]              ok
TASK [Enable and start QuickNotes]                     ok
```

Recap:

```text
PLAY RECAP *********************************************************************
quicknotes-vm : ok=7 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

The handler did not run. This proves that the core deployment is idempotent.

## Selective Variable Change

The restart delay was changed from `3s` to `4s`.

Result:

```text
TASK [Ensure the QuickNotes system group exists]       ok
TASK [Ensure the QuickNotes system user exists]        ok
TASK [Ensure the QuickNotes data directory exists]     ok
TASK [Copy the QuickNotes binary]                      ok
TASK [Copy the QuickNotes seed data]                   ok
TASK [Render the QuickNotes systemd unit]              changed
TASK [Enable and start QuickNotes]                     ok
RUNNING HANDLER [Restart QuickNotes]                   changed
```

Recap:

```text
PLAY RECAP *********************************************************************
quicknotes-vm : ok=8 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

The two reported changes were the changed systemd template and the resulting
restart handler. No unrelated task changed.

## Check Mode with Diff

A third change from `4s` to `5s` was previewed with:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yaml \
  --check \
  --diff
```

Ansible displayed the exact unit difference:

```diff
-RestartSec=4s
+RestartSec=5s
```

Recap:

```text
PLAY RECAP *********************************************************************
quicknotes-vm : ok=6 changed=1 unreachable=0 failed=0 skipped=2 rescued=0 ignored=0
```

The template predicted one change. The service start task and restart handler
were skipped, so no actual configuration or process state was modified.

The previewed change was later applied normally and the service remained
healthy.

## Task 2 Design Questions

### e) Why did the second run report `changed=0`?

The dedicated Ansible modules compared the actual VM state with the declared
state.

The `file` module checked the path type, owner, group, and permissions. The
`copy` module compared the source and destination content checksums and
metadata. The `template` module rendered the expected file and compared it
with the existing destination. The `systemd` module checked whether the service
was already enabled and running.

Because every resource already matched the requested state, all tasks returned
`ok` and the recap reported `changed=0`.

### f) What would happen if `shell` and `echo` replaced `template`?

A shell command such as:

```yaml
shell: 'echo "configuration" > /etc/systemd/system/quicknotes.service'
```

would normally execute on every run and report `changed`, even when the
resulting content was identical. That could restart the service unnecessarily
on every playbook execution.

It would also provide weaker multiline handling, quoting, ownership,
permissions, atomic replacement, check-mode support, and before-and-after
diffs.

The `template` module is state-aware and is therefore safer and more
idempotent.

### g) What can `--check --diff` reveal that plain `--check` may not?

Plain `--check` reports whether a resource would change. Adding `--diff` shows
the exact content difference.

For example, it could reveal an accidental change from `User=quicknotes` to
`User=root`. It could also reveal a wrong data path, address, executable path,
or restart setting before the configuration reaches the VM.

---

# Bonus — Five-Minute `ansible-pull` GitOps Loop

## Local Inventory

The VM-local inventory is:

```ini
[quicknotes_vm]
ubuntu-jammy ansible_host=127.0.0.1 ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

This allows the VM to apply the same playbook to itself without SSH.

## VM Packages

The playbook enables Ubuntu Universe and installs:

```yaml
- ansible
- git
```

The final pull executable is supplied by Ubuntu:

```text
ansible: /usr/bin/ansible-pull
ansible-pull 2.10.8
ansible python module location = /usr/lib/python3/dist-packages/ansible
executable location = /usr/bin/ansible-pull
```

## ansible-pull Service

The generated service runs:

```text
ExecStart=/usr/bin/ansible-pull -U https://github.com/tivdzualubem/DevOps-Intro.git -C feature/lab7 -d /var/lib/ansible-pull -i /var/lib/ansible-pull/ansible/inventory-local.ini /var/lib/ansible-pull/ansible/playbook.yaml
```

## Timer Configuration

The timer contains:

```ini
[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true
Unit=ansible-pull.service
```

It was verified as:

```text
active=active
enabled=enabled
```

Example timer output:

```text
NEXT                        LEFT          LAST                        PASSED
Tue 2026-06-23 12:17:37 UTC 2min 27s left Tue 2026-06-23 12:12:37 UTC 2min 32s ago

UNIT               ACTIVATES
ansible-pull.timer ansible-pull.service
```

## Initial Pull Verification

The first automatic pull cloned the branch and reached:

```text
1965f2c feat(lab7): deploy QuickNotes with Ansible
```

Its playbook execution was idempotent:

```text
PLAY RECAP *********************************************************************
localhost : ok=13 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

## Automatic Reconciliation Test

The playbook value was changed from `quicknotes_restart_delay: 5s` to
`quicknotes_restart_delay: 6s`.

The change was committed and pushed as:

```text
157f0083cc5dc96bde65ed990012488667360875
test(lab7): verify pull-based reconciliation
```

Timeline:

| Event | Time |
|---|---|
| Commit created | 2026-06-23 14:56:06 +03:00 |
| Change pushed | 2026-06-23 14:56:07 +03:00 |
| Timer started the pull | 2026-06-23 11:56:47 UTC |
| Pull completed | 2026-06-23 11:57:08 UTC |
| Reconciled state verified | 2026-06-23 14:58:25 +03:00 |

The automatic pull began approximately 40 seconds after the push and completed
approximately 61 seconds after the push, within the required five-minute
window.

The VM checkout reached the target commit:

```text
157f0083cc5dc96bde65ed990012488667360875
```

The automatic playbook execution reported:

```text
TASK [Render the QuickNotes systemd unit]    changed
RUNNING HANDLER [Restart QuickNotes]         changed

PLAY RECAP *********************************************************************
ubuntu-jammy : ok=14 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

The deployed service then contained:

```text
RestartSec=6s
```

The execution result was:

```text
Result=success
ExecMainStatus=0
ExecMainStartTimestamp=Tue 2026-06-23 11:56:47 UTC
ExecMainExitTimestamp=Tue 2026-06-23 11:57:08 UTC
```

The application remained healthy:

```json
{"notes":4,"status":"ok"}
```

## Distribution-Package Correction and Final Validation

The pull service was subsequently changed to use Ubuntu's
distribution-provided `/usr/bin/ansible-pull`.

The correction was committed as:

```text
ac8cead fix(lab7): use distro Ansible for pull loop
```

The VM automatically pulled the commit, installed the Ubuntu Ansible package,
and updated the service command.

The next execution completed successfully:

```text
Result=success
ExecMainStatus=0
ExecMainStartTimestamp=Tue 2026-06-23 12:12:37 UTC
ExecMainExitTimestamp=Tue 2026-06-23 12:12:58 UTC
```

The final unchanged automatic run proved idempotency:

```text
PLAY RECAP *********************************************************************
ubuntu-jammy : ok=13 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

## Bonus Design Questions

### h) What security benefit does pull mode provide?

Pull mode removes the requirement for a central control machine to store
inbound SSH credentials for every managed server.

Each VM only needs outbound access to the Git repository and permission to
apply its local configuration. This reduces the risk that compromise of one
central SSH key immediately provides interactive access to the entire fleet.

However, repository access becomes a critical trust boundary because committed
configuration is applied with root privileges. Branch protection, review,
signed commits, least-privilege credentials, and repository security remain
essential.

### i) What is the equivalent Kubernetes pattern?

The equivalent Kubernetes pattern is GitOps continuous reconciliation.

Tools such as Argo CD and Flux read desired state from Git, compare it with live
cluster state, apply changes when drift is detected, and continue reconciling
periodically.

The Lab 7 `ansible-pull` timer implements the same control-loop concept at the
VM level.

---

# Final Result

The completed implementation demonstrates that:

- QuickNotes runs as a dedicated non-root user.
- The data directory has restricted ownership and permissions.
- The static binary and systemd unit are managed declaratively.
- QuickNotes is enabled, running, and healthy.
- The core playbook is idempotent.
- Only relevant configuration changes invoke the restart handler.
- `--check --diff` exposes the exact intended configuration change.
- The VM automatically pulls and applies Git changes within five minutes.
- The pull loop uses the Ansible package supplied by Ubuntu.
- Subsequent automatic pulls converge with `changed=0`.
