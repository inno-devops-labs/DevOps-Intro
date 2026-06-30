# Lab 7 Submission: Deploy QuickNotes via Ansible

## The Environment Setup

> Control node: Ansible **10.7.0** (`ansible-core 2.17.14`) running in WSL2 Ubuntu on the
> Windows host. Target: the Lab 5 `bento/ubuntu-24.04` VirtualBox VM (`vagrant up`),
> reached on `127.0.0.1:2222` via Vagrant's NAT port-forward.
>
> **Networking note:** the Lab 5 VM forwards SSH to `127.0.0.1:2222`. WSL2's default NAT
> networking has its own loopback and cannot see the Windows host's `127.0.0.1`. 
> Enabling WSL **mirrored** networking mode
> (`%USERPROFILE%\.wslconfig` → `[wsl2] networkingMode=mirrored`, then `wsl --shutdown`)
> makes WSL share the host loopback, so the inventory's `127.0.0.1:2222` works unchanged.

---

## Task 1: Idempotent Deploy to the Lab 5 VM

### Layout

```text
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── quicknotes          # static binary: CGO_ENABLED=0 GOOS=linux go build
│   └── seed.json           # initial notes, shipped to the data dir
└── templates/
    └── quicknotes.service.j2
```

The binary is built statically so it has no glibc/runtime dependency on the guest:

```bash
cd app && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o quicknotes .
cp quicknotes seed.json ../ansible/files/
```

### `ansible/inventory.ini`

```ini
[quicknotes_vm]
default ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key

[quicknotes_vm:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa'
ansible_python_interpreter=/usr/bin/python3
```

The key path is the relative path Vagrant generates inside the repo (`vagrant ssh-config`
prints it). The `+ssh-rsa` / `HostKeyAlgorithms` options match what `vagrant ssh-config`
emits for the insecure box key.

> When running from WSL, the key on the `/mnt/d` Windows mount shows as world-readable, so
> OpenSSH refuses it. For my runs I copied it into the WSL filesystem with `chmod 600` and
> overrode the path on the command line — the committed inventory keeps the portable value:
> ```bash
> cp .vagrant/machines/default/virtualbox/private_key ~/.ssh/vagrant_qn_key
> chmod 600 ~/.ssh/vagrant_qn_key
> ansible-playbook -i inventory.ini playbook.yaml \
>   -e ansible_ssh_private_key_file=/home/<user>/.ssh/vagrant_qn_key
> ```

### `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes to the Lab 5 Vagrant VM
  hosts: quicknotes_vm
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_bin_path: /usr/local/bin/quicknotes
    quicknotes_listen_addr: ":8080"
    quicknotes_data_path: "{{ quicknotes_data_dir }}/notes.json"
    quicknotes_seed_path: "{{ quicknotes_data_dir }}/seed.json"

  tasks:
    - name: Create system user for quicknotes
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        system: true
        shell: /usr/sbin/nologin
        create_home: false

    - name: Ensure quicknotes data directory exists
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0750"

    - name: Ship seed data
      ansible.builtin.copy:
        src: seed.json
        dest: "{{ quicknotes_seed_path }}"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_user }}"
        mode: "0640"

    - name: Copy quicknotes binary
      ansible.builtin.copy:
        src: quicknotes
        dest: "{{ quicknotes_bin_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: restart quicknotes

    - name: Render quicknotes systemd unit
      ansible.builtin.template:
        src: quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: restart quicknotes

    - name: Reload systemd, enable and start quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        daemon_reload: true
        enabled: true
        state: started

  handlers:
    - name: restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
```

### `ansible/templates/quicknotes.service.j2`

```ini
[Unit]
Description=QuickNotes service
After=network-online.target
Wants=network-online.target

[Service]
User={{ quicknotes_user }}
Group={{ quicknotes_user }}
WorkingDirectory={{ quicknotes_data_dir }}
Environment=ADDR={{ quicknotes_listen_addr }}
Environment=DATA_PATH={{ quicknotes_data_path }}
Environment=SEED_PATH={{ quicknotes_seed_path }}
ExecStart={{ quicknotes_bin_path }}
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

Every value the unit needs (`User`, `WorkingDirectory`, the three env vars, the binary
path) comes from a playbook variable, so changing a var in the play re-renders the unit —
this is what Task 2's selective-change demonstration exercises.

### 1.7a Connectivity check (before deploying)

Confirm Ansible can reach and authenticate to the VM. The `ping` module is an SSH + Python
round-trip (not ICMP); `pong` means the inventory, key, and (mirrored) networking all work.

**Input:**
```bash
ansible -i inventory.ini quicknotes_vm -m ping \
  -e ansible_ssh_private_key_file=$HOME/.ssh/vagrant_qn_key
```

**Output:**
```text
default | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 1.7b Dry run (`--check`)

**Input:**
```bash
ansible-playbook -i inventory.ini playbook.yaml \
  -e ansible_ssh_private_key_file=$HOME/.ssh/vagrant_qn_key --check
```

**Output:**
```text
PLAY [Deploy QuickNotes to the Lab 5 Vagrant VM] *******************************

TASK [Create system user for quicknotes] ***************************************
changed: [default]

TASK [Ensure quicknotes data directory exists] *********************************
[WARNING]: failed to look up user quicknotes. Create user up to this point in
real play
[WARNING]: failed to look up group quicknotes. Create group up to this point in
real play
changed: [default]

TASK [Ship seed data] **********************************************************
changed: [default]

TASK [Copy quicknotes binary] **************************************************
changed: [default]

TASK [Render quicknotes systemd unit] ******************************************
changed: [default]

TASK [Reload systemd, enable and start quicknotes] *****************************
fatal: [default]: FAILED! => {"changed": false, "msg": "Could not find the requested service quicknotes: host"}

PLAY RECAP *********************************************************************
default                    : ok=5    changed=5    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```

This failure is **expected on a first deploy**. `--check` simulates every task without
actually writing anything, so the unit file is never created on disk; when the last task
asks systemd to enable/start `quicknotes`, the service genuinely doesn't exist yet, so it
errors. The two `WARNING` lines are the same effect one task earlier — the `quicknotes` user
isn't really created in check mode, so the `file` task can't look it up to set ownership.
Both disappear once the service exists: re-running `--check` *after* the first real deploy
returns a clean `ok=6 changed=0`.

### 1.7c First run (real deploy)

**Input:**
```bash
ansible-playbook -i inventory.ini playbook.yaml \
  -e ansible_ssh_private_key_file=$HOME/.ssh/vagrant_qn_key
```

**Output:**
```text
PLAY [Deploy QuickNotes to the Lab 5 Vagrant VM] *******************************

TASK [Create system user for quicknotes] ***************************************
changed: [default]

TASK [Ensure quicknotes data directory exists] *********************************
changed: [default]

TASK [Ship seed data] **********************************************************
changed: [default]

TASK [Copy quicknotes binary] **************************************************
changed: [default]

TASK [Render quicknotes systemd unit] ******************************************
changed: [default]

TASK [Reload systemd, enable and start quicknotes] *****************************
changed: [default]

RUNNING HANDLER [restart quicknotes] *******************************************
changed: [default]

PLAY RECAP *********************************************************************
default                    : ok=7    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

With the files actually written, the `systemd` task succeeds and the `restart quicknotes`
handler fires once (notified by both the binary copy and the unit template).

### Verification on host (`curl` via the Vagrant port-forward → `127.0.0.1:18080`)

```console
$ curl.exe -s http://localhost:18080/health
{"notes":4,"status":"ok"}

$ curl.exe -s http://localhost:18080/notes
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]
```

Service state on the guest (confirms it runs as the unprivileged `quicknotes` user, not
root):

```console
$ systemctl is-active quicknotes
active
$ systemctl is-enabled quicknotes
enabled
$ ps -o user:20=,comm= -p $(systemctl show -p MainPID --value quicknotes)
quicknotes           quicknotes
```

### 1.5 Design questions

**a) `command:` vs the dedicated modules (`apt`, `file`, `copy`, `systemd`) — which is
idempotent, and why does it matter?**

`command:`/`shell:` just run a string and report `changed` every run, because Ansible can't
know what state they produce. The dedicated modules are idempotent, they inspect current
state and only act (and only report `changed`) when reality differs from the goal. This
matters because a converged host should report `changed=0`, which makes re-runs safe and
makes any `changed=1` a real drift signal rather than noise.

**b) `notify:` and handlers — when does a handler fire, when does it *not*, and why is that
the right default?**

A handler fires once, at the end of the play, only if at least one notifying task reported
`changed`; it does not fire when those tasks were all `ok`. That's the right default because
you only want to restart the service when something actually changed, and batching means ten
changes that notify "restart quicknotes" cause one restart, not ten. Here both the binary
copy and the unit template notify it, so a no-op run restarts nothing.

**c) Variable hierarchy — top 3 places you'd put a variable for this lab, and why.**

Lowest→highest precedence: (1) **`defaults/`** for baseline fallbacks anything can override;
(2) **playbook `vars:`** (what I used) for values that define this deployment, kept next to
the tasks that use them; (3) **`-e` extra-vars**, which win over everything — I used
`-e ansible_ssh_private_key_file=...` for a per-run override without editing the committed
inventory.

**d) `gather_facts: true` is the default — do you need it here? What does turning it off
save?**

No — the playbook references zero `ansible_*` facts, so I set `gather_facts: false`. That
skips the implicit `setup` run at play start, saving an SSH round-trip and a few hundred ms
per run — worth it for a play the Bonus timer runs every 5 minutes. I'd re-enable it only if
a template needed a fact like `ansible_default_ipv4.address`.
