# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

**Student:** NikolayTaran (na.taranvrn@gmail.com)
**Fork:** https://github.com/NikolayTaran/DevOps-Intro
**Branch:** `feature/lab7`
**PR (course repo):** https://github.com/inno-devops-labs/DevOps-Intro/pull/1678
**Host:** Windows 11 · VirtualBox 7.1.x · Vagrant 2.4.x
**VM:** the Lab 5 machine `quicknotes-lab5` — `bento/ubuntu-24.04` (Ubuntu 24.04.3), NAT, `127.0.0.1:18080 → guest 8080`
**Controller:** Ansible 9.2.0 / ansible-core 2.16.3, running on the VM itself (why: §2.0)
**Date:** 2026-09-26

---

## 1. What the lab requires

| # | Requirement | Where in this report |
|---|-------------|----------------------|
| T1.1 | `ansible/` layout: inventory, playbook, files (binary + seed), template | §2.1 |
| T1.2 | System user `quicknotes` (no login shell, no interactive home) | §2.1 (playbook), §2.3 |
| T1.3 | Data dir `/var/lib/quicknotes`, `quicknotes:quicknotes`, `0750` | §2.1, §2.3 |
| T1.4 | Binary → `/usr/local/bin/quicknotes`, mode `0755` | §2.1, §2.3 |
| T1.5 | `seed.json` shipped, `quicknotes:quicknotes`, `0640`, `SEED_PATH` points at it | §2.1, §2.4 |
| T1.6 | systemd unit rendered from Jinja2 template, values = playbook variables | §2.1, §2.3 |
| T1.7 | Reload systemd, enable, start | §2.1, §2.3 |
| T1.8 | Handler restarts on binary OR unit change — and only then | §2.1, §3.2 |
| T1.9 | Inventory targets the VM via IP + port + SSH key Vagrant uses | §2.2 |
| T1.a–d | Design questions a–d | §2.5 |
| T2.1 | Re-run → `changed=0` | §3.1 |
| T2.2 | One-variable tweak → only template `changed=1` + handler fired | §3.2 |
| T2.3 | `--check --diff` preview captured | §3.3 |
| T2.e–g | Design questions e–g | §3.4 |
| B | `ansible-pull` loop: local inventory + service + timer in the PR, timer active, convergence proven | §4 |
| B.h–i | Design questions h–i | §4.3 |

---

## 0. Setup — branch + VM definition

Fork synced from upstream via the GitHub "Sync fork" button, then:

```
C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git checkout main
C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git pull
C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git checkout -b feature/lab7

C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git branch
* feature/lab7
  main
  ...
```

One consequence of the branch switch: the Lab 5 VM files — the `Vagrantfile` and its provisioner script `scripts/install-go.sh` — are tracked files that exist **only on `feature/lab5`**, so checking out `main` → `feature/lab7` removes them from the working tree. `vagrant up` then fails its config validation — first *"A Vagrant environment or target machine is required"*, and after restoring the Vagrantfile: *"`path` for shell provisioner does not exist ... scripts/install-go.sh"* — Vagrant validates the whole config on **every** `up`, even when it will not re-provision an existing machine. The untracked `.vagrant/` state folder and the VirtualBox VM itself are not touched by git, so the halted Lab 5 VM is intact. Both files are restored from `feature/lab5` and deliberately kept **untracked** (`app/` needs nothing — the course ships it on `main`): they already live in the Lab 5 history and are not duplicated in this PR:

```
C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git checkout feature/lab5 -- Vagrantfile scripts/install-go.sh
C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git restore --staged Vagrantfile scripts/install-go.sh

C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git status --short
?? Vagrantfile
?? scripts/
```

`??` = untracked: present on disk for `vagrant up` (config validation + the `/vagrant` synced folder the playbook runs from, §2.3), but outside the PR (Appendix A).

The first `vagrant up` after the restore surfaced the real cost of the lost `.vagrant/` folder — machine identity is *state*, and git does not track state:

```text
A VirtualBox machine with the name 'quicknotes-lab5' already exists.
```

The VM itself was alive in VirtualBox, but Vagrant's id file (`.vagrant/machines/default/virtualbox/id`) was gone with the rest of `.vagrant/`, so Vagrant tried to import a fresh box and collided with the surviving machine's name.

**Attempt A — adoption.** Point Vagrant's id file at the existing machine's VirtualBox UUID:

```
C:\Users\Inno\OneDrive\Documents\DevOps-Intro>"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list vms
"ubuntu-24.04-amd64_1790419898351_67217" {f63fb830-46c2-4597-8712-190fa3d329f1}
"quicknotes-lab5" {c341f1d8-78aa-4193-9872-cf46af168dc9}
```

`echo {uuid}>.vagrant\machines\default\virtualbox\id` — braces included, no space before `>` (a trailing space corrupts the id). `vagrant up` then finds the machine by id — no box import — but the recovery stalls one step further: the SSH keypair lived in the same lost `.vagrant/` folder, and the VM's `authorized_keys` only trusts the *old* private key, which no longer exists. `vagrant ssh` and provisioning SSH both died with `Permission denied (publickey)` — six attempts, six identical failures. The only remaining in-place fix was VirtualBox GUI console surgery: booting the VM's display and typing key repairs by hand into a console with no clipboard. **Rejected as a dead end** — the time cost outweighed the machine.

**Attempt B — clean rebuild** (cattle, not pet): the old machine was renamed out of the way to free the name, and a fresh `vagrant up` imported a new box with a fresh keypair. The provisioner then hit a transient `curl` failure downloading Go from `dl.google.com` inside `scripts/install-go.sh`; one `vagrant provision` re-run later it completed — the script is idempotent, it skips what already exists.

The `list vms` paste above is the aftermath, read literally: the second line, `"quicknotes-lab5" {c341f1d8-…}`, is the live rebuilt machine every run in this report targets. The first line is the orphan left by the identity fight — a machine VirtualBox named itself (`ubuntu-24.04-amd64_<epoch>_<rand>`), referenced by nothing. That is textbook pet-VM litter; `VBoxManage unregistervm {f63fb830-…} --delete` reclaims the disk once the lab is graded.

The lesson is the reason this lab exists: a pet VM demands manual surgery after losing its state folder; a cattle VM is re-created from code in one command. Everything Lab 7 does assumes exactly that stance — the playbook must be able to build the service on an empty machine (§2.3 proves it did, twice: the original run and the §2.3 rebuild drill).

---

## 2. Task 1 — Idempotent deploy to the Lab 5 VM

### 2.0 One architectural note first: where the Ansible controller runs

Ansible is a Linux control-plane tool — it does not install on Windows natively, and a WSL controller would have to reach the VM's `127.0.0.1:2222` across the WSL→Windows network boundary. So the controller runs **on the Lab 5 VM itself**, in the `/vagrant` synced folder, and the inventory targets the VM over **loopback SSH** with the exact Vagrant-generated key:

- `vagrant ssh-config` on the host prints `HostName 127.0.0.1`, `Port 2222`, `User vagrant`, `IdentityFile ...\.vagrant\machines\default\virtualbox\private_key` (pasted below).
- Inside the VM that same key is reachable through the synced folder (`/vagrant/.vagrant/machines/default/virtualbox/private_key`) and sshd listens directly on `127.0.0.1:22` — same IP, same user, same key; the 2222 hop is only needed when connecting from the host.
- One catch, found by the first playbook run: a VirtualBox shared folder is a `vboxsf` mount where **every file shows mode `0777` and `chmod` has no effect** (permissions are enforced by the mount options, not stored in a filesystem). The OpenSSH client refuses private keys that others can read — `Permissions 0777 ... are too open. This private key will be ignored.` — so Ansible cannot authenticate with the key directly through `/vagrant`. The fix is a one-time bootstrap on the VM: copy the key into the VM's native filesystem (`~/.ssh/lab7_key`, mode `0600`) and point the inventory at that copy (§2.3). `vagrant ssh` never hits this because it uses the host-side copy of the key, outside any shared folder.
- The playbook uses only `user`, `file`, `copy`, `template`, `systemd` + `become: true` (passwordless sudo for `vagrant`), so it behaves identically under both inventories: `inventory.ini` (SSH, Task 1/2) and `inventory-local.ini` (`ansible_connection=local`, bonus pull mode).

```
C:\Users\Inno\OneDrive\Documents\DevOps-Intro>vagrant ssh-config
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile C:/Users/Inno/OneDrive/Documents/DevOps-Intro/.vagrant/machines/default/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
  PubkeyAcceptedKeyTypes +ssh-rsa
  HostKeyAlgorithms +ssh-rsa
```

`HostName 127.0.0.1` + `Port 2222` + `IdentityFile ...private_key` — exactly the three values the inventory pins (port differs on purpose: 2222 is the host-side NAT forward, inside the VM sshd answers on plain 22).

### 2.1 The files (layout in the fork)

```
ansible/
├── inventory.ini                  -> targets the VM over SSH (loopback + vagrant key)
├── inventory-local.ini            -> pull mode: VM reconciles itself (connection=local)
├── playbook.yaml                  -> the single play for both connection modes
├── files/
│   ├── quicknotes                 -> static Linux binary, cross-compiled on the host
│   └── seed.json                  -> copy of app/seed.json, shipped to the VM
└── templates/
    ├── quicknotes.service.j2      -> systemd unit, all values are playbook variables
    ├── ansible-pull.service.j2    -> bonus: oneshot pull unit
    └── ansible-pull.timer.j2      -> bonus: 5-minute GitOps timer
```

**`ansible/inventory.ini`** — IP + port + SSH key the Vagrant machine uses (host-side values come from `vagrant ssh-config`; from inside the VM sshd is on 22, and the key is the `0600` copy `~/.ssh/lab7_key` — see the `vboxsf` note above and §2.3):

```ini
[quicknotes]
vm ansible_host=127.0.0.1 ansible_port=22 ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/lab7_key ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

**`ansible/inventory-local.ini`** — pull mode (B.2 #2): the VM reconciling itself:

```ini
[quicknotes]
127.0.0.1 ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

**`ansible/playbook.yaml`** — one play; the seven required steps in order, plus the guarded bonus block (`quicknotes_pull_enabled: false` until §4 so it cannot interfere with the Task 2 evidence):

```yaml
- name: Deploy QuickNotes as a systemd service
  hosts: quicknotes
  become: true
  gather_facts: false          # no task below references any ansible_facts (answer d)

  vars:
    # --- Task 1 / Task 2 knobs: edit these to drive the demos ---
    quicknotes_addr: ":8080"            # Task 2 demo: ":8080" -> ":9090" -> back
    quicknotes_restart_sec: "5"         # Task 2 demo: --check --diff target (5 -> 3)
    quicknotes_binary: /usr/local/bin/quicknotes
    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_data_file: /var/lib/quicknotes/notes.json
    quicknotes_seed_file: /var/lib/quicknotes/seed.json

    # --- Bonus: ansible-pull GitOps loop (arm it when you get to the bonus) ---
    quicknotes_pull_enabled: false
    quicknotes_pull_repo: https://github.com/NikolayTaran/DevOps-Intro.git
    quicknotes_pull_branch: feature/lab7

  tasks:
    - name: Create system user quicknotes (no login shell, no home dir)
      ansible.builtin.user:
        name: quicknotes
        system: true
        shell: /usr/sbin/nologin
        home: "{{ quicknotes_data_dir }}"
        create_home: false

    - name: Ensure data directory exists
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: quicknotes
        group: quicknotes
        mode: "0750"

    - name: Install QuickNotes binary
      ansible.builtin.copy:
        src: quicknotes                 # ansible/files/quicknotes
        dest: "{{ quicknotes_binary }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart quicknotes        # fires ONLY when the binary changed

    - name: Ship seed.json
      ansible.builtin.copy:
        src: seed.json                  # ansible/files/seed.json (copy of app/seed.json)
        dest: "{{ quicknotes_seed_file }}"
        owner: quicknotes
        group: quicknotes
        mode: "0640"
      # no notify: the app reads the seed only when DATA_PATH does not exist yet

    - name: Render systemd unit from template
      ansible.builtin.template:
        src: quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify:
        - Reload systemd
        - Restart quicknotes            # fires ONLY when the unit changed

    - name: Enable and start QuickNotes
      ansible.builtin.systemd:
        name: quicknotes
        enabled: true
        state: started

    # --- Bonus: ansible-pull GitOps loop (keep false until Task 2 is done) ---

    - name: Install Ansible and Git for the pull loop
      ansible.builtin.apt:
        name: [ansible, git]
        state: present
        update_cache: true
        cache_valid_time: 3600
      when: quicknotes_pull_enabled | bool

    - name: Render ansible-pull service unit
      ansible.builtin.template:
        src: ansible-pull.service.j2
        dest: /etc/systemd/system/ansible-pull.service
        owner: root
        group: root
        mode: "0644"
      when: quicknotes_pull_enabled | bool
      notify: Reload systemd

    - name: Render ansible-pull timer unit
      ansible.builtin.template:
        src: ansible-pull.timer.j2
        dest: /etc/systemd/system/ansible-pull.timer
        owner: root
        group: root
        mode: "0644"
      when: quicknotes_pull_enabled | bool
      notify: Reload systemd

    - name: Enable and start the ansible-pull timer
      ansible.builtin.systemd:
        name: ansible-pull.timer
        enabled: true
        state: started
        daemon_reload: true
      when: quicknotes_pull_enabled | bool

  handlers:
    - name: Reload systemd
      ansible.builtin.systemd:
        daemon_reload: true

    - name: Restart quicknotes
      ansible.builtin.systemd:
        name: quicknotes
        state: restarted
        enabled: true
```

**`ansible/templates/quicknotes.service.j2`** — every value that the lab lets change is a playbook variable:

```jinja
[Unit]
Description=QuickNotes service (deployed by Ansible, Lab 7)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=quicknotes
Group=quicknotes
WorkingDirectory={{ quicknotes_data_dir }}
Environment=ADDR={{ quicknotes_addr }}
Environment=DATA_PATH={{ quicknotes_data_file }}
Environment=SEED_PATH={{ quicknotes_seed_file }}
ExecStart={{ quicknotes_binary }}
Restart=on-failure
RestartSec={{ quicknotes_restart_sec }}

[Install]
WantedBy=multi-user.target
```

It satisfies 1.4: starts after `network-online.target`, `Restart=on-failure` with a short `RestartSec` backoff, runs as `quicknotes`, sets `ADDR`/`DATA_PATH`/`SEED_PATH` from playbook variables, `WorkingDirectory` = the data dir.

**`ansible/templates/ansible-pull.service.j2`** and **`ansible/templates/ansible-pull.timer.j2`** (bonus artifacts, B.5):

```jinja
# ansible-pull.service.j2
[Unit]
Description=ansible-pull: converge QuickNotes from Git ({{ quicknotes_pull_branch }})
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ansible-pull -U {{ quicknotes_pull_repo }} -C {{ quicknotes_pull_branch }} -i ansible/inventory-local.ini ansible/playbook.yaml
```

```jinja
# ansible-pull.timer.j2
[Unit]
Description=Run ansible-pull every 5 minutes (GitOps loop, Lab 7 bonus)

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

### 2.2 Pre-flight: binary, seed, VM state

**Static Linux binary** — cross-compiled on the host with the same flags as the Lab 6 image (`-trimpath`, `-ldflags='-s -w'`, `CGO_ENABLED=0`), `GOOS=linux`:

```cmd
cd C:\Users\Inno\OneDrive\Documents\DevOps-Intro\app
set "CGO_ENABLED=0"
set "GOOS=linux"
set "GOARCH=amd64"
go build -trimpath -ldflags="-s -w" -o ..\ansible\files\quicknotes .
set "GOOS="
set "GOARCH="
set "CGO_ENABLED="
dir ..\ansible\files\quicknotes
```

```
C:\Users\Inno\OneDrive\Documents\DevOps-Intro>dir ansible\files
 Том в устройстве C не имеет метки.
 Серийный номер тома: FE12-148F

 Содержимое папки C:\Users\Inno\OneDrive\Documents\DevOps-Intro\ansible\files

26.09.2026  13:29    <DIR>          .
26.09.2026  13:26    <DIR>          ..
26.09.2026  17:29         6 647 968 quicknotes
10.09.2026  12:29               782 seed.json
               2 файлов      6 648 750 байт
               2 папок  61 256 654 848 байт свободно
```

**Seed** — copy of `app/seed.json` (must ship, otherwise `/notes` returns `[]` — the app silently starts with an empty store when `SEED_PATH` doesn't exist):

```cmd
cd C:\Users\Inno\OneDrive\Documents\DevOps-Intro
copy app\seed.json ansible\files\seed.json
```

**VM** — Lab 5 VM is in `halt` (with the `Vagrantfile` restored in §0 in place); bring it up and capture the SSH facts:

```cmd
cd C:\Users\Inno\OneDrive\Documents\DevOps-Intro
vagrant up
vagrant ssh-config
```

**Controller + leftovers** — install Ansible on the VM and make sure nothing from Lab 5 still occupies port 8080 or owns a `quicknotes` unit (this is a config-management migration: whatever exists gets inspected, then converged/removed so Ansible owns the service):

```bash
vagrant ssh
sudo apt-get update && sudo apt-get install -y ansible git
ansible --version
sudo ss -ltnp | grep :8080 || echo "port 8080 free"
systemctl list-units --all | grep -i quick || echo "no quicknotes units yet"
ls -la /var/lib/quicknotes 2>/dev/null || echo "no data dir yet"
```

```
vagrant@quicknotes-lab5:~$ ansible --version
ansible [core 2.16.3]
  config file = None
  configured module search path = ['/home/vagrant/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/dist-packages/ansible
  ansible collection location = /home/vagrant/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible
  python version = 3.12.3 (main, Aug 14 2025, 17:47:21) [GCC 13.3.0] (/usr/bin/python3)
  jinja version = 3.1.2
  libyaml = True
vagrant@quicknotes-lab5:~$ sudo ss -ltnp | grep :8080 || echo "port 8080 free"
port 8080 free
vagrant@quicknotes-lab5:~$ systemctl list-units --all | grep -i quick || echo "no quicknotes units yet"
no quicknotes units yet
vagrant@quicknotes-lab5:~$ ls -la /var/lib/quicknotes 2>/dev/null || echo "no data dir yet"
no data dir yet
```

Ubuntu 24.04 ships Ansible **9.2.0** (core **2.16.3**) — a notch below the 10.x the spec names for a host install, but this is the distro package inside the VM, and it is deliberately the same package the bonus's `ansible-pull` will use, so the controller and the pull agent cannot diverge. Pre-flight is all green: port 8080 free (nothing left over from Lab 5), no `quicknotes` units, no data dir — Ansible will own every piece of the target state from scratch.

### 2.3 Key bootstrap, dry-run, then the real run

The first `--check` failed before touching any state — exactly the `vboxsf` trap from §2.0. The SSH client on the VM refused the inventory's key because the synced folder forces mode `0777` on every file (`chmod` there is a no-op), so the play died as UNREACHABLE with `Permission denied (publickey,password)` (truncated):

```
TASK [Create system user quicknotes (no login shell, no home dir)]
fatal: [vm]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: ...
Permissions 0777 for '/vagrant/.vagrant/machines/default/virtualbox/private_key' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key \"/vagrant/.vagrant/machines/default/virtualbox/private_key\": bad permissions
vagrant@127.0.0.1: Permission denied (publickey,password)."}

PLAY RECAP **************************************************************************************************************************************************************
vm                         : ok=0    changed=0    unreachable=1    failed=0    skipped=0    rescued=0    ignored=0
```

Nothing was deployed (`ok=0`), and the key material was never wrong — only its enforced-by-the-mount mode was. The fix is a one-time bootstrap: copy the key out of the shared folder into the VM's native filesystem, lock it to `0600`, and point the inventory at the copy (the `sed` rewrites `ansible/inventory.ini` in place — the same file the host repo will commit):

```bash
mkdir -p ~/.ssh
cp /vagrant/.vagrant/machines/default/virtualbox/private_key ~/.ssh/lab7_key
chmod 600 ~/.ssh/lab7_key
ls -l /home/vagrant/.ssh/lab7_key

sed -i 's|ansible_ssh_private_key_file=/vagrant/.vagrant/machines/default/virtualbox/private_key|ansible_ssh_private_key_file=/home/vagrant/.ssh/lab7_key|' ansible/inventory.ini
grep -o 'ansible_ssh_private_key_file=[^ ]*' ansible/inventory.ini
```

```
vagrant@quicknotes-lab5:/vagrant$ ls -l /home/vagrant/.ssh/lab7_key
-rw------- 1 vagrant vagrant 400 Sep 26 14:50 /home/vagrant/.ssh/lab7_key
vagrant@quicknotes-lab5:/vagrant$ grep -o 'ansible_ssh_private_key_file=[^ ]*' ansible/inventory.ini
ansible_ssh_private_key_file=/home/vagrant/.ssh/lab7_key
```

Connectivity proof, then the dry run (no state touched), then the real run:

```bash
cd /vagrant
ansible -i ansible/inventory.ini vm -m ping
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

```
vagrant@quicknotes-lab5:/vagrant$ ansible -i ansible/inventory.ini vm -m ping
vm | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Then the dry run — and check mode earned its keep. The five mutating tasks reported `changed` (would-create), with two `WARNING`s that are pure check-mode artifacts (`failed to look up user quicknotes` — the user task did not actually run, so the `file` task cannot resolve the owner yet; the message literally says "Create user up to this point in real play"). The `systemd` task then FAILED: `Could not find the requested service quicknotes: host`. That is the known check-mode false-negative for `state: started` on a unit that does not exist yet: in check mode the `template` task wrote nothing, so there is no unit file for the systemd module to find, and the module refuses to simulate enable/start of a service it cannot see. Note `skipped=0`: the play aborted at the failed task, so the four bonus tasks below it were never even evaluated. And the state proof — `systemctl status quicknotes` still reports `Unit quicknotes.service could not be found`: check mode touched nothing.

```
vagrant@quicknotes-lab5:/vagrant$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check

PLAY [Deploy QuickNotes as a systemd service] *******************************************************************************************************************

TASK [Create system user quicknotes (no login shell, no home dir)] **********************************************************************************************
changed: [vm]

TASK [Ensure data directory exists] *****************************************************************************************************************************
[WARNING]: failed to look up user quicknotes. Create user up to this point in real play
[WARNING]: failed to look up group quicknotes. Create group up to this point in real play
changed: [vm]

TASK [Install QuickNotes binary] ********************************************************************************************************************************
changed: [vm]

TASK [Ship seed.json] *******************************************************************************************************************************************
changed: [vm]

TASK [Render systemd unit from template] ************************************************************************************************************************
changed: [vm]

TASK [Enable and start QuickNotes] ******************************************************************************************************************************
fatal: [vm]: FAILED! => {"changed": false, "msg": "Could not find the requested service quicknotes: host"}

PLAY RECAP ******************************************************************************************************************************************************
vm                         : ok=5    changed=5    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```

On a real run this cannot happen: the template task writes the unit file *before* the systemd task executes, so the service exists by the time systemd tries to enable it (systemd picks up new unit files from disk on demand).

First real run — PLAY RECAP with tasks `changed` (+ the two `RUNNING HANDLER` lines): the terminal buffer of the original run was lost in the VM migration (§0), so it was **reproduced the cattle way** — a controlled teardown drill that wipes everything the playbook owns and lets the playbook rebuild it. This is not a re-enactment: it is exactly what a fresh VM would see, and the strongest possible statement that `ansible-playbook` alone builds the service from zero.

```bash
sudo systemctl disable --now quicknotes
sudo rm -f /etc/systemd/system/quicknotes.service /usr/local/bin/quicknotes
sudo rm -rf /var/lib/quicknotes
sudo userdel quicknotes
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

```
PLAY [Deploy QuickNotes as a systemd service] **************************************************************************************************

TASK [Create system user quicknotes (no login shell, no home dir)] *****************************************************************************
changed: [vm]

TASK [Ensure data directory exists] ************************************************************************************************************
changed: [vm]

TASK [Install QuickNotes binary] ***************************************************************************************************************
changed: [vm]

TASK [Ship seed.json] **************************************************************************************************************************
changed: [vm]

TASK [Render systemd unit from template] *******************************************************************************************************
changed: [vm]

TASK [Enable and start QuickNotes] *************************************************************************************************************
changed: [vm]

TASK [Install Ansible and Git for the pull loop] ***********************************************************************************************
skipping: [vm]

TASK [Render ansible-pull service unit] ********************************************************************************************************
skipping: [vm]

TASK [Render ansible-pull timer unit] **********************************************************************************************************
skipping: [vm]

TASK [Enable and start the ansible-pull timer] *************************************************************************************************
skipping: [vm]

RUNNING HANDLER [Reload systemd] ***************************************************************************************************************
ok: [vm]

RUNNING HANDLER [Restart quicknotes] ***********************************************************************************************************
changed: [vm]

PLAY RECAP *************************************************************************************************************************************
vm                         : ok=8    changed=7    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0
```

All six mutating tasks `changed` (user, dir, binary, seed, unit, enable+start), both handlers ran — RECAP `ok=8 changed=7 failed=0 skipped=4`. Acceptance check straight after:

```
vagrant@quicknotes-lab5:/vagrant$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

Zero manual repair steps between `userdel` and a healthy service: seed re-shipped, notes re-seeded (the same 4), unit re-rendered, service re-enabled. That is the cattle property this lab is built around — and the exact run a fresh VM (§0) or the §4 pull loop sees.

Service state + the deployed unit:

```bash
systemctl status quicknotes --no-pager | head -5
cat /etc/systemd/system/quicknotes.service
```

```
vagrant@quicknotes-lab5:/vagrant$ systemctl status quicknotes --no-pager | head -5
● quicknotes.service - QuickNotes service (deployed by Ansible, Lab 7)
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; preset: enabled)
     Active: active (running) since Sat 2026-09-26 15:02:30 UTC; 30min ago
   Main PID: 9676 (quicknotes)
      Tasks: 7 (limit: 1056)
```

`active (running)`, unit `enabled` (survives reboot), started by the playbook — the real run did its job. The rendered unit:

```
vagrant@quicknotes-lab5:/vagrant$ cat /etc/systemd/system/quicknotes.service
[Unit]
Description=QuickNotes service (deployed by Ansible, Lab 7)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=quicknotes
Group=quicknotes
WorkingDirectory=/var/lib/quicknotes
Environment=ADDR=:8080
Environment=DATA_PATH=/var/lib/quicknotes/notes.json
Environment=SEED_PATH=/var/lib/quicknotes/seed.json
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Every value the lab required to be playbook-variable-driven is visible in the rendered unit: `User=quicknotes` (system user, no login shell), `Environment=ADDR=:8080` (listen address), `DATA_PATH`/`SEED_PATH` (data dir + shipped seed), `Restart=on-failure` with `RestartSec=5`. The template in the repo is the only place these live — §3.2/§3.3 change them via playbook variables, not by editing the unit on disk.

### 2.4 Service reachable + seed served

From the host (via the Vagrant port forward `18080 -> 8080`) — with one very Windows detour: bare `curl.exe` refused to even launch (*"Невозможно запустить это приложение на вашем ПК"*). `where curl.exe` solved it: a stray, broken `curl.exe` was sitting **in the repo folder itself**, and cmd searches the **current directory before PATH** — the broken local copy shadowed the system one. Invoked by full path, everything works; the stray file was deleted right after (also a hygiene point: `git status --short` showed it as `?? curl.exe` — one blind `git add .` would have shipped it in the PR):

```cmd
C:\Users\Inno\OneDrive\Documents\DevOps-Intro>where curl.exe
C:\Users\Inno\OneDrive\Documents\DevOps-Intro\curl.exe
C:\Windows\System32\curl.exe

C:\Users\Inno\OneDrive\Documents\DevOps-Intro>C:\Windows\System32\curl.exe -V
curl 8.21.0 (Windows) libcurl/8.21.0 Schannel zlib/1.3.2 WinIDN WinLDAP

C:\Users\Inno\OneDrive\Documents\DevOps-Intro>C:\Windows\System32\curl.exe http://localhost:18080/health
{"notes":4,"status":"ok"}

C:\Users\Inno\OneDrive\Documents\DevOps-Intro>C:\Windows\System32\curl.exe http://localhost:18080/notes
[{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"}]
```

4 notes, not `[]` — proves `seed.json` was shipped to `/var/lib/quicknotes/seed.json` and `SEED_PATH` points at it. (The order of the notes changes between calls — Go map iteration randomizes the app's output, same as in Lab 5.)

### 2.5 Design questions (Task 1)

**a) `command:` vs the dedicated modules — which is idempotent, and why does it matter?**

`command:`/`shell:` are *execution* — they run their string on every single play, have no idea what state exists, and report `changed` every time (unless you bolt on `creates:`/`changed_when:` hacks). The dedicated modules are *declarative*: they encode the desired state (`user: name=quicknotes system=true shell=nologin`, `file: mode=0750`, `copy: content+mode+owner`, `systemd: enabled+started`), diff it against the live system, and act only on the delta — otherwise report `ok`. In this playbook every task is a module: the `user` module checks `/etc/passwd` attributes, `file` checks path/type/owner/mode, `copy` compares a content checksum plus attributes, `template` compares the *rendered* output, `systemd` checks the unit's enabled/active state. Why it matters: idempotency turns a playbook from "a script that re-runs" into "a convergence loop" — safe to run nightly, safe in CI, honest `changed` counters, and handlers (b) fire only on real drift instead of on every run.

**b) `notify:` and handlers — when does a handler fire, when not, and why is that the right default?**

A handler fires at the end of the play — exactly once per host, even if notified by five changed tasks — but **only if at least one task that notifies it reported `changed`** in that run. It does not fire when every notifying task reported `ok` (nothing drifted), and it does not fire if the play failed before reaching the handler phase (unless `force_handlers` is set). In this playbook `Restart quicknotes` is notified by exactly two tasks — the binary `copy` and the unit `template` — so a seed-only change or a no-op run never restarts the service. That is the right default because a restart is the one action here with a cost (brief downtime): the notify/changed contract means "restart only when what runs actually changed", and grouping guarantees one restart even when both binary and unit change in the same run.

**c) Variable precedence — top 3 places to put a variable for this lab, and why.**

1. **Play `vars:`** — what I used. One play, one source of truth, the knobs sit next to the tasks they drive; changing `quicknotes_addr` is a one-line diff in the same file the reviewer is already reading. Right scope for lab-sized, play-local configuration.
2. **Inventory-level (`group_vars/` or host vars in the inventory)** — the place for *per-environment/per-host* values (`ansible_port`, addresses, sizes) when the same playbook is reused against dev/stage/prod inventories. The connection variables already live exactly there, in `inventory.ini`.
3. **`-e` extra vars (CLI)** — highest precedence in Ansible's ~22-level list; the place for CI/automation overrides that must beat everything else without editing files (`ansible-playbook ... -e quicknotes_addr=:9090` is how a pipeline could inject a value).
Things I deliberately did *not* use: `set_fact` (runtime-computed, hides the source) and role `defaults/` (we have no role; `defaults` are the lowest-precedence fallback for reusable roles, not for a single play).

**d) `gather_facts: true` is the default — do you need it here? What does turning it off save?**

No task in this playbook references a single fact: no `ansible_os_family` branching (we know the box), no IP/mac math, no package-manager detection — so the play sets `gather_facts: false` and the run skips the implicit `setup` round-trip entirely. What it saves: per host, one Python round-trip that collects hundreds of facts — sub-second on this VM (roughly 0.5–1 s of the run), but on a fleet of hundreds/thousands of nodes that is minutes of pure overhead before the first real task. The cost of turning it off: the moment a task needs a fact (`when: ansible_os_family == ...`), you re-enable gathering or add an explicit `setup:` task — the recap makes it obvious either way. First-run recap below has no `Gathering Facts` task, which is the visible proof.

---

## 3. Task 2 — Prove idempotency + selective re-run

### 3.1 Re-run = zero changes

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

```
vagrant@quicknotes-lab5:/vagrant$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes as a systemd service] **************************************************************************************************

TASK [Create system user quicknotes (no login shell, no home dir)] *****************************************************************************
ok: [vm]

TASK [Ensure data directory exists] ************************************************************************************************************
ok: [vm]

TASK [Install QuickNotes binary] ***************************************************************************************************************
ok: [vm]

TASK [Ship seed.json] **************************************************************************************************************************
ok: [vm]

TASK [Render systemd unit from template] *******************************************************************************************************
ok: [vm]

TASK [Enable and start QuickNotes] *************************************************************************************************************
ok: [vm]

TASK [Install Ansible and Git for the pull loop] ***********************************************************************************************
skipping: [vm]

TASK [Render ansible-pull service unit] ********************************************************************************************************
skipping: [vm]

TASK [Render ansible-pull timer unit] **********************************************************************************************************
skipping: [vm]

TASK [Enable and start the ansible-pull timer] *************************************************************************************************
skipping: [vm]

PLAY RECAP *************************************************************************************************************************************
vm                         : ok=6    changed=0    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0
```

`changed=0`: every module re-diffed desired vs live and found no delta (see answer e). Contrast with the first real run: `user`, `file`, both `copy`s, `template` and `systemd` all reported `changed` then — now the same six tasks are `ok`. The service was not restarted either: no `RUNNING HANDLER` lines, because nothing notified the handlers. The four bonus tasks show `skipping` — their `when: quicknotes_pull_enabled | bool` guard is still `false` (armed in §4).

### 3.2 One-variable tweak = only the template + handler move

Edit **one** variable in `ansible/playbook.yaml`: `quicknotes_addr: ":8080"` → `":9090"`, then re-run:

```
vagrant@quicknotes-lab5:/vagrant$ sed -i 's/quicknotes_addr: ":8080"/quicknotes_addr: ":9090"/' ansible/playbook.yaml
vagrant@quicknotes-lab5:/vagrant$ grep -n 'quicknotes_addr' ansible/playbook.yaml
20:    quicknotes_addr: ":9090"            # Task 2 demo: ":8080" -> ":9090" -> back
vagrant@quicknotes-lab5:/vagrant$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes as a systemd service] **************************************************************************************************

TASK [Create system user quicknotes (no login shell, no home dir)] *****************************************************************************
ok: [vm]

TASK [Ensure data directory exists] ************************************************************************************************************
ok: [vm]

TASK [Install QuickNotes binary] ***************************************************************************************************************
ok: [vm]

TASK [Ship seed.json] **************************************************************************************************************************
ok: [vm]

TASK [Render systemd unit from template] *******************************************************************************************************
changed: [vm]

TASK [Enable and start QuickNotes] *************************************************************************************************************
ok: [vm]

TASK [Install Ansible and Git for the pull loop] ***********************************************************************************************
skipping: [vm]

TASK [Render ansible-pull service unit] ********************************************************************************************************
skipping: [vm]

TASK [Render ansible-pull timer unit] **********************************************************************************************************
skipping: [vm]

TASK [Enable and start the ansible-pull timer] *************************************************************************************************
skipping: [vm]

RUNNING HANDLER [Reload systemd] ***************************************************************************************************************
ok: [vm]

RUNNING HANDLER [Restart quicknotes] ***********************************************************************************************************
changed: [vm]

PLAY RECAP *************************************************************************************************************************************
vm                         : ok=8    changed=2    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0
```

Exactly the claimed selectivity, task by task: one line changed (`Render systemd unit from template` — the new `ADDR=:9090` rendered a different text, checksum mismatch), the two notified handlers ran (`RUNNING HANDLER`), and the five other mutating tasks stayed `ok` — the `user`, both `copy`s and `systemd` did not even flicker, even though the *service restarted underneath them*. RECAP `ok=8 changed=2` (template + restart handler; `daemon_reload` alone reports `ok`, so `Reload systemd` does not inflate `changed`). This is T1.8 proven in both directions: the handler fires when the unit changes — and only then.

Confirm the service actually moved, from inside the VM:

```bash
systemctl show quicknotes -p Environment --no-pager
curl -s http://localhost:9090/health
```

```
vagrant@quicknotes-lab5:/vagrant$ systemctl show quicknotes -p Environment
Environment=ADDR=:9090 DATA_PATH=/var/lib/quicknotes/notes.json SEED_PATH=/var/lib/quicknotes/seed.json
vagrant@quicknotes-lab5:/vagrant$ curl -s http://localhost:9090/health
{"notes":4,"status":"ok"}
```

`ADDR=:9090` is live in the running unit and the service answers on the new port with the same data (the restart re-read the same `notes.json` — note count unchanged, seed untouched because `DATA_PATH` exists).

Note: after this run the host's `curl http://localhost:18080/...` would *fail* — the Vagrant forward maps 18080→8080 and the service now listens on :9090. That is the expected consequence of the demo, not an outage. Revert the variable to `":8080"`, re-run — the recap again shows only the template + handler (the same mechanism proving the revert), and the port-forwarded curl works again:

```
vagrant@quicknotes-lab5:/vagrant$ sed -i 's/quicknotes_addr: ":9090"/quicknotes_addr: ":8080"/' ansible/playbook.yaml
vagrant@quicknotes-lab5:/vagrant$ grep -n 'quicknotes_addr' ansible/playbook.yaml
20:    quicknotes_addr: ":8080"            # Task 2 demo: ":8080" -> ":9090" -> back
vagrant@quicknotes-lab5:/vagrant$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

PLAY [Deploy QuickNotes as a systemd service] **************************************************************************************************

TASK [Create system user quicknotes (no login shell, no home dir)] *****************************************************************************
ok: [vm]

TASK [Ensure data directory exists] ************************************************************************************************************
ok: [vm]

TASK [Install QuickNotes binary] ***************************************************************************************************************
ok: [vm]

TASK [Ship seed.json] **************************************************************************************************************************
ok: [vm]

TASK [Render systemd unit from template] *******************************************************************************************************
changed: [vm]

TASK [Enable and start QuickNotes] *************************************************************************************************************
ok: [vm]

TASK [Install Ansible and Git for the pull loop] ***********************************************************************************************
skipping: [vm]

TASK [Render ansible-pull service unit] ********************************************************************************************************
skipping: [vm]

TASK [Render ansible-pull timer unit] **********************************************************************************************************
skipping: [vm]

TASK [Enable and start the ansible-pull timer] *************************************************************************************************
skipping: [vm]

RUNNING HANDLER [Reload systemd] ***************************************************************************************************************
ok: [vm]

RUNNING HANDLER [Restart quicknotes] ***********************************************************************************************************
changed: [vm]

PLAY RECAP *************************************************************************************************************************************
vm                         : ok=8    changed=2    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0
```

The revert moved through the exact same two-task pipeline (template re-rendered → handlers) — one mechanism, one code path, no special "undo" logic anywhere. And from the host, through the Vagrant port-forward:

```
C:\Users\Inno\OneDrive\Documents\DevOps-Intro>C:\Windows\System32\curl.exe http://localhost:18080/health
{"notes":4,"status":"ok"}
```

The service is back on `:8080`, the `18080 -> 8080` forward works again. Full circle: `changed=0` (nothing to do) → `changed=2` (one variable, template+handlers) → `changed=2` (same variable, back) — three runs, zero manual touching of the unit file or the service.

### 3.3 `--check --diff` preview

Third change (never applied): `quicknotes_restart_sec: "5"` → `"3"`, then:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff
```

```
vagrant@quicknotes-lab5:/vagrant$ sed -i 's/quicknotes_restart_sec: "5"/quicknotes_restart_sec: "3"/' ansible/playbook.yaml
vagrant@quicknotes-lab5:/vagrant$ grep -n 'quicknotes_restart_sec' ansible/playbook.yaml
21:    quicknotes_restart_sec: "3"         # Task 2 demo: --check --diff target (5 -> 3)
vagrant@quicknotes-lab5:/vagrant$ ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff

PLAY [Deploy QuickNotes as a systemd service] **************************************************************************************************

TASK [Create system user quicknotes (no login shell, no home dir)] *****************************************************************************
ok: [vm]

TASK [Ensure data directory exists] ************************************************************************************************************
ok: [vm]

TASK [Install QuickNotes binary] ***************************************************************************************************************
ok: [vm]

TASK [Ship seed.json] **************************************************************************************************************************
ok: [vm]

TASK [Render systemd unit from template] *******************************************************************************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /home/vagrant/.ansible/tmp/ansible-local-10986v4gre9l8/tmpffqavy7s/quicknotes.service.j2
@@ -13,7 +13,7 @@
 Environment=SEED_PATH=/var/lib/quicknotes/seed.json
 ExecStart=/usr/local/bin/quicknotes
 Restart=on-failure
-RestartSec=5
+RestartSec=3
 
 [Install]
 WantedBy=multi-user.target

changed: [vm]

TASK [Enable and start QuickNotes] *************************************************************************************************************
ok: [vm]

TASK [Install Ansible and Git for the pull loop] ***********************************************************************************************
skipping: [vm]

TASK [Render ansible-pull service unit] ********************************************************************************************************
skipping: [vm]

TASK [Render ansible-pull timer unit] **********************************************************************************************************
skipping: [vm]

TASK [Enable and start the ansible-pull timer] *************************************************************************************************
skipping: [vm]

RUNNING HANDLER [Reload systemd] ***************************************************************************************************************
ok: [vm]

RUNNING HANDLER [Restart quicknotes] ***********************************************************************************************************
changed: [vm]

PLAY RECAP *************************************************************************************************************************************
vm                         : ok=8    changed=2    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0

vagrant@quicknotes-lab5:/vagrant$ sed -i 's/quicknotes_restart_sec: "3"/quicknotes_restart_sec: "5"/' ansible/playbook.yaml
vagrant@quicknotes-lab5:/vagrant$ grep -n 'quicknotes_restart_sec' ansible/playbook.yaml
21:    quicknotes_restart_sec: "5"         # Task 2 demo: --check --diff target (5 -> 3)
```

The payoff: the exact would-be diff, line-by-line — `-RestartSec=5` / `+RestartSec=3`, nothing else. (The `+++ after:` path is Ansible's temp render location — the would-be unit exists only in a tmp dir during the dry run.) A wrong variable name, a dropped `Environment=` line, an accidental overwrite of a neighbor stanza — all of it would be visible here *before* touching the live unit.

One surprise worth owning (my own run-prediction was wrong here too): the handlers **do appear** in check mode as `RUNNING HANDLER` — tasks that report `changed` still notify their handlers, and the handlers execute at the end of the play *in check mode themselves*. So `Restart quicknotes` reports `changed` (a prediction: "would restart") and `Reload systemd` reports `ok` — which is why the RECAP is `ok=8 changed=2`, shape-identical to a real run. The prediction-vs-action distinction is verifiable — nothing on the system actually moved:

```bash
grep RestartSec /etc/systemd/system/quicknotes.service
systemctl show quicknotes -p ActiveEnterTimestamp
```

```
vagrant@quicknotes-lab5:/vagrant$ grep RestartSec /etc/systemd/system/quicknotes.service
RestartSec=5
vagrant@quicknotes-lab5:/vagrant$ systemctl show quicknotes -p ActiveEnterTimestamp
ActiveEnterTimestamp=Sat 2026-09-26 15:57:37 UTC
```

Both proofs hold: `RestartSec=5` is still what's on disk (the diff was never written), and `ActiveEnterTimestamp=15:57:37 UTC` is the restart from the §3.2 revert run — the check run happened after it and did not bump the timestamp, so no restart occurred. Check mode predicted, and touched nothing. The variable was then reverted to `"5"` in the playbook, leaving the repo exactly as it will be committed.

### 3.4 Design questions (Task 2)

**e) Why does the second run report `changed=0`? What does each module actually check?**

Because every module is a state-diff, and the first run left the system exactly in the desired state. Concretely: `user` compares the account's fields (shell, home, system flag) against `/etc/passwd`; `file` compares path, type, owner, group, mode bits; `copy` hashes the source file and compares against the destination's content plus owner/mode; `template` renders the Jinja2 with the *current* variables and compares the rendered result against the file on disk (so a variable change re-renders a different text and the checksum differs → changed); `systemd` asks systemd whether the unit is enabled and active. No delta anywhere → every task reports `ok` → no task reports changed → no handler is notified → nothing runs. `changed=0` is not "the playbook did nothing"; it is "the system already matched the declaration".

**f) `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` instead of `template:` — trace the failure modes.**

(1) *Idempotency gone:* `echo >` rewrites the file on every run, `shell` always reports `changed`, so the `Restart quicknotes` handler fires on **every** run — with the bonus timer, a needless service restart every 5 minutes. (2) *Quoting/injection:* every `$`, `"`, `\`, newline in a variable value now goes through a second shell interpretation layer; a value like `ADDR=:8080 # comment` or a path with spaces silently corrupts the unit. (3) *No attribute control:* owner/group/mode of the written file are whatever umask makes them, not `0644 root:root` — and they will *flip-flop* between runs if mixed with the module version. (4) *`--check --diff` lies:* check mode skips the shell task but still reports `changed`, and shows no diff — the preview workflow of §3.3 becomes impossible. (5) *No drift visibility:* a template gives you a clean unified diff of what changed; an `echo` gives you a black box. This is the "if you reach for `shell:`, stop" guideline in its purest form.

**g) `--check` vs `--check --diff` — what bug does the diff catch that plain check misses?**

Plain `--check` answers *which* tasks would change; `--diff` answers *what exactly would be written*. The classic bug it catches: a template that renders **valid-looking but wrong content** — a typo'd variable name rendering an empty string (`ExecStart=` with no path), a wrong override sneaking in from another var source, an `Environment=` line silently dropped by a bad conditional. Plain `--check` cheerfully says `changed=1`; with `--diff` you see the would-be unit diff and spot that `SEED_PATH` would disappear before it ever hits the service. Secondary catches: unexpected whitespace/ordering churn in config files, and confirmations that a change is *only* the one line you intended. That is why the professional habit is `--check --diff` (both), not `--check`.

---

## 4. Bonus — `ansible-pull` GitOps loop

### 4.1 Arming the loop (the artifacts)

The bonus artifacts are part of the PR as Ansible automation (B.5 recommends it): `ansible/templates/ansible-pull.service.j2`, `ansible/templates/ansible-pull.timer.j2` (both pasted in §2.1) and `ansible/inventory-local.ini` (`127.0.0.1` + `ansible_connection=local` — the VM reconciling itself). They are installed by the same playbook, guarded by `quicknotes_pull_enabled`. Arming it:

1. In `ansible/playbook.yaml` set `quicknotes_pull_enabled: true`
2. Commit + push `feature/lab7` to the fork (the pull loop must be able to clone it)
3. Run the playbook once more locally:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml
```

```
PLAY [Deploy QuickNotes as a systemd service] **************************************************************************************************

TASK [Create system user quicknotes (no login shell, no home dir)] *****************************************************************************
ok: [vm]

TASK [Ensure data directory exists] ************************************************************************************************************
ok: [vm]

TASK [Install QuickNotes binary] ***************************************************************************************************************
ok: [vm]

TASK [Ship seed.json] **************************************************************************************************************************
ok: [vm]

TASK [Render systemd unit from template] *******************************************************************************************************
ok: [vm]

TASK [Enable and start QuickNotes] *************************************************************************************************************
ok: [vm]

TASK [Install Ansible and Git for the pull loop] ***********************************************************************************************
ok: [vm]

TASK [Render ansible-pull service unit] ********************************************************************************************************
changed: [vm]

TASK [Render ansible-pull timer unit] **********************************************************************************************************
changed: [vm]

TASK [Enable and start the ansible-pull timer] *************************************************************************************************
changed: [vm]

RUNNING HANDLER [Reload systemd] ***************************************************************************************************************
ok: [vm]

PLAY RECAP *************************************************************************************************************************************
vm                         : ok=11   changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`skipped=0` — the guard is open: the four pull tasks executed. `apt` reports `ok` (ansible + git already present — distro package, installed on the VM in §2.2), the two pull units render `changed`, and the timer enables and starts (`changed`). The quicknotes service itself was not touched — no notification reached `Restart quicknotes`, because nothing in its notify chain moved. Same playbook, one flipped boolean, four new behaviors.

Timer state:

```bash
systemctl list-timers --all --no-pager | grep -E "ansible-pull|NEXT"
```

```
vagrant@quicknotes-lab5:/vagrant$ systemctl list-timers --all --no-pager | grep -E "ansible-pull|NEXT"
NEXT                            LEFT LAST                              PASSED UNIT                         ACTIVATES
Sat 2026-09-26 17:13:03 UTC 3min 30s Sat 2026-09-26 17:08:03 UTC 1min 29s ago ansible-pull.timer           ansible-pull.service
```

The timer is armed and already cyclic: `LAST 17:08:03` — the first fire happened seconds after the arming run (all of the timer's triggers were in the past, so systemd elapsed it immediately), and `NEXT 17:13:03` is exactly 5 minutes later — `OnUnitActiveSec=5min` doing its job. The loop now runs with nobody touching it.

### 4.2 The loop in action: baseline pull → drift in Git → reconcile

**Baseline — the timer fires with nobody touching anything.** Captured at 17:16 UTC, between fires, by asking only the journal:

```bash
sudo journalctl -u ansible-pull.service --no-pager -n 30
```

```
vagrant@quicknotes-lab5:/vagrant$ sudo journalctl -u ansible-pull.service --no-pager -n 30
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: }
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: [WARNING]: Could not match supplied host pattern, ignoring: quicknotes-lab5
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: PLAY [Deploy QuickNotes as a systemd service] **********************************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: TASK [Create system user quicknotes (no login shell, no home dir)] *************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: ok: [127.0.0.1]
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: TASK [Ensure data directory exists] ********************************************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: ok: [127.0.0.1]
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: TASK [Install QuickNotes binary] ***********************************************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: ok: [127.0.0.1]
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: TASK [Ship seed.json] **********************************************************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: ok: [127.0.0.1]
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: TASK [Render systemd unit from template] ***************************************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: ok: [127.0.0.1]
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: TASK [Enable and start QuickNotes] *********************************************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: ok: [127.0.0.1]
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: TASK [Install Ansible and Git for the pull loop] *******************************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: ok: [127.0.0.1]
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: TASK [Render ansible-pull service unit] ****************************************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: ok: [127.0.0.1]
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: TASK [Render ansible-pull timer unit] ******************************************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: ok: [127.0.0.1]
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: TASK [Enable and start the ansible-pull timer] *********************************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: ok: [127.0.0.1]
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: PLAY RECAP *********************************************************************
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: 127.0.0.1                  : ok=10   changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: Starting Ansible Pull at 2026-09-26 17:13:24
Sep 26 17:13:39 quicknotes-lab5 ansible-pull[13583]: /usr/bin/ansible-pull -U https://github.com/NikolayTaran/DevOps-Intro.git -C feature/lab7 -i ansible/inventory-local.ini ansible/playbook.yaml
Sep 26 17:13:39 quicknotes-lab5 systemd[1]: ansible-pull.service: Deactivated successfully.
Sep 26 17:13:39 quicknotes-lab5 systemd[1]: Finished ansible-pull.service - ansible-pull: converge QuickNotes from Git (feature/lab7).
Sep 26 17:13:39 quicknotes-lab5 systemd[1]: ansible-pull.service: Consumed 12.537s CPU time, 153.0M memory peak, 0B memory swap peak.
vagrant@quicknotes-lab5:/vagrant$
```

One paste, four proofs: (1) the full `ansible-pull` command line is in the log — repo URL, branch `feature/lab7`, local inventory, playbook path; (2) the internal checkout reported `before == after == cc9c33b…`, `changed=false`, `remote_url_changed=false` — the repo is unchanged since the last cycle; (3) the playbook converged with **`ok=10 changed=0`** — the §3.1 idempotency, now running with zero human input; (4) systemd closed the unit cleanly (`Deactivated successfully`, 12.5 s CPU / 153 MB peak — the cost of one pull cycle). The `Could not match supplied host pattern, ignoring: quicknotes-lab5` warning is expected and harmless: `inventory-local.ini` only defines `127.0.0.1`, while the play's host pattern also names the controller-run host; the unmatched pattern part is ignored.

**Now the GitOps demo — change the desired state *in Git only*.** The same tweak §3.3 previewed with `--check --diff`, this time shipped for real, and not by running Ansible — by pushing:

```bash
# in the VM (shared folder):
sed -i 's/quicknotes_restart_sec: "5"/quicknotes_restart_sec: "3"/' ansible/playbook.yaml
grep -n 'quicknotes_restart_sec' ansible/playbook.yaml
exit
# on the host:
git add ansible/playbook.yaml
git commit -s -m "feat(lab7): tighten RestartSec to 3s (pull convergence demo)"
git push
git log -1 --format=%cI
```

```
vagrant@quicknotes-lab5:/vagrant$ sed -i 's/quicknotes_restart_sec: "5"/quicknotes_restart_sec: "3"/' ansible/playbook.yaml
vagrant@quicknotes-lab5:/vagrant$ grep -n 'quicknotes_restart_sec' ansible/playbook.yaml
21:    quicknotes_restart_sec: "3"         # Task 2 demo: --check --diff target (5 -> 3)
vagrant@quicknotes-lab5:/vagrant$ exit
logout

C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git add ansible/playbook.yaml
warning: in the working copy of 'ansible/playbook.yaml', LF will be replaced by CRLF the next time Git touches it

C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git commit -s -m "feat(lab7): tighten RestartSec to 3s (pull convergence demo)"
[feature/lab7 cd094d1] feat(lab7): tighten RestartSec to 3s (pull convergence demo)
 1 file changed, 1 insertion(+), 1 deletion(-)

C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git push
Enumerating objects: 7, done.
Counting objects: 100% (7/7), done.
Delta compression using up to 12 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 637 bytes | 637.00 KiB/s, done.
Total 4 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (3/3), completed with 3 local objects.
To https://github.com/NikolayTaran/DevOps-Intro
   cc9c33b..cd094d1  feature/lab7 -> feature/lab7

C:\Users\Inno\OneDrive\Documents\DevOps-Intro>git log -1 --format=%cI
2026-09-26T20:15:50+03:00
```

Push `cc9c33b..cd094d1` landed at **17:15:50 UTC** (`20:15:50+03:00`) — 35 seconds *after* the 17:13:03 fire had already finished (17:13:39), so the loop has not seen it yet. A journal check at 17:16:30 confirmed exactly that: only the 17:13 run in the log, nothing reconciled yet. The drift, recorded live — Git says 3, the machine still runs 5:

```bash
grep RestartSec /etc/systemd/system/quicknotes.service
systemctl show quicknotes -p ActiveEnterTimestamp
```

```
vagrant@quicknotes-lab5:~$ grep RestartSec /etc/systemd/system/quicknotes.service
RestartSec=5
vagrant@quicknotes-lab5:~$ systemctl show quicknotes -p ActiveEnterTimestamp
ActiveEnterTimestamp=Sat 2026-09-26 16:43:25 UTC
```

Now the loop gets ≤ 5 minutes to notice — nobody runs anything.

**Convergence — the next timer fire picks the push up.** The 17:18:37 fire did the reconcile. State after it, checked a few minutes later:

```bash
grep RestartSec /etc/systemd/system/quicknotes.service
systemctl show quicknotes -p ActiveEnterTimestamp
curl -s localhost:8080/health
```

```
vagrant@quicknotes-lab5:~$ grep RestartSec /etc/systemd/system/quicknotes.service
RestartSec=3
vagrant@quicknotes-lab5:~$ systemctl show quicknotes -p ActiveEnterTimestamp
ActiveEnterTimestamp=Sat 2026-09-26 17:18:57 UTC
vagrant@quicknotes-lab5:~$ curl -s localhost:8080/health
{"notes":4,"status":"ok"}
```

Two numbers close the loop. The unit file now carries `RestartSec=3` — a value that exists **only in Git** (it was `5` on disk at 17:16, and nobody touched the VM since). And `ActiveEnterTimestamp` jumped from `16:43:25` to `17:18:57` — the service was restarted **during the 17:18:37 fire** by the handler, exactly like the §3.2 tweak demo, except this time nobody ran Ansible at all. Health is green, all 4 notes intact.

The converging run itself — journal extract of the 17:18 fire (the `-n` window is too small once module debug lines are on, so slice by time and drop the `python3[...]` module-argv noise):

```bash
sudo journalctl -u ansible-pull.service --no-pager --since "17:17" --until "17:20" | grep -v python3
```

```
vagrant@quicknotes-lab5:~$ sudo journalctl -u ansible-pull.service --no-pager --since "17:17" --until "17:20" | grep -v python3
Sep 26 17:18:37 quicknotes-lab5 systemd[1]: Starting ansible-pull.service - ansible-pull: converge QuickNotes from Git (feature/lab7)...
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: [WARNING]: Could not match supplied host pattern, ignoring: quicknotes-lab5
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: localhost | CHANGED => {
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]:     "after": "cd094d1780c2fe683e1ae6c129f8a8e251a36c6c",
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]:     "before": "cc9c33b75ff6647c72eda01c04bbc02f47065616",
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]:     "changed": true,
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]:     "remote_url_changed": false
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: }
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: [WARNING]: Could not match supplied host pattern, ignoring: quicknotes-lab5
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: PLAY [Deploy QuickNotes as a systemd service] **********************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: TASK [Create system user quicknotes (no login shell, no home dir)] *************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: ok: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: TASK [Ensure data directory exists] ********************************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: ok: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: TASK [Install QuickNotes binary] ***********************************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: ok: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: TASK [Ship seed.json] **********************************************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: ok: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: TASK [Render systemd unit from template] ***************************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: changed: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: TASK [Enable and start QuickNotes] *********************************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: ok: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: TASK [Install Ansible and Git for the pull loop] *******************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: ok: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: TASK [Render ansible-pull service unit] ****************************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: ok: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: TASK [Render ansible-pull timer unit] ******************************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: ok: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: TASK [Enable and start the ansible-pull timer] *********************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: ok: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: RUNNING HANDLER [Reload systemd] ***********************************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: ok: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: RUNNING HANDLER [Restart quicknotes] *******************************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: changed: [127.0.0.1]
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: PLAY RECAP *********************************************************************
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: 127.0.0.1                  : ok=12   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: Starting Ansible Pull at 2026-09-26 17:18:37
Sep 26 17:18:57 quicknotes-lab5 ansible-pull[14314]: /usr/bin/ansible-pull -U https://github.com/NikolayTaran/DevOps-Intro.git -C feature/lab7 -i ansible/inventory-local.ini ansible/playbook.yaml
Sep 26 17:18:57 quicknotes-lab5 systemd[1]: ansible-pull.service: Deactivated successfully.
Sep 26 17:18:57 quicknotes-lab5 systemd[1]: Finished ansible-pull.service - ansible-pull: converge QuickNotes from Git (feature/lab7).
Sep 26 17:18:57 quicknotes-lab5 systemd[1]: ansible-pull.service: Consumed 17.727s CPU time, 153.4M memory peak, 0B memory swap peak.
vagrant@quicknotes-lab5:~$
```

This is the GitOps smoking gun, and its fingerprint is the §3.2 handler demo executed by a timer instead of a human: the checkout went `before cc9c33b → after cd094d1`, `changed: true` — the machine *fetched the push on its own*; the only task that moved was `Render systemd unit from template` (`changed`); the handlers folded in (`Reload systemd` → ok, `Restart quicknotes` → changed); and the recap landed on **`ok=12 changed=2`** — exactly the predicted shape. (The fire landed at 17:18:37 rather than 17:18:03 — systemd coalesces timer expiry by up to `AccuracySec=1min` by default; the 5-minute cadence is intact.)

**Stability — the loop returns to sleep.** Both follow-up fires (17:23:55 and 17:29:11) found nothing to do (`PLAY RECAP ok=10 changed=0`). The 17:29 run — git result + recap (the ten `ok:` task lines are identical to the baseline run above and omitted):

```
Sep 26 17:29:25 quicknotes-lab5 ansible-pull[15768]: localhost | SUCCESS => {
Sep 26 17:29:25 quicknotes-lab5 ansible-pull[15768]:     "after": "cd094d1780c2fe683e1ae6c129f8a8e251a36c6c",
Sep 26 17:29:25 quicknotes-lab5 ansible-pull[15768]:     "before": "cd094d1780c2fe683e1ae6c129f8a8e251a36c6c",
Sep 26 17:29:25 quicknotes-lab5 ansible-pull[15768]:     "changed": false,
Sep 26 17:29:25 quicknotes-lab5 ansible-pull[15768]:     "remote_url_changed": false
Sep 26 17:29:25 quicknotes-lab5 ansible-pull[15768]: }
Sep 26 17:29:25 quicknotes-lab5 ansible-pull[15768]: PLAY RECAP *********************************************************************
Sep 26 17:29:25 quicknotes-lab5 ansible-pull[15768]: 127.0.0.1                  : ok=10   changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Sep 26 17:29:25 quicknotes-lab5 ansible-pull[15768]: Starting Ansible Pull at 2026-09-26 17:29:11
Sep 26 17:29:25 quicknotes-lab5 ansible-pull[15768]: /usr/bin/ansible-pull -U https://github.com/NikolayTaran/DevOps-Intro.git -C feature/lab7 -i ansible/inventory-local.ini ansible/playbook.yaml
Sep 26 17:29:25 quicknotes-lab5 systemd[1]: ansible-pull.service: Deactivated successfully.
Sep 26 17:29:25 quicknotes-lab5 systemd[1]: Finished ansible-pull.service - ansible-pull: converge QuickNotes from Git (feature/lab7).
Sep 26 17:29:25 quicknotes-lab5 systemd[1]: ansible-pull.service: Consumed 11.758s CPU time, 152.8M memory peak, 0B memory swap peak.
```

`before == after == cd094d1…`, `changed=false`, `ok=10 changed=0` — converged and holding. The cadence keeps rolling: `list-timers` at 17:29:55 showed `NEXT 17:34:11 / LAST 17:29:11 (48s ago)`.

Timeline of the convergence:

| Event | Time (UTC) | Evidence |
|-------|-----------|----------|
| Baseline pull, nothing to do (`changed=0`, repo `cc9c33b`) | 17:13:24–17:13:39 | journalctl above |
| Commit `cd094d1` pushed to `feature/lab7` | 17:15:50 | `git log -1 --format=%cI` |
| Pre-convergence drift check (`RestartSec=5` live) | ~17:16 | grep + `systemctl show` above |
| Next `ansible-pull.timer` fire — fetches `cd094d1`, re-renders unit, restarts service | 17:18:37–17:18:57 | journal extract below |
| VM reconciled (`RestartSec=3` live) | 17:18:57 | `ActiveEnterTimestamp` + grep above |
| Stabilizing pulls (`changed=0` at `cd094d1`) | 17:23:55 + 17:29:11 | journalctl below |

Measured, not claimed: push at 17:15:50 → the 17:18:37 fire picks it up → handler restarts the service at 17:18:57 — **3 min 07 s from push to reconcile**, well inside the `OnUnitActiveSec=5min` worst case. No `ansible-playbook` was run from anywhere — the VM pulled its own desired state from Git. That is the GitOps loop.

> Note: from this point the VM converges to the **pushed** state every 5 minutes — any further local edit must be committed and pushed, or the loop will converge it back.

### 4.3 Design questions (bonus)

**h) `ansible-pull` is "pull" mode — what's the security benefit vs a push control node?**

In push mode the control node holds SSH credentials for *every* node it manages: one compromised control node = keys to the whole fleet, and every node runs an SSH service reachable from it (a listening attack surface + key-management burden that grows with the fleet). In pull mode the direction inverts: nodes hold **no** management credentials at all — they make an outbound, read-only connection to a Git repo (public over HTTPS needs nothing; private uses a scoped read-only token). There is no inbound management channel to harden or steal, a compromised node cannot pivot into other nodes through the config system, and a leaked node identity leaks read access to the config, not shell access to the fleet. The trade-offs are honest to state: secrets distribution still needs a solution, and failures are silent unless nodes report back (push mode fails loudly on the controller).

**i) What's the same pattern called at the Kubernetes layer? Why is `ansible-pull` a fair simulator?**

The pattern is **GitOps**, and its industry-standard Kubernetes implementations are **ArgoCD** and **Flux**: desired state lives in Git, an in-cluster controller continuously reconciles live state toward it, and drift is corrected automatically. `ansible-pull` is a fair VM-layer simulator because it reproduces the same four properties on a single box: (1) Git is the single source of truth for desired state (the playbook *is* the manifest); (2) an agent on the node (`systemd timer` ↔ ArgoCD controller) pulls and reconciles periodically; (3) the operation is convergence, not execution — re-applying is safe (`changed=0`) and drift self-heals within ≤ 5 minutes; (4) nothing pushes into the node. What it does not simulate: Kubernetes' continuous reconciliation against an API server's resource model and its richer drift/health semantics — which is exactly the gap Lab 9+ closes.

---

## 5. Conclusion

Lab 7 turned a manual deployment into a declaration. Task 1 shipped QuickNotes as a systemd service entirely from playbook variables — system user, data dir, binary, seed, Jinja2-rendered unit — and the teardown drill proved the claim end-to-end: wiped to zero, the same playbook rebuilt the service in one run (`ok=8 changed=7`, seed re-served, `/health` green). Task 2 made the property visible: a re-run folded to `changed=0`, a one-variable tweak moved exactly the template plus its handler (`ok=8 changed=2`), and `--check --diff` previewed the exact `RestartSec=5 → 3` line before anything was written — with one honest surprise owned in §3.3: core 2.16 simulates handlers under `--check`, and the zero-drift verification (`RestartSec=5` on disk, untouched `ActiveEnterTimestamp`) ruled the simulation harmless. The bonus closed the loop at GitOps shape: a systemd timer now pulls `feature/lab7` every 5 minutes, ran silently clean (`changed=0`) until a push landed, then reconciled the VM in **3 min 07 s** — `before cc9c33b → after cd094d1`, template `changed`, `Restart quicknotes` handler, followed by two more silent `changed=0` cycles at the new commit. The road wreckage (VM name conflict, adoption, an SSH dead-end that forced a rebuild) is documented in §0 rather than hidden, because on a config-management lab the honest state history *is* the deliverable. Next stop, Lab 9+: the same reconcile loop, one abstraction level up, against the Kubernetes API.

---

## Appendix A — Files in this PR

| File | Purpose |
|------|---------|
| `ansible/inventory.ini` | SSH inventory: IP + port + Vagrant-generated key (its `0600` copy `~/.ssh/lab7_key` inside the VM) |
| `ansible/inventory-local.ini` | Pull-mode inventory: `127.0.0.1`, `ansible_connection=local` |
| `ansible/playbook.yaml` | The deploy play (+ guarded ansible-pull loop), vars-driven |
| `ansible/files/quicknotes` | Static Linux binary (`CGO_ENABLED=0`, `-trimpath`, `-ldflags='-s -w'`) |
| `ansible/files/seed.json` | Copy of `app/seed.json` shipped to the VM |
| `ansible/templates/quicknotes.service.j2` | systemd unit, all values are playbook variables |
| `ansible/templates/ansible-pull.service.j2` | Bonus: oneshot pull unit |
| `ansible/templates/ansible-pull.timer.j2` | Bonus: `OnBootSec=1min`, `OnUnitActiveSec=5min` |
| `submissions/lab7.md` | This report (evidence = verbatim pasted outputs) |

## Appendix B — Evidence index

| Evidence | Section |
|----------|---------|
| Branch `feature/lab7` + `Vagrantfile` + `scripts/install-go.sh` restored from `feature/lab5` (untracked `??`) | §0 |
| `VBoxManage list vms` + re-adopted VM id (`quicknotes-lab5`) | §0 |
| `vagrant ssh-config` — IP/port/user/key facts | §2.0 |
| Cross-compiled binary + seed copy | §2.2 |
| VM state checks (ansible version, port 8080, old units) | §2.2 |
| Key bootstrap (`0777` vboxsf → `0600` copy) + `ping` → `pong` | §2.3 |
| `--check` dry-run recap | §2.3 |
| First real run — rebuilt from zero via teardown drill, full PLAY RECAP (`changed=7`) + handlers | §2.3 |
| `systemctl status` active (running) + rendered unit | §2.3 |
| `/health` + `/notes` with 4 seeded notes | §2.4 |
| Second run `changed=0` | §3.1 |
| Tweak demo: template `changed=1` + handler + revert | §3.2 |
| `--check --diff` template diff | §3.3 |
| Arming run + `list-timers` | §4.1 |
| Pull-loop baseline run (`changed=0`, repo `cc9c33b`) + GitOps convergence (push `cd094d1` → `RestartSec=3` + timeline) | §4.2 |
