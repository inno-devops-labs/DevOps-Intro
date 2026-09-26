# Lab 7 — Configuration Management with Ansible

Student: Arina ([@sonder314](https://github.com/sonder314))

## Implementation

I implemented the deployment in [playbook.yaml](../ansible/playbook.yaml). My
[host inventory](../ansible/inventory.ini) uses the IP, forwarded SSH port,
user, and generated private key from `vagrant ssh-config`. The
[QuickNotes unit template](../ansible/templates/quicknotes.service.j2) takes
the service identity, paths, address, binary, and restart delay from playbook
variables.

The playbook creates a system group and a non-login system user without a home,
creates `/var/lib/quicknotes` with mode `0750`, and installs the binary and
[seed data](../ansible/files/seed.json) with the required ownership and modes.
The unit runs as `quicknotes:quicknotes`, waits for `network-online.target`,
uses the data directory as its working directory, sets `ADDR`, `DATA_PATH`, and
`SEED_PATH`, and restarts on failure after a two-second delay. I also made the
unit description a variable for the pull-based convergence demonstration.

Binary and unit changes notify the `Restart quicknotes` handler. A unit change
also notifies `Reload systemd`. The handlers are flushed before the service is
enabled and started, so the first run cannot try to manage a stale unit. Seed
changes deliberately do not restart the process because the application only
uses the seed when its persistent data file does not exist.

I built `ansible/files/quicknotes` with `CGO_ENABLED=0`, `-trimpath`, and
stripped linker flags. It is a stripped, statically linked x86-64 ELF with
SHA-256 `8f410876c77ad3a539b3fbe95b7427b5ecb743fef02e1b40a403d3d6d60b7a75`.
The Go test suite passes, the playbook parses successfully as YAML, all Jinja
templates parse with strict undefined-variable handling, and the
deployed seed is byte-for-byte identical to `app/seed.json`.

## Runtime evidence

I used Ansible 10.7.0 with ansible-core 2.17.14; the complete version output is
[recorded here](evidence/lab7/ansible-version.txt). The initial
[`--check --diff` preview](evidence/lab7/check-before-deploy.txt) completed with
`failed=0`, reported the eight resources it would change, and showed the
rendered unit contents while correctly skipping runtime service operations.

I interrupted the first real execution while the guest package manager was
installing the bonus dependencies. The core service changes had already been
applied successfully. After allowing package configuration to finish, I reran
the same idempotent playbook; the complete successful
[recovery run](evidence/lab7/first-run.txt) reported `changed=4`, covering the
remaining local inventory, pull service, pull timer, and timer activation. No
manual service-file edits were used.

The deployed API returned:

```text
$ curl -fsS http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
```

The complete [health response](evidence/lab7/health.txt) and
[non-empty notes response](evidence/lab7/notes.txt) prove that the forwarded
service is reachable and all four records from the shipped seed were loaded.

## Idempotency and selective change evidence

The immediate [second run](evidence/lab7/second-run.txt) completed with:

```text
quicknotes-vm : ok=12 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

For the selective change, I overrode only `quicknotes_restart_sec` from `2s`
to `3s`. The [recorded run](evidence/lab7/selective-change.txt) shows only the
QuickNotes template reporting a change, followed by the systemd reload and
`Restart quicknotes` handler. The recap reports `changed=2`: one change is the
template and the other is the deliberately invoked restart handler; every
ordinary unrelated task reports `ok`.

With the deployed value at `3s`, I previewed a third value, `4s`, using
`--check --diff`. The [captured diff](evidence/lab7/check-diff.txt) contains
only `RestartSec=3s` to `RestartSec=4s`, reports `changed=1`, and skips runtime
handlers in check mode. I then restored the reviewed `2s` default and recorded
a final [zero-change convergence run](evidence/lab7/final-idempotency.txt).

## Task 1 design questions

### a) `command` versus dedicated modules

`command` runs a program and normally cannot infer the desired end state. It
therefore reports a change whenever it runs unless I add explicit guards or
change conditions. Dedicated modules describe resources: `file` compares type,
ownership, permissions, and related attributes; `copy` and `template` compare
content and metadata; `apt` compares package state; and `systemd_service`
queries the service manager. Those modules make an unchanged run a no-op. This
matters because convergence must be safe to repeat and must not cause needless
restarts, writes, or outages.

### b) Notifications and handlers

A task queues a handler only when the task both reports `changed` and contains
the matching `notify`. Notifications are deduplicated, so several changed tasks
still run a named handler once. Handlers normally run after ordinary tasks, or
at an explicit `meta: flush_handlers` boundary. A task that reports `ok`, a
skipped task, or a failed play before the handler phase does not run that
handler. This default couples disruptive actions to genuine configuration
changes and batches repeated notifications.

### c) Variable placement

My first three choices are:

1. Role defaults for reusable, safe values with intentionally low precedence,
   if I extract this play into a role.
2. `group_vars/quicknotes.yaml` for environment or fleet-wide values shared by
   every QuickNotes host, such as the listen address and paths.
3. Playbook `vars` for the small, self-contained lab defaults visible next to
   the tasks, which is what I use here.

I would reserve inventory host variables for connection details and `--extra-vars`
for deliberate one-run overrides, because extra variables have very high
precedence and can otherwise hide the reviewed configuration.

### d) Fact gathering

This playbook does not branch on OS facts or use discovered addresses, mounts,
or hardware data, so I set `gather_facts: false`. Disabling it removes the
automatic `setup` task, one remote module execution, and the transfer and
parsing of a large fact dictionary on every run. Explicit modules still inspect
the narrow state they manage.

## Task 2 design questions

### e) Why the second run is unchanged

The `file` module stats the path and compares its current type, owner, group,
and mode with the requested state. `copy` compares the source and destination
content checksums plus managed metadata. `template` first renders Jinja with
the current variables, then compares the resulting bytes and metadata with the
destination. On the second run all comparisons match, no notifying task reports
a change, and neither QuickNotes handler runs, producing `changed=0`.

### f) Replacing `template` with shell redirection

`shell: 'echo ... > quicknotes.service'` executes on every run and normally
reports a change even when the bytes are identical. That destroys useful
idempotency and can trigger a restart every five minutes. Shell quoting can
corrupt spaces, quotes, dollar signs, backslashes, or multiline directives;
`echo` behavior also varies. Redirection truncates the live file before the new
content is complete, so interruption can leave an empty or partial unit. The
task does not naturally enforce owner and mode, produce a structured diff, or
support template validation. Plain check mode may skip it because Ansible
cannot predict the result. Finally, a careless command may overwrite the unit
without a daemon reload or may notify a restart on every run.

### g) What `--check --diff` catches

Plain check mode can say that a template would change without showing whether
the proposed file is correct. The diff can reveal a wrong port, a misspelled
path, a removed hardening directive, accidental truncation, or a secret being
rendered into a world-readable unit. For this playbook it would immediately
show if a variable change altered `SEED_PATH` instead of only `RestartSec`.

## Bonus — pull-based convergence

I automated the bonus in the same playbook. It installs Git and Ansible, copies
the [local inventory](../ansible/local-inventory.ini), and installs the
[ansible-pull service](../ansible/templates/ansible-pull.service.j2) and
[five-minute timer](../ansible/templates/ansible-pull.timer.j2). The local
inventory targets `localhost` with `ansible_connection=local`. The oneshot
service pulls my `feature/lab7` branch, and the timer uses `OnBootSec=1min`,
`OnUnitActiveSec=5min`, and `Persistent=true`.

The [timer listing](evidence/lab7/ansible-pull-timer.txt) shows the enabled
timer with its previous activation and the next activation less than five
minutes away. I added `quicknotes_description` to the rendered unit as the
Git-driven state change: before this branch is pulled, the VM has
`Description=QuickNotes API`; after the pull it must contain
`Description=QuickNotes API managed by Ansible`. The successful pull journal
and exact commit-to-reconciliation timeline are recorded after the signed
branch is available to the VM.

### h) Pull-mode security benefit

Pull mode does not require a permanently reachable SSH service or a control
node holding credentials that can log in to every managed machine. Each VM
needs outbound repository access and reconciles itself, which reduces inbound
attack surface and the blast radius of one stolen controller credential. It
does not remove trust: I still need protected Git credentials when applicable,
reviewed branches, signed or otherwise verified changes, and secured local root
execution because a compromised repository can distribute privileged code.

### i) Kubernetes equivalent

At the Kubernetes layer this pattern is GitOps, commonly implemented by Argo CD
or Flux. A controller continuously compares declared Git state with live cluster
state and reconciles drift. `ansible-pull` is a fair VM-level simulation because
the node periodically fetches versioned desired state and converges itself
without a push from an operator, although its polling and health model is much
simpler than a Kubernetes controller's reconciliation loop.

## Completion status

- [x] Static binary, seed, inventories, playbook, and all three unit templates.
- [x] Required ownership, modes, variables, service ordering, and handlers.
- [x] All nine design questions answered.
- [x] Bonus artifacts and automated installation included.
- [x] Runtime recaps, HTTP evidence, idempotency, selective change, and timer evidence.
- [ ] Successful pull journal and commit-to-reconciliation timeline.
- [ ] Signed commit, upstream pull request, and Moodle submission.
