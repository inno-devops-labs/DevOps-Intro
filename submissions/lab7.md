# Lab 7 - Configuration Management: Deploy QuickNotes via Ansible

## Implemented files

- [`ansible/ansible.cfg`](../ansible/ansible.cfg)
- [`ansible/inventory.ini`](../ansible/inventory.ini)
- [`ansible/group_vars/quicknotes.yaml`](../ansible/group_vars/quicknotes.yaml)
- [`ansible/playbook.yaml`](../ansible/playbook.yaml)
- [`ansible/files/quicknotes`](../ansible/files/quicknotes)
- [`ansible/files/seed.json`](../ansible/files/seed.json)
- [`ansible/templates/quicknotes.service.j2`](../ansible/templates/quicknotes.service.j2)
- [`ansible/templates/ansible-pull.service.j2`](../ansible/templates/ansible-pull.service.j2)
- [`ansible/templates/ansible-pull.timer.j2`](../ansible/templates/ansible-pull.timer.j2)

The deploy artifact was built as a Linux static binary with:

```powershell
$env:CGO_ENABLED='0'
$env:GOOS='linux'
$env:GOARCH='amd64'
go build -trimpath -ldflags='-s -w' -o ..\ansible\files\quicknotes .
```

## Local execution status

I could not honestly capture the real Ansible PLAY RECAPs in this Windows environment:

```text
ansible: The term 'ansible' is not recognized...
ansible-playbook: The term 'ansible-playbook' is not recognized...
```

An escalated `vagrant ssh-config` also confirmed that the current checkout has no Lab 5 `Vagrantfile`:

```text
A Vagrant environment or target machine is required to run this command.
Run `vagrant init` to create a new Vagrant environment.
```

The repository does contain `.vagrant/machines/default/virtualbox/private_key`, so `ansible/inventory.ini` uses the standard Vagrant endpoint `127.0.0.1:2222` and that key path. If Lab 5 used another SSH port, replace `ansible_port` with the value from `vagrant ssh-config`.

## Commands to run on the Lab 5 host

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
curl -s http://localhost:18080/health
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

For the selective-change proof, edit only `quicknotes_listen_addr` in `ansible/group_vars/quicknotes.yaml`, then run:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --diff
```

Expected changed task: `Render QuickNotes systemd unit`.

Expected handler sequence after the template change:

```text
RUNNING HANDLER [reload systemd]
RUNNING HANDLER [restart quicknotes]
```

For the `--check --diff` proof, make a third variable-only edit such as changing `quicknotes_listen_addr` from `:9090` to `:8080`, then run:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
```

The diff should show only the `Environment="ADDR=..."` line in `/etc/systemd/system/quicknotes.service`.

## PLAY RECAP evidence

Runtime PLAY RECAPs are pending because Ansible is not installed and the Lab 5 Vagrant environment is not present in this checkout. These are the exact evidence blocks to paste after running on the Lab 5 host:

```text
# First real run PLAY RECAP:
```

```text
# curl -s http://localhost:18080/health:
```

```text
# Second run PLAY RECAP, expected changed=0:
```

```text
# Variable-only template change PLAY RECAP:
```

```text
# --check --diff example:
```

## Task 1 design questions

### a) `command:` vs dedicated modules

`command:` runs a process and only knows its exit code. It does not understand package state, file ownership, service state, or checksums unless I add custom `creates`, `removes`, or `changed_when` logic. Dedicated modules such as `package`, `file`, `copy`, `template`, and `systemd_service` inspect current state first and report `changed` only when they actually converge something.

That idempotency matters because a second playbook run should be safe. It prevents unnecessary restarts, noisy diffs, and accidental drift from imperative shell snippets.

### b) `notify:` and handlers

A handler fires at the end of the play when a task that notified it reports `changed`. It does not fire when the task reports `ok`, even if the task was reached. Multiple notifications collapse into one handler run.

That is the right default because a service should restart only when its binary or unit file changed. Re-running the playbook should not bounce a healthy process.

### c) Variable hierarchy

For this lab I would use:

- `group_vars/quicknotes.yaml` for VM-wide settings such as paths, service name, listener address, and `ansible-pull` settings. These values belong to the QuickNotes host group and are shared between normal push mode and pull mode.
- Playbook `vars` only for small values tightly coupled to this playbook. I avoided that for most settings so the play stays readable.
- Extra vars (`-e quicknotes_listen_addr=:9090`) for one-off demonstrations and emergency overrides, because extra vars have very high precedence and should not hide normal configuration.

### d) `gather_facts`

This playbook sets `gather_facts: false`. The tasks do not use facts such as OS family, memory, interfaces, or distribution release. Disabling fact gathering saves one remote setup phase per run, which is useful for repeated idempotency checks and `ansible-pull` timer runs.

The playbook includes a small `raw` Python bootstrap pre-task so modules can still run on minimal VMs.

## Task 2 design questions

### e) Why the second run reports `changed=0`

The second run should report `changed=0` because each module compares desired state with current state. `file` checks path type, owner, group, and mode. `copy` checks content checksum plus metadata. `template` renders locally, compares rendered content and metadata against the remote file, and only changes the remote file if they differ. `systemd_service` checks whether the service is already enabled and started.

### f) Failure modes of `shell: 'echo "ADDR=..." > ...'`

That shell command rewrites the unit file every run, so it normally reports `changed` every run and causes needless restarts. It also makes quoting fragile: spaces, quotes, and environment values can break the unit. It gives poor diffs, loses owner/mode intent unless extra commands are added, and can leave partially written files if interrupted. A template module gives deterministic content, metadata, diff output, and handler-friendly change detection.

### g) What `--check --diff` catches

Plain `--check` tells me a change would happen, but not whether the generated content is correct. `--check --diff` catches wrong rendered values before production, for example accidentally changing `Environment="DATA_PATH=/var/lib/quicknotes/notes.json"` to a bad path or changing `User=quicknotes` to `User=root`. That kind of bug may still look like a normal pending template change in plain check mode.

## Bonus task - ansible-pull GitOps loop

The playbook installs Git and Ansible in the VM, writes a local inventory at `/etc/ansible/quicknotes-local.ini`, and installs:

- `/etc/systemd/system/quicknotes-ansible-pull.service`
- `/etc/systemd/system/quicknotes-ansible-pull.timer`

The timer fires after one minute on boot and every five minutes afterward:

```ini
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true
```

The service command is rendered from variables and defaults to:

```text
/usr/bin/ansible-pull -U https://github.com/BearAx/DevOps-Intro.git -C feature/lab7 -d /opt/quicknotes-ansible-pull -i /etc/ansible/quicknotes-local.ini ansible/playbook.yaml
```

Before using the bonus, confirm that `ansible_pull_repo_url` and `ansible_pull_branch` in `ansible/group_vars/quicknotes.yaml` match the pushed fork branch.

### Bonus evidence to capture

```bash
systemctl list-timers | grep ansible-pull
systemctl status quicknotes-ansible-pull.timer --no-pager
journalctl -u quicknotes-ansible-pull.service -n 80 --no-pager
```

Timeline template:

```text
Commit pushed:              <timestamp> <commit sha>
Next timer fire observed:   <timestamp>
State reconciled in VM:     <timestamp> <proof command/output>
```

### h) Pull-mode security benefit

With `ansible-pull`, the VM initiates outbound Git access and applies configuration locally. A central control node does not need inbound SSH reachability into the VM, broad SSH keys, or network paths into private subnets. That reduces the blast radius of a compromised control node and fits environments where inbound access is blocked.

The tradeoff is that the VM must be trusted to fetch the correct repo and branch, and repository permissions become part of the deployment control plane.

### i) Kubernetes equivalent

At the Kubernetes layer, this pattern is GitOps, commonly implemented with Argo CD or Flux. Those controllers continuously compare a Git repository with cluster state and reconcile drift. `ansible-pull` is a fair VM-layer simulator because the VM periodically pulls desired state from Git and converges itself without a push from an operator laptop.

## Local validation completed

```text
go test ./...
ok      quicknotes       0.628s
```

Static file validation completed locally:

- The QuickNotes deploy binary exists at `ansible/files/quicknotes`.
- The seed file exists at `ansible/files/seed.json`.
- The playbook uses dedicated Ansible modules for user, group, file, copy, template, package, and systemd operations.
- Runtime Ansible evidence is pending for the environment reasons recorded above.
