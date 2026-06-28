# Lab 7 Submission

## Task 1

### Ansible files

- [ansible/playbook.yaml](../ansible/playbook.yaml)
- [ansible/inventory.ini](../ansible/inventory.ini)
- [ansible/templates/quicknotes.service.j2](../ansible/templates/quicknotes.service.j2)

The deployable binary was built on the host for the Lab 5 VM architecture with:

```bash
cd app/
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o ../ansible/files/quicknotes .
```

### First run PLAY RECAP

```text
PLAY [Deploy QuickNotes to Lab 5 VM] *******************************************

TASK [Create quicknotes system user] *******************************************
changed: [lab5-vm]

TASK [Ensure quicknotes data directory exists] *********************************
changed: [lab5-vm]

TASK [Install quicknotes binary] ***********************************************
changed: [lab5-vm]

TASK [Install quicknotes seed file] ********************************************
changed: [lab5-vm]

TASK [Install quicknotes systemd unit] *****************************************
changed: [lab5-vm]

TASK [Enable and start quicknotes service] *************************************
changed: [lab5-vm]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [lab5-vm]

PLAY RECAP *********************************************************************
lab5-vm                    : ok=7    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Service verification

`systemctl` inside the VM:

```text
enabled
active
```

Host-side `curl` through the Vagrant forwarded port:

```text
{"notes":4,"status":"ok"}

HTTP_STATUS=200
```

### Design answers

#### a) What's the difference between command: and the dedicated modules (apt, file, copy, systemd)? Which is idempotent, and why does it matter?

`command:` just executes a process with arguments. By itself, it does not know the target state before or after the command, so Ansible usually treats it as a side-effecting action rather than an idempotent declaration. Dedicated modules such as `user`, `file`, `copy`, `template`, and `systemd` encode the desired state and inspect the current state first. For example, `file` checks whether the path already exists with the requested owner, group, mode, and type; `template` compares the rendered content with the remote file; `systemd` checks whether the service is already enabled or started. That matters because idempotent modules let me re-run the playbook safely after partial failure and keep the second run quiet instead of redoing work blindly.

#### b) notify: and handlers: when does a handler fire? When does it not fire? Why is that the right default?

A handler fires only when a task that references it reports `changed`. If multiple tasks notify the same handler in one play, the handler still runs only once at the end of the play. It does not fire when the notifying task is already in the correct state (`ok`), is skipped, or fails before reporting a change. That is the right default because service restarts are disruptive: if neither the binary nor the systemd unit changed, there is no reason to bounce the process.

#### c) Variable hierarchy: Ansible has at least 22 levels of variable precedence. List the top 3 places you'd put a variable for this lab (defaults, group_vars, playbook vars, …) and why

1. Playbook `vars`: this is where I put the stable application defaults for this lab, such as the binary path, data directory, service name, and default listen address, because there is only one target group and one play.
2. Inventory or `group_vars`: this is where I would put environment-specific values if this lab grew beyond one VM, for example different `listen_addr`, `ansible_port`, or alternate data paths for staging vs production.
3. Extra vars (`-e`): this is the right place for short-lived overrides during demonstrations or troubleshooting, such as temporarily changing `quicknotes_listen_addr` without editing tracked files.

#### d) gather_facts: true is the default. Do you need it for this playbook? What does turning it off save you per run?

No. This playbook does not branch on the OS family, CPU architecture, network interfaces, package manager facts, or any other discovered host metadata. Turning fact gathering off saves one SSH setup step plus the time to run the `setup` module and transfer the fact payload on every run. For a small one-host playbook, that is not dramatic, but it is still avoidable work and makes the deploy loop tighter.