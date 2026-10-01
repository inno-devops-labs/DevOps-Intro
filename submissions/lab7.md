# Lab 7 — Configuration management with Ansible

## Deployment artifacts and environment

The deployment is defined by [ansible/playbook.yaml](../ansible/playbook.yaml), [inventory.ini](../ansible/inventory.ini), [quicknotes.service.j2](../ansible/templates/quicknotes.service.j2), the prebuilt [static Linux binary](../ansible/files/quicknotes), and [seed.json](../ansible/files/seed.json). The binary was built from this repository's `app/` with Go 1.24.13 and `CGO_ENABLED=0 go build -trimpath -ldflags='-s -w'`; its SHA-256 is `699A1EC525A6450A1EA05C814C37A260F583955D82DA291C652737D455636197`.

The target is the Lab 5 Ubuntu 24.04 Vagrant VM. `vagrant ssh-config` reported `HostName 127.0.0.1`, `Port 2222`, `User vagrant`, and the local `.vagrant/machines/default/virtualbox/private_key`. The inventory refers to that key in the sibling Lab 5 worktree; the private key is not committed. On this Windows host, I ran Ansible 10.7.0 (ansible-core 2.17.14) in a Linux controller image built from [Controller.Dockerfile](../ansible/Controller.Dockerfile). Docker Desktop reaches the Vagrant SSH forwarding through `host.docker.internal:2222`; the run overrides only `ansible_host`, `ansible_connection=paramiko_ssh`, and the key path inside the controller. A native Linux host can use the committed inventory directly after adjusting its relative key path if necessary.

The play uses `become: true` and does not gather unused facts. It creates a no-login `quicknotes` system user, owns `/var/lib/quicknotes` as `quicknotes:quicknotes` mode `0750`, installs the binary mode `0755` and seed mode `0640`, renders the systemd unit from variables, and enables/starts the service. The binary and unit notify a single restart handler; seed-file changes do not restart a running instance because seeding only occurs when the data file is absent. To preserve the Lab 5 notes file, Lab 7 uses `/var/lib/quicknotes/notes-lab7.json` for its own data and seeds that file from the copied seed.

## Task 1 — first deployment

An initial `--check` pass reported `ok=4 changed=3 failed=0 skipped=4`. In check mode Ansible predicts the new user but cannot actually create it, so the play deliberately skips tasks requiring that user's ownership until a real run. The real run completed with this full recap:

```text
TASK [Check whether the service account already exists]  ok
TASK [Ensure the dedicated system user exists]           changed
TASK [Ensure the data directory exists]                  changed
TASK [Install the static QuickNotes binary]              changed
TASK [Install the seed data]                              changed
TASK [Render the systemd service unit]                    changed
TASK [Enable and start QuickNotes]                        ok
RUNNING HANDLER [Restart quicknotes]                      changed
PLAY RECAP
lab5-vm : ok=8 changed=6 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

From the host:

```text
$ curl -i http://127.0.0.1:18080/health
HTTP/1.1 200 OK
{"notes":4,"status":"ok"}

$ curl http://127.0.0.1:18080/notes
[{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"}]
```

The service was `active`; `systemctl show quicknotes -p User` reported `User=quicknotes`.

### Design answers a–d

a) `command` executes a command and usually cannot infer whether it changed the target; it can be guarded with `creates`/`removes` or `changed_when`, but that must be designed manually. `apt`, `file`, `copy`, and `systemd_service` inspect the target state and act only when it differs. This makes repeatable deploys safe and makes a `changed` result meaningful.

b) A handler is queued only when a notifying task reports `changed`, then normally runs once after the play's tasks even if multiple tasks notify it. An unchanged binary and unit do not restart the service. This avoids unnecessary downtime and prevents a deploy loop from restarting a healthy process every run.

c) I use playbook `vars` for the small set of deployment defaults shared by this one play; `group_vars/quicknotes` would hold values shared across many QuickNotes VMs/environments; `host_vars/lab5-vm` would hold one VM's exceptions such as a different listen address. A one-off `-e` override is useful for a controlled experiment but should not be the persistent source of truth. Connection coordinates stay in inventory.

d) This play uses fixed paths and service names and needs no OS-discovery facts, so `gather_facts: false` avoids the setup module, its SSH round trip, and fact-transfer overhead on every run. The small explicit `getent` check is only for safe first-run check mode.

## Task 2 — idempotency and selective change

The unchanged second run had every task `ok`, no handler, and:

```text
PLAY RECAP
lab5-vm : ok=7 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

I changed only the play variable `restart_sec` from `2` to `3`. The binary, user, directory, and seed tasks stayed `ok`; only the template changed and the notified handler restarted the service:

```text
TASK [Render the systemd service unit]  changed
TASK [Enable and start QuickNotes]     ok
RUNNING HANDLER [Restart quicknotes]   changed
PLAY RECAP
lab5-vm : ok=8 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

A third edit, `restart_sec: 3` → `4`, was previewed without applying it:

```diff
TASK [Render the systemd service unit] changed
@@ -13,7 +13,7 @@
 Environment="SEED_PATH=/var/lib/quicknotes/seed.json"
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=3s
+RestartSec=4s
 NoNewPrivileges=true
PLAY RECAP
lab5-vm : ok=6 changed=1 unreachable=0 failed=0 skipped=2 rescued=0 ignored=0
```

The handler was skipped in check mode, so the preview made no service change.

### Design answers e–g

e) After the first run, `file` finds the same path, type, owner, group, and mode; `copy` and `template` compare content/checksum and metadata, including rendered variable values. No task reports a state difference, so `changed=0` and no handler runs.

f) A raw `shell: 'echo ... > /etc/systemd/system/quicknotes.service'` would execute and normally report changed on every run, overwriting the unit and causing needless restarts. It also risks quoting mistakes, partial/truncated files, wrong permissions, and no useful structured diff/check-mode prediction. `template` provides deterministic rendering and content-aware change detection.

g) Plain `--check` might only say that the unit would change. `--check --diff` reveals whether the *rendered value* is wrong—for example, `ADDR=:9090` when the Vagrant host forward still expects guest port 8080, or a mistaken `DATA_PATH`—before production traffic is affected.

## Bonus — ansible-pull GitOps loop

The bonus artifacts are [bonus.yaml](../ansible/bonus.yaml), [local inventory](../ansible/local-inventory.ini), [ansible-pull.service](../ansible/files/ansible-pull.service), and [ansible-pull.timer](../ansible/files/ansible-pull.timer). The timer uses `OnBootSec=1min` and `OnUnitActiveSec=5min`; the service pulls the public fork's `feature/lab7` branch and applies the same deployment playbook locally. The unit files are installed as root, systemd is reloaded only when they change, and the timer is enabled.

The VM's distribution Ansible and Git packages were installed, and the bonus play completed with `ok=8 changed=5 failed=0`. The timer is enabled and has run repeatedly. The first installation exposed a missing `/etc/ansible` directory on this image; `bonus.yaml` now creates it before installing the local inventory.

To test convergence, I pushed commit `6d3d9b600d4e926e9bc9725ec0405c5a9e051769` to `feature/lab7` at `2026-10-01 20:57:43 UTC`. It changed the desired `RestartSec` from `4s` to `5s`. The VM's timer started `ansible-pull` at `21:00:40 UTC`; its log showed the checkout advancing from `3c37c8ddc00be3048373ef101c919021238c8655` to that commit, only the unit-template task changing, and the restart handler running. The pull completed successfully at `21:01:21 UTC`, under four minutes after the push:

```text
TASK [Render the systemd service unit]  changed
RUNNING HANDLER [Restart quicknotes]   changed
PLAY RECAP
localhost : ok=8 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
ansible-pull.service: Deactivated successfully.
```

`systemctl show ansible-pull.service -p Result -p ExecMainStatus` reported `Result=success` and `ExecMainStatus=0`; `systemctl show quicknotes.service -p RestartUSec -p User` reported `RestartUSec=5s` and `User=quicknotes`. The timer ran again at `21:05:59 UTC`, confirming it was not a one-off manual pull. The host's `/health` endpoint continued returning HTTP 200 with four notes after convergence.

### Design answers h–i

h) Pull mode lets each VM make outbound HTTPS requests to Git, without exposing a fleet of SSH endpoints or centralizing SSH private keys on a control node. It does not eliminate risk: a compromised Git branch or dependency would still be applied with root privileges, so branch protection, review, and commit verification matter.

i) At the Kubernetes layer this reconciliation pattern is GitOps, implemented by tools such as Argo CD or Flux. `ansible-pull` is a small VM-level analogue: a periodically running local agent compares/applies desired state from Git rather than relying on a one-time manual push.
