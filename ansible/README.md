# QuickNotes Ansible deployment

I use this playbook to deploy QuickNotes to my Lab 5 Vagrant VM and to install
an optional pull-based convergence loop. The playbook creates a dedicated
system account, installs the static application and seed data, renders the
systemd unit, and keeps the service enabled and running.

## Files

- `inventory.ini` targets my Vagrant VM through its loopback SSH forwarding.
- `local-inventory.ini` is installed in the VM for `ansible-pull`.
- `playbook.yaml` contains the idempotent deployment and GitOps-loop tasks.
- `files/quicknotes` is the stripped, statically linked Linux AMD64 binary.
- `files/seed.json` is the initial data set served on the first application run.
- `templates/quicknotes.service.j2` runs QuickNotes as the unprivileged
  `quicknotes` system user.
- `templates/ansible-pull.service.j2` and `ansible-pull.timer.j2` reconcile the
  VM from my `feature/lab7` branch every five minutes.

## Build and deploy

I run these commands from the repository root:

```bash
python3 -m venv .venv
.venv/bin/pip install -r ansible/requirements.txt

cd app
CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' \
  -o ../ansible/files/quicknotes .
cd ..

.venv/bin/ansible-playbook -i ansible/inventory.ini \
  ansible/playbook.yaml --check --diff
.venv/bin/ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

I verify the application through the loopback-only port forward:

```bash
curl -fsS http://127.0.0.1:18080/health
curl -fsS http://127.0.0.1:18080/notes
```

I prove idempotency by running the unchanged playbook again and checking that
the recap reports `changed=0`. To demonstrate a selective template update
without breaking the forwarded application port, I temporarily change
`quicknotes_restart_sec`; only the service template changes, and the
`Restart quicknotes` handler runs.

## Pull-based convergence

The first push-mode run installs Git, the distribution Ansible package, the
local inventory, and both timer units. The VM then runs this equivalent command
on every timer activation:

```bash
ansible-pull \
  -U https://github.com/sonder314/DevOps-Intro.git \
  -C feature/lab7 \
  -i /etc/quicknotes-ansible-inventory.ini \
  -l localhost \
  ansible/playbook.yaml
```

I inspect the loop with:

```bash
ssh -i .vagrant/machines/default/virtualbox/private_key -p 2222 \
  vagrant@127.0.0.1 'systemctl list-timers ansible-pull.timer --no-pager'
ssh -i .vagrant/machines/default/virtualbox/private_key -p 2222 \
  vagrant@127.0.0.1 \
  'sudo journalctl -u ansible-pull.service --no-pager -n 100'
```

After the VM and my Ansible 10.x environment are available, I can capture the
required first run, HTTP checks, idempotency run, selective change, dry-run
diff, and timer logs consistently with `scripts/lab7-capture.sh`.
