# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

**Student:** Sofiia Sultanova  
**GitHub:** [@fsstilerr](https://github.com/fsstilerr)  
**Host architecture:** Apple Silicon (`arm64`)  
**Ansible:** 10.7.0 (`ansible-core` 2.17.14)  
**Python:** 3.12.15  
**Vagrant:** 2.4.9  

---

## Task 1 — Idempotent Deploy to the Lab 5 VM

The Ansible configuration is stored in [`ansible/`](../ansible/):

- [`playbook.yaml`](../ansible/playbook.yaml)
- [`inventory.ini`](../ansible/inventory.ini)
- [`templates/quicknotes.service.j2`](../ansible/templates/quicknotes.service.j2)
- [`files/seed.json`](../ansible/files/seed.json)
- [`files/quicknotes`](../ansible/files/quicknotes)

Because the host is Apple Silicon, I cross-compiled the QuickNotes binary for Linux ARM64:

```bash
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o ../ansible/files/quicknotes .
```

Verification:

```text
ansible/files/quicknotes: ELF 64-bit LSB executable, ARM aarch64, statically linked
```

### Connectivity

```text
quicknotes-vm | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### First deployment

```text
PLAY RECAP ************************************************************
quicknotes-vm : ok=7 changed=6 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

The first run created the `quicknotes` system user, data directory, copied the binary and seed file, rendered the systemd unit, and started the service.

### Verification

```text
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

```text
$ curl -s http://localhost:18080/notes
[{"id":1,"title":"Welcome to QuickNotes",...},{"id":2,"title":"Read app/main.go first",...},{"id":3,"title":"DevOps mantra",...},{"id":4,"title":"Endpoint cheat-sheet",...}]
```

The service was active:

```text
● quicknotes.service - QuickNotes
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled)
     Active: active (running)
```

The process runs under the dedicated system user:

```text
USER       PID CMD
quickno+   2722 /usr/local/bin/quicknotes
```

### Design questions

#### a) `command:` vs dedicated modules

`command:` executes a command but does not normally know the desired state of the resource. Dedicated modules such as `user`, `file`, `copy`, `template`, and `systemd_service` compare the current state with the requested state and change only what is necessary.

This makes dedicated modules naturally idempotent, which matters because the same playbook should be safe to run repeatedly.

#### b) `notify:` and handlers

A handler fires only when a task that contains `notify:` reports `changed`. If the binary and systemd template are already identical to the desired state, the tasks return `ok` and the handler does not run.

This avoids unnecessary service restarts and makes deployments more predictable.

#### c) Variable hierarchy

For this lab I would use:

1. **Playbook vars** for small deployment-specific values such as `listen_addr`, `data_dir`, and `restart_backoff`.
2. **group_vars** for values shared by all QuickNotes hosts.
3. **host_vars** for values that differ between individual machines.

For a larger project I would move most environment-specific configuration out of the playbook into `group_vars` and `host_vars`.

#### d) `gather_facts`

This playbook does not need host facts such as CPU count, interfaces, memory, or distribution metadata, so I used:

```yaml
gather_facts: false
```

This avoids the fact-gathering setup step and saves extra remote calls on every run.

---

## Task 2 — Idempotency + Selective Re-run

### Second run — zero changes

Running the same playbook again without changing anything produced:

```text
PLAY RECAP ************************************************************
quicknotes-vm : ok=6 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

This proves that the deployment is idempotent.

### Selective variable change

I changed:

```yaml
restart_backoff: "2s"
```

to:

```yaml
restart_backoff: "3s"
```

Only the systemd template changed, then the restart handler fired:

```text
TASK [Create quicknotes system user]
ok: [quicknotes-vm]

TASK [Create QuickNotes data directory]
ok: [quicknotes-vm]

TASK [Copy QuickNotes binary]
ok: [quicknotes-vm]

TASK [Copy seed data]
ok: [quicknotes-vm]

TASK [Install QuickNotes systemd unit]
changed: [quicknotes-vm]

TASK [Enable and start QuickNotes]
ok: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes]
changed: [quicknotes-vm]
```

```text
PLAY RECAP ************************************************************
quicknotes-vm : ok=7 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

`changed=2` is expected here: one change is the template task and the second is the handler restart.

The deployed value was:

```text
RestartSec=3s
```

The application remained healthy:

```text
{"notes":4,"status":"ok"}
```

### `--check --diff`

I then changed `restart_backoff` from `3s` to `4s` and previewed it:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
```

Relevant diff:

```diff
-RestartSec=3s
+RestartSec=4s
```

### Design questions

#### e) Why does the second run report `changed=0`?

Modules inspect the current state before modifying it. For example, `file` checks the path type, owner, group, and mode, while `template` compares the rendered content and file metadata with the current destination.

When everything already matches the requested state, the tasks return `ok` and the final recap shows `changed=0`.

#### f) Why not use `shell: echo ... > quicknotes.service`?

A shell command would normally run every time and would not understand whether the file already contains the correct desired state. This can break idempotency and could trigger unnecessary service restarts.

Using `template` also handles content comparison, ownership, permissions, and templated variables directly.

#### g) Why use `--check --diff`?

Plain `--check` tells me that Ansible would change something, while `--diff` shows exactly what would change.

For example, a typo such as `RestartSec=40s` instead of `4s` could still appear only as `changed` in normal check mode, but `--check --diff` would expose the incorrect value before a real deployment.

---

## Bonus — `ansible-pull` GitOps Loop

The bonus setup is automated in the main playbook and uses:

- [`templates/ansible-pull.service.j2`](../ansible/templates/ansible-pull.service.j2)
- [`templates/ansible-pull.timer.j2`](../ansible/templates/ansible-pull.timer.j2)
- [`files/local-inventory.ini`](../ansible/files/local-inventory.ini)

The VM installs distro-packaged `ansible-core` and Git. `ansible-core` provides `/usr/bin/ansible-pull`.

The local inventory uses:

```ini
[quicknotes]
quicknotes-vm ansible_host=127.0.0.1 ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

The timer uses:

```ini
[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=ansible-pull.service
Persistent=true
```

### Timer verification

```text
● ansible-pull.timer - Run ansible-pull every 5 minutes
     Loaded: loaded (/etc/systemd/system/ansible-pull.timer; enabled)
     Active: active (waiting)
    Trigger: Thu 2026-10-01 22:07:57 UTC
   Triggers: ● ansible-pull.service
```

```text
Thu 2026-10-01 22:12:57 UTC ... ansible-pull.timer ansible-pull.service
```

### GitOps convergence test

I committed and pushed this change:

```text
b42b73b 2026-10-02T01:05:58+03:00 test: reconcile restart backoff via ansible-pull
```

Before the timer fired, the VM still had:

```text
RestartSec=3s
```

Observed from the host:

```text
----- 2026-10-02 01:06:31 -----
RestartSec=3s

----- 2026-10-02 01:07:56 -----
RestartSec=3s

----- 2026-10-02 01:08:08 -----
RestartSec=4s
GITOPS RECONCILED SUCCESSFULLY
```

No host-side `ansible-playbook` command was run during this convergence.

The successful pull changed the repository revision:

```text
"before": "d2e9753bccba0c574b20a7836568609b88f524bb"
"after":  "b42b73b1abebf5e911f0437cce58d1ff7abea453"
"changed": true
```

The pulled playbook updated the systemd unit and fired the QuickNotes restart handler:

```text
TASK [Install QuickNotes systemd unit]
changed: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes]
changed: [quicknotes-vm]

PLAY RECAP ************************************************************
quicknotes-vm : ok=14 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

The application was still healthy after reconciliation:

```text
{"notes":4,"status":"ok"}
```

### Timeline

| Event | Time |
|---|---|
| Commit `b42b73b` | 2026-10-02 01:05:58 +03:00 |
| Timer fire | 2026-10-02 01:07:57 +03:00 |
| Reconciliation finished | ~2026-10-02 01:08:06 +03:00 |
| New state observed | 2026-10-02 01:08:08 +03:00 |

The VM converged within the required five-minute window.

### Design questions

#### h) Security benefit of pull mode

In push mode, the control node needs SSH access and credentials for managed hosts. If that control node is compromised, those credentials can increase the blast radius.

With `ansible-pull`, the VM initiates an outbound connection to Git and reconciles itself, so the central controller does not need inbound SSH access to every managed machine.

#### i) Kubernetes equivalent

This pattern is **GitOps**. At the Kubernetes layer, common tools include **Argo CD** and **Flux**.

They continuously compare the desired state stored in Git with the actual cluster state and reconcile differences. `ansible-pull` is a VM-level version of the same desired-state reconciliation pattern.

---

## Result

- Task 1: completed
- Task 2: completed
- Bonus: completed with automatic Git-to-VM reconciliation
