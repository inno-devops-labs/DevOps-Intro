# Lab 7 — Configuration Management: Ansible Deployment of QuickNotes

## 1. Files

### inventory.ini
```ini
[quicknotes]
lab5 ansible_host=127.0.0.1

[quicknotes:vars]
ansible_user=vagrant
ansible_port=2222
ansible_ssh_private_key_file=/home/darknesod/.ssh/vagrant_lab5
ansible_python_interpreter=/usr/bin/python3
```
### playbook.yaml
``` YAML
- name: Deploy QuickNotes
  hosts: quicknotes
  become: true

  vars:
    service_user: quicknotes
    data_path: /var/lib/quicknotes
    listen_addr: ":8080"
    seed_path: "/var/lib/quicknotes/seed.json"

  handlers:
    - name: restart quicknotes
      systemd:
        name: quicknotes
        state: restarted

  tasks:
    - name: Create system user
      user:
        name: quicknotes
        system: yes
        shell: /usr/sbin/nologin

    - name: Create data directory
      file:
        path: /var/lib/quicknotes
        state: directory
        owner: quicknotes
        group: quicknotes
        mode: "0750"

    - name: Copy binary
      copy:
        src: files/quicknotes
        dest: /usr/local/bin/quicknotes
        mode: "0755"
      notify: restart quicknotes

    - name: Install systemd service
      template:
        src: templates/quicknotes.service.j2
        dest: /etc/systemd/system/quicknotes.service
      notify: restart quicknotes

    - name: Reload systemd
      systemd:
        daemon_reload: true

    - name: Enable and start service
      systemd:
        name: quicknotes
        enabled: true
        state: started
        daemon_reload: true
```

### quicknotes.service.j2
``` ini
[Unit]
Description=QuickNotes Service
After=network-online.target

[Service]
User={{ service_user }}
WorkingDirectory={{ data_path }}
Environment=ADDR={{ listen_addr }}
Environment=DATA_PATH={{ data_path }}
Environment=SEED_PATH={{ seed_path }}
ExecStart=/usr/local/bin/quicknotes
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```
## 2. PLAY RECAP — First Run
```
PLAY RECAP *********************************************************************
lab5                       : ok=8    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
QuickNotes was fully deployed, including user creation, binary copy, systemd unit installation, and service startup.

## 3. Idempotency Test — Second Run
```
PLAY RECAP *********************************************************************
lab5                       : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
This proves the playbook is idempotent: no changes occur when the system is already in the desired state.

## 4. Variable Change Test

Changed:
```
listen_addr: ":8080" → ":9090"
```
Result:
- systemd template updated
- handler restart quicknotes triggered

```
PLAY RECAP *********************************************************************
lab5                       : ok=8    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
## 5. Final Rerun After Change
```
PLAY RECAP *********************************************************************
lab5                       : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
This confirms convergence: after applying the change once, subsequent runs produce no further modifications.

## 6. Design Questions
a) command vs modules

Modules (apt, file, copy, systemd) are idempotent because they check system state before applying changes. command is not idempotent because it always executes.

b) notify and handlers

Handlers run only when a task reports changed. They execute once per play at the end. They do not run if nothing changes.

c) variable precedence
playbook vars (highest control for this lab)
group_vars (shared environment configuration)
role defaults (fallback baseline)
d) gather_facts

Not strictly required. Disabling it reduces execution time and avoids unnecessary system inspection.

e) Why second run is changed=0

Modules compare desired vs actual state (file hashes, ownership, systemd state). If identical, no changes are applied.

f) shell vs template

Using shell would overwrite files blindly, breaking idempotency and causing constant restarts or drift.

g) --check --diff

It reveals file-level changes before execution. Without it, you may miss unintended configuration drift or destructive changes.

h) ansible-pull security benefit

Pull model removes inbound SSH access requirements. The node initiates configuration retrieval, reducing attack surface.

i) Kubernetes analogy

This is similar to GitOps with ArgoCD, where a cluster continuously reconciles state from a Git repository.