# Lab 7 — Configuration Management with Ansible

## Goal

Deploy QuickNotes to the Lab 5 VirtualBox VM using Ansible and verify idempotency, variable-driven configuration, systemd integration, and automatic Git-based convergence with `ansible-pull`.

## Task 1 — Ansible deployment

### Inventory

The Lab 5 VM is accessed through the Vagrant SSH configuration:

- Host: `127.0.0.1`
- Port: `2222`
- User: `vagrant`
- Vagrant private SSH key
- Privilege escalation: `become: true`

The inventory is stored in `ansible/inventory.ini`.

### Playbook

The playbook is stored in `ansible/playbook.yaml`.

It:

- creates the `quicknotes` system user;
- disables interactive login with `/usr/sbin/nologin`;
- does not create an interactive home directory;
- creates `/var/lib/quicknotes` with mode `0750`;
- installs the QuickNotes binary to `/usr/local/bin/quicknotes`;
- installs `seed.json` to `/var/lib/quicknotes/seed.json`;
- renders the systemd unit from a Jinja2 template;
- enables and starts QuickNotes;
- uses handlers to restart QuickNotes only when the binary or systemd unit changes.

The application is configured with:

- `ADDR=:8080`
- `DATA_PATH=/var/lib/quicknotes/notes.json`
- `SEED_PATH=/var/lib/quicknotes/seed.json`

### Verification

Syntax validation passed.

The first real deployment completed successfully:

`ok=7 changed=7 failed=0`

The service became active and was enabled by systemd.

Application verification:

`GET /health` returned `{"notes":4,"status":"ok"}`.

The `/notes` endpoint returned the four seeded notes:

1. Welcome to QuickNotes
2. Read app/main.go first
3. DevOps mantra
4. Endpoint cheat-sheet

## Idempotency

The playbook was executed a second time without changing any configuration.

Result:

`ok=6 changed=0 failed=0`

No restart handler was triggered.

This confirms that the playbook is idempotent: Ansible detected that the desired state was already present and did not modify the managed resources.

## Task 2 — Variable-driven configuration

The `listen_addr` variable was changed from `:8080` to `:9090`.

Only the systemd unit changed and the QuickNotes restart handler was triggered.

Result:

`ok=7 changed=2 failed=0`

The VM was verified to listen on port `9090`.

The application responded successfully with:

`{"notes":4,"status":"ok"}`

The variable was then returned to `:8080`, and the service was restored to the Lab 5 forwarded port.

## Check mode and diff

A harmless template change was tested by changing `RestartSec=2s` to `RestartSec=3s`.

The command:

`ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff`

showed the exact systemd unit difference:

`-RestartSec=2s`
`+RestartSec=3s`

The local template was restored to `RestartSec=2s` afterwards.

Check mode was used for validation only; no real service change was required from that experiment.

## Design questions

### a. Modules vs shell commands

Dedicated Ansible modules such as `user`, `file`, `copy`, `template`, and `systemd` are preferable to shell commands because they understand the desired state and can determine whether a change is necessary.

For example, `copy` compares the managed file with the source and reports `changed` only when the content or relevant attributes differ. A shell command such as `cp` does not provide this state-aware behavior by itself.

### b. Handlers

The QuickNotes restart handler is notified only by tasks that can change the executable or systemd unit.

The handler runs at the end of a play when a notifying task reports `changed`.

Therefore:

- changing the binary -> restart;
- changing the systemd template -> restart;
- unchanged binary and template -> no restart.

This prevents unnecessary service restarts.

### c. Variable precedence

For this lab, three useful variable locations are:

1. Playbook `vars` — suitable for default values that belong to this deployment.
2. Inventory/group variables — suitable for environment-specific configuration.
3. Extra variables supplied with `-e` — highest priority and useful for temporary overrides or CI/CD automation.

The playbook keeps the main deployment defaults close to the tasks while still allowing environment-specific overrides.

### d. `gather_facts`

Fact gathering is disabled with `gather_facts: false`.

The playbook does not need operating-system facts, CPU information, memory information, or network facts.

Disabling fact gathering reduces execution time and avoids collecting unnecessary information.

### e. Why second run is `changed=0`

The second run has the same desired state as the first deployment.

Ansible verifies:

- user configuration;
- directory ownership and permissions;
- binary content and permissions;
- seed file content and permissions;
- rendered systemd unit;
- service state.

Because none of these differ from the desired state, no resources change and the restart handler is not triggered.

### f. Shell `echo` vs template

Generating a systemd unit with a shell command such as `echo "..." > /etc/systemd/system/quicknotes.service` has several problems:

- quoting and escaping become difficult;
- variables are harder to manage;
- small configuration changes are difficult to review;
- idempotency must be implemented manually;
- accidental overwrites are easier;
- the intended configuration is less readable.

A Jinja2 template clearly describes the desired unit and lets Ansible compare the rendered result with the existing file.

### g. Check mode with diff

`--check` can report that a managed resource would change, but without `--diff` it may not show the exact file content difference.

`--check --diff` showed the precise `RestartSec` change from `2s` to `3s`, making it easier to detect and review an unintended configuration change before applying it.

# Bonus — ansible-pull

## Git and Ansible on the VM

Git and Ansible were installed inside the Lab 5 VM.

Versions verified:

- Git 2.43.0
- Ansible Core 2.16.3
- Python 3.12.3

## Local inventory

The repository contains `ansible/pull/inventory.ini` with:

`[local]`
`localhost ansible_connection=local`

The main playbook uses `hosts: all`, so it can work with both the normal SSH inventory and the local `ansible-pull` inventory.

## ansible-pull service

The systemd service is defined in `ansible/templates/quicknotes-ansible-pull.service.j2`.

It pulls:

`https://github.com/allniluv/DevOps-Intro.git`

from the branch:

`feature/lab7`

into:

`/opt/quicknotes-config`

and runs:

`ansible/playbook.yaml`

using the local inventory.

## Timer

The timer is defined in `ansible/templates/quicknotes-ansible-pull.timer.j2`.

It uses:

`OnBootSec=1min`

and:

`OnUnitActiveSec=5min`

The timer was verified as enabled and active.

`systemctl list-timers` showed the scheduled execution and confirmed a five-minute interval.

The journal confirmed that the timer automatically started the `ansible-pull` service at `12:30:46 UTC`.

## Automatic convergence demonstration

After the `feature/lab7` branch was pushed to the GitHub fork, a new commit was created:

`a02f133` — `test(lab7): demonstrate ansible-pull convergence`

The VM initially had commit `974d8a3`. The automatic pull updated the working copy from:

`974d8a3`

to:

`a02f133`

The journal showed:

`before: 974d8a3...`

`after: a02f133...`

and:

`changed: true`

The updated Git commit changed the QuickNotes systemd template by adding:

`Environment="LAB7_PULL_DEMO=enabled"`

During automatic convergence:

- `Install systemd unit` changed
- `Restart QuickNotes` handler executed
- play recap reported `ok=11 changed=2 failed=0`
- the resulting systemd unit contained `Environment="LAB7_PULL_DEMO=enabled"`

This demonstrated the complete pull-based convergence flow:

Git commit
      ↓
push to GitHub
      ↓
5-minute systemd timer
      ↓
ansible-pull
      ↓
template change
      ↓
handler restart
      ↓
updated QuickNotes service

QuickNotes remained healthy after the automatic restart:

`{"notes":4,"status":"ok"}`

The warning about `quicknotes-vm` in the `ansible-pull` journal is expected because the bonus inventory intentionally targets `localhost` through the local connection.

## h. Security benefit of pull-based configuration

With `ansible-pull`, the target VM initiates the outbound Git connection instead of requiring a central Ansible controller to initiate SSH connections to the VM.

This can reduce inbound network exposure and makes the target easier to operate behind firewalls or NAT.

The trade-off is that repository integrity, Git credentials, and the VM itself still need to be protected. A compromised repository or host could affect the desired configuration.

## i. Kubernetes analogy

The closest Kubernetes pattern is GitOps, commonly implemented with controllers such as Argo CD or Flux.

`ansible-pull` periodically retrieves desired configuration from Git and reconciles the host with that configuration.

The similarity is the desired-state model:

Git repository
      ↓
configuration pull
      ↓
reconciliation
      ↓
actual system state

The difference is that `ansible-pull` is timer-driven on a single host, while Kubernetes GitOps controllers continuously reconcile the desired state of a cluster.

## Final result

The Lab 7 QuickNotes deployment is managed declaratively with Ansible.

Verified:

- Ansible inventory and SSH access
- privileged deployment with `become`
- system user and permissions
- binary and seed file deployment
- Jinja2 systemd configuration
- service enable/start
- seeded `/notes` endpoint
- idempotent second run with `changed=0`
- variable-driven port change
- handler-triggered restart
- `--check --diff`
- Git and Ansible installed in the VM
- local `ansible-pull` inventory
- systemd `ansible-pull` service
- 5-minute systemd timer
- automatic timer invocation
- Git commit pulled automatically from the remote branch
- template convergence through `ansible-pull`
- handler-triggered QuickNotes restart
- final health check after automatic convergence
