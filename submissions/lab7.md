# Lab 7 submission

## Task 1: Idempotent Deploy to the Lab 5 VM

- Playbook: [ansible/playbook.yaml](../ansible/playbook.yaml)
- Inventory: [ansible/inventory.ini](../ansible/inventory.ini)
- Systemd unit template: [ansible/templates/quicknotes.service.j2](../ansible/templates/quicknotes.service.j2)

### ansible/playbook.yaml

```yaml
---
# Deploys QuickNotes to the Lab 5 VM as a systemd service.
#
# Facts are not gathered: no task below reads one, and the play is the same
# whether it runs over SSH from the host or locally under ansible-pull.
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true
  gather_facts: false

  vars:
    qn_user: quicknotes
    qn_group: quicknotes
    qn_binary: /usr/local/bin/quicknotes
    qn_data_dir: /var/lib/quicknotes
    qn_listen_addr: ":8080"
    qn_data_path: /var/lib/quicknotes/notes.json
    qn_seed_path: /var/lib/quicknotes/seed.json
    qn_restart_sec: 10

  tasks:
    - name: Create the quicknotes system user
      ansible.builtin.user:
        name: "{{ qn_user }}"
        system: true
        shell: /usr/sbin/nologin
        home: "{{ qn_data_dir }}"
        create_home: false
        state: present

    - name: Ensure the data directory exists
      ansible.builtin.file:
        path: "{{ qn_data_dir }}"
        state: directory
        owner: "{{ qn_user }}"
        group: "{{ qn_group }}"
        mode: "0750"

    - name: Install the QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ qn_binary }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart quicknotes

    - name: Install the seed file
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ qn_seed_path }}"
        owner: "{{ qn_user }}"
        group: "{{ qn_group }}"
        mode: "0640"

    - name: Render the systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      register: qn_unit
      notify: Restart quicknotes

    - name: Reload systemd after a unit change
      ansible.builtin.systemd:
        daemon_reload: true
      when: qn_unit is changed

    - name: Enable and start quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        enabled: true
        state: started

  handlers:
    - name: Restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
```

### ansible/inventory.ini

```ini
# The Lab 5 VirtualBox VM, reached through the NAT port forward Vagrant sets up.
# Every value here is what `vagrant ssh-config` prints for this machine.

[quicknotes]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=2222

[quicknotes:vars]
ansible_user=vagrant
ansible_ssh_private_key_file={{ playbook_dir }}/../.vagrant/machines/default/virtualbox/private_key
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args=-o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
```

### ansible/templates/quicknotes.service.j2

```
{{ ansible_managed | comment }}

[Unit]
Description=QuickNotes HTTP service
Documentation=https://github.com/inno-devops-labs/DevOps-Intro
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ qn_user }}
Group={{ qn_group }}
WorkingDirectory={{ qn_data_dir }}
Environment=ADDR={{ qn_listen_addr }}
Environment=DATA_PATH={{ qn_data_path }}
Environment=SEED_PATH={{ qn_seed_path }}
ExecStart={{ qn_binary }}
Restart=on-failure
RestartSec={{ qn_restart_sec }}

[Install]
WantedBy=multi-user.target
```

### First run

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] *******************************************************

TASK [Create the quicknotes system user] ***************************************
changed: [quicknotes-vm]

TASK [Ensure the data directory exists] ****************************************
changed: [quicknotes-vm]

TASK [Install the QuickNotes binary] *******************************************
changed: [quicknotes-vm]

TASK [Install the seed file] ***************************************************
changed: [quicknotes-vm]

TASK [Render the systemd unit] *************************************************
changed: [quicknotes-vm]

TASK [Reload systemd after a unit change] **************************************
ok: [quicknotes-vm]

TASK [Enable and start quicknotes] *********************************************
changed: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=8    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

The reload task reports ok and not changed because the systemd module decides changed from a change in service state, and a daemon-reload alone is not one. The when condition on that task is what matters for the next run: when the unit file did not change, the task is skipped instead of running.

### Service reachable and serving the seed data

```
$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}

$ curl -s http://localhost:18080/notes
[{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},
 {"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},
 {"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},
 {"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"}]

$ vagrant ssh -c 'systemctl show -p ActiveState -p ExecMainStatus quicknotes; ss -ltn | grep 8080'
ActiveState=active
ExecMainStatus=0
LISTEN 0      4096               *:8080            *:*
```

All four seeded notes are returned, so seed.json reached the VM and SEED_PATH points to it.

### Design questions

**a) command: versus the dedicated modules**

Modules like apt, file, copy, template and systemd are declarative. A module first reads the current state on the host. Then it compares this state with the state written in the task. It acts only if the two are different, so it reports changed only when it really changed something.

The command and shell modules only start a program. Ansible cannot know what this program does. So these modules report changed on every run, and a second run can do the same work twice.

This matters because idempotency makes the recap useful. With the dedicated modules, changed=0 means the host already matches the playbook, and any other number means there was a real drift and Ansible fixed it. If I used shell for everything, every run would report changed. Then a real change would look the same as no change, and the handler would restart the service on every run.

**b) notify and handlers**

A handler runs when a task that notifies it reports changed. It runs once at the end of the play, even if several tasks notified it. Handlers run in the order they are written in the file, not in the order of the notifications.

A handler does not run when the task reports ok, when the task is skipped by a when condition, or when the play fails before the handlers start. The last case can be changed with --force-handlers.

This default is correct because a restart stops the service for a moment. QuickNotes has to restart when its binary or its unit file changed, and these are exactly the two tasks that notify the handler. If the restart happened on every run, a safe deploy would become a small outage every time.

**c) Variable hierarchy: the top 3 places for this lab**

1. Playbook vars. This is what the play uses. There is one play and one host, and the values describe this deploy. They sit next to the tasks that read them, so it is easy to see what a task will do. Playbook vars have higher precedence than inventory and group_vars, which is right here: the inventory says where to connect, not what to install.

2. group_vars/quicknotes.yml. This is the place for values that describe the group and not one deploy. If a second host joins the quicknotes group, the paths and the service user belong here, because they live with the inventory and apply to every play against that group.

3. Extra vars given with -e. They have the highest precedence and nothing can override them. This is good for a single test, for example trying another listen address on the VM without editing a file in Git.

If this playbook became a role, the same values would move to defaults/main.yml. That level has the lowest precedence, so every level above it can override it.

**d) Is gather_facts needed here**

No. No task in this play reads a fact. Every path, mode, owner and environment value comes from the vars block, and the modules read the state themselves. So the play sets gather_facts to false.

On this VM the setup task costs about 0.32 s:

```
$ time ansible -i ansible/inventory.ini quicknotes -m setup > /dev/null
0.15s user 0.05s system 62% cpu 0.320 total

$ time ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml > /dev/null
0.43s user 0.22s system 37% cpu 1.705 total
```

That is about one fifth of the whole run for one host, and it is paid for every host on every run, so it grows with the number of hosts. There is a second gain: the play no longer needs fact gathering to work on the target. This helps when the same playbook runs without a person under ansible-pull.

---

## Task 2: Idempotency and Selective Re-run

### Second run, nothing changed

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

TASK [Create the quicknotes system user] ***************************************
ok: [quicknotes-vm]

TASK [Ensure the data directory exists] ****************************************
ok: [quicknotes-vm]

TASK [Install the QuickNotes binary] *******************************************
ok: [quicknotes-vm]

TASK [Install the seed file] ***************************************************
ok: [quicknotes-vm]

TASK [Render the systemd unit] *************************************************
ok: [quicknotes-vm]

TASK [Reload systemd after a unit change] **************************************
skipping: [quicknotes-vm]

TASK [Enable and start quicknotes] *********************************************
ok: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=6    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

No task notified the handler, so the handler did not run at all.

### One variable changed, qn_listen_addr from ":8080" to ":9090"

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

TASK [Create the quicknotes system user] ***************************************
ok: [quicknotes-vm]

TASK [Ensure the data directory exists] ****************************************
ok: [quicknotes-vm]

TASK [Install the QuickNotes binary] *******************************************
ok: [quicknotes-vm]

TASK [Install the seed file] ***************************************************
ok: [quicknotes-vm]

TASK [Render the systemd unit] *************************************************
changed: [quicknotes-vm]

TASK [Reload systemd after a unit change] **************************************
ok: [quicknotes-vm]

TASK [Enable and start quicknotes] *********************************************
ok: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Only the template task changed, and the handler it notifies ran. The user, the data directory, the binary and the seed file stayed ok. The two changes in the recap are the template task and the handler.

### Third change, previewed with --check --diff

The third change sets qn_listen_addr back to ":8080" and raises qn_restart_sec from 2 to 5.

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff

TASK [Render the systemd unit] *************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/annaksel/.ansible/tmp/ansible-local-1076fcgv3p4j/tmpqxz70j9i/quicknotes.service.j2
@@ -13,12 +13,12 @@
 User=quicknotes
 Group=quicknotes
 WorkingDirectory=/var/lib/quicknotes
-Environment=ADDR=:9090
+Environment=ADDR=:8080
 Environment=DATA_PATH=/var/lib/quicknotes/notes.json
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=2
+RestartSec=5

 [Install]
 WantedBy=multi-user.target

changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

The preview was then applied for real, so Git and the VM stayed in the same state:

```
$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

TASK [Render the systemd unit] *************************************************
changed: [quicknotes-vm]

TASK [Reload systemd after a unit change] **************************************
ok: [quicknotes-vm]

TASK [Enable and start quicknotes] *********************************************
ok: [quicknotes-vm]

RUNNING HANDLER [Restart quicknotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm              : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

The bonus task later raised qn_restart_sec once more, from 5 to 10. That is the commit the pull loop converged on, and it is the value in the playbook now.

### Design questions

**e) Why the second run reports changed=0**

Every module compares the state in the task with the state on the host and reports changed only if they differ.

The file module stats the path. It checks what it manages: the path exists, it is a directory, and its owner, group and mode. On the second run the directory was already there with owner and group quicknotes and mode 0750, so there was nothing to do.

The template module renders the template on the control node and takes a checksum of the result. It reads the SHA1 checksum of the remote file with a stat call before it sends anything, and compares the two. Equal checksums mean no transfer. After that it compares owner, group and mode in the same way as the file module. The copy module works the same way, with the checksum of the local source file. This is why the 5.3 MB binary is not sent again on every run.

On the second run none of these comparisons found a difference. So every task reported ok, no task notified the handler, and the daemon-reload task was skipped by its own when condition.

**f) What would happen with shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'**

- It is not idempotent. The redirect writes the file every time, so the task is changed on every run. The handler is notified every run, and the service restarts every run.
- Drift cannot be seen. The task is always changed, so a real change and no change look the same in the recap.
- A dry run shows nothing. The shell module does not run under --check, so the preview says nothing about the new file, and --diff has nothing to compare.
- The file attributes are wrong. The owner, group and mode come from root's umask instead of the values in the task, and no later run fixes them.
- Quoting can break the value. The text goes through one more shell, so a colon, a space or a dollar sign in the address can be split or expanded before it reaches the file.
- The write is not atomic. The redirect first makes the file empty, so a run that stops in the middle leaves a broken unit and systemd cannot load it. The template module writes a temporary file and then renames it, so the unit is either the old one or the new one.
- An undefined variable fails silently. It gives an empty line in the unit instead of an error. The template module raises an undefined variable error and stops the play.

**g) What --check --diff catches that plain --check misses**

Plain --check says which tasks would change. It does not say what would change inside them. The bug it misses is an unwanted change inside a task that was expected to change anyway.

In this playbook the template task reports changed in both modes. Only the diff shows which lines move. If a variable was renamed and the template still used the old name, the render would silently drop an Environment line or leave it empty. The recap would look exactly like a correct deploy, and the service would come back on the wrong address or read the wrong data file. The diff shows that line disappear before anything is written.

The opposite case works the same way. If a template reports changed on every run for a cosmetic reason, such as a rendered timestamp, plain --check only keeps saying changed. The diff shows that the file is rewritten with the same meaning, so it is noise and not drift.

---

## Bonus Task: ansible-pull GitOps Loop

The setup is automated. pull-setup.yaml installs the ansible and git packages in the guest with apt, creates the checkout directory, and then installs the local inventory, the service unit and the timer unit:

- Setup playbook: [ansible/pull-setup.yaml](../ansible/pull-setup.yaml)
- Service template: [ansible/templates/ansible-pull.service.j2](../ansible/templates/ansible-pull.service.j2)
- Timer template: [ansible/templates/ansible-pull.timer.j2](../ansible/templates/ansible-pull.timer.j2)
- Local inventory: [ansible/files/pull-inventory.ini](../ansible/files/pull-inventory.ini)

### The deployed artifacts

```
# /etc/systemd/system/ansible-pull.service
[Unit]
Description=Converge this host from Git with ansible-pull
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull \
    --url https://github.com/aniksel/DevOps-Intro.git \
    --checkout feature/lab7 \
    --directory /var/lib/ansible-pull \
    --inventory /etc/ansible/pull-inventory.ini \
    ansible/playbook.yaml
```

```
# /etc/systemd/system/ansible-pull.timer
[Unit]
Description=Run ansible-pull every 5min

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
AccuracySec=10s
Unit=ansible-pull.service

[Install]
WantedBy=timers.target
```

```
# /etc/ansible/pull-inventory.ini
[quicknotes]
127.0.0.1 ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

### Timer installed and active

```
$ vagrant ssh -c 'systemctl is-enabled ansible-pull.timer; systemctl list-timers --all | grep ansible-pull'
enabled
Wed 2026-09-30 21:03:54 UTC 4min 37s Wed 2026-09-30 20:58:54 UTC 22s ago ansible-pull.timer  ansible-pull.service
```

### Convergence timeline

| Time (UTC) | Event |
|---|---|
| 20:53:51 | commit 2e64976 pushed to origin feature/lab7, qn_restart_sec raised from 5 to 10 |
| 20:53:51 | the timer starts ansible-pull.service in the VM |
| 20:54:02 | the pull run ends with changed=2: the unit was rendered again and the handler ran |
| 20:58:36 | checked in the VM: RestartUSec=10s, checkout at 2e64976 |

From the push to the new state: 11 seconds.

The push does not start the run. The timer does, and it fires every five minutes. This push landed one second before a fire that was already due, because the run before it was at 20:48:50. So 11 seconds is the best case, not the normal one. What the timer guarantees is at most five minutes, and a push made just after a fire waits almost the full five minutes.

```
$ vagrant ssh -c 'systemctl show -p RestartUSec quicknotes; grep RestartSec /etc/systemd/system/quicknotes.service; sudo git -C /var/lib/ansible-pull log -1 --format="checkout now at %h %s"'
RestartUSec=10s
RestartSec=10
checkout now at 2e64976 chore(lab7): raise restart backoff to 10s to demo pull convergence
```

### Journal excerpt from the converging run

```
$ vagrant ssh -c 'sudo journalctl -u ansible-pull.service --no-pager'

Sep 30 20:53:51 quicknotes-vm systemd[1]: Starting ansible-pull.service - Converge this host from Git with ansible-pull...
Sep 30 20:54:02 quicknotes-vm ansible-pull[5887]: TASK [Render the systemd unit] *************************
Sep 30 20:54:02 quicknotes-vm ansible-pull[5887]: changed: [127.0.0.1]
Sep 30 20:54:02 quicknotes-vm ansible-pull[5887]: changed: [127.0.0.1]
Sep 30 20:54:02 quicknotes-vm ansible-pull[5887]: PLAY RECAP *********************************************
Sep 30 20:54:02 quicknotes-vm ansible-pull[5887]: 127.0.0.1                  : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Sep 30 20:54:02 quicknotes-vm systemd[1]: Finished ansible-pull.service - Converge this host from Git with ansible-pull.
```

The run before it, at 20:48:50, pulled the same branch and reported changed=0. So the same playbook is idempotent in local pull mode too, not only over SSH.

### Design questions

**h) The security benefit of pull mode over push mode**

In push mode the control node keeps an SSH key that can become root on every managed host, and every host has to accept incoming SSH from it. So the control node is one single weak point: an attacker who takes it controls all the hosts. The hosts also need an open SSH port, and this is the port that should be closed to everything else.

Pull mode turns the direction around. Each host opens an outgoing HTTPS connection to a read-only Git remote and applies what it finds. No host needs an open incoming port for configuration management. There is no key anywhere that gives root on other machines, and the only credential a host holds gives read access to one repository. An attacker on one host can read the desired state, which that host already applies, but cannot use it to reach a second host. So one stolen credential costs one machine instead of the whole fleet.

**i) The same pattern at the Kubernetes layer**

The pattern is GitOps, and the tool named in the lecture is ArgoCD. Flux is the other common implementation.

ansible-pull is a fair simulator because the main mechanism is the same. Git holds the desired state, an agent on the target reads it on a timer instead of waiting for a push, and every cycle compares the real state with the declared state and fixes the difference. This is why the pull run above reports changed=0 when nothing moved and changed=2 when the declared state changed, which is what a sync status means in ArgoCD.

ansible-pull does not have the parts that ArgoCD adds around this loop:

- a diff and a health status for every resource
- deletion of resources that were removed from Git
- many clusters managed from one place
- a UI and an API that show the sync state of many applications
- a run started by a webhook on push, not only by the timer
