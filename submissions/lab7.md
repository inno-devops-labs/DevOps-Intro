# Lab 7 - Configuration Management: Deploy QuickNotes via Ansible

## Files

- `ansible/inventory.ini`
- `ansible/playbook.yaml`
- `ansible/templates/quicknotes.service.j2`
- `ansible/files/quicknotes`
- `ansible/files/seed.json`

## Inventory

```ini
[quicknotes_vm]
qn-vm-1 ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa'
```

## Playbook

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes_vm
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_group: quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_binary_path: /usr/local/bin/quicknotes
    quicknotes_listen_addr: ":8080"
    quicknotes_data_path: /var/lib/quicknotes/notes.json
    quicknotes_seed_path: /var/lib/quicknotes/seed.json
    quicknotes_restart_sec: 4s

  tasks:
    - name: Create QuickNotes system group
      ansible.builtin.group:
        name: "{{ quicknotes_group }}"
        system: true

    - name: Create QuickNotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        system: true
        shell: /usr/sbin/nologin
        home: "{{ quicknotes_data_dir }}"
        create_home: false

    - name: Ensure QuickNotes data directory exists
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        mode: "0750"

    - name: Install QuickNotes seed data
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ quicknotes_seed_path }}"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        mode: "0640"

    - name: Install QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ quicknotes_binary_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: restart quicknotes

    - name: Install QuickNotes systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: restart quicknotes

    - name: Enable and start QuickNotes
      ansible.builtin.systemd:
        name: quicknotes
        enabled: true
        state: started
        daemon_reload: true

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
        daemon_reload: true
```

## Systemd Template

```ini
[Unit]
Description=QuickNotes API
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User={{ quicknotes_user }}
Group={{ quicknotes_group }}
WorkingDirectory={{ quicknotes_data_dir }}
Environment="ADDR={{ quicknotes_listen_addr }}"
Environment="DATA_PATH={{ quicknotes_data_path }}"
Environment="SEED_PATH={{ quicknotes_seed_path }}"
ExecStart={{ quicknotes_binary_path }}
Restart=on-failure
RestartSec={{ quicknotes_restart_sec }}

[Install]
WantedBy=multi-user.target
```

## Commands

```bash
cd app
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -trimpath -ldflags='-s -w' -o ../ansible/files/quicknotes .
cd ..
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
curl -s http://localhost:18080/health
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
```

## Evidence

Captured against the Lab 5 Vagrant VM on branch `feature/lab7`.

First run PLAY RECAP:

```text
PLAY RECAP *********************************************************************
qn-vm-1                    : ok=8    changed=5    unreachable=0    failed=0    skipped=6    rescued=0    ignored=0
```

Health check:

```text
{"notes":4,"status":"ok"}
```

Second run PLAY RECAP:

```text
PLAY RECAP *********************************************************************
qn-vm-1                    : ok=7    changed=0    unreachable=0    failed=0    skipped=6    rescued=0    ignored=0
```

Selective variable change:

```text
Changed quicknotes_listen_addr from ":8080" to ":9090".

TASK [Install QuickNotes systemd unit] *****************************************
changed: [qn-vm-1]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [qn-vm-1]

PLAY RECAP *********************************************************************
qn-vm-1                    : ok=8    changed=2    unreachable=0    failed=0    skipped=6    rescued=0    ignored=0
```

Check diff:

```diff
--- before: /etc/systemd/system/quicknotes.service
+++ after: /tmp/ansible-local/ansible-local-41556g3h5lxpf/tmpfx5kjmbm/quicknotes.service.j2
@@ -8,7 +8,7 @@
 User=quicknotes
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment="ADDR=:9090"
+Environment="ADDR=:7070"
 Environment="DATA_PATH=/var/lib/quicknotes/notes.json"
 Environment="SEED_PATH=/var/lib/quicknotes/seed.json"
 ExecStart=/usr/local/bin/quicknotes

PLAY RECAP *********************************************************************
qn-vm-1                    : ok=8    changed=2    unreachable=0    failed=0    skipped=6    rescued=0    ignored=0
```

## Design Questions

### a. command vs dedicated modules

`command` runs a program on the target. It does not know the desired end state unless I add custom `creates`, `removes`, or `changed_when` logic. Dedicated modules such as `apt`, `file`, `copy`, `template`, and `systemd` understand the resource they manage and compare current state with desired state before changing anything. That idempotency matters because repeated deploys become safe: an unchanged system reports `ok`, does not restart services, and does not hide real drift in noisy output.

### b. notify and handlers

A handler fires only when a task that notifies it reports `changed`. If the binary checksum and rendered unit file already match the target, the copy/template tasks report `ok` and the handler does not run. This is the right default because restarts are operationally visible events; Ansible should restart QuickNotes only when the service inputs changed.

### c. variable hierarchy

For this lab I would put role defaults first if this were converted to a role, because defaults document safe baseline values and are easy to override. I would put VM-specific settings such as SSH host or per-environment listen address in `group_vars/quicknotes_vm.yml`, because they belong to the inventory group. I would keep a few top-level playbook vars for this small single-play lab, because they make the exercise readable without introducing a role layout too early. For one-off demonstrations, `-e quicknotes_listen_addr=:9090` is useful, but I would avoid committing operational settings there because extra vars have very high precedence.

### d. gather_facts

This playbook does not need facts. It deploys fixed paths, a fixed Linux service, and static files. Setting `gather_facts: false` skips the setup phase and saves a few seconds per run on a single VM, more on a larger inventory.

### e. why the second run reports changed=0

The second run reports `changed=0` because every module sees that current state already matches desired state. The `file` module checks path existence, type, owner, group, and mode. The `copy` module compares file content/checksum plus ownership and mode. The `template` module renders locally, compares the rendered result with the remote file, and changes only if content or metadata differs.

### f. shell echo instead of template

Using `shell: 'echo ... > /etc/systemd/system/quicknotes.service'` would rewrite the file on every run unless I wrote extra change detection myself. That would report `changed` every time, fire the restart handler every time, and break the idempotency proof. It also makes quoting multi-line unit files fragile, hides diffs, can accidentally truncate the file on a failed command, and does not naturally manage owner/mode the way `template` does.

### g. check and diff

Plain `--check` tells me that a file would change, but not whether the rendered content is correct. `--check --diff` can catch bugs such as accidentally rendering `ADDR=:9090` without quotes, changing `DATA_PATH` to the wrong directory, or removing `User=quicknotes`. Those mistakes might still appear as a normal planned change in plain check mode.

### h. ansible-pull security benefit

In pull mode, the VM reaches out to the Git repository and reconciles itself. That means the control side does not need inbound SSH access to the VM, does not need to hold a fleet-wide SSH key, and can sit behind tighter network boundaries. The node still needs repository access, so credentials must be scoped read-only where possible.

### i. Kubernetes equivalent

At the Kubernetes layer this pattern is called GitOps, commonly implemented with Argo CD or Flux. `ansible-pull` is a fair VM-layer simulator because the control loop is the same: Git is the desired-state source, an agent periodically pulls, compares, and converges the running system toward that state.

## Bonus - ansible-pull

The playbook includes optional ansible-pull tasks. The repository URL is set to `https://github.com/whynotgm/DevOps-Intro.git`. To enable the timer, run:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml \
  -e quicknotes_ansible_pull_enabled=true
```

Timer evidence:

```text
Sun 2026-06-28 16:59:22 UTC 4min 37s Sun 2026-06-28 16:54:22 UTC      22s ago ansible-pull-quicknotes.timer ansible-pull-quicknotes.service
```

Convergence timeline:

```text
2026-06-28T19:54:59+03:00 - pushed ea510bf0ae32aa8718c3f510bc89c0ad16fd923c, changing quicknotes_restart_sec from 3s to 4s.
2026-06-28T16:59:25Z - ansible-pull-quicknotes.service started from the systemd timer.
2026-06-28T16:59:30Z - ansible-pull reported before=7bb444927b86db7a2174b3bf14d4b36c252787de and after=ea510bf0ae32aa8718c3f510bc89c0ad16fd923c.
2026-06-28T16:59:30Z - Install QuickNotes systemd unit changed, restart quicknotes handler ran.
2026-06-28T16:59:51Z - /etc/systemd/system/quicknotes.service showed RestartSec=4s.
Health remained OK: {"notes":4,"status":"ok"}.
```
