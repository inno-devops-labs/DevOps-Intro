# Lab 7 Submission

Environment note: WSL is unavailable on this Windows host, so I verified the
playbook from inside the Lab 5 VM with `ansible/local-inventory.ini`
(`ansible_connection=local`). The committed `ansible/inventory.ini` still
contains the required Vagrant SSH target for host-side runs.

## Artifacts

- `ansible/inventory.ini`: Vagrant SSH inventory using `127.0.0.1:2222`.
- `ansible/local-inventory.ini`: local inventory used for VM-side verification.
- `ansible/playbook.yaml`: idempotent deploy playbook.
- `ansible/files/quicknotes`: static Linux amd64 binary built in the VM with Go 1.24.5.
- `ansible/files/seed.json`: seed data shipped to `/var/lib/quicknotes/seed.json`.
- `ansible/templates/quicknotes.service.j2`: systemd unit template.
- `ansible/templates/ansible-pull*.j2`: bonus pull-mode units and inventory.

Static binary evidence:

```text
../ansible/files/quicknotes: ELF 64-bit LSB executable, x86-64, statically linked, stripped
-rwxrwxrwx 1 vagrant vagrant 5.6M Sep 25 2026 ../ansible/files/quicknotes
```

## Task 1: Deploy

First real run:

```text
TASK [Create quicknotes system user] changed
TASK [Ensure quicknotes data directory exists] changed
TASK [Install quicknotes binary] changed
TASK [Install seed data] changed
TASK [Render quicknotes systemd unit] changed
RUNNING HANDLER [reload systemd] ok
RUNNING HANDLER [restart quicknotes] changed
TASK [Enable and start quicknotes] ok

PLAY RECAP
localhost : ok=8 changed=6 unreachable=0 failed=0 skipped=7 rescued=0 ignored=0
```

Service and HTTP checks:

```text
systemctl is-active quicknotes
active

curl http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}

curl http://127.0.0.1:18080/notes
returned the four seeded notes, including:
- Welcome to QuickNotes
- Read app/main.go first
- DevOps mantra
- Endpoint cheat-sheet
```

Systemd status excerpt:

```text
Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled)
Active: active (running)
Main PID: 26050 (quicknotes)
Exec: /usr/local/bin/quicknotes
quicknotes listening on :8080 (notes loaded: 4)
```

## Task 1 Design Answers

a) `command:` and `shell:` execute text commands and usually cannot tell
whether the desired state already exists. Dedicated modules like `user`, `file`,
`copy`, `template`, and `systemd` inspect current state, compare it to desired
state, and report `changed` only when they actually converge something. That is
what makes repeated runs safe.

b) A handler fires when a task that has `notify:` reports `changed`. It does not
fire when the task is already `ok`, and duplicate notifications are coalesced so
the handler runs once. That is the right default because a service restarts only
when an input that affects it changed.

c) For this lab I use playbook vars for service defaults such as paths and
`quicknotes_listen_addr`, inventory variables for environment-specific
connection details, and extra vars for temporary demonstrations like changing
the listen address or restart backoff. If this were a role, role defaults would
hold reusable low-precedence defaults.

d) I do not need facts here because the VM paths, service name, and user are all
explicit. `gather_facts: false` saves the fact collection step on every run,
which is useful for a small playbook with no OS branching.

## Task 2: Idempotency and Selective Change

Second run with the same source:

```text
TASK [Create quicknotes system user] ok
TASK [Ensure quicknotes data directory exists] ok
TASK [Install quicknotes binary] ok
TASK [Install seed data] ok
TASK [Render quicknotes systemd unit] ok
TASK [Enable and start quicknotes] ok

PLAY RECAP
localhost : ok=6 changed=0 unreachable=0 failed=0 skipped=7 rescued=0 ignored=0
```

Selective variable change:

```text
ansible-playbook ... -e 'quicknotes_listen_addr=:9090'

TASK [Render quicknotes systemd unit] changed
RUNNING HANDLER [reload systemd] ok
RUNNING HANDLER [restart quicknotes] changed

PLAY RECAP
localhost : ok=8 changed=2 unreachable=0 failed=0 skipped=7 rescued=0 ignored=0
```

`--check --diff` preview for a third variable:

```diff
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/vagrant/.ansible/tmp/.../quicknotes.service.j2
@@ -13,7 +13,7 @@
 Environment="SEED_PATH=/var/lib/quicknotes/seed.json"
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=3s
+RestartSec=9s
 NoNewPrivileges=true
 ProtectHome=true
 ProtectSystem=full

PLAY RECAP
localhost : ok=5 changed=1 unreachable=0 failed=0 skipped=10 rescued=0 ignored=0
```

## Task 2 Design Answers

e) The second run reports `changed=0` because each module compares current state
to desired state. `file` checks type, owner, group, and mode. `copy` checks the
destination checksum and metadata. `template` renders locally and compares the
rendered bytes with the remote file before replacing it.

f) A `shell: echo ... > quicknotes.service` task would likely report changed on
every run, even when the unit content is identical. It would lose structured
diffs, make quoting mistakes easy, risk truncating the unit on errors, and would
not naturally notify reload/restart handlers only when content changed.

g) Plain `--check` can tell me that a task would change, but not whether the
change is correct. `--check --diff` catches bugs like changing `RestartSec` or
`ADDR` to the wrong value before production, because it shows the exact line
that would be written.

## Bonus: ansible-pull GitOps Loop

The bonus artifacts are automated by `ansible/playbook.yaml` when
`enable_ansible_pull=true`. It installs:

```text
/etc/ansible/quicknotes-local.ini
/etc/systemd/system/ansible-pull-quicknotes.service
/etc/systemd/system/ansible-pull-quicknotes.timer
```

Local inventory content:

```ini
[quicknotes]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

Service unit content:

```ini
[Unit]
Description=Converge QuickNotes from Git with ansible-pull
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
WorkingDirectory=/
ExecStart=/usr/bin/ansible-pull -U https://github.com/Valdezzar/DevOps-Intro.git -C feature/lab7 -d /var/lib/ansible-pull/quicknotes -i /etc/ansible/quicknotes-local.ini ansible/playbook.yaml -e enable_ansible_pull=true
```

Timer unit content:

```ini
[Unit]
Description=Run QuickNotes ansible-pull every five minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
AccuracySec=30s
Unit=ansible-pull-quicknotes.service

[Install]
WantedBy=timers.target
```

Timer evidence:

```text
systemctl list-timers --all | grep ansible-pull
Fri 2026-09-25 13:43:44 UTC 4min 49s left  Fri 2026-09-25 13:36:10 UTC 2min 44s ago  ansible-pull-quicknotes.timer ansible-pull-quicknotes.service
```

Successful pull run:

```text
Process: 30136 ExecStart=/usr/bin/ansible-pull ... (code=exited, status=0/SUCCESS)
PLAY RECAP
localhost : ok=13 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
Finished Converge QuickNotes from Git with ansible-pull.
```

Timeline:

```text
93fe72c committed/pushed at 2026-09-25T16:38:28+03:00
ansible-pull service run completed at 2026-09-25 13:38:54 UTC
VM checkout: 93fe72c on feature/lab7
Elapsed time: about 26 seconds
```

## Bonus Design Answers

h) Pull mode avoids a central controller needing inbound SSH access to every VM.
Each VM only needs outbound access to Git and can use a narrowly scoped read
credential. That reduces the blast radius if the control node or one SSH key is
compromised.

i) At the Kubernetes layer this pattern is GitOps, commonly implemented by
Argo CD or Flux. `ansible-pull` is a fair VM-layer simulator because desired
state lives in Git and an agent on the target periodically reconciles local
state back to that Git revision.
