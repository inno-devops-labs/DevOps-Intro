# Lab 7 Submission

## Task 1 — Idempotent Deploy to the Lab 5 VM

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

## Task 2 — Prove Idempotency + Selective Re-run

For the selective-change demonstration I used the playbook variable `quicknotes_restart_sec`, which is rendered into the systemd unit as `RestartSec=...`. That let me trigger a template-only change without moving the service off port `8080`.

### Second run: changed=0

```text
PLAY [Deploy QuickNotes to Lab 5 VM] *******************************************

TASK [Create quicknotes system user] *******************************************
ok: [lab5-vm]

TASK [Ensure quicknotes data directory exists] *********************************
ok: [lab5-vm]

TASK [Install quicknotes binary] ***********************************************
ok: [lab5-vm]

TASK [Install quicknotes seed file] ********************************************
ok: [lab5-vm]

TASK [Install quicknotes systemd unit] *****************************************
ok: [lab5-vm]

TASK [Enable and start quicknotes service] *************************************
ok: [lab5-vm]

PLAY RECAP *********************************************************************
lab5-vm                    : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Selective re-run after one variable change

I changed `quicknotes_restart_sec` in [ansible/playbook.yaml](../ansible/playbook.yaml) from `2s` to `3s` and re-ran the playbook.

```text
PLAY [Deploy QuickNotes to Lab 5 VM] *******************************************

TASK [Create quicknotes system user] *******************************************
ok: [lab5-vm]

TASK [Ensure quicknotes data directory exists] *********************************
ok: [lab5-vm]

TASK [Install quicknotes binary] ***********************************************
ok: [lab5-vm]

TASK [Install quicknotes seed file] ********************************************
ok: [lab5-vm]

TASK [Install quicknotes systemd unit] *****************************************
changed: [lab5-vm]

TASK [Enable and start quicknotes service] *************************************
ok: [lab5-vm]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [lab5-vm]

PLAY RECAP *********************************************************************
lab5-vm                    : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Host-side health check after the restart:

```text
{"notes":4,"status":"ok"}

HTTP_STATUS=200
```

### `--check --diff` preview

For the dry-run diff preview, I changed `quicknotes_restart_sec` from `3s` to `4s` locally and ran `ansible-playbook --check --diff`.

```text
PLAY [Deploy QuickNotes to Lab 5 VM] *******************************************

TASK [Create quicknotes system user] *******************************************
ok: [lab5-vm]

TASK [Ensure quicknotes data directory exists] *********************************
ok: [lab5-vm]

TASK [Install quicknotes binary] ***********************************************
ok: [lab5-vm]

TASK [Install quicknotes seed file] ********************************************
ok: [lab5-vm]

TASK [Install quicknotes systemd unit] *****************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/axxil/.ansible/tmp/ansible-local-8786tk_qkp82/tmpk7m4ybfj/quicknotes.service.j2
@@ -13,7 +13,7 @@
 Environment="SEED_PATH=/var/lib/quicknotes/seed.json"
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=3s
+RestartSec=4s

 [Install]
 WantedBy=multi-user.target
\ No newline at end of file

changed: [lab5-vm]

TASK [Enable and start quicknotes service] *************************************
skipping: [lab5-vm]

RUNNING HANDLER [restart quicknotes] *******************************************
skipping: [lab5-vm]

PLAY RECAP *********************************************************************
lab5-vm                    : ok=5    changed=1    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
```

After capturing the preview, I restored the playbook variable to `3s` so the tracked playbook matches the state that is actually deployed in the VM.

### Design answers

#### e) Why does the second run report changed=0? What specifically does the file / template module check to decide?

The second run reports `changed=0` because every managed object on the VM already matches the desired state declared in the playbook. The `file` module checks the target path's existence and metadata such as type, owner, group, and mode; if `/var/lib/quicknotes` is already a directory owned by `quicknotes:quicknotes` with mode `0750`, there is nothing to do. The `template` module renders the Jinja template on the control side and compares the resulting content against the remote file; if the rendered unit file bytes are identical to `/etc/systemd/system/quicknotes.service`, it returns `ok` instead of `changed`.

#### f) What would happen if you used shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service' instead of the template: module? Trace the failure modes

That would throw away most of the unit file and replace it with a single line, so systemd would no longer have a valid service definition. Even if I used a longer shell redirection to write the whole file, I would still lose the template module's built-in comparison, diff support, quoting safety, ownership/mode management, and predictable newline handling. The shell command would usually report a change every run, which would restart the service every time whether the content actually changed or not. It also makes subtle bugs easier: bad escaping, partial writes, missing permissions, or writing an invalid unit that plain `--check` cannot meaningfully preview.

#### g) ansible-playbook --check is dry-run. --diff shows changes. What's the bug you'd catch by running --check --diff before a production deploy that you'd miss with plain --check?

`--check` alone tells me that a template task would change, but not what the rendered difference is. `--diff` lets me see the exact line-level mutation before I apply it. In this lab, that means I can verify that only `RestartSec=3s` is changing to `RestartSec=4s`. If I had accidentally pointed the wrong variable into the template and changed `ExecStart`, `DATA_PATH`, or `ADDR` at the same time, plain `--check` would still only say `changed`; `--diff` would expose the unintended drift before it hits the VM.

## Bonus Task — `ansible-pull` GitOps Loop

### Bonus files

- [ansible/playbook.yaml](../ansible/playbook.yaml)
- [ansible/templates/quicknotes-local.ini.j2](../ansible/templates/quicknotes-local.ini.j2)
- [ansible/templates/quicknotes-ansible-pull.service.j2](../ansible/templates/quicknotes-ansible-pull.service.j2)
- [ansible/templates/quicknotes-ansible-pull.timer.j2](../ansible/templates/quicknotes-ansible-pull.timer.j2)

The bonus extends the same playbook so the Lab 5 VM can reconcile itself from my fork via `ansible-pull` every 5 minutes.

### Timer installation

`systemctl list-timers | grep ansible-pull` after the timer-fired reconciliation:

```text
Sun 2026-06-28 09:09:45 UTC 3min 31s Sun 2026-06-28 09:04:45 UTC 1min 28s ago quicknotes-ansible-pull.timer quicknotes-ansible-pull.service
```

### Convergence timeline

1. I pushed commit `16ff83ce448340be2718855c3edfc896e73a482a` on branch `feature/lab7` at `2026-06-28T12:01:24+03:00`.
2. That commit changed `quicknotes_restart_sec` in [ansible/playbook.yaml](../ansible/playbook.yaml) from `3s` to `4s`, giving the VM a template-backed drift to reconcile.
3. The VM timer fired at `Sun 2026-06-28 09:04:45 UTC`.
4. The pull service finished at `Sun 2026-06-28 09:04:56 UTC`.
5. After the timer-driven run, the VM had pulled the same commit and the deployed unit showed `RestartSec=4s`.

### `ansible-pull` service log excerpt

```text
Jun 28 09:04:45 quicknotes-lab5 systemd[1]: Starting quicknotes-ansible-pull.service - QuickNotes ansible-pull reconciliation...
Jun 28 09:04:56 quicknotes-lab5 ansible-pull[7804]:     "after": "16ff83ce448340be2718855c3edfc896e73a482a",
Jun 28 09:04:56 quicknotes-lab5 ansible-pull[7804]:     "before": "c5c5f10e32a4fe05626f9daf3758ba7c8580173e",
Jun 28 09:04:56 quicknotes-lab5 ansible-pull[7804]: TASK [Install quicknotes systemd unit] *****************************************
Jun 28 09:04:56 quicknotes-lab5 ansible-pull[7804]: changed: [127.0.0.1]
Jun 28 09:04:56 quicknotes-lab5 ansible-pull[7804]: RUNNING HANDLER [restart quicknotes] *******************************************
Jun 28 09:04:56 quicknotes-lab5 ansible-pull[7804]: changed: [127.0.0.1]
Jun 28 09:04:56 quicknotes-lab5 ansible-pull[7804]: PLAY RECAP *********************************************************************
Jun 28 09:04:56 quicknotes-lab5 ansible-pull[7804]: 127.0.0.1                  : ok=14   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Jun 28 09:04:56 quicknotes-lab5 systemd[1]: Finished quicknotes-ansible-pull.service - QuickNotes ansible-pull reconciliation.
```

### Reconciled state verification

Inside the VM after the timer fire:

```text
16ff83ce448340be2718855c3edfc896e73a482a
RestartSec=4s
LastTriggerUSec=Sun 2026-06-28 09:04:45 UTC
```

Host-side health check after the timer-driven reconciliation:

```text
{"notes":4,"status":"ok"}

HTTP_STATUS=200
```

### Design answers

#### h) `ansible-pull` is pull mode. What's the security benefit vs the push model where a control node SSHes in?

With `ansible-pull`, the VM makes an outbound connection to fetch desired state instead of exposing an inbound management path from a central control node. That reduces the blast radius of stolen control-node SSH credentials, avoids distributing private SSH access from one orchestrator into every managed machine, and fits stricter firewall models where servers may reach Git over HTTPS but do not accept ad hoc inbound administration from multiple places. The node still needs trust in the repo content, but the trust boundary is narrower than giving a separate control host shell access into the VM.

#### i) What's the same pattern called at the Kubernetes layer, and why is `ansible-pull` a fair simulator at the VM layer?

At the Kubernetes layer this pattern is commonly called GitOps, with tools such as Argo CD or Flux continuously reconciling cluster state from Git. `ansible-pull` is a fair VM-level simulator because the control loop is the same: Git is the source of truth, the target system periodically fetches desired state, compares it to current state, and converges itself without a human pushing imperative changes directly into the node.