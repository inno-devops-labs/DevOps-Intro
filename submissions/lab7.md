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

The committed branch is `feature/lab7` and the diff against `upstream/main` contains only `ansible/` and `submissions/lab7.md`.

## How I verified it

Host-side Ansible is not installed on this Windows machine, so I verified the same playbook inside the running Lab 5 VM with a local inventory:

```ini
[quicknotes]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

This still exercises the same idempotent tasks, templates, handlers, systemd service, and bonus timer against the real VM.

## Task 1 - first deploy

Command used in the VM:

```bash
cd /tmp/lab7
ansible-playbook -i local.ini ansible/playbook.yaml
```

PLAY RECAP from the first real run:

```text
PLAY RECAP *********************************************************************
localhost                  : ok=17   changed=13   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Important changed tasks were the QuickNotes group/user, data and seed directories, seed file, binary, service unit, local ansible-pull inventory, ansible-pull service/timer units, timer enablement, and the `restart quicknotes` handler.

Service health from the host through the Lab 5 port forward:

```text
curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}
```

## Task 2 - idempotency

Second run without changing anything:

```text
PLAY RECAP *********************************************************************
localhost                  : ok=15   changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

After adding `quicknotes_restart_sec` as a template variable with the same value, the playbook stayed idempotent:

```text
PLAY RECAP *********************************************************************
localhost                  : ok=15   changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## Task 2 - selective change

I changed only this variable inside the VM copy:

```yaml
quicknotes_restart_sec: 4s
```

The rendered unit diff showed only the expected line:

```diff
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/vagrant/.ansible/tmp/.../quicknotes.service.j2
@@ -13,7 +13,7 @@
 Environment="SEED_PATH=/etc/quicknotes/seed.json"
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=3s
+RestartSec=4s
 NoNewPrivileges=true
 PrivateTmp=true
 ProtectSystem=strict
```

Relevant task and handler output:

```text
TASK [Render QuickNotes systemd unit] ******************************************
changed: [localhost]

RUNNING HANDLER [reload systemd] ***********************************************
ok: [localhost]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=17   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

The recap counts both the changed template task and the changed restart handler. All ordinary non-template tasks remained `ok`.

## Task 2 - `--check --diff`

For a third variable-only change, I previewed `4s -> 5s` using `--check --diff`:

```diff
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/vagrant/.ansible/tmp/.../quicknotes.service.j2
@@ -13,7 +13,7 @@
 Environment="SEED_PATH=/etc/quicknotes/seed.json"
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=4s
+RestartSec=5s
 NoNewPrivileges=true
 PrivateTmp=true
 ProtectSystem=strict
```

PLAY RECAP from the preview:

```text
PLAY RECAP *********************************************************************
localhost                  : ok=16   changed=2    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

The change was previewed but not applied.

## Bonus - ansible-pull timer

The playbook installs Git and Ansible in the VM, writes a local inventory at `/etc/ansible/quicknotes-local.ini`, and installs:

- `/etc/systemd/system/quicknotes-ansible-pull.service`
- `/etc/systemd/system/quicknotes-ansible-pull.timer`

Timer status:

```text
systemctl list-timers --all | grep ansible-pull
Sat 2026-06-27 13:41:28 UTC 2min 24s left  Sat 2026-06-27 13:36:28 UTC 2min 35s ago         quicknotes-ansible-pull.timer quicknotes-ansible-pull.service

systemctl is-enabled quicknotes-ansible-pull.timer
enabled

systemctl is-active quicknotes-ansible-pull.timer
active
```

Timer unit details:

```text
quicknotes-ansible-pull.timer - Run QuickNotes ansible-pull every five minutes
Loaded: loaded (/etc/systemd/system/quicknotes-ansible-pull.timer; enabled; vendor preset: enabled)
Active: active (waiting) since Sat 2026-06-27 13:36:28 UTC
Trigger: Sat 2026-06-27 13:41:28 UTC
Triggers: quicknotes-ansible-pull.service
```

The service command rendered by the playbook:

```text
/usr/bin/ansible-pull -U https://github.com/BearAx/DevOps-Intro.git -C feature/lab7 -d /opt/quicknotes-ansible-pull -i /etc/ansible/quicknotes-local.ini ansible/playbook.yaml
```

Convergence timeline:

```text
Commit on feature/lab7:       2026-06-27T16:25:15+03:00 f358d16
Timer installed and active:   2026-06-27 13:36:28 UTC
Next timer fire observed:     2026-06-27 13:41:28 UTC
State reconciled in VM:       quicknotes service active and /health returns {"notes":4,"status":"ok"}
```

## Task 1 design questions

### a) `command:` vs dedicated modules

`command:` runs a process and only knows its exit code. It does not understand package state, file ownership, service state, or checksums unless I add custom `creates`, `removes`, or `changed_when` logic. Dedicated modules such as `package`, `file`, `copy`, `template`, and `systemd` inspect current state first and report `changed` only when they actually converge something.

That idempotency matters because a second playbook run should be safe. It prevents unnecessary restarts, noisy diffs, and accidental drift from imperative shell snippets.

### b) `notify:` and handlers

A handler fires at the end of the play when a task that notified it reports `changed`. It does not fire when the task reports `ok`, even if the task was reached. Multiple notifications collapse into one handler run.

That is the right default because a service should restart only when its binary or unit file changed. Re-running the playbook should not bounce a healthy process.

### c) Variable hierarchy

For this lab I would use:

- `group_vars/quicknotes.yaml` for VM-wide settings such as paths, service name, listener address, restart backoff, and `ansible-pull` settings. These values belong to the QuickNotes host group and are shared between normal push mode and pull mode.
- Playbook `vars` only for small values tightly coupled to this playbook. I avoided that for most settings so the play stays readable.
- Extra vars (`-e quicknotes_listen_addr=:9090`) for one-off demonstrations and emergency overrides, because extra vars have very high precedence and should not hide normal configuration.

### d) `gather_facts`

This playbook sets `gather_facts: false`. The tasks do not use facts such as OS family, memory, interfaces, or distribution release. Disabling fact gathering saves one remote setup phase per run, which is useful for repeated idempotency checks and `ansible-pull` timer runs.

The playbook includes a small `raw` Python bootstrap pre-task so modules can still run on minimal VMs.

## Task 2 design questions

### e) Why the second run reports `changed=0`

The second run reports `changed=0` because each module compares desired state with current state. `file` checks path type, owner, group, and mode. `copy` checks content checksum plus metadata. `template` renders locally, compares rendered content and metadata against the remote file, and only changes the remote file if they differ. `systemd` checks whether the service is already enabled and started.

### f) Failure modes of `shell: 'echo "ADDR=..." > ...'`

That shell command rewrites the unit file every run, so it normally reports `changed` every run and causes needless restarts. It also makes quoting fragile: spaces, quotes, and environment values can break the unit. It gives poor diffs, loses owner/mode intent unless extra commands are added, and can leave partially written files if interrupted. A template module gives deterministic content, metadata, diff output, and handler-friendly change detection.

### g) What `--check --diff` catches

Plain `--check` tells me a change would happen, but not whether the generated content is correct. `--check --diff` catches wrong rendered values before production, for example accidentally changing `Environment="DATA_PATH=/var/lib/quicknotes/notes.json"` to a bad path or changing `User=quicknotes` to `User=root`. That kind of bug may still look like a normal pending template change in plain check mode.

## Bonus design questions

### h) Pull-mode security benefit

With `ansible-pull`, the VM initiates outbound Git access and applies configuration locally. A central control node does not need inbound SSH reachability into the VM, broad SSH keys, or network paths into private subnets. That reduces the blast radius of a compromised control node and fits environments where inbound access is blocked.

The tradeoff is that the VM must be trusted to fetch the correct repo and branch, and repository permissions become part of the deployment control plane.

### i) Kubernetes equivalent

At the Kubernetes layer, this pattern is GitOps, commonly implemented with Argo CD or Flux. Those controllers continuously compare a Git repository with cluster state and reconcile drift. `ansible-pull` is a fair VM-layer simulator because the VM periodically pulls desired state from Git and converges itself without a push from an operator laptop.

## Local validation

```text
go test ./...
ok      quicknotes       0.628s
```

The QuickNotes deploy binary exists at `ansible/files/quicknotes`, the seed file exists at `ansible/files/seed.json`, and the playbook uses dedicated Ansible modules for user, group, file, copy, template, package, and systemd operations.
