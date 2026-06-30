\# Lab 7 - Configuration Management: Deploy QuickNotes via Ansible



\## Task 1 - Idempotent Deploy to the Lab 5 VM



\### Goal



The goal of this lab was to deploy QuickNotes to the Lab 5 Vagrant VM using Ansible. The playbook creates a dedicated system user, installs the QuickNotes binary, deploys the seed file, renders a systemd service from a Jinja2 template, enables the service, starts it, and restarts it only when the binary or unit file changes.



\---



\## Ansible Inventory



File: `ansible/inventory.yaml`



```yaml

all:

&#x20; children:

&#x20;   quicknotes\_vm:

&#x20;     hosts:

&#x20;       lab5-vm:

&#x20;         ansible\_host: 172.19.128.1

&#x20;         ansible\_port: 2223

&#x20;         ansible\_user: vagrant

&#x20;         ansible\_private\_key\_file: /root/.ssh/vagrant-devops-intro/private\_key

&#x20;         ansible\_ssh\_common\_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa"

```



I used port `2223` because the normal Vagrant SSH port `2222` was bound to Windows localhost. The extra forwarded SSH port was exposed on `0.0.0.0`, allowing Ansible from WSL to reach the VM.



\### SSH and Ansible connectivity test



Command:



```bash

ssh -i /root/.ssh/vagrant-devops-intro/private\_key \\

&#x20; -p 2223 \\

&#x20; -o StrictHostKeyChecking=no \\

&#x20; -o UserKnownHostsFile=/dev/null \\

&#x20; -o PubkeyAcceptedKeyTypes=+ssh-rsa \\

&#x20; -o HostKeyAlgorithms=+ssh-rsa \\

&#x20; vagrant@172.19.128.1 'echo SSH\_OK'

```



Output:



```text

SSH\_OK

```



Command:



```bash

ansible -i ansible/inventory.yaml quicknotes\_vm -m ping

```



Output:



```text

lab5-vm | SUCCESS => {

&#x20;   "ansible\_facts": {

&#x20;       "discovered\_interpreter\_python": "/usr/bin/python3.12"

&#x20;   },

&#x20;   "changed": false,

&#x20;   "ping": "pong"

}

```



\---



\## Playbook



File: `ansible/playbook.yaml`



```yaml

\---

\- name: Deploy QuickNotes to Lab 5 VM

&#x20; hosts: quicknotes\_vm

&#x20; become: true

&#x20; gather\_facts: false



&#x20; vars:

&#x20;   quicknotes\_user: quicknotes

&#x20;   quicknotes\_group: quicknotes

&#x20;   quicknotes\_data\_dir: /var/lib/quicknotes

&#x20;   quicknotes\_config\_dir: /etc/quicknotes

&#x20;   quicknotes\_binary\_src: files/quicknotes

&#x20;   quicknotes\_seed\_src: files/seed.json

&#x20;   quicknotes\_binary\_dest: /usr/local/bin/quicknotes

&#x20;   quicknotes\_seed\_dest: /etc/quicknotes/seed.json

&#x20;   quicknotes\_listen\_addr: ":8080"

&#x20;   quicknotes\_data\_path: /var/lib/quicknotes/notes.json

&#x20;   quicknotes\_seed\_path: /etc/quicknotes/seed.json

&#x20;   quicknotes\_restart\_sec: 4



&#x20; tasks:

&#x20;   - name: Create QuickNotes group

&#x20;     ansible.builtin.group:

&#x20;       name: "{{ quicknotes\_group }}"

&#x20;       system: true

&#x20;       state: present



&#x20;   - name: Create QuickNotes system user

&#x20;     ansible.builtin.user:

&#x20;       name: "{{ quicknotes\_user }}"

&#x20;       group: "{{ quicknotes\_group }}"

&#x20;       system: true

&#x20;       shell: /usr/sbin/nologin

&#x20;       create\_home: false

&#x20;       home: "{{ quicknotes\_data\_dir }}"

&#x20;       state: present



&#x20;   - name: Ensure QuickNotes data directory exists

&#x20;     ansible.builtin.file:

&#x20;       path: "{{ quicknotes\_data\_dir }}"

&#x20;       state: directory

&#x20;       owner: "{{ quicknotes\_user }}"

&#x20;       group: "{{ quicknotes\_group }}"

&#x20;       mode: "0750"



&#x20;   - name: Ensure QuickNotes config directory exists

&#x20;     ansible.builtin.file:

&#x20;       path: "{{ quicknotes\_config\_dir }}"

&#x20;       state: directory

&#x20;       owner: root

&#x20;       group: root

&#x20;       mode: "0755"



&#x20;   - name: Copy QuickNotes seed file

&#x20;     ansible.builtin.copy:

&#x20;       src: "{{ quicknotes\_seed\_src }}"

&#x20;       dest: "{{ quicknotes\_seed\_dest }}"

&#x20;       owner: root

&#x20;       group: root

&#x20;       mode: "0644"

&#x20;     notify: restart quicknotes



&#x20;   - name: Copy QuickNotes binary

&#x20;     ansible.builtin.copy:

&#x20;       src: "{{ quicknotes\_binary\_src }}"

&#x20;       dest: "{{ quicknotes\_binary\_dest }}"

&#x20;       owner: root

&#x20;       group: root

&#x20;       mode: "0755"

&#x20;     notify: restart quicknotes



&#x20;   - name: Render QuickNotes systemd unit

&#x20;     ansible.builtin.template:

&#x20;       src: quicknotes.service.j2

&#x20;       dest: /etc/systemd/system/quicknotes.service

&#x20;       owner: root

&#x20;       group: root

&#x20;       mode: "0644"

&#x20;     notify:

&#x20;       - reload systemd

&#x20;       - restart quicknotes



&#x20;   - name: Enable and start QuickNotes service

&#x20;     ansible.builtin.systemd:

&#x20;       name: quicknotes

&#x20;       enabled: true

&#x20;       state: started

&#x20;       daemon\_reload: true



&#x20; handlers:

&#x20;   - name: reload systemd

&#x20;     ansible.builtin.systemd:

&#x20;       daemon\_reload: true



&#x20;   - name: restart quicknotes

&#x20;     ansible.builtin.systemd:

&#x20;       name: quicknotes

&#x20;       state: restarted

&#x20;       daemon\_reload: true

```



\---



\## Systemd Unit Template



File: `ansible/templates/quicknotes.service.j2`



```ini

\[Unit]

Description=QuickNotes service

Wants=network-online.target

After=network-online.target



\[Service]

Type=simple

User={{ quicknotes\_user }}

Group={{ quicknotes\_group }}

WorkingDirectory={{ quicknotes\_data\_dir }}

Environment=ADDR={{ quicknotes\_listen\_addr }}

Environment=DATA\_PATH={{ quicknotes\_data\_path }}

Environment=SEED\_PATH={{ quicknotes\_seed\_path }}

ExecStart={{ quicknotes\_binary\_dest }}

Restart=on-failure

RestartSec={{ quicknotes\_restart\_sec }}s



\[Install]

WantedBy=multi-user.target

```



The template runs the service as the `quicknotes` user, sets the working directory to `/var/lib/quicknotes`, reads environment values from playbook variables, starts after `network-online.target`, and restarts on failure with a configurable backoff.



\---



\## Static QuickNotes Binary



The static Linux binary was built from the `app/` directory and copied into `ansible/files/quicknotes`.



Command used:



```powershell

docker run --rm -v "${PWD}:/work" -w /work/app golang:1.24-alpine sh -c "CGO\_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags='-s -w' -o /work/ansible/files/quicknotes ."

```



The seed file was also copied into `ansible/files/seed.json`.



```powershell

Copy-Item .\\app\\seed.json .\\ansible\\files\\seed.json -Force

```



\---



\## First Real Run



Command:



```bash

ansible-playbook -i ansible/inventory.yaml ansible/playbook.yaml

```



Output:



```text

PLAY \[Deploy QuickNotes to Lab 5 VM] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*



TASK \[Create QuickNotes group] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



TASK \[Create QuickNotes system user] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



TASK \[Ensure QuickNotes data directory exists] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



TASK \[Ensure QuickNotes config directory exists] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



TASK \[Copy QuickNotes seed file] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



TASK \[Copy QuickNotes binary] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



TASK \[Render QuickNotes systemd unit] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



TASK \[Enable and start QuickNotes service] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



RUNNING HANDLER \[reload systemd] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



RUNNING HANDLER \[restart quicknotes] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



PLAY RECAP \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

lab5-vm                    : ok=10   changed=9    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```



The first real run changed the VM because the QuickNotes user, directories, files, systemd unit, and service state had to be created.



\---



\## Health Check



Command from the host:



```powershell

curl.exe -s http://localhost:18080/health

```



Output:



```json

{"notes":4,"status":"ok"}

```



This confirms that the service is reachable through the Vagrant port forward from host port `18080` to guest port `8080`.



\---



\## Task 1 Design Questions



\### a) What is the difference between `command:` and dedicated modules like `apt`, `file`, `copy`, and `systemd`?



`command:` runs a command without understanding the desired final state. For example, it can run `mkdir /var/lib/quicknotes`, but it does not naturally understand ownership, permissions, or whether the directory already matches the desired state.



Dedicated modules are state-aware. The `file` module checks whether the path exists, whether it has the correct owner, group, mode, and state. The `copy` module checks file content, ownership, and permissions. The `systemd` module checks whether a service is enabled or running.



This matters because idempotent modules can report `changed=0` when the machine already matches the playbook. That makes repeated runs safe and predictable.



\### b) `notify:` and handlers: when does a handler fire? When does it not fire?



A handler fires when a task with `notify:` reports `changed`. In this playbook, copying the binary or rendering the systemd unit notifies the `restart quicknotes` handler. The systemd unit template also notifies the `reload systemd` handler.



A handler does not fire if the notifying task reports `ok`. For example, if the template content is already identical on the VM, the template task reports `ok`, so the restart handler does not run.



This is the right default because services should not restart on every playbook run. They should restart only when something that affects the service actually changes.



\### c) Variable hierarchy: where would I put variables for this lab?



The top three places I would use are:



1\. \*\*Playbook vars\*\*

&#x20;  I used playbook vars for this lab because all variables are specific to this one deployment. The service user, binary path, data path, seed path, and restart delay are all easy to see in one file.



2\. \*\*group\_vars\*\*

&#x20;  If there were multiple QuickNotes VMs, I would move shared settings into `group\_vars/quicknotes\_vm.yaml`. This would keep the playbook generic while still applying the same configuration to the group.



3\. \*\*role defaults\*\*

&#x20;  If this became a reusable role, I would put safe defaults in `defaults/main.yaml`. Defaults are easy to override, which makes the role reusable across environments like development, staging, and production.



For this small lab, playbook vars are enough. For a larger project, `group\_vars` and role defaults would be cleaner.



\### d) Do I need `gather\_facts: true` for this playbook? What does turning it off save?



I do not need `gather\_facts: true` for this playbook because the tasks do not depend on facts such as OS version, memory, CPU count, network interfaces, or distribution-specific variables. The paths, user, service name, binary location, and template values are explicitly defined.



Turning facts off saves time on each run because Ansible skips the initial fact-gathering step. It also reduces noise in the output and avoids collecting information the playbook does not use.



\---



\# Task 2 - Prove Idempotency and Selective Re-run



\## Second Run: Idempotency



Command:



```bash

ansible-playbook -i ansible/inventory.yaml ansible/playbook.yaml

```



Output:



```text

PLAY \[Deploy QuickNotes to Lab 5 VM] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*



TASK \[Create QuickNotes group] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Create QuickNotes system user] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Ensure QuickNotes data directory exists] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Ensure QuickNotes config directory exists] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Copy QuickNotes seed file] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Copy QuickNotes binary] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Render QuickNotes systemd unit] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Enable and start QuickNotes service] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



PLAY RECAP \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

lab5-vm                    : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```



The second run reports `changed=0`, proving that the playbook is idempotent when the VM already matches the desired state.



\---



\## Selective Variable Tweak



I changed one variable in the playbook:



```yaml

quicknotes\_restart\_sec: 2

```



to:



```yaml

quicknotes\_restart\_sec: 3

```



Command:



```bash

sed -i 's/quicknotes\_restart\_sec: 2/quicknotes\_restart\_sec: 3/' ansible/playbook.yaml

ansible-playbook -i ansible/inventory.yaml ansible/playbook.yaml

```



Output:



```text

TASK \[Create QuickNotes group] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Create QuickNotes system user] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Ensure QuickNotes data directory exists] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Ensure QuickNotes config directory exists] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Copy QuickNotes seed file] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Copy QuickNotes binary] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Render QuickNotes systemd unit] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



TASK \[Enable and start QuickNotes service] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



RUNNING HANDLER \[reload systemd] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



RUNNING HANDLER \[restart quicknotes] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



PLAY RECAP \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

lab5-vm                    : ok=10   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```



Only the template changed, which caused the systemd reload and QuickNotes restart handlers to run. The other tasks stayed `ok`.



\---



\## `--check --diff` Preview



I then changed:



```yaml

quicknotes\_restart\_sec: 3

```



to:



```yaml

quicknotes\_restart\_sec: 4

```



Command:



```bash

sed -i 's/quicknotes\_restart\_sec: 3/quicknotes\_restart\_sec: 4/' ansible/playbook.yaml

ansible-playbook -i ansible/inventory.yaml ansible/playbook.yaml --check --diff

```



Output:



```diff

TASK \[Render QuickNotes systemd unit] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

\--- before: /etc/systemd/system/quicknotes.service

+++ after: /root/.ansible/tmp/ansible-local-3546ce654yqm/tmp2gzhsvf0/quicknotes.service.j2

@@ -13,7 +13,7 @@

&#x20;Environment=SEED\_PATH=/etc/quicknotes/seed.json

&#x20;ExecStart=/usr/local/bin/quicknotes

&#x20;Restart=on-failure

\-RestartSec=3s

+RestartSec=4s



&#x20;\[Install]

&#x20;WantedBy=multi-user.target

```



PLAY RECAP:



```text

PLAY RECAP \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

lab5-vm                    : ok=10   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```



This showed the exact systemd unit change before applying it.



\---



\## Final Apply After `--check --diff`



Command:



```bash

ansible-playbook -i ansible/inventory.yaml ansible/playbook.yaml

```



Output:



```text

TASK \[Create QuickNotes group] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Create QuickNotes system user] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Ensure QuickNotes data directory exists] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Ensure QuickNotes config directory exists] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Copy QuickNotes seed file] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Copy QuickNotes binary] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



TASK \[Render QuickNotes systemd unit] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



TASK \[Enable and start QuickNotes service] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



RUNNING HANDLER \[reload systemd] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

ok: \[lab5-vm]



RUNNING HANDLER \[restart quicknotes] \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

changed: \[lab5-vm]



PLAY RECAP \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

lab5-vm                    : ok=10   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```



This applied the `RestartSec=4s` change for real.



\---



\## Task 2 Design Questions



\### e) Why does the second run report `changed=0`?



The second run reports `changed=0` because the VM already matches the desired state described by the playbook.



The `file` module checks whether the directory exists and whether its owner, group, mode, and type match the requested state. If `/var/lib/quicknotes` already exists with owner `quicknotes`, group `quicknotes`, and mode `0750`, it reports `ok`.



The `copy` module checks whether the destination file already has the same content, owner, group, and mode. If the binary and seed file have not changed, it reports `ok`.



The `template` module renders the Jinja2 template locally, compares it with the remote file, and only reports `changed` if the rendered content or file metadata differs.



Because nothing differed during the second run, Ansible reported `changed=0`.



\### f) What would happen if I used `shell: 'echo "ADDR=..." > /etc/systemd/system/quicknotes.service'` instead of `template:`?



Using `shell` would make the playbook less reliable and less idempotent.



First, the shell command would likely rewrite the file every run, causing `changed=1` every time even if the content was logically the same. That would restart the service unnecessarily.



Second, quoting multiline systemd unit content through `echo` is fragile. It is easy to break newlines, quoting, environment variables, or special characters.



Third, the output would not produce a useful diff. With the `template` module, `--check --diff` clearly showed `RestartSec=3s` changing to `RestartSec=4s`. With a shell command, that visibility would be weaker or missing.



Finally, `template` manages owner, group, mode, content comparison, and change detection in a structured way. A shell command would force me to manually reimplement that behavior badly.



\### g) What bug would `--check --diff` catch that plain `--check` might miss?



Plain `--check` tells me that something would change, but it does not show the exact content change. `--check --diff` shows the actual before-and-after difference.



For example, plain `--check` might say the systemd template would change, but `--diff` showed the exact line:



```diff

\-RestartSec=3s

+RestartSec=4s

```



This would catch bugs like accidentally changing the wrong environment variable, pointing `DATA\_PATH` to the wrong location, using the wrong port in `ADDR`, changing the wrong `ExecStart`, or corrupting the unit file formatting. In production, seeing the exact diff before deploying helps prevent a correct-looking playbook from making the wrong configuration change.



\---



\# Bonus Task - ansible-pull GitOps Loop



Bonus was not attempted for this submission.



\---



\## Final File Layout



The Lab 7 files added are:



```text

ansible/

├── inventory.yaml

├── playbook.yaml

├── files/

│   ├── quicknotes

│   └── seed.json

└── templates/

&#x20;   └── quicknotes.service.j2



submissions/

└── lab7.md

```



\---



\## Final Result



QuickNotes was successfully deployed to the Lab 5 VM using Ansible. The service runs under a dedicated `quicknotes` system user, stores data under `/var/lib/quicknotes`, is managed by systemd, and is reachable from the host through the Vagrant port forward.



Final health check:



```json

{"notes":4,"status":"ok"}

```



