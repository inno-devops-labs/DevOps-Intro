# Lab 7 — Configuration Management: Deploy QuickNotes via Ansible

## Environment

The lab was completed using:

- macOS Apple Silicon as the Ansible control node
- Python 3.12.15
- Ansible 10.7.0
- ansible-core 2.17.14
- Vagrant with the Parallels provider
- Ubuntu 24.04 VM
- VM architecture: `aarch64`
- VM Python: Python 3.12.3
- systemd 255

The Lab 5 VM was already running:

```text
default                   running (parallels)
```

Vagrant SSH configuration:

```text
Host default
  HostName 127.0.0.1
  User vagrant
  Port 22022
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /Users/alisaevdosenko/DevOps-Intro/.vagrant/machines/default/parallels/private_key
  IdentitiesOnly yes
  LogLevel FATAL
  PubkeyAcceptedKeyTypes +ssh-rsa
  HostKeyAlgorithms +ssh-rsa
```

Port forwarding:

```text
22   (guest) => 22022 (host)
8080 (guest) => 18080 (host)
```

Ansible connectivity was verified with:

```bash
ansible \
  -i ansible/inventory.ini \
  quicknotes \
  -m ping
```

Result:

```text
quicknotes-vm | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Privilege escalation was also verified:

```bash
ansible \
  -i ansible/inventory.ini \
  quicknotes \
  -b \
  -m command \
  -a 'id'
```

Result:

```text
uid=0(root) gid=0(root) groups=0(root)
```

---

# Task 1 — Idempotent Deploy to the Lab 5 VM

## 1. Project layout

The Ansible configuration is stored under:

```text
ansible/
├── inventory.ini
├── playbook.yaml
├── files/
│   ├── quicknotes
│   └── seed.json
└── templates/
    └── quicknotes.service.j2
```

The deployment installs:

```text
/usr/local/bin/quicknotes
/var/lib/quicknotes/
/var/lib/quicknotes/seed.json
/etc/systemd/system/quicknotes.service
```

---

# 2. Static QuickNotes binary

Because the control node is macOS/ARM64 while the managed VM is Linux/ARM64, the binary was cross-compiled explicitly for Linux:

```bash
CGO_ENABLED=0 \
GOOS=linux \
GOARCH=arm64 \
go build \
  -trimpath \
  -ldflags="-s -w" \
  -o ../ansible/files/quicknotes \
  .
```

The resulting binary was verified with:

```bash
file ansible/files/quicknotes
```

Output:

```text
ansible/files/quicknotes: ELF 64-bit LSB executable, ARM aarch64,
version 1 (SYSV), statically linked, Go BuildID=...,
BuildID[sha1]=7e69787617610c0ac0bcc27e6e98514c92274bc9, stripped
```

Binary size:

```text
5.8M
```

This confirms that the artifact is a Linux ARM64 executable rather than a macOS Mach-O binary.

The seed file was copied from the application directory:

```bash
cp app/seed.json ansible/files/seed.json
```

SHA-256 verification:

```text
de1abc8157efd9fd1c3a3233b8581a1d1af659b44d2104f11ca600018f024e7b  app/seed.json
de1abc8157efd9fd1c3a3233b8581a1d1af659b44d2104f11ca600018f024e7b  ansible/files/seed.json
```

The matching hashes confirm that the shipped seed file is identical to `app/seed.json`.

---

# 3. Inventory

File: `ansible/inventory.ini`

```ini
[quicknotes]
quicknotes-vm ansible_host=127.0.0.1 ansible_port=22022 ansible_user=vagrant ansible_ssh_private_key_file=/Users/alisaevdosenko/DevOps-Intro/.vagrant/machines/default/parallels/private_key ansible_python_interpreter=/usr/bin/python3

[quicknotes:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa'
```

The inventory uses the same SSH connection parameters that Vagrant reports via:

```bash
vagrant ssh-config
```

Although the VM is separate from the host, Ansible connects to:

```text
127.0.0.1:22022
```

because Vagrant forwards that host port to SSH port `22` inside the guest.

Connection flow:

```text
Ansible on macOS
      |
      | SSH
      | 127.0.0.1:22022
      v
Vagrant / Parallels forwarding
      |
      | guest :22
      v
Ubuntu VM
      |
      +-- user: vagrant
      |
      +-- become / sudo
              |
              v
             root
```

---

# 4. Systemd Jinja2 template

File: `ansible/templates/quicknotes.service.j2`

```ini
[Unit]
Description=QuickNotes service
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

The template contains variables instead of hard-coded application settings.

For example:

```jinja2
Environment="ADDR={{ quicknotes_listen_addr }}"
```

is rendered using the playbook variable:

```yaml
quicknotes_listen_addr: ":8080"
```

into:

```ini
Environment="ADDR=:8080"
```

This allows Ansible to detect a configuration change, rewrite only the affected unit file, and notify the restart handler.

---

# 5. Playbook

File: `ansible/playbook.yaml`

```yaml
---
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true
  gather_facts: false

  vars:
    quicknotes_user: quicknotes
    quicknotes_group: quicknotes

    quicknotes_binary_path: /usr/local/bin/quicknotes

    quicknotes_data_dir: /var/lib/quicknotes
    quicknotes_data_path: /var/lib/quicknotes/notes.json
    quicknotes_seed_path: /var/lib/quicknotes/seed.json

    quicknotes_listen_addr: ":8080"
    quicknotes_restart_sec: "3s"

  tasks:
    - name: Create QuickNotes system user
      ansible.builtin.user:
        name: "{{ quicknotes_user }}"
        system: true
        create_home: false
        shell: /usr/sbin/nologin
        state: present

    - name: Ensure QuickNotes data directory exists
      ansible.builtin.file:
        path: "{{ quicknotes_data_dir }}"
        state: directory
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        mode: "0750"

    - name: Install QuickNotes binary
      ansible.builtin.copy:
        src: files/quicknotes
        dest: "{{ quicknotes_binary_path }}"
        owner: root
        group: root
        mode: "0755"
      notify: Restart QuickNotes

    - name: Install QuickNotes seed data
      ansible.builtin.copy:
        src: files/seed.json
        dest: "{{ quicknotes_seed_path }}"
        owner: "{{ quicknotes_user }}"
        group: "{{ quicknotes_group }}"
        mode: "0640"

    - name: Render QuickNotes systemd unit
      ansible.builtin.template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
        owner: root
        group: root
        mode: "0644"
      notify: Restart QuickNotes

    - name: Ensure QuickNotes service is enabled and started
      ansible.builtin.systemd_service:
        name: quicknotes
        daemon_reload: true
        enabled: true
        state: started
      when: not ansible_check_mode

  handlers:
    - name: Restart QuickNotes
      ansible.builtin.systemd_service:
        name: quicknotes
        daemon_reload: true
        state: restarted
      when: not ansible_check_mode
```

---

# 6. First deployment

The first deployment created all required resources.

Command:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yaml
```

Initial PLAY RECAP:

```text
PLAY RECAP *********************************************************************
quicknotes-vm : ok=7 changed=7 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

The first run correctly reported changes because the required user, directory, binary, seed file, systemd unit, and service state did not yet exist in their desired form.

---

# 7. Troubleshooting during the first deployment

During verification, the new systemd-managed QuickNotes service initially failed.

`systemctl status` showed:

```text
Active: failed (Result: exit-code)
ExecStart=/usr/local/bin/quicknotes
```

However:

```bash
curl -s http://localhost:18080/health
```

still worked and returned six notes.

This indicated that another process was already listening on port `8080`.

The listener was identified with:

```bash
sudo ss -ltnp | grep ":8080"
```

Output:

```text
LISTEN 0 4096 *:8080 *:* users:(("qn",pid=11547,fd=3))
```

The old process was confirmed:

```text
vagrant 11547 1 ... /tmp/qn
```

It was a QuickNotes binary manually started during an earlier lab.

The systemd journal confirmed the root cause:

```text
quicknotes listening on :8080 (notes loaded: 4)
listen: listen tcp :8080: bind: address already in use
quicknotes.service: Main process exited, code=exited, status=1/FAILURE
```

Because the unit contained:

```ini
Restart=on-failure
RestartSec=2s
```

systemd repeatedly tried to restart the service.

The old `/tmp/qn` process was stopped, after which the systemd-managed application was started successfully.

This was a useful example of configuration drift outside Ansible: the configuration itself was valid, but an unmanaged process from a previous lab conflicted with the desired service state.

---

# 8. Final systemd state

After removing the stale process:

```text
● quicknotes.service - QuickNotes service
     Loaded: loaded (/etc/systemd/system/quicknotes.service; enabled; preset: enabled)
     Active: active (running)
   Main PID: 31084 (quicknotes)
     CGroup: /system.slice/quicknotes.service
             └─31084 /usr/local/bin/quicknotes
```

The application log showed:

```text
quicknotes listening on :8080 (notes loaded: 4)
```

Service checks:

```text
active
enabled
```

Listener:

```text
LISTEN 0 4096 *:8080 *:* users:(("quicknotes",pid=31084,fd=3))
```

The actual executable used by systemd was verified through `/proc`:

```text
MainPID=31084

/usr/local/bin/quicknotes
```

Process:

```text
USER         PID    PPID CMD
quickno+   31084       1 /usr/local/bin/quicknotes
```

This confirms that the service is:

- managed by systemd;
- running from `/usr/local/bin/quicknotes`;
- running as the dedicated `quicknotes` user;
- not using the previous manually started `/tmp/qn`.

---

# 9. Deployed user and files

System user:

```text
quicknotes:x:999:988::/home/quicknotes:/usr/sbin/nologin
```

Data directory:

```text
drwxr-x--- 2 quicknotes quicknotes ... /var/lib/quicknotes
```

Files:

```text
-rw-r--r-- 1 quicknotes quicknotes ... notes.json
-rw-r----- 1 quicknotes quicknotes ... seed.json
```

Binary:

```text
-rwxr-xr-x 1 root root ... /usr/local/bin/quicknotes
```

Therefore:

```text
/var/lib/quicknotes
owner: quicknotes
group: quicknotes
mode: 0750

seed.json
owner: quicknotes
group: quicknotes
mode: 0640

/usr/local/bin/quicknotes
mode: 0755
```

---

# 10. Application verification

Health endpoint from the macOS host:

```bash
curl -s http://localhost:18080/health | jq .
```

Output:

```json
{
  "notes": 4,
  "status": "ok"
}
```

Notes endpoint:

```bash
curl -s http://localhost:18080/notes | jq .
```

Output:

```json
[
  {
    "id": 1,
    "title": "Welcome to QuickNotes",
    "body": "This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.",
    "created_at": "2026-01-15T10:00:00Z"
  },
  {
    "id": 2,
    "title": "Read app/main.go first",
    "body": "Start by understanding the entry point — env vars, signal handling, graceful shutdown.",
    "created_at": "2026-01-15T10:05:00Z"
  },
  {
    "id": 3,
    "title": "DevOps mantra",
    "body": "If it hurts, do it more often.",
    "created_at": "2026-01-15T10:10:00Z"
  },
  {
    "id": 4,
    "title": "Endpoint cheat-sheet",
    "body": "GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics",
    "created_at": "2026-01-15T10:15:00Z"
  }
]
```

The non-empty response proves that:

- `seed.json` was copied to the VM;
- `SEED_PATH` points to the correct location;
- QuickNotes successfully initialized its data store from the shipped seed data.

---

# Task 1 — Design Questions

## a) What is the difference between `command:` and dedicated modules such as `file`, `copy`, `user`, and `systemd`? Which is idempotent and why does it matter?

The `command` module executes an arbitrary command on the managed host.

For example:

```yaml
ansible.builtin.command:
  cmd: mkdir /var/lib/quicknotes
```

Ansible knows that the command was executed, but it usually does not understand the state that the command is supposed to represent.

This was visible during the connectivity test:

```bash
ansible ... -b -m command -a 'id'
```

Ansible reported:

```text
CHANGED
```

even though `id` only displayed information and did not modify the machine.

Dedicated modules instead understand the resource they manage.

For example:

```yaml
ansible.builtin.file:
  path: /var/lib/quicknotes
  state: directory
  owner: quicknotes
  group: quicknotes
  mode: "0750"
```

The `file` module can inspect:

- whether the path exists;
- whether it is a directory;
- its owner;
- its group;
- its permissions.

If all attributes already match, the result is:

```text
ok
```

rather than:

```text
changed
```

Similarly:

- `user` understands user account state;
- `copy` compares source and destination content and metadata;
- `template` compares rendered output with the remote file;
- `systemd_service` understands whether a service is started, stopped, enabled, or disabled.

This makes dedicated modules naturally suited to idempotent configuration management.

Idempotency matters because infrastructure configuration must be safe to apply repeatedly.

The desired property is:

```text
apply once
    ↓
machine converges

apply again
    ↓
nothing changes if state is already correct
```

With arbitrary shell or command tasks, Ansible often cannot determine whether work is necessary, which leads to unnecessary changes and can make automation unsafe.

---

## b) When does a handler notified by `notify:` fire? When does it not fire? Why is this the right default?

A handler is notified only when the notifying task reports:

```text
changed
```

In this playbook both:

```yaml
Install QuickNotes binary
```

and:

```yaml
Render QuickNotes systemd unit
```

contain:

```yaml
notify: Restart QuickNotes
```

If the binary differs from the deployed binary:

```text
copy task → changed
            ↓
notify handler
```

If the rendered systemd unit differs from the installed unit:

```text
template task → changed
                ↓
notify handler
```

If both tasks are already correct:

```text
copy     → ok
template → ok
             ↓
no notification
             ↓
no restart
```

Handlers normally execute near the end of the play.

Multiple tasks can notify the same handler, but the handler normally runs only once.

For example:

```text
binary changed ----\
                    +--> Restart QuickNotes once
unit changed ------/
```

This is the right default because service restarts are disruptive operations.

A configuration-management system should not restart a service when nothing relevant changed.

This behavior reduces:

- unnecessary downtime;
- dropped connections;
- avoidable process churn;
- deployment risk.

---

## c) Ansible has many levels of variable precedence. What are the top three places you would put variables for this lab, and why?

For this lab I would consider three main locations.

### 1. Playbook variables

For a small, single-purpose lab, play-level variables are simple and easy to understand:

```yaml
vars:
  quicknotes_listen_addr: ":8080"
  quicknotes_data_dir: /var/lib/quicknotes
```

Advantages:

- all configuration is visible next to the play;
- easy to review;
- good for a small project with one managed service.

This is the approach used in this lab.

### 2. `group_vars`

For a larger inventory, values that apply to the entire `quicknotes` group would be better stored in something such as:

```text
ansible/group_vars/quicknotes.yaml
```

For example:

```yaml
quicknotes_listen_addr: ":8080"
quicknotes_restart_sec: "3s"
```

This separates configuration from playbook logic.

It also allows the same playbook to be reused against different groups or environments.

For example:

```text
group_vars/dev.yaml
group_vars/staging.yaml
group_vars/prod.yaml
```

### 3. Role defaults

If this deployment were converted into a reusable Ansible role, default values could be placed in:

```text
roles/quicknotes/defaults/main.yaml
```

Role defaults have intentionally low precedence, which makes them easy to override from inventory or play variables.

This is useful when creating reusable automation:

```text
role provides sensible defaults
        ↓
environment overrides what differs
```

For temporary command-line overrides, Ansible also supports extra variables such as:

```bash
ansible-playbook ... -e quicknotes_listen_addr=:9090
```

Extra vars have very high precedence, but I would not use them as the normal configuration source because they make persistent configuration less visible in version control.

---

## d) `gather_facts: true` is the default. Do you need facts for this playbook? What does disabling them save?

This playbook does not require gathered facts.

It does not use variables such as:

```text
ansible_distribution
ansible_architecture
ansible_hostname
ansible_default_ipv4
ansible_mounts
```

Therefore it uses:

```yaml
gather_facts: false
```

Fact gathering normally requires Ansible to execute its setup module against the managed node and collect information about:

- operating system;
- network interfaces;
- architecture;
- memory;
- CPU;
- filesystems;
- Python;
- environment;
- other host properties.

Disabling facts saves at least one extra remote module execution per play and avoids transferring and processing information that the playbook does not use.

For one VM the time saving is small, but across many hosts the cost becomes more significant.

Facts should be enabled when the automation actually needs host-specific data, rather than simply because they are available.

---

# Task 2 — Prove Idempotency and Selective Re-run

## 1. Second run with zero changes

After the VM reached the desired state, the playbook was executed again without modifying any input.

Command:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yaml
```

Output:

```text
PLAY [Deploy QuickNotes] *******************************************************

TASK [Create QuickNotes system user] *******************************************
ok: [quicknotes-vm]

TASK [Ensure QuickNotes data directory exists] *********************************
ok: [quicknotes-vm]

TASK [Install QuickNotes binary] ***********************************************
ok: [quicknotes-vm]

TASK [Install QuickNotes seed data] ********************************************
ok: [quicknotes-vm]

TASK [Render QuickNotes systemd unit] ******************************************
ok: [quicknotes-vm]

TASK [Ensure QuickNotes service is enabled and started] ************************
ok: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm : ok=6 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

The result:

```text
changed=0
```

proves that applying the same desired configuration repeatedly does not create unnecessary changes.

---

# 2. Selective variable change

The systemd restart backoff variable was changed from:

```yaml
quicknotes_restart_sec: "2s"
```

to:

```yaml
quicknotes_restart_sec: "3s"
```

The QuickNotes PID before the change was:

```text
31084
```

The playbook was then executed again.

Output:

```text
PLAY [Deploy QuickNotes] *******************************************************

TASK [Create QuickNotes system user] *******************************************
ok: [quicknotes-vm]

TASK [Ensure QuickNotes data directory exists] *********************************
ok: [quicknotes-vm]

TASK [Install QuickNotes binary] ***********************************************
ok: [quicknotes-vm]

TASK [Install QuickNotes seed data] ********************************************
ok: [quicknotes-vm]

TASK [Render QuickNotes systemd unit] ******************************************
changed: [quicknotes-vm]

TASK [Ensure QuickNotes service is enabled and started] ************************
ok: [quicknotes-vm]

RUNNING HANDLER [Restart QuickNotes] *******************************************
changed: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm : ok=7 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

Only the template task changed among the normal tasks.

The restart handler was then invoked because the template notified it.

Although the PLAY RECAP contains:

```text
changed=2
```

there was only one configuration change:

```text
template changed
```

The second changed result represents the actual service restart performed by the handler.

After deployment:

```text
PID after change:
31778
```

The new unit contained:

```text
RestartSec=3s
```

and the service remained:

```text
active
```

The PID changed from:

```text
31084
```

to:

```text
31778
```

which independently confirms that the handler restarted the process.

The application remained available:

```json
{
  "notes": 4,
  "status": "ok"
}
```

---

# 3. `--check --diff` preview

For the dry-run demonstration, the listen address was temporarily changed in the playbook from:

```yaml
quicknotes_listen_addr: ":8080"
```

to:

```yaml
quicknotes_listen_addr: ":9090"
```

The playbook was then executed with:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/playbook.yaml \
  --check \
  --diff
```

Output:

```text
PLAY [Deploy QuickNotes] *******************************************************

TASK [Create QuickNotes system user] *******************************************
ok: [quicknotes-vm]

TASK [Ensure QuickNotes data directory exists] *********************************
ok: [quicknotes-vm]

TASK [Install QuickNotes binary] ***********************************************
ok: [quicknotes-vm]

TASK [Install QuickNotes seed data] ********************************************
ok: [quicknotes-vm]

TASK [Render QuickNotes systemd unit] ******************************************
--- before: /etc/systemd/system/quicknotes.service
+++ after: /Users/alisaevdosenko/.ansible/tmp/.../quicknotes.service.j2
@@ -10,7 +10,7 @@

 WorkingDirectory=/var/lib/quicknotes

-Environment="ADDR=:8080"
+Environment="ADDR=:9090"
 Environment="DATA_PATH=/var/lib/quicknotes/notes.json"
 Environment="SEED_PATH=/var/lib/quicknotes/seed.json"

changed: [quicknotes-vm]

TASK [Ensure QuickNotes service is enabled and started] ************************
skipping: [quicknotes-vm]

RUNNING HANDLER [Restart QuickNotes] *******************************************
skipping: [quicknotes-vm]

PLAY RECAP *********************************************************************
quicknotes-vm : ok=5 changed=1 unreachable=0 failed=0 skipped=2 rescued=0 ignored=0
```

The diff clearly predicted:

```diff
-Environment="ADDR=:8080"
+Environment="ADDR=:9090"
```

However, because this was check mode, the deployed unit remained unchanged.

Verification immediately after the dry-run:

```text
Environment="ADDR=:8080"
active
```

This proves that `--check --diff` previewed the proposed change without applying it.

The final playbook configuration was restored to:

```yaml
quicknotes_listen_addr: ":8080"
quicknotes_restart_sec: "3s"
```

---

# Task 2 — Design Questions

## e) Why does the second run report `changed=0`? What specifically do the `file` and `template` modules check?

The second run reports:

```text
changed=0
```

because every managed resource already matches the desired state described by the playbook.

The `file` module checks attributes of the filesystem object, including values such as:

- path existence;
- object type;
- owner;
- group;
- permissions.

For example, the desired data directory is:

```text
path:  /var/lib/quicknotes
type:  directory
owner: quicknotes
group: quicknotes
mode:  0750
```

If the directory already matches all of these attributes, the module returns:

```text
ok
```

The `template` module first renders the Jinja2 template using the current variables.

Conceptually:

```text
template + variables
        ↓
rendered content
        ↓
compare with remote file
```

If the rendered content and required metadata already match the destination file, the task reports:

```text
ok
```

If even one rendered value changes, such as:

```text
RestartSec=2s
```

becoming:

```text
RestartSec=3s
```

the destination differs and the task reports:

```text
changed
```

That state comparison is what makes these modules naturally idempotent.

---

## f) What would happen if the systemd unit were written using `shell: 'echo ... > /etc/systemd/system/quicknotes.service'` instead of `template:`?

Using a shell command would introduce several problems.

### 1. Ansible would not naturally understand file state

A shell command such as:

```yaml
shell: 'echo "..." > /etc/systemd/system/quicknotes.service'
```

describes an action rather than a desired state.

Unless additional conditions are manually implemented, Ansible may execute it every time and report a change even when the resulting file content is identical.

This damages idempotency.

### 2. The service could restart on every deployment

If the shell task always reports:

```text
changed
```

and notifies the handler, QuickNotes could restart on every playbook execution:

```text
playbook run
    ↓
shell task reports changed
    ↓
handler notified
    ↓
service restart
```

even when the configuration did not actually change.

### 3. File ownership and permissions would need separate management

A redirect creates or truncates the file, but it does not declaratively guarantee:

```text
owner=root
group=root
mode=0644
```

Additional tasks or shell commands would be required.

### 4. Quoting becomes fragile

A systemd unit contains:

- quotes;
- newlines;
- environment-variable syntax;
- potentially shell-sensitive characters.

Embedding the entire unit inside an `echo` command creates quoting and escaping risks.

### 5. File replacement is less controlled

The shell redirection:

```bash
>
```

truncates the target before writing new data.

A malformed command or interrupted operation can leave the file incomplete.

The template module provides a safer file-management abstraction.

### 6. Check mode becomes weaker

Ansible cannot reliably predict arbitrary shell side effects.

A dedicated template module knows:

- what file it manages;
- what the rendered content should be;
- whether that content differs.

This makes `--check` and `--diff` substantially more useful.

### 7. Diff output is lost or requires custom logic

With `template`, Ansible can show:

```diff
-Environment="ADDR=:8080"
+Environment="ADDR=:9090"
```

With an arbitrary shell command, Ansible generally cannot produce such a semantic before/after file diff automatically.

Therefore `template` is preferable because it represents desired file state rather than an imperative sequence of shell operations.

---

## g) What bug can `--check --diff` catch that plain `--check` might miss?

Plain:

```bash
ansible-playbook --check
```

can tell me that a task **would change**.

For example:

```text
Render QuickNotes systemd unit
changed
```

But that does not show whether the proposed new content is correct.

Adding:

```bash
--diff
```

shows the exact content difference.

In this lab it displayed:

```diff
-Environment="ADDR=:8080"
+Environment="ADDR=:9090"
```

This could catch configuration bugs such as:

```text
wrong port
wrong DATA_PATH
wrong SEED_PATH
wrong executable path
accidentally removed systemd directive
incorrect restart interval
incorrect user
bad templated value
```

before they are deployed.

For example, suppose I intended to configure:

```text
ADDR=:8080
```

but accidentally entered:

```text
ADDR=:808
```

Plain `--check` might only report:

```text
changed=1
```

which looks expected.

`--check --diff` would reveal:

```diff
-Environment="ADDR=:8080"
+Environment="ADDR=:808"
```

making the typo visible before production configuration is modified.

Therefore:

```text
--check
= tells me whether state would change

--check --diff
= tells me whether state would change
  AND shows exactly how
```

The second is much more useful for reviewing configuration changes before a real deployment.

---

# Idempotency Summary

The lab demonstrated three different configuration-management states.

## Initial convergence

```text
desired state != current state
        ↓
Ansible changes resources
        ↓
changed > 0
```

Initial recap:

```text
ok=7 changed=7
```

## Stable state

```text
desired state == current state
        ↓
nothing needs modification
        ↓
changed=0
```

Second-run recap:

```text
ok=6 changed=0
```

## Selective configuration change

One variable was changed:

```text
RestartSec: 2s → 3s
```

Result:

```text
user task       → ok
directory       → ok
binary          → ok
seed            → ok
template        → changed
service state   → ok
handler         → changed
```

The handler restarted QuickNotes only because its systemd configuration actually changed.

## Dry-run preview

A temporary address change:

```text
:8080 → :9090
```

was previewed with:

```bash
--check --diff
```

The exact diff was shown, while the remote unit remained unchanged.

---

# Results

| Requirement | Result |
|---|---|
| Ansible inventory targets Lab 5 VM | ✅ |
| Vagrant SSH key and forwarded port used | ✅ |
| `become: true` | ✅ |
| System user `quicknotes` | ✅ |
| No login shell | ✅ |
| `/var/lib/quicknotes` owner/mode | ✅ |
| Static Linux ARM64 QuickNotes binary | ✅ |
| Binary installed as `/usr/local/bin/quicknotes` | ✅ |
| `seed.json` deployed | ✅ |
| Jinja2 systemd template | ✅ |
| `ADDR`, `DATA_PATH`, `SEED_PATH` templated | ✅ |
| Runs as non-root `quicknotes` user | ✅ |
| Starts after `network-online.target` | ✅ |
| Restart-on-failure configured | ✅ |
| Service enabled | ✅ |
| Service active and running | ✅ |
| Host `/health` verification | ✅ |
| Host `/notes` contains seeded records | ✅ |
| First convergence changes resources | ✅ |
| Second run `changed=0` | ✅ |
| Variable change modifies only template | ✅ |
| Restart handler fires | ✅ |
| PID changes after handler restart | ✅ |
| `--check --diff` preview captured | ✅ |
| Dry-run leaves deployed state unchanged | ✅ |
| Design questions a–g answered | ✅ |

---

# Conclusion

Lab 7 demonstrated the difference between imperative remote execution and declarative configuration management.

Instead of manually SSHing into the VM and running commands, the desired QuickNotes state is now expressed in Ansible:

```text
user
directory
binary
seed file
systemd unit
service state
```

Ansible compares that desired configuration with the actual VM and applies only the required changes.

The most important result is the second playbook execution:

```text
changed=0
```

which proves idempotency.

The selective variable experiment also demonstrated why handlers are useful: changing one value in the systemd template changed only that resource and triggered exactly the service restart required to activate the new configuration.

Finally, `--check --diff` showed how Ansible can be used to review the exact effect of a configuration change before it is applied.

The resulting deployment is reproducible: one Ansible playbook can take the Lab 5 VM and converge it to a running, systemd-managed QuickNotes service.