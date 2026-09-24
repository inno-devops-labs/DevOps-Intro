# Lab 7 — Configuration Management: QuickNotes via Ansible

## Artifacts

- [Inventory](../ansible/inventory.ini) targets the Vagrant SSH forward at
  `127.0.0.1:2222` as `vagrant`. The Vagrant-generated private key was copied
  to `~/.ssh/quicknotes-lab5` with mode `0600`, because a key mounted from
  `/mnt/c` is visible as mode `0777` to WSL OpenSSH.
- [Playbook](../ansible/playbook.yaml)
- [QuickNotes unit template](../ansible/templates/quicknotes.service.j2)
- [Static QuickNotes binary](../ansible/files/quicknotes) and
  [seed data](../ansible/files/seed.json)

The binary was built on the control host with:

```bash
cd app
CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o ../ansible/files/quicknotes .
```

## Task 1 — first deployment

The initial `--check --diff` correctly showed the planned creation of the
system user and group. It then stopped at the data-directory task because a
check run does not actually create the previously absent `quicknotes` account,
so it cannot resolve that account for `chown`. The real deployment below creates
the account; subsequent check runs are complete.

Initial deploy changed the `quicknotes` group and user, data directory, static
binary, seed data, and unit. The host-side Ansible process exceeded the terminal
capture interval while apt installed the VM's Ansible package; the process
continued on the VM and completed the bonus artifacts. The subsequent complete
host run proved the final converged state:

```text
PLAY RECAP
lab5 : ok=13 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

Host verification through the Vagrant port forward:

```text
$ curl -fsS http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}

$ curl -fsS http://127.0.0.1:18080/notes
[{"id":1,"title":"Welcome to QuickNotes",...},
 {"id":2,"title":"Read app/main.go first",...},
 {"id":3,"title":"DevOps mantra",...},
 {"id":4,"title":"Endpoint cheat-sheet",...}]
```

## Task 1 design questions

### a) `command:` versus dedicated modules

`command:` runs an imperative executable and normally has no model of the
desired state; absent `creates:` or `removes:` guards, it reports a change on
every run. Dedicated modules such as `user`, `file`, `copy`, `template`, and
`systemd` understand the resource they manage, inspect its present state, and
apply only the difference. This makes repeated deployments safe, makes changes
auditable, and prevents an unchanged server from being needlessly restarted.

### b) `notify:` and handlers

A task queues its notified handler only when the task reports `changed`. A
handler runs once, at the end of the play, even if several notifying tasks
changed. It does not run for an `ok` task (or for a skipped task). Here only the
binary-copy and systemd-unit template tasks notify `restart quicknotes`, so a
repeat run does not restart a healthy service and changing seed data alone does
not restart it.

### c) Variable locations

For this small lab I keep readable application defaults such as `listen_addr`
and `data_path` in playbook `vars`, because there is one application and one
deployment definition. For multiple VM groups I would move environment-specific
values (for example an address or repo branch) to `group_vars/quicknotes.yml`.
For a reusable role I would put conservative overridable values in role
`defaults/main.yml`, the lowest-precedence place, so an environment can replace
them without editing the role.

### d) Facts

The playbook never references `ansible_facts`, so `gather_facts: false` is
safe. Disabling it saves the remote setup/facts module execution, an SSH round
trip and usually a few seconds on each run.

## Task 2 — idempotency and selective re-run

### Second run: no changes

```text
PLAY RECAP
lab5 : ok=13 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

### Template-only variable change

After changing only `listen_addr` and then restoring it to `:8080`, the captured
run was:

```text
TASK [Render the QuickNotes systemd unit]
changed: [lab5]

RUNNING HANDLER [restart quicknotes]
changed: [lab5]

PLAY RECAP
lab5 : ok=14 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

Every non-template task was `ok`; the second `changed` is the handler itself.

### `--check --diff`

Changing only `restart_delay` from `2s` to `3s` produced this preview and did
not apply it to the VM:

```diff
--- before: /etc/systemd/system/quicknotes.service
+++ after: quicknotes.service.j2
@@
 Restart=on-failure
-RestartSec=2s
+RestartSec=3s
```

The check recap was `ok=14 changed=2 failed=0`; the second planned change was
the notified restart handler.

## Task 2 design questions

### e) Why the second run is `changed=0`

The `file` module checks that the directory exists and that its owner, group,
and mode match the requested state. The `template` module renders the Jinja2
source, compares the resulting content checksum with the destination, and also
checks the requested metadata. When all those values already match, both tasks
return `ok`; the other declarative tasks make the same desired-state comparison.

### f) Why not use `shell: 'echo ... > unit'`

The shell command is opaque to Ansible and normally reports a change each run,
destroying idempotency and causing unnecessary restarts. Shell quoting can
corrupt values, `>` is not an atomic managed write, an interrupted command can
leave a partial unit, and it does not enforce owner or mode. It also hides a
useful content diff and can overwrite a correct unit with malformed text;
`template` renders variables safely, compares content, and integrates with
`notify`.

### g) What `--check --diff` catches beyond plain `--check`

Plain check tells me that the template would change, but not *how*. The diff can
reveal an accidental replacement or deletion of `SEED_PATH`, `DATA_PATH`, or
`ADDR` before a production deploy. Such a task would still appear simply as
`changed` in plain check even though it could make the service start with an
empty store or bind the wrong address.

## Bonus — `ansible-pull` GitOps loop

The bonus is automated by the main playbook:

- [Local inventory template](../ansible/templates/ansible-pull.inventory.j2)
- [Service template](../ansible/templates/ansible-pull.service.j2)
- [Timer template](../ansible/templates/ansible-pull.timer.j2)
- [Installation tasks](../ansible/playbook.yaml) install the distro `ansible`
  and `git`, deploy the three artifacts, reload systemd, and enable the timer.

Timer evidence:

```text
NEXT                            LEFT LAST                              PASSED
Thu 2026-09-24 21:42:07 UTC 4min Thu 2026-09-24 21:35:58 UTC 1min ago
ansible-pull.timer -> ansible-pull.service
```

Successful automated-pull journal excerpt:

```text
Sep 24 21:42:09 systemd[1]: Starting ansible-pull.service
Sep 24 21:42:24 ansible-pull[13937]: TASK [Render the QuickNotes systemd unit]
Sep 24 21:42:24 ansible-pull[13937]: changed: [localhost]
Sep 24 21:42:24 ansible-pull[13937]: RUNNING HANDLER [restart quicknotes]
Sep 24 21:42:24 ansible-pull[13937]: changed: [localhost]
Sep 24 21:42:24 ansible-pull[13937]: localhost : ok=14 changed=2 failed=0
Sep 24 21:42:24 systemd[1]: Finished ansible-pull.service
```

Convergence timeline (UTC+03):

1. `00:39:24` — committed and pushed `9f2d85c` (`restart_delay: 3s`).
2. `00:42:09` — the 5-minute systemd timer fired on the VM, without a host
   `ansible-playbook` run.
3. `00:42:24` — pull completed; `/opt/quicknotes-ansible` was at `9f2d85c`,
   `/etc/systemd/system/quicknotes.service` contained `RestartSec=3s`, and
   `quicknotes.service` was `active`.

The full end-to-end delay was 3 minutes, within the required five minutes.

### h) Security of pull mode

With `ansible-pull`, the VM initiates an outbound connection to the approved
Git repository. A central controller does not need inbound SSH access to every
machine or a set of SSH credentials capable of changing them. That reduces the
inbound attack surface and limits the blast radius of a compromised controller.

### i) Kubernetes equivalent

At the Kubernetes layer this reconciliation pattern is used by GitOps
controllers such as Argo CD (and Flux). They continuously compare a Git desired
state with actual state and converge it. `ansible-pull` is a fair VM-scale
analogue: the host periodically pulls a versioned desired configuration and
applies it locally.
