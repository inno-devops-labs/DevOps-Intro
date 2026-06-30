# Lab 7 Submission

## Prerequisites

I checked the prerequisites before starting:

```text
$ ~/.venvs/ansible10/bin/ansible --version
ansible [core 2.17.14]
python version = 3.11.15
```

```text
$ vagrant ssh-config 71d2eb3
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  IdentityFile /Users/tatyana/Documents/DevOps-Intro/.vagrant/machines/default/virtualbox/private_key
```

```text
$ vagrant ssh 71d2eb3 -c 'uname -m'
aarch64
```

The VM was running, Ansible 10.x was available on the host, and I built a static Linux ARM64 binary because the VM architecture is `aarch64`.

## Task 1

### Files

- [ansible/inventory.ini](/Users/tatyana/Documents/DevOps-Intro/ansible/inventory.ini)
- [ansible/playbook.yaml](/Users/tatyana/Documents/DevOps-Intro/ansible/playbook.yaml)
- [ansible/templates/quicknotes.service.j2](/Users/tatyana/Documents/DevOps-Intro/ansible/templates/quicknotes.service.j2)
- [ansible/files/quicknotes](/Users/tatyana/Documents/DevOps-Intro/ansible/files/quicknotes)
- [ansible/files/seed.json](/Users/tatyana/Documents/DevOps-Intro/ansible/files/seed.json)

### First Real Run

Changed tasks on the first real run:

```text
TASK [Install git and ansible for ansible-pull] changed
TASK [Create quicknotes system group] changed
TASK [Create quicknotes system user] changed
TASK [Ensure quicknotes data directory] changed
TASK [Ensure quicknotes seed directory] changed
TASK [Copy quicknotes binary] changed
TASK [Copy quicknotes seed file] changed
TASK [Install quicknotes systemd unit] changed
TASK [Ensure ansible-pull config directory] changed
TASK [Install ansible-pull local inventory] changed
TASK [Install ansible-pull service unit] changed
TASK [Install ansible-pull timer unit] changed
TASK [Enable and start ansible-pull timer] changed
RUNNING HANDLER [Restart quicknotes] changed
```

PLAY RECAP from the first real run:

```text
PLAY RECAP *********************************************************************
quicknotes-lab5            : ok=15   changed=14   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Reachability Check

```text
$ curl -sS http://127.0.0.1:18080/health
{"notes":4,"status":"ok"}
```

The service became reachable from the host through the Vagrant forwarded port.

### Design Answers

#### a) `command:` vs dedicated modules

Dedicated modules such as `apt`, `file`, `copy`, `template`, and `systemd_service` know the target state. They compare the current state with the requested state and change only what is different.

`command:` only runs a command. It does not understand package state, file ownership, or rendered template content unless I add extra logic around it. That matters because idempotency is the main goal of this lab. With dedicated modules, the second run can safely report `changed=0`.

#### b) `notify:` and handlers

A handler runs only if a task with `notify:` reports `changed`. If the task result is `ok`, the handler does not run.

That is the right default because restarts are expensive and risky. In this playbook, QuickNotes restarts only when the binary or the unit file really changed.

#### c) Variable hierarchy

For this lab, I would use these three places first:

1. Playbook `vars` for stable lab constants such as paths, service names, and the default listen address.
2. `group_vars` for environment-specific values such as VM host groups, repo URL, or production-only overrides.
3. Role defaults if this playbook grows into a reusable role, because defaults are easy to override without editing the role itself.

I did not use `group_vars` or role defaults in the final solution because the lab has one small environment and one playbook, so playbook vars were enough.

#### d) `gather_facts`

I set `gather_facts: false` because this playbook does not need facts such as OS family, IP addresses, or CPU count. The tasks use fixed paths and dedicated modules only.

Turning facts off saves one setup step per run and makes the playbook a bit faster. For a one-host lab it is a small saving, but it still removes unnecessary work.

## Task 2

### Second Run: Zero Changes

```text
PLAY RECAP *********************************************************************
quicknotes-lab5            : ok=14   changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

This shows the deploy is idempotent when nothing changed.

### One Variable Change: Template Only + Handler

I changed `quicknotes_restart_sec` from `2` to `3` and ran the playbook again.

```text
TASK [Install quicknotes systemd unit] *****************************************
changed: [quicknotes-lab5]

TASK [Enable and start quicknotes service] *************************************
ok: [quicknotes-lab5]

TASK [Install ansible-pull local inventory] ************************************
ok: [quicknotes-lab5]

TASK [Install ansible-pull service unit] ***************************************
ok: [quicknotes-lab5]

TASK [Install ansible-pull timer unit] *****************************************
ok: [quicknotes-lab5]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [quicknotes-lab5]

PLAY RECAP *********************************************************************
quicknotes-lab5            : ok=15   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

The only normal task that changed was the `template` task. The second change in the recap is the handler restart, which is expected.

### `--check --diff` Preview

I changed `quicknotes_restart_sec` from `3` to `4` and ran a dry run with diff:

```diff
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/tatyana/.ansible/tmp/ansible-local-368444wu9hu1s/tmpj53m76yv/quicknotes.service.j2
@@ -13,7 +13,7 @@
 Environment=SEED_PATH=/usr/local/share/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=3
+RestartSec=4

 [Install]
 WantedBy=multi-user.target
```

And the recap:

```text
PLAY RECAP *********************************************************************
quicknotes-lab5            : ok=15   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Design Answers

#### e) Why the second run reports `changed=0`

The second run reports `changed=0` because the managed state already matches the desired state. The `file` module checks attributes such as path type, owner, group, and mode. The `template` module renders the file and compares the result with the current target file.

If content, permissions, and ownership are already correct, the task returns `ok` instead of `changed`.

#### f) Why `shell: 'echo ... > /etc/systemd/system/quicknotes.service'` is a bad idea

That approach would be fragile in several ways:

- it overwrites the file every time, so idempotency is lost
- quoting can break when values contain spaces or special characters
- there is no structured diff between old and new content
- file owner and mode are not managed cleanly
- handlers become noisy because the task would likely report a change every run

With `template:`, Ansible renders the file safely, compares content, and changes it only when needed.

#### g) What `--check --diff` catches that plain `--check` can miss

Plain `--check` tells me that something would change, but it does not always show exactly what text would be written. `--diff` shows the real line-level change.

That helps catch bugs such as the wrong port, a wrong path, or a broken systemd directive before the deploy. In this lab, `--diff` showed that only `RestartSec` would change from `3` to `4`.

## Bonus Task

### Bonus Files

- [ansible/templates/pull-inventory.ini.j2](/Users/tatyana/Documents/DevOps-Intro/ansible/templates/pull-inventory.ini.j2)
- [ansible/templates/ansible-pull.service.j2](/Users/tatyana/Documents/DevOps-Intro/ansible/templates/ansible-pull.service.j2)
- [ansible/templates/ansible-pull.timer.j2](/Users/tatyana/Documents/DevOps-Intro/ansible/templates/ansible-pull.timer.j2)

### Timer Output

```text
$ systemctl list-timers --all | grep ansible-pull-quicknotes
Tue 2026-06-30 10:36:37 UTC 4min 21s Tue 2026-06-30 10:31:37 UTC      38s ago ansible-pull-quicknotes.timer ansible-pull-quicknotes.service
```

### Convergence Timeline

I used the `quicknotes_restart_sec` variable for the GitOps demo.

1. Before the final push, the VM still had:

```text
RestartSec=3
```

2. I committed and pushed this change:

```text
commit=f10738c57d51661b50f8aa9415e8d3e6de520fa7
committer_time=2026-06-30T13:27:56+03:00
```

3. The next timer fired at:

```text
Tue 2026-06-30 10:31:37 UTC
```

4. The journal showed the pull loop updated the clone to commit `f10738c...`, changed the `quicknotes` unit template, and ran the restart handler:

```text
Jun 30 10:31:44 quicknotes-lab5 ansible-pull[8485]: localhost | CHANGED => {
Jun 30 10:31:44 quicknotes-lab5 ansible-pull[8485]:     "after": "f10738c57d51661b50f8aa9415e8d3e6de520fa7",
Jun 30 10:31:44 quicknotes-lab5 ansible-pull[8485]:     "before": "313695c5f2404a660b5e2ca744d328e3cf75163f",
Jun 30 10:31:44 quicknotes-lab5 ansible-pull[8485]:     "changed": true
Jun 30 10:31:44 quicknotes-lab5 ansible-pull[8485]: }
Jun 30 10:31:44 quicknotes-lab5 ansible-pull[8485]: TASK [Install quicknotes systemd unit] *****************************************
Jun 30 10:31:44 quicknotes-lab5 ansible-pull[8485]: changed: [localhost]
Jun 30 10:31:44 quicknotes-lab5 ansible-pull[8485]: RUNNING HANDLER [Restart quicknotes] *******************************************
Jun 30 10:31:44 quicknotes-lab5 ansible-pull[8485]: changed: [localhost]
```

5. After the timer run, the VM showed the new state:

```text
$ grep RestartSec /etc/systemd/system/quicknotes.service
RestartSec=4
```

Verification time:

```text
now=2026-06-30T10:32:15Z
RestartSec=4
```

This proved that the VM reconciled itself from Git within five minutes, without running `ansible-playbook` from the host.

### Design Answers

#### h) Security benefit of `ansible-pull`

In pull mode, the VM connects out to Git and applies its own config. That means I do not need a central control node with SSH access into every machine.

This reduces inbound access, reduces the number of long-lived SSH credentials on a control node, and fits a tighter trust model. The target needs outbound access to Git, not inbound admin access from many places.

#### i) Kubernetes equivalent

At the Kubernetes layer, this pattern is called GitOps. The lecture named tools such as Argo CD and Flux.

`ansible-pull` is a fair VM-level simulator because it follows the same core idea: Git stores the desired state, and an agent on the target keeps reconciling the real state to match it.
