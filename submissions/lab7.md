# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

> Lab was done with my lovely macbook Air M4, this lab was based on lab5
> The shipped binary is built with `CGO_ENABLED=0 GOOS=linux GOARCH=arm64`, so it runs
> natively in the guest. Ansible runs on the host(installed by brew).

---


## Task 1 — Idempotent Deploy to the Lab 5 VM

What I have done?

### inventory.ini

```
[quicknotes_vm]
qn-vm ansible_host=127.0.0.1 ansible_port=2222

[quicknotes_vm:vars]
ansible_user=vagrant
ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
ansible_python_interpreter=/usr/bin/python3
```

### playbook.yaml

```
---
- name: Deploy QuickNotes
  hosts: quicknotes_vm
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    data_dir: /var/lib/quicknotes
    binary_path: /usr/local/bin/quicknotes
    listen_addr: ":8080"

  tasks:
    - name: Bootstrap python3
      ansible.builtin.raw: test -e /usr/bin/python3 || (apt-get update && apt-get install -y python3)
      changed_when: false

    - name: Create the quicknotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false

    - name: Ensure the data directory exists
      ansible.builtin.file:
        path: "{{ data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0750"

    - name: Copy the QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ binary_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart quicknotes

    - name: Render the systemd unit from the template
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: Restart quicknotes

    - name: Enable and start quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        enabled: true
        state: started
        daemon_reload: true

  handlers:
    - name: Restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
        daemon_reload: true
```

### templates/quicknotes.service.j2

```
[Unit]
Description=QuickNotes API
After=network-online.target
Wants=network-online.target

[Service]
User={{ quicknotes_user }}
Group={{ quicknotes_user }}
Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ data_dir }}/notes.json
Environment=SEED_PATH={{ data_dir }}/seed.json
WorkingDirectory={{ data_dir }}
ExecStart={{ binary_path }}
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

### first run of ansible 

```
ephy@Starless-night DevOps-Intro % ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] ***********************************************************************************************

TASK [Bootstrap python3] ***********************************************************************************************
ok: [qn-vm]

TASK [Create the quicknotes system user] *******************************************************************************
changed: [qn-vm]

TASK [Ensure the data directory exists] ********************************************************************************
changed: [qn-vm]

TASK [Copy the QuickNotes binary] **************************************************************************************
changed: [qn-vm]

TASK [Render the systemd unit from the template] ***********************************************************************
changed: [qn-vm]

TASK [Enable and start quicknotes] *************************************************************************************
ok: [qn-vm]

RUNNING HANDLER [Restart quicknotes] ***********************************************************************************
changed: [qn-vm]

PLAY RECAP *************************************************************************************************************
qn-vm                      : ok=7    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0



```

### Service reachable from the host

```
ephy@Starless-night DevOps-Intro % curl -s http://localhost:18080/health

{"notes":0,"status":"ok"}
```

**Why `notes:0`?** According to README in app/ , I might insert seed.json to prefilled quicknotes. However, The unit still
sets `SEED_PATH`, it just points at a `seed.json` that does not exist.
QuickNotes is totally fine with that: on first boot it can't find `notes.json` or a seed,
so it writes an empty `[]` and starts clean. So `/health` comes back
`{"notes":0,"status":"ok"}` — still a 200, service is up, just no starter notes in it.

### Design questions

**a) `command:`/`shell:` vs dedicated modules — which is idempotent, why it matters.**
Dedicated modules (`user`, `file`, `copy`, `template`, `systemd`) are declarative — each
one looks at the current state and only changes what is different -  reports `changed`
and plays nice with `--check`/`--diff`. 

`command:`/`shell:`: they run every
single time, have no idea what the end-state should be, and shout `changed` on every run
That kills idempotency, which is the whole point of config management — so I use modules everywhere.

**b) `notify:`/handlers — when a handler fires, when it doesn't, why that's right.**
Handler fires only if the task that notifies it actually reported `changed`, and it runs
once, at the very end of the play. If the notifying task is
just `ok` (nothing changed) — handler stays quiet. That's exactly the default I want:
restart QuickNotes only when its binary or unit really changed. Restarting on every run
 is not an idempotency.

**c) Variable hierarchy — top 3**
1. **Playbook `vars:`** — where I keep `listen_addr`, `data_dir`, `binary_path`. Visible,
   in git.
2. **`group_vars/quicknotes_vm`** — if I wanted to pull inventory-specific values out of
   the play logic.
3. **`--extra-vars`** — top precedence, for a quick one-off override while testing,
    without touching files.


**d) Is `gather_facts` needed here? What does turning it off save?**
No. The play doesn't read a single `ansible_fact` — no OS/IP/memory `when:`,
everything's a plain static var. 
So `gather_facts: false` skips the implicit `setup`
module, which is one extra SSH trip and so it saves several seconds every run.

---

## Task 2 — Prove Idempotency

### Second run — `changed=0`

```
ephy@Starless-night DevOps-Intro % ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] ***********************************************************************************************

TASK [Bootstrap python3] ***********************************************************************************************
ok: [qn-vm]

TASK [Create the quicknotes system user] *******************************************************************************
ok: [qn-vm]

TASK [Ensure the data directory exists] ********************************************************************************
ok: [qn-vm]

TASK [Copy the QuickNotes binary] **************************************************************************************
ok: [qn-vm]

TASK [Render the systemd unit from the template] ***********************************************************************
ok: [qn-vm]

TASK [Enable and start quicknotes] *************************************************************************************
ok: [qn-vm]

PLAY RECAP *************************************************************************************************************
qn-vm                      : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Variable tweak 

Changed `listen_addr` from `:8080` to `:9090`, re-ran, then reverted to `:8080`.

```
ephy@Starless-night DevOps-Intro % ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes] ***********************************************************************************************

TASK [Bootstrap python3] ***********************************************************************************************
ok: [qn-vm]

TASK [Create the quicknotes system user] *******************************************************************************
ok: [qn-vm]

TASK [Ensure the data directory exists] ********************************************************************************
ok: [qn-vm]

TASK [Copy the QuickNotes binary] **************************************************************************************
ok: [qn-vm]

TASK [Render the systemd unit from the template] ***********************************************************************
changed: [qn-vm]

TASK [Enable and start quicknotes] *************************************************************************************
ok: [qn-vm]

RUNNING HANDLER [Restart quicknotes] ***********************************************************************************
changed: [qn-vm]

PLAY RECAP *************************************************************************************************************
qn-vm                      : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```

### `--check --diff` preview

Changed `RestartSec` 2 → 3 in the template, ran with `--check --diff`, then reverted.

```
ephy@Starless-night DevOps-Intro % ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff

PLAY [Deploy QuickNotes] ***********************************************************************************************

TASK [Bootstrap python3] ***********************************************************************************************
skipping: [qn-vm]

TASK [Create the quicknotes system user] *******************************************************************************
ok: [qn-vm]

TASK [Ensure the data directory exists] ********************************************************************************
ok: [qn-vm]

TASK [Copy the QuickNotes binary] **************************************************************************************
ok: [qn-vm]

TASK [Render the systemd unit from the template] ***********************************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/ephy/.ansible/tmp/ansible-local-4494ag19dbiw/tmpd7jv2my4/quicknotes.service.j2
@@ -12,7 +12,7 @@
 WorkingDirectory=/var/lib/quicknotes
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=2
+RestartSec=3
 
 [Install]
 WantedBy=multi-user.target

changed: [qn-vm]

TASK [Enable and start quicknotes] *************************************************************************************
ok: [qn-vm]

RUNNING HANDLER [Restart quicknotes] ***********************************************************************************
changed: [qn-vm]

PLAY RECAP *************************************************************************************************************
qn-vm                      : ok=6    changed=2    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0 

```

### Design questions

**e) Why does the second run report `changed=0`?**
Because the modules check desired vs actual before touching anything. `copy`/`template`
hash the source/rendered content and compare it; `user`/`file` check the resource's attributes. Second run nothing's
different, so every task comes back `ok` and the recap says `changed=0`. That's the
idempotency proof right there.

**f) What breaks if you use `shell: 'echo "ADDR=..." > unit'` instead of `template:`?**
A lot of stuff. It runs every time and always says `changed`, so the handler restarts
the service on every run. No `--check`/`--diff`. 
A crash mid-write leaves a half-written, corrupt unit. And it can't see drift — if
someone hand-edits the file, `shell` won't notice or fix it. `template:` gives me all of
that for free.

**g) `--check` vs `--check --diff` —**
Plain `--check` tells me which tasks would change, not **what** would change. 

`--check --diff` shows the actual content. 

The bug it catches: a template edit that's "applied" but wrong For example  a typo renders `ADDR=` empty. Plain `--check` just says "template
changed=1" but `--diff` shows me the broken line, so I catch it before it ships
and the service refuses to start.

---

## Bonus Task — `ansible-pull` GitOps loop

The VM runs `ansible-pull` on a systemd timer every 5 minutes, pulling `feature/lab7`
from `https://github.com/Ephy01/DevOps-Intro.git` and reconciling itself with
`ansible/inventory-local.ini` + `ansible/playbook.yaml`.

### Timer active

```text
$ systemctl list-timers | grep ansible-pull
 Wed 2026-06-24 10:11:51 UTC     18ms ago ansible-pull.timer             ansible-pull.service
```

### Convergence timeline 

```text
Wed Jun 24 13:30:56 MSK 2026 - time of push

then, on VM, during 5 minutes:

ephy@Starless-night DevOps-Intro % vagrant ssh -c 'grep ADDR /etc/systemd/system/quicknotes.service; sudo systemctl show quicknotes -p ActiveEnterTimestamp'
Environment=ADDR=:8082

ActiveEnterTimestamp=Wed 2026-06-24 10:32:15 UTC(which 13:32:15 in Moscow time)

When I desided to restore `8080`
Wed Jun 24 13:35:24 MSK 2026 - push time
then
Environment=ADDR=:8080
ActiveEnterTimestamp=Wed 2026-06-24 10:37:27 UTC
```

### Design questions

**h) Pull vs push**
In pull mode each node reaches git itself, so no node needs an inbound SSH port
open for management, and there's no central control node sitting on keys that can touch
every machine. A node only needs
read access to the repo, so the blast radius of a compromised box is just that box. Plus
it scales — adding nodes needs zero changes to control inventory.

**i) Same pattern at the Kubernetes layer? Why is `ansible-pull` a fair simulator?**
It is ArgoCD / Flux. `ansible-pull` is a fair simulator because it is the same
control loop: an agent on the box pulls the declared desired state from git on a timer
and reconciles the machine to it. That is exactly what Argo/Flux do for
cluster manifests — just one layer down, VM/OS config instead of k8s objects.
