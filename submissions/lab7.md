# Lab 7 — Configuration Management with Ansible

## Environment and artifacts

- Controller: macOS ARM64, Python 3.11.14, Ansible 10.7.0, ansible-core 2.17.14.
- Target: the Lab 5 Ubuntu 24.04 ARM64 VM, managed by Vagrant and VirtualBox.
- SSH: vagrant@127.0.0.1:2222, using the Vagrant-generated private key.
- Port forwarding: 127.0.0.1:18080 on the host to port 8080 in the VM.

Files:

- [Playbook](../ansible/playbook.yaml)
- [Inventory](../ansible/inventory.ini)
- [Systemd template](../ansible/templates/quicknotes.service.j2)
- [Static binary](../ansible/files/quicknotes)
- [Seed data](../ansible/files/seed.json)
- [Vagrantfile reused from Lab 5](../Vagrantfile)

The inventory uses a key path relative to the repository root. Run Ansible commands from that directory.

Build command, executed inside app/:

```bash
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o ../ansible/files/quicknotes .
```

The resulting executable was verified as an ARM aarch64 ELF binary, statically linked.

## Task 1 — Deploy QuickNotes

The playbook creates a system group and user without an interactive shell or home directory. It manages the data directory, binary, seed file, and systemd unit with dedicated Ansible modules.

The service runs as quicknotes. Its ADDR, DATA_PATH, SEED_PATH, working directory, executable path, and restart delay come from playbook variables.

The data directory has mode 0750, the binary 0755, and seed.json 0640. The data directory and seed file belong to quicknotes:quicknotes.

### First deployment

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

```text
PLAY RECAP *********************************************************************
quicknotes_vm              : ok=8    changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

[Full first-run output](lab7-logs/01-first-run.txt).

Before deployment, syntax validation passed and Ansible ping returned pong. The initial --check run predicted file and user changes but failed at the service task because check mode had not actually installed the new unit. The real deployment succeeded.

### Service verification

```bash
curl -fsS http://localhost:18080/health
curl -fsS http://localhost:18080/notes
```

The health response was:

```json
{"notes":4,"status":"ok"}
```

The notes response contained all four seed notes. Captured service and HTTP outputs are included below.

### a) command versus dedicated modules

The command module executes a program and normally reports changed whenever it runs; it does not automatically compare the desired state with the current state. Guards such as creates/removes can make particular commands repeatable.

Dedicated modules understand their resources. For example, file checks filesystem attributes, copy compares content and attributes, apt can ensure a package is present, and systemd_service with state: started starts a service only when needed. They are idempotent when used with suitable options; state: restarted deliberately restarts every time it executes.

Idempotency makes repeated deployments safe and prevents unnecessary changes and restarts.

### b) notify and handlers

A task notifies a handler when it reports changed. An unchanged or skipped task does not notify it. On a successful run, notified handlers normally execute after the tasks, and repeated notifications to the same handler produce one execution.

In this playbook, only the binary and unit-template tasks notify restart quicknotes. Updating seed.json alone does not trigger it. This avoids unnecessary interruptions when the deployed configuration is already correct.

### c) Variable organization and precedence

My three preferred locations are:

1. Playbook vars for this small lab's explicit deployment settings, such as paths, listen_addr, and restart_delay. This is what the implementation uses.
2. group_vars/quicknotes.yml for environment-specific settings shared by a group of VMs if the deployment grows.
3. Role defaults for reusable baseline settings if the deployment is later extracted into a role.

Among these locations, playbook vars override inventory group_vars, which override role defaults. A setting intended to be configurable through group_vars should therefore not also be fixed in playbook vars.

### d) Fact gathering

This playbook does not need gathered facts: it targets a known Ubuntu VM, uses explicit paths, and receives a prebuilt ARM64 binary. Therefore gather_facts is false.

This avoids running the setup module and collecting and transferring system facts on every run. It saves processing and connection time; the exact saving depends on the host and network.

## Task 2 — Idempotency and selective changes

### Second run without changes

```text
PLAY RECAP *********************************************************************
quicknotes_vm              : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Every task reported ok, and no handler ran.

[Full second-run output](lab7-logs/02-second-run.txt).

### Change one variable

I changed restart_delay from 2 to 3. This changed RestartSec in the generated unit without changing the application's port.

Only Render QuickNotes systemd unit and the restart quicknotes handler reported changed. All other tasks reported ok.

```text
PLAY RECAP *********************************************************************
quicknotes_vm              : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

The total changed=2 counts one changed template task and one handler execution.

[Full selective-change output](lab7-logs/03-variable-change.txt).

### Preview another change

I changed restart_delay from 3 to 4 and ran:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
```

The diff included:

```diff
-RestartSec=3
+RestartSec=4
```

The predicted recap was:

```text
PLAY RECAP *********************************************************************
quicknotes_vm              : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

After this preview, systemctl show quicknotes -p RestartUSec still returned RestartUSec=3s. No actual configuration change or restart occurred during check mode.

[Full check-mode diff](lab7-logs/04-check-diff.txt).

I then applied the change normally. The run succeeded with changed=2 and failed=0, and the VM reported RestartUSec=4s.

[Apply output](lab7-logs/05-apply.txt).

### e) Why does the second run report changed=0?

The existing resources already match the requested state. The file module checks the path's existence, type, owner, group, and permissions. The template task renders the desired content and compares it with the destination, also checking managed file attributes.

The binary and seed content are unchanged, and the service is already enabled and running. No notifying task changes, so the restart handler does not execute.

### f) What if shell echo replaced template?

A shell command using > rewrites the file on every normal run and normally reports changed, causing unnecessary handler executions if notify is attached.

Writing only ADDR=... to quicknotes.service would also replace the complete unit with invalid unit content: it would lack the required sections and ExecStart. An existing process might keep running until a reload or restart exposes the broken configuration.

Shell quoting and expansion introduce further risks. The command would not automatically manage ownership and permissions, compare rendered content, or provide the same useful check-mode and diff behavior as template.

### g) What can --check --diff reveal?

Plain --check can report that a template would change without showing the proposed values. --diff lets a reviewer notice a wrong port, incorrect DATA_PATH, or missing SEED_PATH before applying the change.

For example, an accidental DATA_PATH change could make the app use a different notes store. Seeing the exact changed line makes this easier to catch. Neither mode proves that the resulting application will run correctly; runtime checks are still necessary.

## Captured verification output

### Service state after the final apply

```text
active
enabled
[?1h=
RestartUSec=4s[m

[K[?1l>
```

### GET /health

```json
{"notes":4,"status":"ok"}
```

### GET /notes

```json
[{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"}]
```

## Bonus — ansible-pull GitOps loop

### Implementation artifacts

The bonus setup is automated with Ansible:

- [Setup playbook](../ansible/setup-pull.yaml)
- [ansible-pull service template](../ansible/templates/ansible-pull.service.j2)
- [Systemd timer](../ansible/files/ansible-pull.timer)
- [Local inventory](../ansible/files/local-inventory.ini)

The setup playbook installs the distribution's Ansible package and Git, creates the configuration directories, installs the inventory and systemd units, and enables and starts the timer.

The service runs as root and executes:

```bash
/usr/bin/ansible-pull \
  -U https://github.com/amiranabiullina/DevOps-Intro.git \
  -C feature/lab7 \
  -i /etc/ansible/quicknotes-local.ini \
  -d /var/lib/ansible-pull/quicknotes \
  ansible/playbook.yaml
```

The local inventory targets 127.0.0.1 with ansible_connection=local and /usr/bin/python3. The same deployment playbook is applied locally without an SSH connection.

The timer uses OnBootSec=1min, OnUnitActiveSec=5min, and AccuracySec=1s. Each invocation updates the checkout and reapplies the configuration, even if there is no new commit.

Setup command:

```bash
ansible-playbook -i ansible/inventory.ini ansible/setup-pull.yaml
```

Setup result:

```text
quicknotes_vm : ok=6 changed=6 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

[Full setup output](lab7-logs/09-pull-setup.txt).

### First scheduled pull

The first invocation started at 10:24:54 UTC and completed successfully at 10:25:07 UTC. It checked out commit 13f1555f7b125691474fd71979806af29d9c5cd1.

The deployment playbook reported:

```text
127.0.0.1 : ok=7 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

The existing deployment already matched the configuration in Git.

[First successful pull journal](lab7-logs/10-first-pull.txt).

The timer listing showed:

```text
NEXT                            LEFT     LAST                         PASSED  UNIT                ACTIVATES
Thu 2026-10-01 10:29:54 UTC       4min 16s Thu 2026-10-01 10:24:54 UTC   43s ago ansible-pull.timer  ansible-pull.service
```

[Captured timer output](lab7-logs/11-pull-timer.txt).

### Automatic convergence demonstration

I changed restart_delay from 4 to 5, committed the change, and pushed feature/lab7. I did not manually run the deployment playbook or start ansible-pull for this demonstration.

Commit: 4732f83e7580521059d769469e835c3f80004090.

All times below are UTC on 2026-10-01.

| Event | Time |
|---|---|
| Commit created | 10:26:16 |
| Push completion recorded | 10:26:40 |
| Early check: old commit and RestartUSec=4s | 10:27:17 |
| Next scheduled pull started | 10:29:55 |
| QuickNotes restarted with the new configuration; pull completed | 10:29:59 |
| Follow-up observation confirmed new commit and RestartUSec=5s | 10:31:17 |

The commit timestamp was originally recorded as 13:26:16+03:00, equivalent to 10:26:16 UTC.

Convergence took 3 minutes 43 seconds from the commit, or 3 minutes 19 seconds from the recorded push completion. The journal and service activation timestamp establish when the change was applied; the later observation confirms the resulting state.

The scheduled run changed only the service template and invoked the restart handler. Other deployment tasks remained unchanged.

Successful pull journal excerpt:

```text
2026-10-01T10:29:55+00:00 quicknotes systemd[1]: Starting ansible-pull.service - Reconcile QuickNotes configuration from Git...
2026-10-01T10:29:59+00:00 quicknotes ansible-pull[4987]: RUNNING HANDLER [restart quicknotes] *******************************************
2026-10-01T10:29:59+00:00 quicknotes ansible-pull[4987]: changed: [127.0.0.1]
2026-10-01T10:29:59+00:00 quicknotes ansible-pull[4987]: PLAY RECAP *********************************************************************
2026-10-01T10:29:59+00:00 quicknotes ansible-pull[4987]: 127.0.0.1                  : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
2026-10-01T10:29:59+00:00 quicknotes systemd[1]: Finished ansible-pull.service - Reconcile QuickNotes configuration from Git.
```

Confirmed VM state:

```text
RestartUSec=5s
ActiveEnterTimestamp=Thu 2026-10-01 10:29:59 UTC
4732f83e7580521059d769469e835c3f80004090
Result=success
ExecMainStatus=0
```

Evidence:

- [Commit, push, and observation timeline](lab7-logs/12-convergence-timeline.txt)
- [Full convergence journal](lab7-logs/13-convergence-journal.txt)

The final restart delay after the bonus is 5 seconds. The earlier 4-second output documents the end of Task 2.

### h) Security benefit of pull mode

Pull mode removes the need for a central deployment controller to initiate SSH connections to all managed machines and hold credentials granting access to them. Each machine retrieves configuration through an outbound connection and applies it locally.

This can reduce inbound management exposure and the impact of a compromised controller. Repository write access remains sensitive because the VM executes retrieved automation as root. Pull mode does not make untrusted configuration safe. Vagrant SSH remains available in this lab for setup and verification.

### i) Equivalent pattern in Kubernetes

This pattern is called GitOps. Lecture 7 names Argo CD and Flux: Git stores the desired configuration, and a controller retrieves it and reconciles the managed environment.

ansible-pull simulates this at the VM layer by periodically retrieving configuration from Git and applying an idempotent playbook to local users, files, and services. It is scheduled reconciliation rather than a Kubernetes controller watching cluster resources.
